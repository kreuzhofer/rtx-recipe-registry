#!/bin/bash
# Batch deploy + benchmark every @rtx recipe on aihost01 (RTX 5090).
# For each model: deploy via manager inline -> wait running -> wait vLLM API ->
# tps (chat-short) -> tool-eval (tool-eval-quick) -> record -> undeploy.
# Results appended to bench-results.jsonl (resumable: skips models already recorded).
set -uo pipefail
API=http://localhost:4000/api
NODE_ID=cmqb6l6ws1q8i36o0gqjeut5e
NODE_IP=192.168.44.30
REG=/home/daniel/src/github/dgx-manager/rtx-recipe-registry
OUT=$REG/bench-results.jsonl
TPS_PRESET=chat-short
TOOL_PRESET=tool-eval-quick
mkdir -p "$(dirname "$OUT")"; touch "$OUT"

# Deploy order: open models smallest-first, then gated.
MODELS=(
  qwen3/qwen3-4b-bf16-vllm
  qwen2.5/qwen2.5-7b-fp8-vllm
  qwen2.5-coder/qwen2.5-coder-7b-fp8-vllm
  deepseek-r1-distill/deepseek-r1-distill-qwen-7b-fp8-vllm
  qwen3/qwen3-8b-fp8-vllm
  qwen3/qwen3-14b-fp8-vllm
  qwen2.5/qwen2.5-14b-fp8-vllm
  qwen2.5/qwen2.5-14b-awq-vllm
  deepseek-r1-distill/deepseek-r1-distill-qwen-14b-fp8-vllm
  phi/phi-4-fp8-vllm
  gpt-oss/gpt-oss-20b-vllm
  qwen2.5/qwen2.5-32b-awq-vllm
  qwen2.5-coder/qwen2.5-coder-32b-awq-vllm
  qwq/qwq-32b-awq-vllm
  llama3.2/llama-3.2-3b-bf16-vllm
  llama3.1/llama-3.1-8b-fp8-vllm
  mistral/mistral-7b-fp8-vllm
  mistral/mistral-small-24b-fp8-vllm
  gemma3/gemma-3-4b-bf16-vllm
  gemma3/gemma-3-12b-fp8-vllm
  gemma3/gemma-3-27b-awq-vllm
  granite/granite-3.3-8b-fp8-vllm
  nemotron/nemotron-nano-8b-fp8-vllm
  qwen3/qwen3-30b-a3b-fp8-vllm
  qwen3/qwen3-32b-awq-vllm
  glm/glm-4-9b-fp8-vllm
  deepseek-r1-distill/deepseek-r1-distill-llama-8b-fp8-vllm
  phi/phi-4-mini-fp8-vllm
  olmo/olmo-2-13b-fp8-vllm
  falcon/falcon3-10b-fp8-vllm
  yi/yi-1.5-34b-awq-vllm
  qwen2.5/qwen2.5-7b-awq-vllm
  qwen2.5/qwen2.5-7b-bf16-vllm
  qwen3/qwen3-8b-bf16-vllm
  qwen2.5/qwen2.5-32b-gptq-vllm
  qwen2.5/qwen2.5-7b-int8-vllm
  cohere/command-r-35b-awq-vllm
  mistral/devstral-24b-fp8-vllm
  mistral/mistral-nemo-12b-fp8-vllm
  mistral/ministral-8b-fp8-vllm
  qwen3.5/qwen3.5-0.8b-bf16-vllm
  qwen3.5/qwen3.5-2b-bf16-vllm
  qwen3.5/qwen3.5-4b-bf16-vllm
  qwen3.5/qwen3.5-4b-awq-vllm
  qwen3.5/qwen3.5-9b-fp8-vllm
  qwen3.5/qwen3.5-27b-fp8-vllm
  qwen2.5-coder/qwen2.5-coder-32b-gptq-vllm
  qwen3.6/qwen3.6-27b-fp8-vllm
)

jget() { python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('$1',''))" 2>/dev/null; }

# Wait until the node's LATEST reported vramUsed is low enough for admission
# (admission needs free >= 0.85*total + 5% margin, i.e. vramUsed <= ~3200 MiB).
# This gates on the exact signal admission uses, avoiding stale-metric churn.
wait_vram_free() {
  local to=180 t=0
  while [ $t -lt $to ]; do
    used=$(curl -s $API/nodes | python3 -c "
import sys,json
n=[x for x in json.load(sys.stdin) if x['id']=='$NODE_ID']
m=(n[0].get('metrics') or [{}]) if n else [{}]
print(m[0].get('vramUsed') if m and m[0].get('vramUsed') is not None else 99999)" 2>/dev/null)
    [ -n "$used" ] && [ "$used" -le 3000 ] 2>/dev/null && { echo "  node vramUsed=$used MiB (ok to deploy)"; return 0; }
    sleep 10; t=$((t+10))
  done
  echo "  WARN: node vramUsed still high ($used) after ${to}s; deploying anyway"
}

record() { # recipe json-fields...
  python3 - "$@" >> "$OUT" <<'PY'
import sys,json,datetime
rec={"recipe":sys.argv[1]}
for kv in sys.argv[2:]:
    k,_,v=kv.partition("=")
    rec[k]=v
print(json.dumps(rec))
PY
}

already_done() { grep -q "\"recipe\": \"$1\"" "$OUT" 2>/dev/null; }

deploy() { # recipe_file -> echoes deployment id
  local rf=$1
  python3 -c "
import json
y=open('$REG/recipes/$rf.yaml').read()
# No gpuMem override — let each recipe's defaults.gpu_memory_utilization apply
# (so tight 27B models can use 0.92 etc).
print(json.dumps({'nodeId':'$NODE_ID','runtime':'vllm','recipeYaml':y,'config':{'port':8000}}))
" | curl -s -X POST $API/deployments -H 'content-type: application/json' -d @- | jget id
}

wait_running() { # did timeout_s -> prints final status
  local did=$1 to=$2 t=0
  while [ $t -lt $to ]; do
    st=$(curl -s $API/deployments | python3 -c "import sys,json;d=[x for x in json.load(sys.stdin) if x['id']=='$did'];print(d[0]['status'] if d else 'GONE')")
    [ "$st" = running -o "$st" = failed -o "$st" = stopped -o "$st" = GONE ] && { echo "$st"; return; }
    sleep 15; t=$((t+15))
  done
  echo timeout
}

wait_api() { # timeout_s -> 0 ready / 1 not
  local to=$1
  timeout $((to+20)) ssh -o StrictHostKeyChecking=no $NODE_IP "for i in \$(seq 1 $((to/10))); do curl -sf -m5 http://localhost:8000/v1/models >/dev/null 2>&1 && exit 0; sleep 10; done; exit 1"
}

run_bench() { # did preset -> echoes "status|tps|tooleval|rating"
  local did=$1 preset=$2
  local bid=$(curl -s -X POST $API/benchmarks -H 'content-type: application/json' -d "{\"deploymentId\":\"$did\",\"presetId\":\"$preset\"}" | jget id)
  [ -z "$bid" ] && { echo "start-failed|||"; return; }
  local t=0
  while [ $t -lt 1800 ]; do
    out=$(curl -s $API/benchmarks/$bid | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('%s|%s|%s|%s'%(d['status'],d.get('meanTps') or '',d.get('toolEvalScore') or '',d.get('toolEvalRating') or ''))")
    st=${out%%|*}
    [ "$st" = completed -o "$st" = failed -o "$st" = canceled ] && { echo "$out"; return; }
    sleep 12; t=$((t+12))
  done
  echo "timeout|||"
}

undeploy() { local did=$1; curl -s -X DELETE "$API/deployments/$did?delete=true" >/dev/null 2>&1
  for i in $(seq 1 24); do curl -s $API/deployments | grep -q "$did" || return; sleep 5; done; }

for rf in "${MODELS[@]}"; do
  if already_done "$rf"; then echo "SKIP (done): $rf"; continue; fi
  echo "=================================================================="
  echo "MODEL: $rf  ($(date -u +%H:%M:%S))"
  # Determine the model's HF cache dir and whether it already exists (cluster model
  # we must NOT delete) vs newly downloaded by us (safe to clean afterward).
  MID=$(grep -E '^model:' "$REG/recipes/$rf.yaml" | head -1 | sed 's/model:[[:space:]]*//' | tr -d '\r')
  CACHE_DIR="/mnt/tank/models/hub/models--$(echo "$MID" | sed 's#/#--#g' | sed 's#:.*##')"
  PRE_EXISTED=no
  ssh -o StrictHostKeyChecking=no $NODE_IP "test -d '$CACHE_DIR'" 2>/dev/null && PRE_EXISTED=yes
  echo "  model=$MID  cache_pre_existed=$PRE_EXISTED"
  wait_vram_free
  did=""; for attempt in $(seq 1 10); do did=$(deploy "$rf"); [ -n "$did" ] && break; echo "  deploy attempt $attempt empty (vram/admission timing?), retrying"; sleep 20; done
  if [ -z "$did" ]; then echo "  deploy POST failed"; record "$rf" deploy=post-failed; continue; fi
  echo "  deployment=$did"
  st=$(wait_running "$did" 1500)
  echo "  deploy status=$st"
  if [ "$st" != running ]; then
    log=$(curl -s "$API/deployments/$did/logs?tail=8" | tr '\n' ' ' | tail -c 300)
    record "$rf" deploy="$st" error="${log//\"/ }"
    undeploy "$did"; continue
  fi
  if ! wait_api 600; then
    echo "  API not ready"; record "$rf" deploy=running api=not-ready
    undeploy "$did"; continue
  fi
  vram=$(curl -s $API/deployments | python3 -c "import sys,json;d=[x for x in json.load(sys.stdin) if x['id']=='$did'];print(d[0].get('vramActual') or '')")
  echo "  API ready, vram=$vram MiB"
  tps_out=$(run_bench "$did" "$TPS_PRESET");  echo "  tps:  $tps_out"
  tool_out=$(run_bench "$did" "$TOOL_PRESET"); echo "  tool: $tool_out"
  record "$rf" deploy=running vram="$vram" \
    tps_status="${tps_out%%|*}" tps="$(echo "$tps_out"|cut -d'|' -f2)" \
    tool_status="${tool_out%%|*}" tooleval="$(echo "$tool_out"|cut -d'|' -f3)" rating="$(echo "$tool_out"|cut -d'|' -f4)"
  undeploy "$did"
  # Self-clean: delete the model's HF cache ONLY if WE downloaded it (never a
  # pre-existing cluster model), to keep the NFS from filling up.
  if [ "$PRE_EXISTED" = no ] && [ -n "$CACHE_DIR" ]; then
    ssh -o StrictHostKeyChecking=no $NODE_IP "rm -rf '$CACHE_DIR'" 2>/dev/null && echo "  cleaned HF cache: $CACHE_DIR"
  fi
  sleep 15   # let GPU VRAM fully release before the next deploy's admission check
  echo "  done + undeployed"
done
echo "=== BATCH COMPLETE ($(date -u +%H:%M:%S)) ==="

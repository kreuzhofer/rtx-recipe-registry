#!/bin/bash
# Run AFTER: aihost01 fsck'd/rebooted (clean dmesg, readable /etc/ssl/certs)
# AND a valid HF token w/ accepted licenses at /mnt/tank/models/token.
# Clears all failed records so blocked/gated/failed models re-run, then resumes
# the batch (skips the models already benchmarked OK).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json
keep=[l.rstrip("\n") for l in open("bench-results.jsonl")
      if json.loads(l).get("tps")]   # keep only successful (have tps)
open("bench-results.jsonl","w").write("\n".join(keep)+("\n" if keep else ""))
print(f"kept {len(keep)} successful records; all failures cleared for re-run")
PY
echo "Pre-flight checks on aihost01:"
ssh -o StrictHostKeyChecking=no 192.168.44.30 'echo " dmesg ext4:"; sudo dmesg|grep -ic "EXT4-fs error" || true; echo " cert readable:"; head -c1 /etc/ssl/certs/ca-certificates.crt >/dev/null 2>&1 && echo OK || echo BAD; echo " HF token:"; HF_HOME=/mnt/tank/models ~/.local/bin/uv run --quiet --with huggingface_hub python3 -c "from huggingface_hub import whoami;print(whoami().get(\"name\"))" 2>&1 | tail -1'
echo "Launching batch..."
bash scripts/run-benchmarks.sh

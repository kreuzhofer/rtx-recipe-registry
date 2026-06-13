<h3 align="center">sparkrun recipes for amd64 + NVIDIA RTX</h3>

<p align="center">
  Inference recipes for x86-64 machines with discrete NVIDIA RTX GPUs —
  RTX 5090, RTX PRO 6000 Blackwell, and similar — run through
  <a href="https://github.com/spark-arena/sparkrun">sparkrun</a>.
</p>

---

This is a custom [sparkrun](https://github.com/spark-arena/sparkrun) recipe registry for **amd64 hosts with
consumer/workstation NVIDIA GPUs**. The official sparkrun registries (`@official`, `@eugr`, `@community`, …) target
**NVIDIA DGX Spark** (arm64 + GB10, `sm_121a`) with arm64-only container images, so none of those recipes run on an
x86-64 RTX box. These do.

Recipes here are run with the `@rtx` prefix:

```bash
sparkrun run @rtx/qwen3-4b-bf16-vllm
```

## Why these work where the official library doesn't

`sparkrun`'s **solo** (single-node) run path is architecture-agnostic — the GB10 gating is clustering-only, and its
"121 GB unified memory" estimate is cosmetic (display only, never blocks launch). vLLM itself runs fine on consumer
Blackwell (`sm_120`, e.g. RTX 5090): the upstream `vllm/vllm-openai` image ships `sm_120` kernels (torch cu130) and
loads/serves models normally. The friction is entirely in how sparkrun *launches* the container on non-DGX hardware.
Three things make a recipe work on amd64 + RTX (all verified live on an RTX 5090):

1. **`container:` → an entrypoint-less wrapper of the upstream vLLM image** (`rtx-vllm`, built from
   `vllm/vllm-openai`; see [`images/`](images/)). **Why:** sparkrun launches the container with a keep-alive command
   (`bash -c "sleep infinity"`) and then `docker exec`s the serve command. The upstream image declares
   `ENTRYPOINT ["vllm","serve"]`, so the keep-alive becomes `vllm serve bash -c "sleep infinity"` → the container dies
   in ~3 s. Resetting `ENTRYPOINT []` fixes it. (The DGX/eugr images work because they have a shell entrypoint.)

2. **`executor_config: { devices: [] }` → drop the hardcoded `--device /dev/infiniband`.** **Why:** when sparkrun runs
   as a non-root user (rootless mode — which the dgx-manager agent does) it injects `--device /dev/infiniband` into the
   `docker run`. DGX Spark has InfiniBand/RDMA hardware so the device exists; an RTX box does not, so `docker run` fails
   with *"error gathering device information while adding custom device /dev/infiniband: no such file or directory"* —
   and sparkrun's launch script (`set -uo pipefail`, no `set -e`) **swallows the error** and reports success, so the
   only downstream symptom is a later "No such container". Setting `devices: []` in the recipe overrides it (recipe
   `executor_config` outranks sparkrun's rootless adjustments).

3. **No `builder:` field** → with `recipe_version: 2` + an explicit `container:` and no `build_args`/`mods`, sparkrun
   skips the image-build step and just uses the (locally-built or pulled) image.

With those, sparkrun runs the container generically (`docker run --gpus all --network host`, HF cache mounted) and
execs `vllm serve` inside it — and vLLM serves on the RTX GPU.

> **Container tag:** the wrapper is built `FROM vllm/vllm-openai:<tag>`; pin a tag with **consumer Blackwell (`sm_120`)**
> support (CUDA 12.8+; `latest`/cu130 work today). NVFP4 is intentionally avoided — those kernels are `sm_121a`/GB10-only;
> we use bf16 (small models) and fp8 / AWQ-int4 (larger), all supported on `sm_120`.

## Build the wrapper image (required, one-time per amd64 node)

The recipes reference `rtx-vllm:latest`. Build it on each amd64 node (near-instant — it only resets the entrypoint;
all base layers are reused):

```bash
docker build -t rtx-vllm:latest images/vllm-openai-entrypointless/
```

sparkrun uses the local image (its distribution layer detects locally-built images and skips the registry pull). For
multi-node fleets, instead push it once and point `container:` at the registry tag:

```bash
docker build -t ghcr.io/kreuzhofer/rtx-vllm:latest images/vllm-openai-entrypointless/
docker push ghcr.io/kreuzhofer/rtx-vllm:latest
```

## Register this registry

```bash
sparkrun registry add https://github.com/kreuzhofer/rtx-recipe-registry
sparkrun list @rtx
```

(`sparkrun registry add` reads `.sparkrun/registry.yaml` from this repo and pulls the recipes.)

## Hardware tiers

Recipes are sized to fit common RTX VRAM envelopes. The model's VRAM need (weights + KV) must fit the card; pick by tier:

| Tier | Example GPUs | VRAM | Good for |
|---|---|---|---|
| 32 GB | RTX 5090 | 32 GB | ≤14B (bf16 ≤4B, fp8 ≤8B, AWQ-int4 ≤14B) |
| 48 GB | RTX 6000 Ada | 48 GB | ≤32B quantized |
| 96 GB | RTX PRO 6000 Blackwell | 96 GB | ≤70B quantized, or smaller at long context |

Multi-GPU on a single host works via tensor-parallel within the node (`tensor_parallel: N` + `--gpus all`) — this is
plain vLLM TP, not the multi-node Ray path (which is GB10-gated and not used here).

## Directory structure

```
recipes/{model-family}/{model}-{quant}-{runtime}.yaml
```

The recipe filename is the canonical lookup (`@rtx/<filename-without-.yaml>`), so it must be unique and descriptive.
Include the dtype/quant even when "native" (e.g. `bf16`) for clarity. A `README.md` may sit alongside a recipe; only
the `.yaml` is part of the recipe.

## Recipe format

Standard sparkrun v2 recipe schema. See the [recipe authoring docs](https://sparkrun.dev/recipes/overview/). A minimal
amd64 recipe:

```yaml
recipe_version: "2"
model: Qwen/Qwen3-4B
runtime: vllm
container: vllm/vllm-openai:latest   # pin a tag with sm_120 support
metadata:
  description: Qwen3 4B (bf16) — amd64 + RTX, 32GB class
defaults:
  port: 8000
  host: 0.0.0.0
  tensor_parallel: 1
  gpu_memory_utilization: 0.85
  max_model_len: 16384
  served_model_name: qwen3-4b
command: |
  vllm serve {model} \
      --served-model-name {served_model_name} \
      --host {host} --port {port} \
      --tensor-parallel-size {tensor_parallel} \
      --gpu-memory-utilization {gpu_memory_utilization} \
      --max-model-len {max_model_len}
```

## Links

- [sparkrun](https://github.com/spark-arena/sparkrun) — the tool that runs recipes
- [sparkrun docs](https://sparkrun.dev) — full documentation

# Entrypoint-less wrapper around the upstream multi-arch vLLM image.
#
# WHY THIS EXISTS:
#   sparkrun's vllm runtime (`runtime: vllm` → resolves to `vllm-distributed`)
#   launches the container with a two-phase pattern: it runs the container with
#   a keep-alive command (`bash -c "sleep infinity"`) and then `docker exec`s the
#   real `vllm serve …` command inside it. It does NOT pass `--entrypoint`.
#
#   The upstream `vllm/vllm-openai` image declares `ENTRYPOINT ["vllm","serve"]`,
#   so the keep-alive becomes `vllm serve bash -c "sleep infinity"` → vLLM errors
#   on the unknown args and the container dies in ~3 s ("container is not running",
#   "CRITICAL: Container died unexpectedly after detached launch").
#
#   Resetting ENTRYPOINT to [] makes the keep-alive run as written, the container
#   idles, and sparkrun's `docker exec vllm serve …` works (vllm is on PATH).
#   The DGX/eugr images work with sparkrun precisely because they have a shell
#   entrypoint; this wrapper gives the upstream amd64 image the same property.
#
#   (The `atlas` runtime injects `--entrypoint '""'` for the same reason —
#   see sparkrun runtimes/atlas.py — but it runs its own `spark` binary, not
#   `vllm serve`, so it can't be reused with the upstream image.)
#
# BUILD (on an amd64 host; base layers are reused so this is near-instant):
#   docker build -t rtx-vllm:latest .
#   # optional, to share across nodes / survive prune:
#   #   docker tag rtx-vllm:latest ghcr.io/kreuzhofer/rtx-vllm:latest
#   #   docker push ghcr.io/kreuzhofer/rtx-vllm:latest
#
# Pin the same upstream tag your recipes target (must have sm_120 support).
ARG VLLM_TAG=latest
FROM vllm/vllm-openai:${VLLM_TAG}
ENTRYPOINT []

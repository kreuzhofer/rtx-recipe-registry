# RTX 5090 (32 GB) — model recipe checklist & benchmark results

Target: **aihost01**, RTX 5090, 32 GB, amd64, sm_120. Each model is deployed via the manager, then run
through two dgx-manager benchmarks: **tps** (throughput, `chat-short` preset) and **tool-eval** (`tool-eval-quick`).
Results are filled in as the batch runs.

Quant policy for 32 GB: bf16 (≤4B), fp8 dynamic (7–14B), AWQ-int4 (24–32B). No NVFP4 (sm_121a/GB10-only).

## Review checklist (check/trim before/while the batch runs)

### Open models (ungated — high confidence)
- [ ] `@rtx/qwen3-1.7b-bf16-vllm` — Qwen3 1.7B (bf16) · reasoning
- [ ] `@rtx/qwen3-4b-bf16-vllm` — Qwen3 4B (bf16) · reasoning
- [ ] `@rtx/qwen3-8b-fp8-vllm` — Qwen3 8B (fp8) · reasoning
- [ ] `@rtx/qwen3-14b-fp8-vllm` — Qwen3 14B (fp8) · reasoning
- [ ] `@rtx/qwen2.5-7b-fp8-vllm` — Qwen2.5 7B Instruct (fp8)
- [ ] `@rtx/qwen2.5-14b-fp8-vllm` — Qwen2.5 14B Instruct (fp8)
- [ ] `@rtx/qwen2.5-14b-awq-vllm` — Qwen2.5 14B Instruct (AWQ int4)
- [ ] `@rtx/qwen2.5-32b-awq-vllm` — Qwen2.5 32B Instruct (AWQ int4, ~18 GB)
- [ ] `@rtx/qwen2.5-coder-7b-fp8-vllm` — Qwen2.5-Coder 7B (fp8) · code
- [ ] `@rtx/qwen2.5-coder-32b-awq-vllm` — Qwen2.5-Coder 32B (AWQ int4) · code
- [ ] `@rtx/deepseek-r1-distill-qwen-7b-fp8-vllm` — DeepSeek-R1-Distill-Qwen 7B (fp8) · reasoning
- [ ] `@rtx/deepseek-r1-distill-qwen-14b-fp8-vllm` — DeepSeek-R1-Distill-Qwen 14B (fp8) · reasoning
- [ ] `@rtx/phi-4-fp8-vllm` — Phi-4 14B (fp8)
- [ ] `@rtx/gpt-oss-20b-vllm` — gpt-oss-20b (MXFP4 MoE) · ⚠️ sm_120 MXFP4 support uncertain
- [ ] `@rtx/qwq-32b-awq-vllm` — QwQ-32B (AWQ int4) · reasoning · ⚠️ verify AWQ checkpoint

### Gated models (need HF license acceptance on the agent's HF token)
- [ ] `@rtx/llama-3.2-3b-bf16-vllm` — Llama 3.2 3B Instruct (bf16) · 🔒 gated
- [ ] `@rtx/llama-3.1-8b-fp8-vllm` — Llama 3.1 8B Instruct (fp8) · 🔒 gated
- [ ] `@rtx/mistral-7b-fp8-vllm` — Mistral 7B Instruct v0.3 (fp8) · 🔒 gated
- [ ] `@rtx/mistral-small-24b-fp8-vllm` — Mistral Small 24B (fp8, ~24 GB tight) · 🔒 gated
- [ ] `@rtx/gemma-3-4b-bf16-vllm` — Gemma 3 4B it (bf16) · 🔒 gated
- [ ] `@rtx/gemma-3-12b-fp8-vllm` — Gemma 3 12B it (fp8) · 🔒 gated
- [ ] `@rtx/gemma-3-27b-awq-vllm` — Gemma 3 27B it (AWQ int4, community) · 🔒 gated · ⚠️ verify checkpoint

## Results — RTX 5090 (aihost01, 32 GB, sm_120)

**17 models benchmarked.** `gen tps` = single-stream decode @ concurrency 1 (the user-facing generation speed); `prefill` = prompt-processing throughput. Tool-eval = dgx-manager `tool-eval-quick` (15 scenarios); throughput = `chat-short`.

| Model | Quant | gen tps | prefill tps | tool-eval | rating |
|---|---|---:|---:|---:|---|
| Qwen/Qwen3-8B | fp8 | 145.8 | 16326 | 83 | ★★★★ Good |
| Qwen/Qwen2.5-32B-Instruct-AWQ | AWQ int4 | 74.3 | 2700 | 80 | ★★★★ Good |
| Qwen/Qwen3-14B | fp8 | 89.0 | 10982 | 77 | ★★★★ Good |
| Qwen/QwQ-32B-AWQ | AWQ int4 | 74.4 | 2684 | 73 | ★★★ Adequate |
| Qwen/Qwen2.5-14B-Instruct | fp8 | 88.6 | 8367 | 73 | ★★★ Adequate |
| Qwen/Qwen3-1.7B | bf16 | 318.4 | 29164 | 73 | ★★★ Adequate |
| Qwen/Qwen2.5-7B-Instruct | bf16 | 160.8 | 12925 | 67 | ★★★ Adequate |
| Qwen/Qwen3-4B | bf16 | 160.5 | 17082 | 67 | ★★★ Adequate |
| Qwen/Qwen2.5-14B-Instruct-AWQ | AWQ int4 | 139.7 | 5273 | 47 | ★★ Weak |
| openai/gpt-oss-20b | MXFP4 | 280.7 | 16728 | 33 | ★ Poor |
| mistralai/Mistral-7B-Instruct-v0.3 | fp8 | 169.3 | 18783 | 20 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-14B | fp8 | 89.3 | 8311 | 13 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-7B | fp8 | 162.7 | 12850 | 13 | ★ Poor |
| Qwen/Qwen2.5-Coder-7B-Instruct | fp8 | 160.8 | 12912 | 7 | ★ Poor |
| ibm-granite/granite-3.3-8b-instruct | fp8 | 148.0 | 11397 | 0 | ★ Poor |
| gaunernst/gemma-3-27b-it-int4-awq | AWQ int4 | 71.1 | 3135 | 0 | ★ Poor |
| microsoft/phi-4 | fp8 | 91.6 | 6674 | 0 | ★ Poor |

**Notes:** tool-eval of 0–7 for Coder-7B / Phi-4 / Granite / Gemma reflects a **missing vLLM tool-call parser** for those families (not the model's true ability). fp8 = vLLM dynamic fp8; AWQ/GPTQ = pre-quantized int4. MXFP4 gpt-oss confirmed working on sm_120.

### Headlines
- **Best tool use (32 GB):** Qwen3-8B (83), Qwen2.5-32B-AWQ (80), Qwen3-14B (77).
- **Fastest useful:** Qwen3-1.7B (318 tok/s), gpt-oss-20b (281, MoE).
- **Quant tradeoff:** 14B AWQ-int4 ~57% faster decode than fp8 (140 vs 89) but lower tool quality (47 vs 73); at 32B, AWQ holds quality (80).

### Not yet benchmarked (blocked — to resume)
- **Gated (need a valid HF token w/ accepted licenses):** Llama-3.2-3B, Llama-3.1-8B, Mistral-Small-24B, Gemma-3-4B/12B, Nemotron-Nano-8B, Command-R-35B, Devstral-24B, Mistral-Nemo-12B, Ministral-8B.
- **Blocked by aihost01 root-FS corruption (needs fsck/reboot):** Qwen3-30B-A3B, Qwen3-32B-AWQ, GLM-4-9B, DeepSeek-R1-Distill-Llama-8B, Phi-4-mini, OLMo-2-13B, Falcon3-10B, Yi-1.5-34B, the quant variants (Qwen2.5-7B AWQ/bf16/int8, Qwen3-8B bf16, Qwen2.5-32B GPTQ), and all 7 Qwen3.5/3.6.
- **Other failures:** Qwen2.5-Coder-32B-AWQ (vLLM segfault on load — try GPTQ or different gpu-mem).

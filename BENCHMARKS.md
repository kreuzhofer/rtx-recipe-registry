# RTX 5090 benchmark results

All runs on **aihost01** — single RTX 5090 (32 GB, sm_120, amd64) — via the `@rtx` sparkrun registry on dgx-manager.

`gen tps` = single-stream **decode** throughput @ concurrency 1 (token generation). `prefill` = prompt-processing tps. Tool-eval = dgx-manager `tool-eval-quick` (0–100). Throughput preset = `chat-short`.

Tool-call parsers per family: Qwen3.5/3.6 → `qwen3_coder`+`qwen3`; Qwen3/2.5 → `hermes`; Llama → `llama3_json`; Mistral → `mistral`. Families without a wired parser score 0 (recipe gap, not a model limit).

## Served & benchmarked (35 recipes)

| Model | Quant | gen tps | prefill | tool-eval | rating |
|---|---|--:|--:|--:|---|
| Qwen/Qwen3.5-9B | fp8 | 138.7 | 11176 | 100 | ★★★★★ Excellent |
| mistralai/Mistral-Small-24B-Instruct-2501 | fp8 | 61.4 | 8064 | 93 | ★★★★★ Excellent |
| Qwen/Qwen3.5-4B | bf16 | 160.5 | 9678 | 90 | ★★★★★ Excellent |
| Qwen/Qwen3-8B | fp8 | 96.4 | 10738 | 83 | ★★★★ Good |
| Qwen/Qwen2.5-32B-Instruct-GPTQ-Int4 | GPTQ-int4 | 75.4 | 2813 | 80 | ★★★★ Good |
| Qwen/Qwen2.5-32B-Instruct-AWQ | AWQ-int4 | 74.3 | 2700 | 80 | ★★★★ Good |
| Qwen/Qwen3-14B | fp8 | 89.0 | 10983 | 77 | ★★★★ Good |
| Qwen/Qwen3-1.7B | bf16 | 305.1 | 27838 | 73 | ★★★ Adequate |
| Qwen/Qwen2.5-14B-Instruct | fp8 | 88.6 | 8368 | 73 | ★★★ Adequate |
| Qwen/Qwen3-32B-AWQ | AWQ-int4 | 74.8 | 2646 | 73 | ★★★ Adequate |
| Qwen/QwQ-32B-AWQ | AWQ-int4 | 74.4 | 2684 | 73 | ★★★ Adequate |
| Qwen/Qwen3-4B | bf16 | 160.5 | 17082 | 67 | ★★★ Adequate |
| Qwen/Qwen2.5-7B-Instruct | fp8 | 102.8 | 9506 | 67 | ★★★ Adequate |
| Qwen/Qwen2.5-7B-Instruct | bf16 | 102.8 | 9506 | 67 | ★★★ Adequate |
| Qwen/Qwen3.5-2B | bf16 | 307.3 | 12599 | 63 | ★★★ Adequate |
| Qwen/Qwen3.5-0.8B | bf16 | 540.6 | 12366 | 57 | ★★ Weak |
| Qwen/Qwen2.5-7B-Instruct-AWQ | AWQ-int4 | 244.8 | 8767 | 57 | ★★ Weak |
| Qwen/Qwen2.5-14B-Instruct-AWQ | AWQ-int4 | 139.7 | 5273 | 47 | ★★ Weak |
| openai/gpt-oss-20b | MXFP4 | 280.7 | 16729 | 33 | ★ Poor |
| meta-llama/Llama-3.2-3B-Instruct | bf16 | 205.2 | 18964 | 30 | ★ Poor |
| meta-llama/Llama-3.1-8B-Instruct | fp8 | 154.4 | 14613 | 27 | ★ Poor |
| mistralai/Mistral-7B-Instruct-v0.3 | fp8 | 169.3 | 18783 | 20 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-7B | fp8 | 162.7 | 12850 | 13 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Llama-8B | fp8 | 155.1 | 17060 | 13 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-14B | fp8 | 89.3 | 8311 | 13 | ★ Poor |
| Qwen/Qwen2.5-Coder-7B-Instruct | fp8 | 160.8 | 12913 | 7 | ★ Poor |
| microsoft/Phi-4-mini-instruct | fp8 | 223.7 | 21180 | 0 | ★ Poor |
| google/gemma-3-4b-it | bf16 | 151.0 | 12203 | 0 | ★ Poor |
| ibm-granite/granite-3.3-8b-instruct | fp8 | 148.0 | 11397 | 0 | ★ Poor |
| THUDM/glm-4-9b-chat | fp8 | 124.3 | 10508 | 0 | ★ Poor |
| tiiuae/Falcon3-10B-Instruct | fp8 | 117.2 | 12512 | 0 | ★ Poor |
| Qwen/Qwen3-8B | bf16 | 96.4 | 10738 | 0 | ★ Poor |
| microsoft/phi-4 | fp8 | 91.6 | 6675 | 0 | ★ Poor |
| google/gemma-3-12b-it | fp8 | 90.9 | 10470 | 0 | ★ Poor |
| gaunernst/gemma-3-27b-it-int4-awq | AWQ-int4 | 71.1 | 3135 | 0 | ★ Poor |

## Did not serve (14 recipes)

| Recipe | Cause |
|---|---|
| `cohere/command-r-35b-awq-vllm` | checkpoint missing / gated |
| `mistral/devstral-24b-fp8-vllm` | HF download exceeded 1500 s deploy cap — **inconclusive, retry** |
| `mistral/ministral-8b-fp8-vllm` | HF download exceeded 1500 s deploy cap — **inconclusive, retry** |
| `mistral/mistral-nemo-12b-fp8-vllm` | HF download exceeded 1500 s deploy cap — **inconclusive, retry** |
| `nemotron/nemotron-nano-8b-fp8-vllm` | loaded but vLLM API never came up (load failure) |
| `olmo/olmo-2-13b-fp8-vllm` | loaded but vLLM API never came up (load failure) |
| `qwen2.5-coder/qwen2.5-coder-32b-awq-vllm` | deploy timeout |
| `qwen2.5-coder/qwen2.5-coder-32b-gptq-vllm` | HF download exceeded 1500 s deploy cap — **inconclusive, retry** |
| `qwen2.5/qwen2.5-7b-int8-vllm` | loaded but vLLM API never came up (load failure) |
| `qwen3.5/qwen3.5-27b-fp8-vllm` | loaded but vLLM API never came up (load failure) |
| `qwen3.5/qwen3.5-4b-awq-vllm` | deploy timeout |
| `qwen3.6/qwen3.6-27b-fp8-vllm` | HF download exceeded 1500 s deploy cap — **inconclusive, retry** |
| `qwen3/qwen3-30b-a3b-fp8-vllm` | loaded but vLLM API never came up (load failure) |
| `yi/yi-1.5-34b-awq-vllm` | checkpoint missing / gated |

## Notes

- **Best in 32 GB:** Qwen3.5-9B (tool-eval 100 @ 139 tps), Mistral-Small-24B (93), Qwen3.5-4B (90 @ 161 tps).
- **Genuine 32 GB non-fits:** 27–32B at fp8 OOM; Coder-32B int4 (AWQ+GPTQ) won't load on the current `vllm/cu130` image.
- **Download-timeout failures** (Devstral-24B, Mistral-Nemo-12B, Ministral-8B) are inconclusive — they died fetching weights inside the deploy cap, not from a fit/runtime error.
- **tool-eval = 0** for Phi-4, Gemma-3, Granite, GLM-4, Falcon3, Qwen3-8B-bf16: these serve fine but their recipes lack a family-specific `--tool-call-parser`. Wiring it is the next fix (it took Qwen3.5 from low → 100).

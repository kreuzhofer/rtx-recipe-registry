

## Results — RTX 5090 (aihost01, 32 GB, sm_120)

**25 models benchmarked.** `gen tps` = single-stream decode @ concurrency 1; `prefill` = prompt-processing tps. Tool-eval = dgx-manager `tool-eval-quick` (15 scenarios); throughput = `chat-short`. Qwen3.5/3.6 use the `qwen3_coder`+`qwen3` parsers; Qwen3/2.5 use `hermes`.

| Model | Quant | gen tps | prefill | tool-eval | rating |
|---|---|--:|--:|--:|---|
| Qwen/Qwen3.5-9B | fp8 | 138.7 | 11098 | 100 | ★★★★★ Excellent |
| Qwen/Qwen3.5-4B | bf16 | 160.0 | 9612 | 90 | ★★★★★ Excellent |
| Qwen/Qwen3-8B | fp8 | 145.8 | 16326 | 83 | ★★★★ Good |
| Qwen/Qwen2.5-32B-Instruct-GPTQ-Int4 | GPTQ-int4 | 75.4 | 2813 | 80 | ★★★★ Good |
| Qwen/Qwen2.5-32B-Instruct-AWQ | AWQ-int4 | 74.3 | 2700 | 80 | ★★★★ Good |
| Qwen/Qwen3-14B | fp8 | 89.0 | 10982 | 77 | ★★★★ Good |
| Qwen/Qwen3-32B-AWQ | AWQ-int4 | 74.8 | 2646 | 73 | ★★★ Adequate |
| Qwen/QwQ-32B-AWQ | AWQ-int4 | 74.4 | 2684 | 73 | ★★★ Adequate |
| Qwen/Qwen2.5-14B-Instruct | fp8 | 88.6 | 8367 | 73 | ★★★ Adequate |
| Qwen/Qwen3-1.7B | bf16 | 318.4 | 29164 | 73 | ★★★ Adequate |
| Qwen/Qwen2.5-7B-Instruct | bf16 | 160.8 | 12925 | 67 | ★★★ Adequate |
| Qwen/Qwen3-4B | bf16 | 160.5 | 17082 | 67 | ★★★ Adequate |
| Qwen/Qwen3.5-2B | bf16 | 304.3 | 12586 | 63 | ★★★ Adequate |
| Qwen/Qwen3.5-0.8B | bf16 | 539.3 | 13613 | 57 | ★★ Weak |
| Qwen/Qwen2.5-7B-Instruct-AWQ | AWQ-int4 | 244.8 | 8767 | 57 | ★★ Weak |
| Qwen/Qwen2.5-14B-Instruct-AWQ | AWQ-int4 | 139.7 | 5273 | 47 | ★★ Weak |
| openai/gpt-oss-20b | MXFP4 | 280.7 | 16728 | 33 | ★ Poor |
| mistralai/Mistral-7B-Instruct-v0.3 | fp8 | 169.3 | 18783 | 20 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-14B | fp8 | 89.3 | 8311 | 13 | ★ Poor |
| deepseek-ai/DeepSeek-R1-Distill-Qwen-7B | fp8 | 162.7 | 12850 | 13 | ★ Poor |
| Qwen/Qwen2.5-Coder-7B-Instruct | fp8 | 160.8 | 12912 | 7 | ★ Poor |
| THUDM/glm-4-9b-chat | fp8 | 124.3 | 10508 | 0 | ★ Poor |
| ibm-granite/granite-3.3-8b-instruct | fp8 | 148.0 | 11397 | 0 | ★ Poor |
| gaunernst/gemma-3-27b-it-int4-awq | AWQ-int4 | 71.1 | 3135 | 0 | ★ Poor |
| microsoft/phi-4 | fp8 | 91.6 | 6674 | 0 | ★ Poor |

### Not benchmarked (by reason)
- **🔒 Gated — need a valid HF token:** llama-3.2-3b-bf16, llama-3.1-8b-fp8, mistral-small-24b-fp8, gemma-3-4b-bf16, gemma-3-12b-fp8, nemotron-nano-8b-fp8, command-r-35b-awq, devstral-24b-fp8, mistral-nemo-12b-fp8, ministral-8b-fp8
- **💾 Too tight for 32 GB (fp8 weights ~27–30 GB → OOM):** qwen3-30b-a3b-fp8, qwen3.5-27b-fp8, qwen3.6-27b-fp8
- **⚙️ No working int4 build on sm_120 (AWQ segfault + GPTQ hang):** qwen2.5-coder-32b-awq, qwen2.5-coder-32b-gptq
- **❓ Bad/missing checkpoint:** yi-1.5-34b-awq
- **⏳ Download stalled (HF rate-limit, unauthenticated — needs token; retryable):** phi-4-mini-fp8, deepseek-r1-distill-llama-8b-fp8, olmo-2-13b-fp8, falcon3-10b-fp8, qwen2.5-7b-bf16, qwen2.5-7b-int8

### Headlines
- **Best tool use:** Qwen3.5-9B **100** and Qwen3.5-4B **90** (★★★★★) — the Qwen3.5 line dominates once parsed with `qwen3_coder`.
- **Fastest:** Qwen3.5-0.8B 539 tok/s, Qwen3-1.7B 318, Qwen3.5-2B 304, gpt-oss-20b 281 (MoE).
- **Best 'big' model:** Qwen2.5-32B int4 (AWQ & GPTQ both 80, ~75 tok/s) — int4 quant choice doesn't matter at 32B.
- **Quant tradeoffs:** 7B AWQ 245 tok/s vs bf16 161 (but tool 57 vs 67); 14B AWQ 140 vs fp8 89 (tool 47 vs 73).
- **Parser coverage gaps** (tool-eval 0, not model ability): GLM-4, Granite, Gemma, Phi-4 have no matching vLLM tool-call parser.

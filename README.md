# Gemma-4-26B-A4B on RTX PRO 1000 8 GB — Windows GGUF recipe

A standalone, native-Windows llama.cpp profile measured on **8 November 2026**. Selected longer-validation decode rate: **41.12 tokens/s**. This is a tested profile for one system, not a universal best configuration or a speed guarantee.

Most expert weights remain in system RAM; a GPU expert cache and CPU execution of eligible cache misses make the model usable with 8 GB VRAM. See [CPU miss handling PR #30966](https://github.com/ggml-org/llama.cpp/pull/30966) and [speculative decoding](https://github.com/ggml-org/llama.cpp/blob/b12201/docs/speculative.md).

## Requirements and runtime

- Windows x64, Intel Core Ultra 7 265H (16 reported logical processors), 64 GB system RAM, NVIDIA RTX PRO 1000 Blackwell **Laptop** GPU (8150 MiB VRAM). An 8 GB GPU alone does not establish equivalent performance.
- Recorded runtime: **llama.cpp b12201, commit a2b301831**, CUDA 13.5 Windows x64 build, with available CUDA 13 runtime libraries and a compatible NVIDIA driver.
- Download [llama.cpp b12201 Windows CUDA 13.5 ZIP](https://github.com/ggml-org/llama.cpp/releases/download/b12201/llama-b12201-bin-win-cuda-13.5-x64.zip) and [matching CUDA runtime DLL ZIP](https://github.com/ggml-org/llama.cpp/releases/download/b12201/cudart-llama-bin-win-cuda-13.5-x64.zip), from the [release](https://github.com/ggml-org/llama.cpp/releases/tag/b12201). Extract the executable and DLLs together into `runtime/`. The original test used existing local CUDA 13 DLLs; a clean installation with this matching DLL package has not been benchmarked.
- Check `runtime\llama-server.exe --version`, `--list-devices` and `--help` before loading. The CUDA GPU and `--moe-cache-cpu-share` must be available. A CUDA 12.4 build enumerated no GPU in the recorded environment.
- Run one model at a time. Final measurements used AC power, effective Windows **Best performance** mode and plugged-in PCIe Link State Power Management Off. A Balanced power *plan* can coexist with Best performance *mode*. Firmware thermal mode and maximum hardware power allocation were not independently verified.

[Original model](https://huggingface.co/google/gemma-4-26B-A4B-it) · [GGUF model files](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF). Model and runtime licenses remain upstream; no weights or binaries are distributed here.

### Exact model and matching draft downloads

Use these pinned files from Unsloth revision `c099eb48e663fd284577b04978a94ffccb261841`:

- [Target UD-Q4_K_M](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF/resolve/c099eb48e663fd284577b04978a94ffccb261841/gemma-4-26B-A4B-it-UD-Q4_K_M.gguf): 16,947,541,728 bytes; SHA-256 `f2c28b3dc4776931ac6f879e11f203dec637ea0f14267a86ec8f6165f63f293f`.
- [Matching MTP Q8_0 draft](https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF/resolve/c099eb48e663fd284577b04978a94ffccb261841/MTP/mtp-gemma-4-26B-A4B-it-Q8_0.gguf): 461,766,816 bytes; SHA-256 `6326fb9f5e487aa8dcdd313a091e3c67724cb2a666ec3b7d2895b5b26d93ed1b`.

Save both in `models/` with the linked basenames. This is text-only serving; no vision projector is configured. MTP needs this matching separate draft (`-md`, `-ngld all`), not just speculative flags.

At 3072 MiB, eight threads and MTP2, changing CPU miss share 0 to 0.95 increased three-workload screening harmonic mean from 27.94 to 40.61 tokens/s (+45.3%). At share 0.95, disabling MTP gave 26.56 versus 40.61 with MTP2 (+52.9%). Increasing cache to 4096 MiB reduced throughput to 16.78; near-capacity GPU memory was observed, but paging was not measured. Earlier short screens also had slow observations; longer validation did not repeat the collapse. Four draft tokens did not improve the aggregate.

## Launch

The launcher uses repo-relative defaults and accepts absolute paths, including paths with spaces:

```powershell
.\Start-Model.ps1
# Or use files stored elsewhere:
.\Start-Model.ps1 -Runtime "D:\llama\llama-server.exe" -Model "D:\models\gemma-4-26B-A4B-it-UD-Q4_K_M.gguf" -Draft "D:\models\mtp-gemma-4-26B-A4B-it-Q8_0.gguf"
```

Run in a PowerShell session permitted by your local script policy. `-PrintCommand` prints one argument per line without starting inference. The foreground server binds **127.0.0.1:18290** only; Ctrl+C stops it. There is no web UI, background service, account integration or remote exposure. Check `http://127.0.0.1:18290/health`; OpenAI-compatible API base is `http://127.0.0.1:18290/v1`. No automatic download is performed. Verify downloaded model hashes with `Get-FileHash -Algorithm SHA256`.

| Selected setting | Value |
|---|---:|
| Expert cache | 3072 MiB |
| CPU miss share | 0.95 |
| CPU / batch threads | 8 / 8 |
| Allocated context | 32,768 tokens |
| Speculation | MTP, maximum 2 tokens |

All profiles use `-ngl 99 --cpu-moe`, one request slot, Flash Attention, q8_0 K/V caches, batch 512, microbatch 256, `--fit off`, Jinja templates and prompt caching requested off. `Start-Model.ps1` contains the full recorded benchmark arguments with only portable paths and configurable port substituted; `profile.json` summarizes the selection. The newly packaged launcher has been command/parse checked, not rebenchmarked. The original main launcher passed health and 64-token generation checks after profile installation.

## Benchmark evidence

| 768-token workload | Server decode tokens/s |
|---|---:|
| OS explanation | 38.45 |
| Python LRU-cache code | 47.39 |
| Synthetic warehouse summary | 38.68 |
| Harmonic mean, warmup excluded | **41.12** |

`results.csv` is an allowlisted numeric projection of the original native-Windows timing rows, including warmups. It excludes prompts, responses, timestamps, machine identifiers and private paths. Source evidence was the complete Windows lab report, recommended configuration JSON and validation measurements dated 2026-11-08; no inference was rerun to publish these repositories.

### Repeated matched CPU-share controls — 8 November 2026

These later controls are separate from the historical validation above and the earlier 384-token screens. At the selected profile (cache 3072 MiB, 8 threads, MTP2), only CPU miss share changed. Pooled decode harmonic means were **27.85 tokens/s at share 0** and **40.41 tokens/s at share 0.95**, a **+45.1%** gain. This does not replace the original selected-validation rate.

| Workload | Share 0 tokens/s | Share 0.95 tokens/s | Gain |
|---|---:|---:|---:|
| explain | 26.71 | 37.22 | +39.4% |
| code | 34.33 | 47.36 | +38.0% |
| summary | 24.31 | 38.09 | +56.7% |

| Block | Share 0 tokens/s | Share 0.95 tokens/s | Gain |
|---|---:|---:|---:|
| b1 | 27.60 | 40.02 | +45.0% |
| b2 | 28.11 | 40.81 | +45.2% |

- Share 0: measured-run range 24.05–34.97 tokens/s; sample CV 15.7%.
- Share 0.95: measured-run range 35.76–48.64 tokens/s; sample CV 12.1%.

#### Control method and scope

[matched-controls.csv](matched-controls.csv) contains this model's 32 timing-only rows: eight fresh server configurations, eight 256-token warmups and 24 measured responses. Each of two blocks used ABBA order (share 0, 0.95, 0.95, 0); every configuration ran explanation, code and synthetic summary at 768 tokens after warmup. The model order was Qwen → Gemma → LFM in block 1 and reversed in block 2. This counterbalanced order was not randomized. There are 12 measured responses per share. All 96 responses across the three models (72 measured, 24 warmups) were independently verified unique and complete; none were retried or excluded. These are additional to the original 196-request investigation and three launcher smoke checks.

The existing runtime, selected cache/context/thread/speculation settings, synthetic workloads and sampling/template protocol were retained. Qwen's matched cache is 4096 MiB, unlike its historical 3072 MiB share screen. Harmonic means use server decode rates with warmups excluded; gain is `(share095 / share0 - 1) * 100`. Block rates pool six responses per share; workload rates pool four. CV is sample standard deviation divided by arithmetic mean. CSV IDs encode model, block, position and share; `draft` is configured maximum draft tokens, `draft_n`/`accepted` are server draft counters where available. No prompts, answers, timestamps, host identifiers, telemetry or private paths are published.

AC power and the effective Windows Best performance overlay were observed without changing settings. GPU sampling covered loading, warmups and measurements, but there was no synchronized per-request CPU/package-power or effective-frequency readback; telemetry cannot establish clock/power causality. An auxiliary read-only power-mode probe failed and was retried during the first Qwen share-0.95 entry; that entry remains included. The worker's final expected-count expression failed after inference; independent verification confirmed all 24 configurations and 96 responses, correct sequence, and no remaining benchmark server/listener. No inference rerun was needed.

These are throughput-only controls on one laptop, runtime and three fixed workloads. They do not establish output-quality equivalence, long-context performance, statistical population confidence or a universal optimum. Cache history, expert routing, desktop activity and clocks remain possible sources of variation.

### Method and reproducibility

Start a fresh server, wait for health, then in a second PowerShell window run:

```powershell
.\Benchmark.ps1
# Screening length used in the original tuning:
.\Benchmark.ps1 -Tokens 384
```

The benchmark sends only bundled synthetic workloads to localhost and writes timing-only CSV under ignored `benchmark-results/`. It does not start or stop the server. It first applies the model's chat template (`enable_thinking=false` requested), runs a separate 256-token warmup, then explanation, coding and repeated-document summary. Qwen/Gemma honored non-thinking templates; LFM retained native reasoning behavior. Measured outputs use temperature 0, seed 42, `cache_prompt=false`, `ignore_eos=true`, and 768 generated tokens. Forcing length is not natural completion and can continue beyond an answer. Summary inputs were approximately 1350–1470 tokens; allocated context was **not filled**.

Aggregate = `3 / (1/r1 + 1/r2 + 1/r3)` using server-reported decode rates, excluding warmup. The server reports 767 timed token intervals for 768-token output, so requested token count divided by decode time is slightly different. These are decode-only rates, not prompt processing or end-to-end response speed; CSV also retains prefill and wall timings.

The original investigation across all three models recorded 196 requests including warmups, plus three launcher smoke checks; the later repeated controls add 96 requests as detailed above. Early raw-prompt median screens and later chat-templated harmonic means are distinct protocols. Longer validation restarted selected candidates and changed model order; this was not randomized repeated crossover testing. Cache history, expert routes, desktop activity and GPU clocks can affect results. No near-limit context throughput, accuracy equivalence of speculative/plain output, hallucination rate or coding success is established. Different models' reasoning behavior makes output-token comparisons imperfect. Reproduce on your own system before drawing broader conclusions.

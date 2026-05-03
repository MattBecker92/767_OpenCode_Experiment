# Model Compatibility Notes

Several models were tested before finding one that worked with OpenCode's
tool-call format.

## Models tested

| Model | Size | Result | Failure mode |
|-------|------|-------|------|
| qwen3.6:latest | 23 GB | Failed | Produced `<tool:none>` XML tags — OpenCode could not parse |
| qwen2.5-coder:latest | 4.7 GB | Failed | Hallucinated tool names (`skill`, `todolist`) — raw JSON blobs |
| qwen2.5-coder:7b-16k | 4.7 GB | Failed | Same as above |
| qwen3.5:397b (cloud) | cloud | Failed | Unauthorized error — accidentally selected cloud variant |
| **qwen3.5:latest (→ qwen3.5-16k)** | **6.6 GB** | **Works** | Tool calls execute correctly |

## Why qwen3.5 worked

Qwen3.5 is the 9B-parameter model from Alibaba's Qwen3.5 family. At Q4_K_M
quantization it uses 6.6 GB on disk. It produces tool calls in a format that
OpenCode v1.14.28 can parse, which the larger qwen3.6 and the coding-specific
qwen2.5-coder do not.

## The context window problem

Ollama defaults to a 4,096-token context window for all models regardless of
native capacity. This is too small for multi-step coding agent workflows. The
fix is to resave the model with a larger context:

```bash
ollama run qwen3.5
/set parameter num_ctx 16384
/save qwen3.5-16k
/bye
```

Without this fix, tool calls become unreliable as the context fills up.

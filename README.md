# Harness Over Model

**A controlled experiment measuring whether LLM agent harness quality matters
more than model selection for local coding agent performance.**

This repository accompanies the paper:

> Becker, M. (2026). *Harness Over Model: Optimizing Local LLM Agent Systems
> Through Environment and Harness Engineering.* SEIS 767: Conversational AI,
> University of St. Thomas.

## What This Experiment Does

The experiment holds the model fixed — Qwen3.5-9B (9.65B parameters) running
locally via Ollama on WSL — and varies the **harness**: the instruction files,
context, and tool-use guidance provided to the agent. Four harness
configurations are tested across five coding tasks on a synthetic Python
library called `schedlib`. Results are measured with automated pass/fail checks.

## Key Results

| Iteration | Harness | Score | Tool Calls | Words |
|-----------|---------|-------|------------|-------|
| iter_0 | None (cold baseline) | 4/5 | 90 | 7,365 |
| iter_1 | Basic AGENTS.md | 5/5 | 120 | 8,220 |
| iter_2 | Rich context | 5/5 | 155 | 10,730 |
| iter_3 | Tool-use guidance | 5/5 | 38 | 2,518 |

**Finding 1:** A minimal AGENTS.md with a four-step workflow was sufficient to
move from 4/5 to 5/5 — resolving a deliberately planted red-herring task that
defeated the cold baseline.

**Finding 2:** Explicit tool-use guidance (iter_3) achieved the same score
with 75% fewer tool calls, demonstrating that harness engineering changes not
just correctness but agent *efficiency*.

**Finding 3:** The execution platform is part of the harness. `opencode run`
(CLI mode) exits after one response — unusable for multi-step agentic tasks with a local model. The
interactive TUI maintains a full tool-execution loop.

## Repository Structure

```
eval/
├── check.sh          # Automated scorer (runs assertions against project)
└── reset.sh          # Resets project to buggy baseline between iterations
iterations/
├── iter_0/README.md  # Cold baseline — no AGENTS.md
├── iter_1/AGENTS.md  # Basic: project name + 4-step workflow
├── iter_2/AGENTS.md  # Rich: adds file map + constraints
└── iter_3/AGENTS.md  # Tool-use: adds explicit per-tool instructions
project/
├── schedlib/         # Synthetic job scheduler library (with planted bugs)
└── tests/            # Test suite
results/
└── scores.log        # Score history across all iterations
runner/
├── run_hybrid.sh     # Main runner script
└── extract_transcripts.py
docs/
├── findings.md            # Detailed analysis of results
├── model-compatibility.md # Which models worked and why
└── setup-troubleshooting.md
SETUP.md                   # Full end-to-end setup instructions
```

## Quick Start

See [SETUP.md](SETUP.md) for full installation. Once set up:

```bash
bash eval/check.sh baseline          # should show 0/5 (bugs not yet fixed)
bash runner/run_hybrid.sh iter_0     # cold baseline
bash runner/run_hybrid.sh iter_1     # with basic AGENTS.md
bash runner/run_hybrid.sh iter_2     # with rich context
bash runner/run_hybrid.sh iter_3     # with tool-use guidance
```

## Requirements

- Windows 11 with WSL2 (Ubuntu 24.04)
- Ollama ≥ 0.6 installed in WSL
- OpenCode v1.14.28 (installed via official install script)
- Python 3.10+ with pytest
- ~8 GB disk space for the Qwen3.5-9B model

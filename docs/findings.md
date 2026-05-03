# Experiment Findings

## Scores

| Iteration | Harness | T1 | T2 | T3 | T4 | T5 | Score | Tool Calls | Words |
|-----------|---------|----|----|----|----|-----|-------|------------|-------|
| iter_0 | None | pass | FAIL | pass | pass | pass | 4/5 | 90 | 7,365 |
| iter_1 | Basic AGENTS.md | pass | pass | pass | pass | pass | 5/5 | 120 | 8,220 |
| iter_2 | Rich context | pass | pass | pass | pass | pass | 5/5 | 155 | 10,730 |
| iter_3 | Tool-use guidance | pass | pass | pass | pass | pass | 5/5 | 38 | 2,518 |

## The Five Tasks

| Task | Type | What the agent had to do |
|------|------|--------------------------|
| T1 | Straightforward | Fix case-insensitive tag matching in `get_by_tag()` |
| T2 | Red herring | Fix `get_results()` — an internal cache misleads toward the wrong fix |
| T3 | Multi-file | Catch exceptions in `Job.run()` so failures don't crash the scheduler |
| T4 | Ambiguous + write test | Fix `run_all()` priority ordering AND write a test proving it |
| T5 | Multi-file + spec | Add `pending_jobs()` and `pending` key to `Reporter.summary()` |

## Key Findings

### Finding 1: Minimal harness closes a meaningful gap
A four-step AGENTS.md workflow (read → edit → pytest → fix) was sufficient to
move from 4/5 to 5/5. The only failing task in the cold baseline was T2 — the
red herring — where an internal `_results` cache made the wrong fix look
attractive. The basic harness prompted the model to read more carefully first.

### Finding 2: Richer context increases effort without changing outcome
iter_1 and iter_2 both scored 5/5, but iter_2 generated 29% more tool calls
(155 vs 120) and 30% more words. The file map caused the model to read more
files and reason more extensively — useful but not necessary.

### Finding 3: Tool-use guidance produces different behaviour
iter_3's explicit per-tool instructions produced 75% fewer tool calls (38 vs
155) and 77% fewer words (2,518 vs 10,730) at the same score. The model
stopped exploring and started acting directly.

**Caveat:** iter_3 used separate sessions per task while iter_0–2 used one
session for all five tasks. T5 in iter_3 also required zero edits because a
previous task had already modified reporter.py as a side effect. These factors
contribute to iter_3's low counts alongside any genuine harness effect.

### Finding 4: The execution platform is part of the harness
`opencode run` (CLI mode) exits after one model response. Every task completed
in under 10 seconds with zero code changes. `ollama launch opencode` (TUI mode)
maintains a full agentic loop — the same tasks took several minutes and
hundreds of tool calls. Platform choice is a harness-layer decision.

## Session Structure Note
- **iter_0, iter_1, iter_2**: All 5 tasks in a single continuous session.
  The agent accumulated context across tasks.
- **iter_3**: Each task in its own fresh session — genuinely isolated.

This inconsistency means efficiency metrics are not directly comparable across
iterations. Future work should standardize to one session per task throughout.

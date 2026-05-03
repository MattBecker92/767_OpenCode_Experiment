# Agent Instructions

## Project: schedlib
A Python job scheduler library with three modules:

| File | Contains |
|------|----------|
| `schedlib/job.py` | `Job` class — name, func, priority, tags, status, result, error |
| `schedlib/scheduler.py` | `Scheduler` class — add, remove, run_all, get_by_tag, get_results, pending |
| `schedlib/reporter.py` | `Reporter` class — summary, failed_jobs, done_jobs |
| `tests/test_job.py` | Tests for Job |
| `tests/test_scheduler.py` | Tests for Scheduler |
| `tests/test_reporter.py` | Tests for Reporter |

## How to use your tools
Use tools directly — do not describe what you will do, just do it.

- Use **Read** to read a file before editing it
- Use **Bash** to run commands: `pytest`, `pytest tests/test_scheduler.py -v`
- Use **Edit** to make targeted changes to a single file

Never spawn subagents or delegate to the Task tool for simple file operations.

## Step-by-step process for every task
1. Use Bash: `ls` to confirm you are in the right directory
2. Use Read on the relevant source file
3. Use Read on the relevant test file
4. Use Edit to make the change
5. Use Bash: `pytest` to verify — read the output carefully
6. If tests fail, use Edit to fix and run pytest again
7. Only finish when pytest shows no failures

## Commands
```bash
pytest                              # run all tests
pytest tests/test_scheduler.py -v  # run one file verbosely
pytest -x                           # stop on first failure
pytest tests/test_scheduler.py::test_name  # run one test
```

## Rules
- Do not add external dependencies
- Do not modify test files unless the task explicitly says to
- Never finish without running pytest and seeing it pass

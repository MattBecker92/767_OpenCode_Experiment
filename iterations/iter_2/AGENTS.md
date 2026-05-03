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

## Commands
- Run all tests: `pytest`
- Run one file: `pytest tests/test_scheduler.py -v`
- Run one test: `pytest tests/test_scheduler.py::test_name -v`
- Stop on first failure: `pytest -x`

## Workflow
1. Read the relevant source file and its test file before changing anything
2. Make the minimum change needed to complete the task
3. Run `pytest` — all tests must pass before you finish
4. If tests fail, read the error and fix it

## Rules
- Do not add external dependencies
- Do not modify test files unless the task explicitly asks you to
- Run pytest after every change — never finish without verifying

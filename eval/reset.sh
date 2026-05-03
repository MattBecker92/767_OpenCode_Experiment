#!/usr/bin/env bash
# eval/reset.sh — restore project to buggy baseline
set -uo pipefail
PROJECT="$(cd "$(dirname "$0")/../project" && pwd)"

echo "Resetting schedlib project to baseline..."

rm -f "${PROJECT}/AGENTS.md"

cat > "${PROJECT}/schedlib/job.py" << 'PYEOF'
from __future__ import annotations
from typing import Callable, Any


class Job:
    """A unit of work managed by the Scheduler."""

    VALID_STATUSES = {"pending", "running", "done", "failed"}

    def __init__(
        self,
        name: str,
        func: Callable[[], Any],
        priority: int = 0,
        tags: list[str] | None = None,
    ):
        self.name = name
        self.func = func
        self.priority = priority
        self.tags: list[str] = tags or []
        self.result: Any = None
        self.error: Exception | None = None
        self.status: str = "pending"

    def run(self) -> None:
        """Execute the job's function and record the result.

        BUG T3: any exception raised by func propagates uncaught,
        crashing the caller. status is never set to 'failed'.
        """
        self.status = "running"
        self.result = self.func()   # raises on failure — intentional bug
        self.status = "done"

    def __repr__(self) -> str:
        return f"Job({self.name!r}, priority={self.priority}, status={self.status!r})"
PYEOF

cat > "${PROJECT}/schedlib/scheduler.py" << 'PYEOF'
from __future__ import annotations
from .job import Job


class Scheduler:
    """Manages and executes a collection of Jobs."""

    def __init__(self) -> None:
        self.jobs: list[Job] = []
        self._results: dict[str, object] = {}

    def add(self, job: Job) -> None:
        self.jobs.append(job)

    def remove(self, name: str) -> bool:
        before = len(self.jobs)
        self.jobs = [j for j in self.jobs if j.name != name]
        return len(self.jobs) < before

    def run_all(self) -> None:
        """BUG T4: ignores priority, runs in insertion order."""
        for job in self.jobs:
            job.run()
            self._cache_result(job)

    def _cache_result(self, job: Job) -> None:
        if job.status == "done":
            self._results[job.name] = job.result

    def get_by_tag(self, tag: str) -> list[Job]:
        """BUG T1: case-sensitive comparison."""
        return [j for j in self.jobs if tag in j.tags]

    def get_results(self) -> dict[str, object]:
        """RED HERRING T2: reads from cache which may be incomplete."""
        return dict(self._results)

    def pending(self) -> list[Job]:
        return [j for j in self.jobs if j.status == "pending"]
PYEOF

cat > "${PROJECT}/schedlib/reporter.py" << 'PYEOF'
from __future__ import annotations
from .scheduler import Scheduler
from .job import Job


class Reporter:
    """Produces human-readable summaries of a Scheduler's state."""

    def __init__(self, scheduler: Scheduler) -> None:
        self.scheduler = scheduler

    def summary(self) -> dict:
        """BUG T5: missing 'pending' key."""
        jobs = self.scheduler.jobs
        return {
            "total":  len(jobs),
            "done":   sum(1 for j in jobs if j.status == "done"),
            "failed": sum(1 for j in jobs if j.status == "failed"),
        }

    def failed_jobs(self) -> list[Job]:
        return [j for j in self.scheduler.jobs if j.status == "failed"]

    def done_jobs(self) -> list[Job]:
        return [j for j in self.scheduler.jobs if j.status == "done"]
PYEOF

# Reset test_scheduler.py to baseline (no priority test)
cat > "${PROJECT}/tests/test_scheduler.py" << 'PYEOF'
import pytest
from schedlib import Job, Scheduler


def test_add_and_count():
    s = Scheduler()
    s.add(Job("a", lambda: 1))
    s.add(Job("b", lambda: 2))
    assert len(s.jobs) == 2


def test_remove_existing():
    s = Scheduler()
    s.add(Job("x", lambda: None))
    assert s.remove("x") is True
    assert len(s.jobs) == 0


def test_remove_nonexistent():
    s = Scheduler()
    assert s.remove("ghost") is False


def test_run_all_executes_jobs():
    s = Scheduler()
    s.add(Job("a", lambda: 10))
    s.add(Job("b", lambda: 20))
    s.run_all()
    assert all(j.status == "done" for j in s.jobs)


def test_get_by_tag_exact_match():
    s = Scheduler()
    s.add(Job("j1", lambda: None, tags=["urgent"]))
    s.add(Job("j2", lambda: None, tags=["nightly"]))
    result = s.get_by_tag("urgent")
    assert len(result) == 1
    assert result[0].name == "j1"


def test_get_by_tag_case_insensitive():
    s = Scheduler()
    s.add(Job("j1", lambda: None, tags=["URGENT"]))
    s.add(Job("j2", lambda: None, tags=["nightly"]))
    result = s.get_by_tag("urgent")
    assert len(result) == 1
    assert result[0].name == "j1"


def test_get_results_after_run():
    s = Scheduler()
    s.add(Job("compute", lambda: 99))
    s.run_all()
    results = s.get_results()
    assert "compute" in results
    assert results["compute"] == 99


def test_run_all_resilient_to_failure():
    results = []
    s = Scheduler()
    s.add(Job("good1", lambda: results.append("good1")))
    s.add(Job("bad",   lambda: 1 / 0))
    s.add(Job("good2", lambda: results.append("good2")))
    s.run_all()
    assert "good1" in results
    assert "good2" in results


def test_pending_returns_unstarted():
    s = Scheduler()
    s.add(Job("a", lambda: None))
    s.add(Job("b", lambda: None))
    s.run_all()
    s.add(Job("c", lambda: None))
    pending = s.pending()
    assert len(pending) == 1
    assert pending[0].name == "c"
PYEOF

echo "✅ Project reset to baseline. Ready for next iteration."

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
        """Run jobs ordered by priority (highest first)."""
        for job in sorted(self.jobs, key=lambda j: j.priority, reverse=True):
            job.run()
            self._cache_result(job)

    def _cache_result(self, job: Job) -> None:
        if job.status == "done":
            self._results[job.name] = job.result
        elif job.status == "failed":
            self._results[job.name] = job.error

    def get_by_tag(self, tag: str) -> list[Job]:
        """BUG T1: case-sensitive comparison."""
        return [j for j in self.jobs if tag.lower() in [t.lower() for t in j.tags]]

    def get_results(self) -> dict[str, object]:
        """RED HERRING T2: reads from cache which may be incomplete."""
        return dict(self._results)

    def pending(self) -> list[Job]:
        return [j for j in self.jobs if j.status == "pending"]

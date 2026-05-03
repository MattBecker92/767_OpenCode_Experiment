from __future__ import annotations
from .scheduler import Scheduler
from .job import Job


class Reporter:
    """Produces human-readable summaries of a Scheduler's state."""

    def __init__(self, scheduler: Scheduler) -> None:
        self.scheduler = scheduler

    def summary(self) -> dict:
        jobs = self.scheduler.jobs
        return {
            "total":   len(jobs),
            "done":    sum(1 for j in jobs if j.status == "done"),
            "failed":  sum(1 for j in jobs if j.status == "failed"),
            "pending": sum(1 for j in jobs if j.status == "pending"),
        }

    def pending_jobs(self) -> list[Job]:
        return [j for j in self.scheduler.jobs if j.status == "pending"]

    def failed_jobs(self) -> list[Job]:
        return [j for j in self.scheduler.jobs if j.status == "failed"]

    def done_jobs(self) -> list[Job]:
        return [j for j in self.scheduler.jobs if j.status == "done"]

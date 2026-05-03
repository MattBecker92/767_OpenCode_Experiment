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
        """Execute the job's function and record the result."""
        self.status = "running"
        try:
            self.result = self.func()
            self.status = "done"
        except Exception as e:
            self.status = "failed"
            self.error = e

    def __repr__(self) -> str:
        return f"Job({self.name!r}, priority={self.priority}, status={self.status!r})"

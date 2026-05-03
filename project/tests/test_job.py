import pytest
from schedlib import Job


def test_job_defaults():
    j = Job("task", lambda: 42)
    assert j.priority == 0
    assert j.tags == []
    assert j.status == "pending"
    assert j.result is None
    assert j.error is None


def test_job_run_success():
    j = Job("add", lambda: 1 + 1)
    j.run()
    assert j.status == "done"
    assert j.result == 2


def test_job_run_captures_failure():
    """A failing job should set status='failed' and store the error."""
    j = Job("boom", lambda: 1 / 0)
    j.run()   # should NOT raise
    assert j.status == "failed"
    assert j.error is not None
    assert j.result is None


def test_job_priority_stored():
    j = Job("hi", lambda: None, priority=5)
    assert j.priority == 5


def test_job_tags_stored():
    j = Job("tagged", lambda: None, tags=["urgent", "nightly"])
    assert "urgent" in j.tags

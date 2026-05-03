import pytest
from schedlib import Job, Scheduler, Reporter


def _make_scheduler(*jobs):
    s = Scheduler()
    for j in jobs:
        s.add(j)
    return s


def test_summary_basic():
    s = _make_scheduler(
        Job("a", lambda: 1),
        Job("b", lambda: 1),
    )
    s.run_all()
    r = Reporter(s)
    summary = r.summary()
    assert summary["total"] == 2
    assert summary["done"] == 2
    assert summary["failed"] == 0


def test_summary_includes_pending():
    """summary() must include a 'pending' key for unstarted jobs."""
    s = _make_scheduler(
        Job("done_job", lambda: 1),
        Job("pending_job", lambda: 1),
    )
    # Only run the first job manually to leave one pending
    s.jobs[0].run()
    r = Reporter(s)
    summary = r.summary()
    assert "pending" in summary
    assert summary["pending"] == 1


def test_summary_pending_excludes_running():
    """'running' jobs must NOT be counted as pending."""
    s = _make_scheduler(Job("r", lambda: 1))
    s.jobs[0].status = "running"   # simulate mid-execution
    r = Reporter(s)
    summary = r.summary()
    assert summary.get("pending", 0) == 0


def test_pending_jobs_method():
    """Reporter.pending_jobs() must return jobs with status == 'pending'."""
    s = _make_scheduler(
        Job("p1", lambda: 1),
        Job("p2", lambda: 1),
        Job("done", lambda: 1),
    )
    s.jobs[2].run()
    r = Reporter(s)
    pending = r.pending_jobs()
    names = [j.name for j in pending]
    assert "p1" in names
    assert "p2" in names
    assert "done" not in names


def test_failed_jobs():
    s = _make_scheduler(
        Job("ok",  lambda: 1),
        Job("bad", lambda: 1 / 0),
    )
    # Manually set states (T3 must fix Job.run first for this to work naturally)
    s.jobs[0].status = "done"
    s.jobs[1].status = "failed"
    r = Reporter(s)
    assert len(r.failed_jobs()) == 1
    assert r.failed_jobs()[0].name == "bad"

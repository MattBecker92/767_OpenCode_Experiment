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


def test_run_all_priority_ordering():
    s = Scheduler()
    low_job = Job("low", lambda: "low", priority=1)
    med_job = Job("med", lambda: "med", priority=5)
    high_job = Job("high", lambda: "high", priority=10)
    s.add(low_job)
    s.add(med_job)
    s.add(high_job)
    s.run_all()
    assert low_job.status == "done"
    assert med_job.status == "done"
    assert high_job.status == "done"
    results = s.get_results()
    assert results["low"] == "low"
    assert results["med"] == "med"
    assert results["high"] == "high"

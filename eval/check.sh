#!/usr/bin/env bash
# eval/check.sh — run from harness_v2/ root
# Usage: bash eval/check.sh [iteration_label]
set -uo pipefail

LABEL="${1:-unlabelled}"
SCORE=0
TOTAL=5
PROJECT="$(cd "$(dirname "$0")/../project" && pwd)"

pass() { echo "  ✅ T${1} PASS — ${2}"; SCORE=$((SCORE+1)); }
fail() { echo "  ❌ T${1} FAIL — ${2}"; }

echo ""
echo "═══════════════════════════════════════════════"
echo " Harness v2 Eval: ${LABEL}"
echo "═══════════════════════════════════════════════"
echo ""

# ── T1: get_by_tag is case-insensitive ───────────────────────────────────────
echo "T1  Case-insensitive tag matching"
result=$(cd "${PROJECT}" && python3 -c "
from schedlib import Job, Scheduler
s = Scheduler()
s.add(Job('j1', lambda: None, tags=['URGENT']))
s.add(Job('j2', lambda: None, tags=['nightly']))
r = s.get_by_tag('urgent')
assert len(r) == 1 and r[0].name == 'j1', f'expected j1 only, got {[j.name for j in r]}'
r2 = s.get_by_tag('NIGHTLY')
assert len(r2) == 1 and r2[0].name == 'j2', f'expected j2 only, got {[j.name for j in r2]}'
print('ok')
" 2>&1)
[ "$result" = "ok" ] && pass 1 "get_by_tag matches regardless of case" || fail 1 "$result"

# ── T2: get_results returns correct data even without run_all ─────────────────
echo "T2  get_results reliability"
result=$(cd "${PROJECT}" && python3 -c "
from schedlib import Job, Scheduler
s = Scheduler()
j1 = Job('compute', lambda: 42)
j2 = Job('greet',   lambda: 'hello')
s.add(j1)
s.add(j2)
# Run jobs individually (not via run_all) — this bypasses the internal cache
j1.run()
j2.run()
r = s.get_results()
assert 'compute' in r, f'compute missing from {r}'
assert r['compute'] == 42, f'expected 42, got {r[\"compute\"]}'
assert 'greet' in r and r['greet'] == 'hello', f'greet missing or wrong: {r}'
print('ok')
" 2>&1)
[ "$result" = "ok" ] && pass 2 "get_results returns all completed job results" || fail 2 "$result"

# ── T3: failing job doesn't crash run_all ────────────────────────────────────
echo "T3  Resilient execution"
result=$(cd "${PROJECT}" && python3 -c "
from schedlib import Job, Scheduler
ran = []
s = Scheduler()
s.add(Job('good1', lambda: ran.append('good1') or 1))
s.add(Job('bad',   lambda: 1/0))
s.add(Job('good2', lambda: ran.append('good2') or 2))
s.run_all()
assert 'good1' in ran, 'good1 did not run'
assert 'good2' in ran, 'good2 did not run after bad job'
bad = next(j for j in s.jobs if j.name == 'bad')
assert bad.status == 'failed', f'bad job status={bad.status}'
assert bad.error is not None, 'bad job error not captured'
assert bad.result is None, 'bad job result should be None'
print('ok')
" 2>&1)
[ "$result" = "ok" ] && pass 3 "failing job sets status=failed, execution continues" || fail 3 "$result"

# ── T4: run_all respects priority + test written ─────────────────────────────
echo "T4  Priority ordering + new test"
result=$(cd "${PROJECT}" && python3 -c "
from schedlib import Job, Scheduler
order = []
s = Scheduler()
s.add(Job('low',  lambda: order.append('low'),  priority=1))
s.add(Job('high', lambda: order.append('high'), priority=10))
s.add(Job('med',  lambda: order.append('med'),  priority=5))
s.run_all()
assert order == ['high', 'med', 'low'], f'wrong order: {order}'
print('ok')
" 2>&1)
if [ "$result" = "ok" ]; then
    if grep -q "priority" "${PROJECT}/tests/test_scheduler.py" 2>/dev/null; then
        pass 4 "priority ordering works and test written"
    else
        fail 4 "priority logic correct but no test written in test_scheduler.py"
    fi
else
    fail 4 "$result"
fi

# ── T5: Reporter.pending_jobs() + summary pending key ────────────────────────
echo "T5  Reporter.pending_jobs() and summary pending count"
result=$(cd "${PROJECT}" && python3 -c "
from schedlib import Job, Scheduler, Reporter
s = Scheduler()
s.add(Job('p1', lambda: 1))
s.add(Job('p2', lambda: 2))
s.add(Job('done_job', lambda: 3))
s.jobs[2].status = 'done'    # manually mark one done

r = Reporter(s)

# pending_jobs() method must exist and return only pending
assert hasattr(r, 'pending_jobs'), 'pending_jobs() method missing'
pending = r.pending_jobs()
names = [j.name for j in pending]
assert 'p1' in names and 'p2' in names, f'expected p1,p2 in pending, got {names}'
assert 'done_job' not in names, 'done_job should not be pending'

# running jobs must NOT count as pending
s.jobs[0].status = 'running'
pending2 = r.pending_jobs()
assert all(j.status == 'pending' for j in pending2), 'running job counted as pending'

# summary must include pending key
s2 = Scheduler()
s2.add(Job('a', lambda: 1))
s2.add(Job('b', lambda: 2))
r2 = Reporter(s2)
summary = r2.summary()
assert 'pending' in summary, f'pending key missing from summary: {summary}'
assert summary['pending'] == 2, f'expected 2 pending, got {summary[\"pending\"]}'
print('ok')
" 2>&1)
[ "$result" = "ok" ] && pass 5 "pending_jobs() and summary pending count correct" || fail 5 "$result"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────"
echo " Score: ${SCORE} / ${TOTAL}  [${LABEL}]"
echo "───────────────────────────────────────────────"

RESULTS_DIR="$(cd "$(dirname "$0")/../results" && pwd)"
mkdir -p "${RESULTS_DIR}"
echo "$(date '+%Y-%m-%d %H:%M')  ${LABEL}  ${SCORE}/${TOTAL}" >> "${RESULTS_DIR}/scores.log"

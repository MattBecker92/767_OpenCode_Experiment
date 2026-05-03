#!/usr/bin/env bash
# runner/run.sh — Fully automated harness experiment runner
#
# Usage:
#   bash runner/run.sh iter_0            # cold baseline (no AGENTS.md)
#   bash runner/run.sh iter_1            # basic AGENTS.md
#   bash runner/run.sh iter_2            # rich context
#   bash runner/run.sh iter_3            # tool-use guidance
#   bash runner/run.sh iter_0 --dry-run  # decode and print tasks only

set -uo pipefail

ITER="${1:-iter_0}"
DRY_RUN="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/project"
RESULTS_DIR="${SCRIPT_DIR}/results"
ITER_DIR="${SCRIPT_DIR}/iterations/${ITER}"
DB="${HOME}/.local/share/opencode/opencode.db"

mkdir -p "${RESULTS_DIR}"
LOG="${RESULTS_DIR}/${ITER}_run.log"
SESSION_LOG="${RESULTS_DIR}/${ITER}_sessions.log"

log() { echo "$@" | tee -a "${LOG}"; }

T1="Rml4IHRoZSBTY2hlZHVsZXIuZ2V0X2J5X3RhZygpIG1ldGhvZCBpbiBzY2hlZGxpYi9zY2hlZHVsZXIucHkgc28gdGhhdCB0YWcgbWF0Y2hpbmcgaXMgY2FzZS1pbnNlbnNpdGl2ZS4gQSBqb2IgdGFnZ2VkICdVUkdFTlQnIHNob3VsZCBiZSByZXR1cm5lZCB3aGVuIHNlYXJjaGluZyBmb3IgJ3VyZ2VudCcgYW5kIHZpY2UgdmVyc2EuCgpUaGUgdGVzdCB0ZXN0X2dldF9ieV90YWdfY2FzZV9pbnNlbnNpdGl2ZSBpbiB0ZXN0cy90ZXN0X3NjaGVkdWxlci5weSBpcyBjdXJyZW50bHkgZmFpbGluZy4gTWFrZSBpdCBwYXNzIHdpdGhvdXQgYnJlYWtpbmcgYW55IG90aGVyIHRlc3RzLgoKU3RlcHM6CjEuIFJlYWQgc2NoZWRsaWIvc2NoZWR1bGVyLnB5IGFuZCB1bmRlcnN0YW5kIHRoZSBjdXJyZW50IGltcGxlbWVudGF0aW9uCjIuIEZpeCBnZXRfYnlfdGFnKCkgdG8gbm9ybWFsaXNlIGNhc2Ugb24gYm90aCBzaWRlcyBvZiB0aGUgY29tcGFyaXNvbgozLiBSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gdGhlIGZpeCB3b3Jrcw=="
T2="U2NoZWR1bGVyLmdldF9yZXN1bHRzKCkgYWx3YXlzIHJldHVybnMgYW4gaW5jb21wbGV0ZSBvciBlbXB0eSBkaWN0IGV2ZW4gYWZ0ZXIgcnVubmluZyBqb2JzLiBGaXggaXQgc28gaXQgcmVsaWFibHkgcmV0dXJucyBhIG1hcHBpbmcgb2Ygam9iIG5hbWUgdG8gcmVzdWx0IGZvciBldmVyeSBjb21wbGV0ZWQgam9iLgoKTm90ZTogdGhlcmUgaXMgZXhpc3RpbmcgaW5mcmFzdHJ1Y3R1cmUgaW4gdGhlIFNjaGVkdWxlciBjbGFzcyByZWxhdGVkIHRvIHJlc3VsdHMg4oCUIHJlYWQgdGhlIGNvZGUgY2FyZWZ1bGx5IGJlZm9yZSBkZWNpZGluZyBob3cgdG8gZml4IGl0LiBUaGUgc2ltcGxlc3QgY29ycmVjdCBmaXggbWF5IG5vdCBiZSB0aGUgbW9zdCBvYnZpb3VzIG9uZS4KClJ1biBweXRlc3QgdGVzdHMvdGVzdF9zY2hlZHVsZXIucHk6OnRlc3RfZ2V0X3Jlc3VsdHNfYWZ0ZXJfcnVuIHRvIHZlcmlmeS4="
T3="Q3VycmVudGx5IGEgc2luZ2xlIGZhaWxpbmcgam9iIGNyYXNoZXMgdGhlIGVudGlyZSBzY2hlZHVsZXIuIEZvciBleGFtcGxlLCBpZiBqb2IgQiByYWlzZXMgYW4gZXhjZXB0aW9uLCBqb2IgQyBuZXZlciBydW5zLgoKRml4IHRoaXMgc28gdGhhdDoKLSBBIGpvYiB0aGF0IHJhaXNlcyBhbiBleGNlcHRpb24gaGFzIGl0cyBzdGF0dXMgc2V0IHRvICdmYWlsZWQnIGFuZCBpdHMgZXJyb3IgYXR0cmlidXRlIHNldCB0byB0aGUgZXhjZXB0aW9uCi0gRXhlY3V0aW9uIGNvbnRpbnVlcyB3aXRoIHRoZSBuZXh0IGpvYgotIFRoZSBqb2IncyByZXN1bHQgcmVtYWlucyBOb25lIG9uIGZhaWx1cmUKClRoZSBmaXggbXVzdCB0b3VjaCBzY2hlZGxpYi9qb2IucHkuIFlvdSBtYXkgYWxzbyBuZWVkIHRvIHVwZGF0ZSBzY2hlZGxpYi9zY2hlZHVsZXIucHkuCgpSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gYWxsIHRlc3RzIHBhc3Mu"
T4="VGhlIFNjaGVkdWxlci5ydW5fYWxsKCkgbWV0aG9kIGV4ZWN1dGVzIGpvYnMgaW4gdGhlIG9yZGVyIHRoZXkgd2VyZSBhZGRlZCwgYnV0IGl0IHNob3VsZCBleGVjdXRlIGhpZ2hlci1wcmlvcml0eSBqb2JzIGZpcnN0IChoaWdoZXN0IHByaW9yaXR5IGludGVnZXIgPSBydW5zIGZpcnN0KS4KCkZpeCBydW5fYWxsKCkgaW4gc2NoZWRsaWIvc2NoZWR1bGVyLnB5LiBUaGVuIHdyaXRlIGEgbmV3IHRlc3QgaW4gdGVzdHMvdGVzdF9zY2hlZHVsZXIucHkgcHJvdmluZyB0aGUgcHJpb3JpdHkgb3JkZXJpbmcgd29ya3MgY29ycmVjdGx5LgoKQWxsIGV4aXN0aW5nIHRlc3RzIG11c3Qgc3RpbGwgcGFzcyBhZnRlciB5b3VyIGNoYW5nZXMu"
T5="VGhlIFJlcG9ydGVyIGNsYXNzIGlzIG1pc3NpbmcgYSBwZW5kaW5nX2pvYnMoKSBtZXRob2QsIGFuZCBpdHMgc3VtbWFyeSgpIG1ldGhvZCBpcyBpbmNvbXBsZXRlLgoKTWFrZSB0aGUgZm9sbG93aW5nIGNoYW5nZXMgdG8gc2NoZWRsaWIvcmVwb3J0ZXIucHk6CjEuIEFkZCBhIHBlbmRpbmdfam9icygpIG1ldGhvZCB0aGF0IHJldHVybnMgYWxsIGpvYnMgd2l0aCBzdGF0dXMgZXhhY3RseSBlcXVhbCB0byAncGVuZGluZycuIEpvYnMgd2l0aCBzdGF0dXMgJ3J1bm5pbmcnIG11c3QgTk9UIGJlIGluY2x1ZGVkLgoyLiBVcGRhdGUgc3VtbWFyeSgpIHRvIGluY2x1ZGUgYSAncGVuZGluZycga2V5IGNvbnRhaW5pbmcgdGhlIGNvdW50IG9mIHBlbmRpbmcgam9icy4KClVwZGF0ZSBvciBhZGQgdGVzdHMgaW4gdGVzdHMvdGVzdF9yZXBvcnRlci5weSBhcyBuZWVkZWQuIFJ1biBweXRlc3QgdG8gY29uZmlybSBhbGwgdGVzdHMgcGFzcy4="

decode() { echo "$1" | base64 -d; }

if [ "${DRY_RUN}" = "--dry-run" ]; then
    for i in 1 2 3 4 5; do
        varname="T${i}"
        echo "════ Task ${i} ════"
        decode "${!varname}"
        echo ""
    done
    exit 0
fi

log ""
log "╔══════════════════════════════════════════════════════╗"
log "  Harness Experiment v2 — ${ITER}"
log "  $(date '+%Y-%m-%d %H:%M:%S')"
log "╚══════════════════════════════════════════════════════╝"

log ""
log "── Resetting project..."
bash "${SCRIPT_DIR}/eval/reset.sh"

rm -f "${PROJECT_DIR}/AGENTS.md"
if [ -f "${ITER_DIR}/AGENTS.md" ]; then
    cp "${ITER_DIR}/AGENTS.md" "${PROJECT_DIR}/AGENTS.md"
    log "── Harness: ${ITER}/AGENTS.md installed"
else
    log "── Harness: none (cold baseline)"
fi

{
    echo "Iteration: ${ITER}"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
} > "${SESSION_LOG}"

# ── Tool-use preamble ─────────────────────────────────────────────────────────
# Injected into every prompt regardless of harness level.
# Ensures local model executes tools rather than describing them.
# AGENTS.md (if present) adds project-specific context on top of this.
read -r -d '' PREAMBLE << 'PREAMBLE_EOF' || true
You are a coding agent. Use your tools directly — do NOT write XML tags like <read> or <bash>, produce pseudocode, or describe what you would do. Execute the Bash, Read, and Edit tools immediately.

Required workflow:
1. Use Read to read the relevant source file(s)
2. Use Edit to make the change
3. Use Bash to run: pytest
4. If tests fail, read the error, use Edit to fix it, run pytest again
5. Only finish when pytest shows no failures

PREAMBLE_EOF

run_task() {
    local num="$1"
    local encoded="$2"
    local task
    task=$(decode "$encoded")

    local prompt="${PREAMBLE}
Task:
${task}"

    log ""
    log "── Task ${num} starting at $(date '+%H:%M:%S')"

    cd "${PROJECT_DIR}"
    opencode run "$prompt" 2>&1 | tee -a "${LOG}"
    local exit_code=$?
    cd "${SCRIPT_DIR}"

    local session_id
    session_id=$(sqlite3 "${DB}" \
        "SELECT id FROM session ORDER BY time_created DESC LIMIT 1;" \
        2>/dev/null || echo "unknown")
    echo "T${num}: ${session_id}" >> "${SESSION_LOG}"

    log "── Task ${num} done (exit: ${exit_code}, session: ${session_id})"
}

run_task 1 "$T1"
run_task 2 "$T2"
run_task 3 "$T3"
run_task 4 "$T4"
run_task 5 "$T5"

log ""
log "── Scoring..."
bash "${SCRIPT_DIR}/eval/check.sh" "${ITER}" 2>&1 | tee -a "${LOG}"

log ""
log "── Extracting session transcripts..."
python3 "${SCRIPT_DIR}/runner/extract_transcripts.py" \
    "${SESSION_LOG}" \
    "${RESULTS_DIR}/${ITER}_transcript.md" \
    2>&1 | tee -a "${LOG}"

log ""
log "── Done. Results in: ${RESULTS_DIR}/"
log "   Score log:   ${RESULTS_DIR}/scores.log"
log "   Transcript:  ${RESULTS_DIR}/${ITER}_transcript.md"
log "   Run log:     ${LOG}"

#!/usr/bin/env bash
# Hybrid runner: automates reset/score/capture, you paste prompts in TUI
set -uo pipefail

ITER="${1:-iter_0}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/project"
RESULTS_DIR="${SCRIPT_DIR}/results"
DB="${HOME}/.local/share/opencode/opencode.db"

mkdir -p "${RESULTS_DIR}"
SESSION_LOG="${RESULTS_DIR}/${ITER}_sessions.log"

decode() { echo "$1" | base64 -d; }

T1="Rml4IHRoZSBTY2hlZHVsZXIuZ2V0X2J5X3RhZygpIG1ldGhvZCBpbiBzY2hlZGxpYi9zY2hlZHVsZXIucHkgc28gdGhhdCB0YWcgbWF0Y2hpbmcgaXMgY2FzZS1pbnNlbnNpdGl2ZS4gQSBqb2IgdGFnZ2VkICdVUkdFTlQnIHNob3VsZCBiZSByZXR1cm5lZCB3aGVuIHNlYXJjaGluZyBmb3IgJ3VyZ2VudCcgYW5kIHZpY2UgdmVyc2EuCgpUaGUgdGVzdCB0ZXN0X2dldF9ieV90YWdfY2FzZV9pbnNlbnNpdGl2ZSBpbiB0ZXN0cy90ZXN0X3NjaGVkdWxlci5weSBpcyBjdXJyZW50bHkgZmFpbGluZy4gTWFrZSBpdCBwYXNzIHdpdGhvdXQgYnJlYWtpbmcgYW55IG90aGVyIHRlc3RzLgoKU3RlcHM6CjEuIFJlYWQgc2NoZWRsaWIvc2NoZWR1bGVyLnB5IGFuZCB1bmRlcnN0YW5kIHRoZSBjdXJyZW50IGltcGxlbWVudGF0aW9uCjIuIEZpeCBnZXRfYnlfdGFnKCkgdG8gbm9ybWFsaXNlIGNhc2Ugb24gYm90aCBzaWRlcyBvZiB0aGUgY29tcGFyaXNvbgozLiBSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gdGhlIGZpeCB3b3Jrcw=="
T2="U2NoZWR1bGVyLmdldF9yZXN1bHRzKCkgYWx3YXlzIHJldHVybnMgYW4gaW5jb21wbGV0ZSBvciBlbXB0eSBkaWN0IGV2ZW4gYWZ0ZXIgcnVubmluZyBqb2JzLiBGaXggaXQgc28gaXQgcmVsaWFibHkgcmV0dXJucyBhIG1hcHBpbmcgb2Ygam9iIG5hbWUgdG8gcmVzdWx0IGZvciBldmVyeSBjb21wbGV0ZWQgam9iLgoKTm90ZTogdGhlcmUgaXMgZXhpc3RpbmcgaW5mcmFzdHJ1Y3R1cmUgaW4gdGhlIFNjaGVkdWxlciBjbGFzcyByZWxhdGVkIHRvIHJlc3VsdHMg4oCUIHJlYWQgdGhlIGNvZGUgY2FyZWZ1bGx5IGJlZm9yZSBkZWNpZGluZyBob3cgdG8gZml4IGl0LiBUaGUgc2ltcGxlc3QgY29ycmVjdCBmaXggbWF5IG5vdCBiZSB0aGUgbW9zdCBvYnZpb3VzIG9uZS4KClJ1biBweXRlc3QgdGVzdHMvdGVzdF9zY2hlZHVsZXIucHk6OnRlc3RfZ2V0X3Jlc3VsdHNfYWZ0ZXJfcnVuIHRvIHZlcmlmeS4="
T3="Q3VycmVudGx5IGEgc2luZ2xlIGZhaWxpbmcgam9iIGNyYXNoZXMgdGhlIGVudGlyZSBzY2hlZHVsZXIuIEZvciBleGFtcGxlLCBpZiBqb2IgQiByYWlzZXMgYW4gZXhjZXB0aW9uLCBqb2IgQyBuZXZlciBydW5zLgoKRml4IHRoaXMgc28gdGhhdDoKLSBBIGpvYiB0aGF0IHJhaXNlcyBhbiBleGNlcHRpb24gaGFzIGl0cyBzdGF0dXMgc2V0IHRvICdmYWlsZWQnIGFuZCBpdHMgZXJyb3IgYXR0cmlidXRlIHNldCB0byB0aGUgZXhjZXB0aW9uCi0gRXhlY3V0aW9uIGNvbnRpbnVlcyB3aXRoIHRoZSBuZXh0IGpvYgotIFRoZSBqb2IncyByZXN1bHQgcmVtYWlucyBOb25lIG9uIGZhaWx1cmUKClRoZSBmaXggbXVzdCB0b3VjaCBzY2hlZGxpYi9qb2IucHkuIFlvdSBtYXkgYWxzbyBuZWVkIHRvIHVwZGF0ZSBzY2hlZGxpYi9zY2hlZHVsZXIucHkuCgpSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gYWxsIHRlc3RzIHBhc3Mu"
T4="VGhlIFNjaGVkdWxlci5ydW5fYWxsKCkgbWV0aG9kIGV4ZWN1dGVzIGpvYnMgaW4gdGhlIG9yZGVyIHRoZXkgd2VyZSBhZGRlZCwgYnV0IGl0IHNob3VsZCBleGVjdXRlIGhpZ2hlci1wcmlvcml0eSBqb2JzIGZpcnN0IChoaWdoZXN0IHByaW9yaXR5IGludGVnZXIgPSBydW5zIGZpcnN0KS4KCkZpeCBydW5fYWxsKCkgaW4gc2NoZWRsaWIvc2NoZWR1bGVyLnB5LiBUaGVuIHdyaXRlIGEgbmV3IHRlc3QgaW4gdGVzdHMvdGVzdF9zY2hlZHVsZXIucHkgcHJvdmluZyB0aGUgcHJpb3JpdHkgb3JkZXJpbmcgd29ya3MgY29ycmVjdGx5LgoKQWxsIGV4aXN0aW5nIHRlc3RzIG11c3Qgc3RpbGwgcGFzcyBhZnRlciB5b3VyIGNoYW5nZXMu"
T5="VGhlIFJlcG9ydGVyIGNsYXNzIGlzIG1pc3NpbmcgYSBwZW5kaW5nX2pvYnMoKSBtZXRob2QsIGFuZCBpdHMgc3VtbWFyeSgpIG1ldGhvZCBpcyBpbmNvbXBsZXRlLgoKTWFrZSB0aGUgZm9sbG93aW5nIGNoYW5nZXMgdG8gc2NoZWRsaWIvcmVwb3J0ZXIucHk6CjEuIEFkZCBhIHBlbmRpbmdfam9icygpIG1ldGhvZCB0aGF0IHJldHVybnMgYWxsIGpvYnMgd2l0aCBzdGF0dXMgZXhhY3RseSBlcXVhbCB0byAncGVuZGluZycuIEpvYnMgd2l0aCBzdGF0dXMgJ3J1bm5pbmcnIG11c3QgTk9UIGJlIGluY2x1ZGVkLgoyLiBVcGRhdGUgc3VtbWFyeSgpIHRvIGluY2x1ZGUgYSAncGVuZGluZycga2V5IGNvbnRhaW5pbmcgdGhlIGNvdW50IG9mIHBlbmRpbmcgam9icy4KClVwZGF0ZSBvciBhZGQgdGVzdHMgaW4gdGVzdHMvdGVzdF9yZXBvcnRlci5weSBhcyBuZWVkZWQuIFJ1biBweXRlc3QgdG8gY29uZmlybSBhbGwgdGVzdHMgcGFzcy4="

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "  Harness v2 — ${ITER}  (hybrid mode)"
echo "╚══════════════════════════════════════════════════════╝"

# Reset and install harness
bash "${SCRIPT_DIR}/eval/reset.sh"
rm -f "${PROJECT_DIR}/AGENTS.md"
if [ -f "${SCRIPT_DIR}/iterations/${ITER}/AGENTS.md" ]; then
    cp "${SCRIPT_DIR}/iterations/${ITER}/AGENTS.md" "${PROJECT_DIR}/AGENTS.md"
    echo "Harness: ${ITER}/AGENTS.md installed"
else
    echo "Harness: none (cold baseline)"
fi

{
    echo "Iteration: ${ITER}"
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
} > "${SESSION_LOG}"

# Walk through each task interactively
for i in 1 2 3 4 5; do
    varname="T${i}"
    task=$(decode "${!varname}")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TASK ${i} / 5"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "${task}"
    echo ""
    echo "──────────────────────────────────────────────────────"
    echo "  Copy the task above, open OpenCode in another terminal:"
    echo "    cd ${PROJECT_DIR} && ollama launch opencode"
    echo "  Paste the task, wait for it to finish, then quit OpenCode."
    echo "──────────────────────────────────────────────────────"
    echo ""
    read -r -p "  Press ENTER when task ${i} is complete... "

    session_id=$(sqlite3 "${DB}" \
        "SELECT id FROM session ORDER BY time_created DESC LIMIT 1;" \
        2>/dev/null || echo "unknown")
    echo "T${i}: ${session_id}" >> "${SESSION_LOG}"
    echo "  Captured session: ${session_id}"
done

echo ""
echo "── All tasks done. Scoring..."
bash "${SCRIPT_DIR}/eval/check.sh" "${ITER}"

echo ""
echo "── Extracting transcripts..."
python3 "${SCRIPT_DIR}/runner/extract_transcripts.py" \
    "${SESSION_LOG}" \
    "${RESULTS_DIR}/${ITER}_transcript.md"

echo ""
echo "── Done. Score logged to: ${RESULTS_DIR}/scores.log"

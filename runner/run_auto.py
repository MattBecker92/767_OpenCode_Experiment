#!/usr/bin/env python3
"""
runner/run_auto.py

Fully automated experiment runner. Uses tmux to drive the OpenCode TUI,
injects task prompts via bracketed paste, and detects agent completion by
polling the OpenCode SQLite database.

Usage:
    python3 runner/run_auto.py <iter_name> <repo_root>
    e.g. python3 runner/run_auto.py iter_1 ~/767_OpenCode_Experiment
"""

import base64
import json
import shutil
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

TMUX_SESSION = "opencode_auto"
OPENCODE_BIN = str(Path.home() / ".opencode/bin/opencode")
DB = Path.home() / ".local/share/opencode/opencode.db"

QUIET_SECONDS = 45        # agent considered done after 45 s of no new DB parts
TASK_TIMEOUT = 600        # max seconds per task
SESSION_WAIT = 45         # max seconds to wait for a new DB session to appear
TUI_LOAD_WAIT = 8         # seconds to let OpenCode TUI initialise
SESSION_GRACE = 75        # don't trigger quiet check until this many seconds
                          # after the session first appears (gives model time
                          # to produce its first response token)

TASK_B64 = {
    "T1": "Rml4IHRoZSBTY2hlZHVsZXIuZ2V0X2J5X3RhZygpIG1ldGhvZCBpbiBzY2hlZGxpYi9zY2hlZHVsZXIucHkgc28gdGhhdCB0YWcgbWF0Y2hpbmcgaXMgY2FzZS1pbnNlbnNpdGl2ZS4gQSBqb2IgdGFnZ2VkICdVUkdFTlQnIHNob3VsZCBiZSByZXR1cm5lZCB3aGVuIHNlYXJjaGluZyBmb3IgJ3VyZ2VudCcgYW5kIHZpY2UgdmVyc2EuCgpUaGUgdGVzdCB0ZXN0X2dldF9ieV90YWdfY2FzZV9pbnNlbnNpdGl2ZSBpbiB0ZXN0cy90ZXN0X3NjaGVkdWxlci5weSBpcyBjdXJyZW50bHkgZmFpbGluZy4gTWFrZSBpdCBwYXNzIHdpdGhvdXQgYnJlYWtpbmcgYW55IG90aGVyIHRlc3RzLgoKU3RlcHM6CjEuIFJlYWQgc2NoZWRsaWIvc2NoZWR1bGVyLnB5IGFuZCB1bmRlcnN0YW5kIHRoZSBjdXJyZW50IGltcGxlbWVudGF0aW9uCjIuIEZpeCBnZXRfYnlfdGFnKCkgdG8gbm9ybWFsaXNlIGNhc2Ugb24gYm90aCBzaWRlcyBvZiB0aGUgY29tcGFyaXNvbgozLiBSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gdGhlIGZpeCB3b3Jrcw==",
    "T2": "U2NoZWR1bGVyLmdldF9yZXN1bHRzKCkgYWx3YXlzIHJldHVybnMgYW4gaW5jb21wbGV0ZSBvciBlbXB0eSBkaWN0IGV2ZW4gYWZ0ZXIgcnVubmluZyBqb2JzLiBGaXggaXQgc28gaXQgcmVsaWFibHkgcmV0dXJucyBhIG1hcHBpbmcgb2Ygam9iIG5hbWUgdG8gcmVzdWx0IGZvciBldmVyeSBjb21wbGV0ZWQgam9iLgoKTm90ZTogdGhlcmUgaXMgZXhpc3RpbmcgaW5mcmFzdHJ1Y3R1cmUgaW4gdGhlIFNjaGVkdWxlciBjbGFzcyByZWxhdGVkIHRvIHJlc3VsdHMg4oCUIHJlYWQgdGhlIGNvZGUgY2FyZWZ1bGx5IGJlZm9yZSBkZWNpZGluZyBob3cgdG8gZml4IGl0LiBUaGUgc2ltcGxlc3QgY29ycmVjdCBmaXggbWF5IG5vdCBiZSB0aGUgbW9zdCBvYnZpb3VzIG9uZS4KClJ1biBweXRlc3QgdGVzdHMvdGVzdF9zY2hlZHVsZXIucHk6OnRlc3RfZ2V0X3Jlc3VsdHNfYWZ0ZXJfcnVuIHRvIHZlcmlmeS4=",
    "T3": "Q3VycmVudGx5IGEgc2luZ2xlIGZhaWxpbmcgam9iIGNyYXNoZXMgdGhlIGVudGlyZSBzY2hlZHVsZXIuIEZvciBleGFtcGxlLCBpZiBqb2IgQiByYWlzZXMgYW4gZXhjZXB0aW9uLCBqb2IgQyBuZXZlciBydW5zLgoKRml4IHRoaXMgc28gdGhhdDoKLSBBIGpvYiB0aGF0IHJhaXNlcyBhbiBleGNlcHRpb24gaGFzIGl0cyBzdGF0dXMgc2V0IHRvICdmYWlsZWQnIGFuZCBpdHMgZXJyb3IgYXR0cmlidXRlIHNldCB0byB0aGUgZXhjZXB0aW9uCi0gRXhlY3V0aW9uIGNvbnRpbnVlcyB3aXRoIHRoZSBuZXh0IGpvYgotIFRoZSBqb2IncyByZXN1bHQgcmVtYWlucyBOb25lIG9uIGZhaWx1cmUKClRoZSBmaXggbXVzdCB0b3VjaCBzY2hlZGxpYi9qb2IucHkuIFlvdSBtYXkgYWxzbyBuZWVkIHRvIHVwZGF0ZSBzY2hlZGxpYi9zY2hlZHVsZXIucHkuCgpSdW4gcHl0ZXN0IHRvIGNvbmZpcm0gYWxsIHRlc3RzIHBhc3Mu",
    "T4": "VGhlIFNjaGVkdWxlci5ydW5fYWxsKCkgbWV0aG9kIGV4ZWN1dGVzIGpvYnMgaW4gdGhlIG9yZGVyIHRoZXkgd2VyZSBhZGRlZCwgYnV0IGl0IHNob3VsZCBleGVjdXRlIGhpZ2hlci1wcmlvcml0eSBqb2JzIGZpcnN0IChoaWdoZXN0IHByaW9yaXR5IGludGVnZXIgPSBydW5zIGZpcnN0KS4KCkZpeCBydW5fYWxsKCkgaW4gc2NoZWRsaWIvc2NoZWR1bGVyLnB5LiBUaGVuIHdyaXRlIGEgbmV3IHRlc3QgaW4gdGVzdHMvdGVzdF9zY2hlZHVsZXIucHkgcHJvdmluZyB0aGUgcHJpb3JpdHkgb3JkZXJpbmcgd29ya3MgY29ycmVjdGx5LgoKQWxsIGV4aXN0aW5nIHRlc3RzIG11c3Qgc3RpbGwgcGFzcyBhZnRlciB5b3VyIGNoYW5nZXMu",
    "T5": "VGhlIFJlcG9ydGVyIGNsYXNzIGlzIG1pc3NpbmcgYSBwZW5kaW5nX2pvYnMoKSBtZXRob2QsIGFuZCBpdHMgc3VtbWFyeSgpIG1ldGhvZCBpcyBpbmNvbXBsZXRlLgoKTWFrZSB0aGUgZm9sbG93aW5nIGNoYW5nZXMgdG8gc2NoZWRsaWIvcmVwb3J0ZXIucHk6CjEuIEFkZCBhIHBlbmRpbmdfam9icygpIG1ldGhvZCB0aGF0IHJldHVybnMgYWxsIGpvYnMgd2l0aCBzdGF0dXMgZXhhY3RseSBlcXVhbCB0byAncGVuZGluZycuIEpvYnMgd2l0aCBzdGF0dXMgJ3J1bm5pbmcnIG11c3QgTk9UIGJlIGluY2x1ZGVkLgoyLiBVcGRhdGUgc3VtbWFyeSgpIHRvIGluY2x1ZGUgYSAncGVuZGluZycga2V5IGNvbnRhaW5pbmcgdGhlIGNvdW50IG9mIHBlbmRpbmcgam9icy4KClVwZGF0ZSBvciBhZGQgdGVzdHMgaW4gdGVzdHMvdGVzdF9yZXBvcnRlci5weSBhcyBuZWVkZWQuIFJ1biBweXRlc3QgdG8gY29uZmlybSBhbGwgdGVzdHMgcGFzcy4=",
}


# ── tmux helpers ──────────────────────────────────────────────────────────────

def tmux(*args):
    subprocess.run(["tmux"] + list(args), check=True)


def tmux_run(cmd):
    """Send a shell command followed by Enter to the tmux session."""
    tmux("send-keys", "-t", TMUX_SESSION, cmd, "Enter")


def tmux_keys(keys):
    """Send a key sequence (e.g. 'C-c') without Enter."""
    tmux("send-keys", "-t", TMUX_SESSION, keys, "")


def kill_tmux_session():
    subprocess.run(["tmux", "kill-session", "-t", TMUX_SESSION], capture_output=True)


def fresh_tmux_session():
    kill_tmux_session()
    time.sleep(0.5)
    tmux("new-session", "-d", "-s", TMUX_SESSION)
    time.sleep(0.5)


# ── SQLite helpers ────────────────────────────────────────────────────────────

def db_query(sql, *params):
    """Return first column of first row, or None."""
    if not DB.exists():
        return None
    try:
        con = sqlite3.connect(str(DB), timeout=5)
        cur = con.cursor()
        cur.execute(sql, params)
        row = cur.fetchone()
        con.close()
        return row[0] if row else None
    except Exception:
        return None


def get_latest_session_id():
    return db_query("SELECT id FROM session ORDER BY time_created DESC LIMIT 1")


def get_part_count(session_id):
    return db_query("SELECT COUNT(*) FROM part WHERE session_id = ?", session_id) or 0


def get_part_details(session_id):
    counts = {"total": 0, "bash": 0, "read": 0, "write": 0, "edit": 0,
              "text": 0, "reasoning": 0, "other": 0}
    if not DB.exists():
        return counts
    try:
        con = sqlite3.connect(str(DB), timeout=5)
        cur = con.cursor()
        cur.execute("SELECT data FROM part WHERE session_id = ?", (session_id,))
        for (data_str,) in cur.fetchall():
            counts["total"] += 1
            try:
                d = json.loads(data_str)
                ptype = d.get("type", "other")
                if ptype == "tool":
                    tool = d.get("tool", "other")
                    counts[tool] = counts.get(tool, 0) + 1
                elif ptype in counts:
                    counts[ptype] += 1
                else:
                    counts["other"] += 1
            except Exception:
                counts["other"] += 1
        con.close()
    except Exception:
        pass
    return counts


# ── Ollama ────────────────────────────────────────────────────────────────────

def ensure_ollama():
    result = subprocess.run(["ollama", "ps"], capture_output=True, text=True)
    if "NAME" not in result.stdout:
        print("  Starting Ollama server...")
        subprocess.Popen(["ollama", "serve"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(6)
        result2 = subprocess.run(["ollama", "ps"], capture_output=True, text=True)
        if result2.returncode != 0:
            raise RuntimeError("Ollama failed to start — run 'ollama serve' manually")
    print("  Ollama: running")


# ── Task runner ───────────────────────────────────────────────────────────────

def run_one_task(task_text, project_dir, task_name):
    before_id = get_latest_session_id()

    # Fresh tmux session + start OpenCode
    fresh_tmux_session()
    tmux_run(f"cd {project_dir} && {OPENCODE_BIN}")

    print(f"  Waiting {TUI_LOAD_WAIT}s for OpenCode TUI to load...", flush=True)
    time.sleep(TUI_LOAD_WAIT)

    # Inject task via bracketed paste (handles multi-line without spurious Enter)
    task_file = Path("/tmp/oc_task.txt")
    task_file.write_text(task_text)
    tmux("load-buffer", str(task_file))
    tmux("paste-buffer", "-t", TMUX_SESSION, "-p")
    time.sleep(0.5)
    tmux_keys("Enter")

    # Wait for a new session row to appear in the DB
    print(f"  Task injected — waiting for OpenCode session in DB...", flush=True)
    start = time.time()
    session_id = None
    while time.time() - start < SESSION_WAIT:
        sid = get_latest_session_id()
        if sid and sid != before_id:
            session_id = sid
            break
        time.sleep(2)

    if not session_id:
        print(f"  WARNING: No new session after {SESSION_WAIT}s — using latest")
        session_id = get_latest_session_id() or "unknown"

    print(f"  Session: {session_id}", flush=True)

    # Poll for completion: stable part count for QUIET_SECONDS.
    # SESSION_GRACE gives the model time to produce its first token before
    # we start checking whether it has gone quiet.
    task_start = time.time()
    session_seen = time.time()  # when the DB session first appeared
    last_count = 0
    last_change = time.time()
    done = False

    while time.time() - task_start < TASK_TIMEOUT:
        count = get_part_count(session_id)
        if count != last_count:
            last_count = count
            last_change = time.time()
            elapsed = time.time() - task_start
            print(f"  [{elapsed:5.0f}s] {task_name}: {count} parts", flush=True)
        else:
            past_grace = (time.time() - session_seen) > SESSION_GRACE
            quiet_long = count > 0 and (time.time() - last_change) > QUIET_SECONDS
            if past_grace and quiet_long:
                done = True
                break
        time.sleep(2)

    elapsed = time.time() - task_start
    if done:
        print(f"  {task_name}: complete ({last_count} parts, {elapsed:.0f}s)", flush=True)
    else:
        print(f"  WARNING: {task_name} timed out after {TASK_TIMEOUT}s ({last_count} parts)", flush=True)

    # Stop OpenCode by killing the tmux session
    kill_tmux_session()
    time.sleep(1)

    details = get_part_details(session_id)
    return session_id, elapsed, details


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <iter_name> <repo_root>")
        sys.exit(1)

    iter_name = sys.argv[1]
    repo_root = Path(sys.argv[2]).expanduser().resolve()
    project_dir = repo_root / "project"
    results_dir = repo_root / "results"
    results_dir.mkdir(exist_ok=True)

    session_log   = results_dir / f"{iter_name}_auto_sessions.log"
    metrics_file  = results_dir / f"{iter_name}_auto_metrics.json"
    transcript_file = results_dir / f"{iter_name}_auto_transcript.md"

    print(f"\n{'═'*56}")
    print(f"  Harness v2 — {iter_name}  (auto mode)")
    print(f"{'═'*56}")

    # Prerequisites
    print("\n── Checking prerequisites...")
    ensure_ollama()

    # Reset project to buggy baseline
    print("\n── Resetting project to baseline...")
    subprocess.run(["bash", str(repo_root / "eval/reset.sh")], check=True)

    # Install AGENTS.md for this iteration
    agents_src = repo_root / "iterations" / iter_name / "AGENTS.md"
    agents_dst = project_dir / "AGENTS.md"
    agents_dst.unlink(missing_ok=True)
    if agents_src.exists():
        shutil.copy(agents_src, agents_dst)
        print(f"Harness: {iter_name}/AGENTS.md installed")
    else:
        print("Harness: none (cold baseline)")

    # Session log header
    with open(session_log, "w") as f:
        f.write(f"Iteration: {iter_name}\n")
        f.write(f"Started: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")

    metrics = {}

    for i in range(1, 6):
        task_name = f"T{i}"
        task_text = base64.b64decode(TASK_B64[task_name]).decode("utf-8")

        print(f"\n{'─'*56}")
        print(f"  TASK {i} / 5")
        print(f"{'─'*56}")

        session_id, elapsed, details = run_one_task(task_text, project_dir, task_name)

        with open(session_log, "a") as f:
            f.write(f"{task_name}: {session_id}\n")

        metrics[task_name] = {
            "session_id": session_id,
            "elapsed_seconds": round(elapsed, 1),
            **details,
        }

    # Score
    print(f"\n{'─'*56}", flush=True)
    print("── Scoring...", flush=True)
    subprocess.run(
        ["bash", str(repo_root / "eval/check.sh"), f"{iter_name}_auto"],
        check=True,
    )

    # Extract transcripts
    print("\n── Extracting transcripts...")
    subprocess.run(
        [
            "python3",
            str(repo_root / "runner/extract_transcripts.py"),
            str(session_log),
            str(transcript_file),
        ],
        check=True,
    )

    # Write metrics JSON
    metrics_file.write_text(json.dumps(metrics, indent=2))

    print(f"\n── Metrics : {metrics_file}")
    print(f"── Score   : {results_dir / 'scores.log'}")
    print(f"── Done.")


if __name__ == "__main__":
    main()

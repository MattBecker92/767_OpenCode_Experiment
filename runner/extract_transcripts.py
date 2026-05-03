#!/usr/bin/env python3
"""
runner/extract_transcripts.py

Reads a session log file (one session ID per task) and extracts
a clean human-readable transcript from the OpenCode SQLite database.

Usage:
    python3 extract_transcripts.py <session_log> <output_md>
"""

import json
import re
import sqlite3
import sys
from pathlib import Path

DB_PATH = Path.home() / ".local/share/opencode/opencode.db"


def extract(session_log_path: str, output_path: str) -> None:
    log_lines = Path(session_log_path).read_text().splitlines()

    # Parse "T1: ses_xxx" lines
    task_sessions: dict[str, str] = {}
    for line in log_lines:
        m = re.match(r"(T\d+):\s*(ses_\S+)", line)
        if m:
            task_sessions[m.group(1)] = m.group(2)

    if not task_sessions:
        print("No session IDs found in log.")
        return

    con = sqlite3.connect(str(DB_PATH))
    cur = con.cursor()

    lines = []
    for task_id in sorted(task_sessions):
        session_id = task_sessions[task_id]
        lines.append(f"\n{'='*70}")
        lines.append(f"## {task_id} — Session: {session_id}")
        lines.append('='*70)

        # Get session title
        cur.execute("SELECT title FROM session WHERE id = ?", (session_id,))
        row = cur.fetchone()
        if row:
            lines.append(f"**Title:** {row[0]}\n")

        # Get all parts ordered by time
        cur.execute(
            "SELECT data FROM part WHERE session_id = ? ORDER BY time_created",
            (session_id,)
        )
        parts = cur.fetchall()

        for (data_str,) in parts:
            try:
                d = json.loads(data_str)
            except Exception:
                continue

            ptype = d.get("type")

            if ptype == "text":
                text = d.get("text", "").strip()
                if not text:
                    continue
                if "time" not in d:
                    lines.append(f"\n**[USER]**")
                else:
                    lines.append(f"\n**[ASSISTANT]**")
                lines.append(text)

            elif ptype == "reasoning":
                text = d.get("text", "").strip()
                if text:
                    lines.append(f"\n*[THINKING]: {text[:400]}{'...' if len(text) > 400 else ''}*")

            elif ptype == "tool":
                tool = d.get("tool", "")
                state = d.get("state", {})
                inp = state.get("input", {})
                output = state.get("output", "")

                if tool == "bash":
                    cmd = inp.get("command", "")[:300]
                    lines.append(f"\n```bash\n# [BASH]\n{cmd}\n```")
                    if output:
                        out = str(output).strip()[:600]
                        lines.append(f"```\n{out}\n```")
                elif tool == "read":
                    fp = inp.get("filePath", inp.get("file_path", ""))
                    lines.append(f"\n*[READ] `{fp}`*")
                elif tool in ("write", "edit"):
                    fp = inp.get("filePath", inp.get("file_path", ""))
                    content = inp.get("content", inp.get("newStr", ""))[:300]
                    lines.append(f"\n*[{tool.upper()}] `{fp}`*")
                    if content:
                        lines.append(f"```python\n{content}\n```")
                else:
                    lines.append(f"\n*[TOOL:{tool}] {str(inp)[:200]}*")

    con.close()

    output = "\n".join(lines)
    Path(output_path).write_text(output)
    print(f"Transcript written: {output_path} ({len(lines)} lines)")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <session_log> <output_md>")
        sys.exit(1)
    extract(sys.argv[1], sys.argv[2])

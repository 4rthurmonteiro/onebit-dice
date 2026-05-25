#!/usr/bin/env python3
"""
Merge `gh issue list --json` output into .ralph/prd.json.

Usage:
    gh issue list --json number,title,url,labels | \\
        python3 sync_prd.py <prd_path> <repo> <label> <limit>

Reads issue JSON from stdin. Preserves `passes` and `note` on existing tasks.
Prints merge stats to stderr and a summary table to stdout.
"""

import json
import sys
import datetime

PRIORITY_MAP = {
    "priority:urgent": 1,
    "priority:high":   2,
    "priority:normal": 3,
    "priority:low":    4,
}


def parse_priority(labels):
    matches = [PRIORITY_MAP[lbl["name"]] for lbl in labels if lbl.get("name") in PRIORITY_MAP]
    return min(matches) if matches else 0


def main():
    if len(sys.argv) != 5:
        print(f"Usage: {sys.argv[0]} <prd_path> <repo> <label> <limit>", file=sys.stderr)
        sys.exit(2)

    prd_path = sys.argv[1]
    repo     = sys.argv[2]
    label    = sys.argv[3]
    limit    = int(sys.argv[4])

    tasks_fetched = json.load(sys.stdin)

    existing = {}
    try:
        with open(prd_path) as f:
            existing = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        pass

    existing_by_id = {t["id"]: t for t in existing.get("tasks", [])}

    def build_task(t):
        id_ = f"GH-{t['number']}"
        prev = existing_by_id.get(id_, {})
        return {
            "id":       id_,
            "title":    t.get("title", ""),
            "url":      t.get("url", ""),
            "priority": parse_priority(t.get("labels", [])),
            "passes":   prev.get("passes", False) is True,
            "note":     prev.get("note", ""),
        }

    tasks = [build_task(t) for t in tasks_fetched]
    tasks.sort(key=lambda t: (t["priority"] if t["priority"] else 99, t["title"]))

    now_utc = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    out = {
        "syncedAt": now_utc,
        "filter":   {"repo": repo, "label": label, "limit": limit},
        "tasks":    tasks,
    }
    with open(prd_path, "w") as f:
        json.dump(out, f, indent=2)
        f.write("\n")

    done = sum(1 for t in tasks if t["passes"])
    new  = sum(1 for t in tasks if t["id"] not in existing_by_id)
    print(f"Synced {len(tasks)} tasks ({new} new, {done} already passing).", file=sys.stderr)

    todo = len(tasks) - done
    print(f"  syncedAt: {now_utc}")
    print(f"  total:    {len(tasks)} ({done} passing, {todo} pending)")
    for t in tasks[:10]:
        flag = "OK" if t["passes"] else "  "
        print(f"  {flag} {t['id']:<10} {t['title'][:70]}")
    if len(tasks) > 10:
        print(f"  ... and {len(tasks) - 10} more")


if __name__ == "__main__":
    main()

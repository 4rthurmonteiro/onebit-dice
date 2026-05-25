#!/usr/bin/env bash
# Description: Pull GitHub Issues into .ralph/prd.json, the task source for the Ralph loop.
# Usage:
#   ./tools/ralph/sync-github.sh [--repo <owner/repo>] [--label <label>] \
#                                 [--limit <n>] [--dry-run]
#
# Defaults: repo=4rthurmonteiro/onebit-dice, label=ready-for-agent, limit=25
# Requires: gh CLI (authenticated), python3.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RALPH_DIR="$REPO_ROOT/.ralph"
PRD_FILE="$RALPH_DIR/prd.json"

repo="4rthurmonteiro/onebit-dice"
label="ready-for-agent"
limit=25
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)    repo="$2";    shift 2 ;;
    --label)   label="$2";   shift 2 ;;
    --limit)   limit="$2";   shift 2 ;;
    --dry-run) dry_run=1;    shift ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "sync-github.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "sync-github.sh: gh CLI not found on PATH. Install GitHub CLI: https://cli.github.com" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "sync-github.sh: python3 not found on PATH." >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "sync-github.sh: gh is not authenticated. Run: gh auth login" >&2
  exit 1
fi

if [[ "$dry_run" -eq 1 ]]; then
  echo "--- DRY RUN ---"
  echo "Would run: gh issue list --repo $repo --label $label --json number,title,url,labels --limit $limit"
  exit 0
fi

mkdir -p "$RALPH_DIR"

echo "[ralph/sync-github] Fetching issues from $repo (label=$label, limit=$limit)" >&2

gh issue list \
  --repo "$repo" \
  --label "$label" \
  --json number,title,url,labels \
  --limit "$limit" | \
  python3 "$SCRIPT_DIR/sync_prd.py" "$PRD_FILE" "$repo" "$label" "$limit"

if [[ ! -s "$PRD_FILE" ]]; then
  echo "[ralph/sync-github] WARNING: $PRD_FILE was not produced." >&2
  exit 1
fi

echo "[ralph/sync-github] Done."

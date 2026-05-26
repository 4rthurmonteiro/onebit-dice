#!/usr/bin/env bash
# Description: Run the Ralph loop unsupervised, up to N iterations or until done.
# Usage: ./tools/ralph/afk-ralph.sh <max-iterations> [--sleep <secs>]
#
# Workflow:
#   - Creates an integration branch ralph/batch/<UTC-timestamp> from the current
#     branch and pushes it to origin. All per-task branches gh-NNN-* are created
#     from this batch branch and each PR targets it (gh pr create --base ...).
#   - Once the loop finishes, the dev opens a single release-candidate PR from
#     ralph/batch/<ts> to the original branch (usually main). The command is
#     printed at startup and logged for convenience.
#
# Each iteration:
#   - Verifies a clean working tree (no leftover diff).
#   - Invokes claude against tools/ralph/prompt.md and captures its output.
#   - Greps the output for a <promise>...</promise> stop marker.
#   - Loops only on <promise>CONTINUE</promise>; any other marker exits the driver.
#
# Outputs are tee'd to .ralph/runs/<timestamp>.log so you can audit AFK runs.
#
# Iteration cap is mandatory to prevent runaway loops with stochastic agents.
# Requires: claude CLI (authenticated via `claude login`, or ANTHROPIC_API_KEY
# in env if running in a sandbox/Docker without local auth).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RALPH_DIR="$REPO_ROOT/.ralph"
RUN_DIR="$RALPH_DIR/runs"
PRD_FILE="$RALPH_DIR/prd.json"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

if [[ $# -lt 1 ]]; then usage; fi

max_iter="$1"; shift
if ! [[ "$max_iter" =~ ^[0-9]+$ ]] || [[ "$max_iter" -lt 1 ]] || [[ "$max_iter" -gt 200 ]]; then
  echo "afk-ralph.sh: <max-iterations> must be an integer in [1, 200]" >&2
  exit 2
fi

sleep_secs=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sleep)   sleep_secs="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "afk-ralph.sh: unknown arg: $1" >&2; usage ;;
  esac
done

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------

if ! command -v claude >/dev/null 2>&1; then
  echo "afk-ralph.sh: claude CLI not found on PATH. Install Claude Code first." >&2
  exit 1
fi

# ANTHROPIC_API_KEY is optional: when unset, claude CLI uses the local
# keychain auth from `claude login`. Only required in headless sandboxes
# (Docker, CI) where no keychain is available.

cd "$REPO_ROOT"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ ! -s "$PRD_FILE" ]]; then
  echo "afk-ralph.sh: $PRD_FILE missing/empty. Run ./tools/ralph/sync-github.sh first." >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "afk-ralph.sh: working tree is dirty. Commit or stash first." >&2
  git status --short
  exit 1
fi

# ---------------------------------------------------------------------------
# Integration (batch) branch: all per-task branches and PRs target this branch.
# The dev opens a single release-candidate PR from this branch to main at the
# end of the AFK run. ralph/batch/<UTC-timestamp> from current branch.
# ---------------------------------------------------------------------------
ts="$(date -u +%Y%m%dT%H%M%SZ)"
batch_branch="ralph/batch/$ts"

echo "[afk-ralph] Creating integration branch $batch_branch from $current_branch" >&2
if ! git checkout -b "$batch_branch" "$current_branch"; then
  echo "afk-ralph.sh: failed to create $batch_branch" >&2
  exit 1
fi

if ! git push -u origin "$batch_branch"; then
  echo "afk-ralph.sh: failed to push $batch_branch to origin" >&2
  exit 1
fi

base_branch="$batch_branch"

mkdir -p "$RUN_DIR"
log_file="$RUN_DIR/$ts.log"

echo "[afk-ralph] base=$base_branch  max_iter=$max_iter  log=$log_file" | tee -a "$log_file"
echo "[afk-ralph] When the loop finishes, open the release-candidate PR with:" | tee -a "$log_file"
echo "[afk-ralph]   gh pr create --base $current_branch --head $batch_branch --title 'feat: ralph batch $ts (release candidate)'" | tee -a "$log_file"

# ---------------------------------------------------------------------------
# Loop
# ---------------------------------------------------------------------------

for ((i=1; i<=max_iter; i++)); do
  echo "" | tee -a "$log_file"
  echo "================ iteration $i / $max_iter ================" | tee -a "$log_file"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "[afk-ralph] dirty tree between iterations — stopping." | tee -a "$log_file"
    git status --short | tee -a "$log_file"
    exit 1
  fi

  prompt=$(cat <<EOF
@tools/ralph/prompt.md
@tools/ralph/AGENTS.md
@.ralph/prd.json
@.ralph/progress.txt

Base branch: ${base_branch}
Iteration: ${i} of ${max_iter}

Run one Ralph iteration following the contract in @tools/ralph/prompt.md exactly.
Your last line MUST be exactly <promise>COMPLETE|CONTINUE|BLOCKED|NO_TASKS|DIRTY_TREE</promise>.
EOF
)

  set +e
  output=$(claude --dangerously-skip-permissions -p "$prompt" 2>&1 | tee -a "$log_file")
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    echo "[afk-ralph] claude exited $rc — stopping." | tee -a "$log_file"
    exit "$rc"
  fi

  last_marker=$(printf '%s\n' "$output" | grep -oE '<promise>(COMPLETE|CONTINUE|BLOCKED|NO_TASKS|DIRTY_TREE)</promise>' | tail -n1 || true)

  case "$last_marker" in
    "<promise>COMPLETE</promise>")
      echo "[afk-ralph] Loop COMPLETE at iteration $i." | tee -a "$log_file"
      exit 0 ;;
    "<promise>CONTINUE</promise>")
      echo "[afk-ralph] iteration $i CONTINUE — running another." | tee -a "$log_file"
      sleep "$sleep_secs" ;;
    "<promise>BLOCKED</promise>")
      echo "[afk-ralph] BLOCKED — human attention needed. Stopping." | tee -a "$log_file"
      exit 1 ;;
    "<promise>NO_TASKS</promise>")
      echo "[afk-ralph] NO_TASKS — re-run sync-github.sh." | tee -a "$log_file"
      exit 1 ;;
    "<promise>DIRTY_TREE</promise>")
      echo "[afk-ralph] DIRTY_TREE — clean the working tree and rerun." | tee -a "$log_file"
      exit 1 ;;
    "")
      echo "[afk-ralph] No <promise> marker found in output — stopping defensively." | tee -a "$log_file"
      exit 1 ;;
    *)
      echo "[afk-ralph] Unknown marker '$last_marker' — stopping." | tee -a "$log_file"
      exit 1 ;;
  esac
done

echo "[afk-ralph] Reached iteration cap ($max_iter) without COMPLETE." | tee -a "$log_file"
exit 1

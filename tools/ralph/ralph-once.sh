#!/usr/bin/env bash
# Description: Run a single (HITL) iteration of the Ralph loop using Claude Code CLI.
# Usage: ./tools/ralph/ralph-once.sh [--print-prompt-only]
#
# This is the human-in-the-loop entrypoint: you watch the agent work, intervene if needed,
# and rerun manually. Use this until the prompt is well-tuned, then switch to afk-ralph.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RALPH_DIR="$REPO_ROOT/.ralph"
PRD_FILE="$RALPH_DIR/prd.json"
PROGRESS_FILE="$RALPH_DIR/progress.txt"

print_prompt_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print-prompt-only) print_prompt_only=1; shift ;;
    -h|--help)
      sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "ralph-once.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

cd "$REPO_ROOT"
base_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$print_prompt_only" -eq 1 ]]; then
  cat <<EOF
@tools/ralph/prompt.md
@tools/ralph/AGENTS.md
@.ralph/prd.json
@.ralph/progress.txt

Base branch: ${base_branch}

Run one Ralph iteration following the contract in @tools/ralph/prompt.md exactly.
Remember: your final line MUST be one of <promise>COMPLETE|CONTINUE|BLOCKED|NO_TASKS|DIRTY_TREE</promise>.
EOF
  exit 0
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "ralph-once.sh: claude CLI not found on PATH. Install Claude Code first." >&2
  exit 1
fi

mkdir -p "$RALPH_DIR"
[[ -f "$PROGRESS_FILE" ]] || : > "$PROGRESS_FILE"

if [[ ! -s "$PRD_FILE" ]]; then
  echo "ralph-once.sh: $PRD_FILE missing or empty. Run ./tools/ralph/sync-github.sh first." >&2
  exit 1
fi

prompt=$(cat <<EOF
@tools/ralph/prompt.md
@tools/ralph/AGENTS.md
@.ralph/prd.json
@.ralph/progress.txt

Base branch: ${base_branch}

Run one Ralph iteration following the contract in @tools/ralph/prompt.md exactly.
Remember: your final line MUST be one of <promise>COMPLETE|CONTINUE|BLOCKED|NO_TASKS|DIRTY_TREE</promise>.
EOF
)

echo "[ralph-once] base=$base_branch  claude -> 1 iteration"

claude --dangerously-skip-permissions -p "$prompt"

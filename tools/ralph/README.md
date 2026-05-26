# Ralph — autonomous coding loop for 1-Bit Dice

Ralph is a small set of scripts that run **Claude Code CLI** (`claude --dangerously-skip-permissions`)
in a loop against a list of GitHub Issues. Each iteration: pick a task, implement it, run
Flutter feedback loops, commit, open a PR, log progress, repeat until the list is done.

Based on the pattern from [Tips For AI Coding With Ralph Wiggum][ralph-post], adapted for:
- **Claude Code CLI** instead of Cursor (`claude --dangerously-skip-permissions -p`).
- **GitHub Issues** as the task source (via `gh` CLI).
- **Flutter / Dart** feedback loops — `flutter analyze` + `very_good test --coverage --min-coverage 100`,
  enforcing the 100% line-coverage rule from `CLAUDE.md` (with `lib/main.dart` excluded).

[ralph-post]: https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum

## Files

```
tools/ralph/
├── README.md          ← you are here
├── AGENTS.md          ← operating contract the agent reads each iteration
├── prompt.md          ← per-iteration prompt (what to do in one pass)
├── sync-github.sh     ← seed .ralph/prd.json from GitHub Issues
├── sync_prd.py        ← Python helper: merge gh issue list JSON into prd.json
├── feedback.sh        ← Flutter feedback orchestrator (analyze + coverage)
├── ralph-once.sh      ← HITL: a single iteration you watch
└── afk-ralph.sh       ← AFK: a capped loop you don't watch

.ralph/                 ← gitignored session state
├── prd.json           ← task list, refreshed by sync-github.sh
├── progress.txt       ← append-only iteration log
└── runs/<ts>.log      ← per-AFK-run transcripts
```

## Prerequisites

| Tool | Why | How to check |
|------|-----|--------------|
| `claude` | Claude Code CLI | `claude --version` |
| `ANTHROPIC_API_KEY` | Required for non-interactive runs (AFK loop) | `echo $ANTHROPIC_API_KEY` |
| `gh` | GitHub CLI (authenticated) | `gh auth status` |
| `flutter` or `fvm` | Flutter feedback loops | `flutter --version` |
| `very_good` | Coverage gate via Very Good CLI | `very_good --version` (install: `dart pub global activate very_good_cli`) |
| `python3` | JSON helpers in sync scripts | `python3 --version` |
| `shellcheck` *(optional)* | Lints `tools/**/*.sh` | `shellcheck --version` |

Missing optional tools degrade gracefully — `feedback.sh` skips that loop with a log line.

## GitHub labels

Issues that Ralph should pick up are tagged with `ready-for-agent`. Priority is derived
from label:

| GitHub label | Priority |
|---|---|
| `priority:urgent` | 1 |
| `priority:high` | 2 |
| `priority:normal` | 3 |
| `priority:low` | 4 |
| *(none)* | 0 (sorted last) |

All five labels are created on the repo by the setup. If a label is missing on a fresh
repo, create it with `gh label create <name>`.

Issues board: https://github.com/4rthurmonteiro/onebit-dice/issues?q=label%3Aready-for-agent

## Writing an issue Ralph can handle

A good Ralph-ready issue has:

1. **Clear acceptance criteria** as a checklist — Ralph stops when these are met.
2. **Scope** — one feature slice or fix. Multi-package, multi-feature work should be split.
3. **References** to `CLAUDE.md`, the relevant `docs/plan/`, or design notes.
4. **Constraints** that aren't already in `CLAUDE.md` (e.g. "must not touch the splash
   feature").
5. Labels: `ready-for-agent` + optional `priority:*`.

Example:

```markdown
## Goal
Add a d20 face to the dice roller.

## Acceptance criteria
- [ ] `DiceRoller` supports `DiceKind.d20`
- [ ] Tapping the d20 chip triggers a roll animation
- [ ] 100% line coverage on new code
- [ ] No new dependencies; no new colors

## References
- `docs/roadmap/m1.md` — dice section
- `lib/features/dice/` — existing implementation
```

## Usage

### 0. Make scripts executable (first time only)

```bash
chmod +x tools/ralph/*.sh
```

### 1. Pick a feature branch (optional — Ralph creates per-task branches)

Ralph creates a per-task branch (`gh-NNN-desc`) for each issue, so you can run from
`main`. If you want to gate the work behind an integration branch, check out that
branch before running.

### 2. Sync the PRD from GitHub Issues

```bash
./tools/ralph/sync-github.sh                                # ready-for-agent, up to 25
./tools/ralph/sync-github.sh --label ready-for-agent --limit 10
./tools/ralph/sync-github.sh --dry-run                      # show what would run
```

This uses the `gh` CLI to fetch open issues and writes `.ralph/prd.json`. Re-run any
time to refresh — `passes` and `note` fields on existing tasks are preserved across syncs.

Available flags:

| Flag | Default | Meaning |
|------|---------|---------|
| `--repo` | `4rthurmonteiro/onebit-dice` | GitHub repo |
| `--label` | `ready-for-agent` | Label filter |
| `--limit` | `25` | Max issues to fetch |
| `--dry-run` | off | Print what would run without calling the API |

### 3. Start with HITL (human-in-the-loop)

```bash
./tools/ralph/ralph-once.sh
```

Watch the agent work, intervene if it goes off-track. Re-run as many times as you want.
Use this until you trust the prompt and the loops on your machine.

### 4. Then go AFK (capped)

```bash
./tools/ralph/afk-ralph.sh 10           # up to 10 iterations
./tools/ralph/afk-ralph.sh 30 --sleep 5 # up to 30, 5s between iterations
```

**Batch (integration) branch.** At startup `afk-ralph.sh` creates
`ralph/batch/<UTC-timestamp>` from the current branch and pushes it to origin. Every
per-task PR Ralph opens targets that integration branch (not `main`). When the loop
finishes you review the stack of small PRs, then open a single release-candidate PR
from `ralph/batch/<ts>` → original branch. The exact `gh pr create --base ...` command
for the release-candidate PR is printed at startup and tee'd to the run log.

Each iteration's full output is tee'd to `.ralph/runs/<timestamp>.log`. The driver stops
on any of:

| Marker the agent emits | Driver action |
|------------------------|---------------|
| `<promise>COMPLETE</promise>` | exit 0 (every PRD task `passes: true`) |
| `<promise>CONTINUE</promise>` | run another iteration |
| `<promise>BLOCKED</promise>`  | exit 1 (review the log) |
| `<promise>NO_TASKS</promise>` | exit 1 (re-sync from GitHub Issues) |
| `<promise>DIRTY_TREE</promise>` | exit 1 (commit/stash and rerun) |

**The cap is mandatory** (1–200).

### 5. End of sprint

```bash
rm -rf .ralph/
```

`.ralph/` is session-local, never committed. `progress.txt` is for the agent's
short-term memory; once the work is merged the git log is the permanent record.

## Feedback loops

`feedback.sh` is what the agent calls before every commit:

| Files changed | What runs |
|---------------|-----------|
| `*.dart`, `pubspec.yaml`, `analysis_options.yaml` | `flutter analyze` + `very_good test --coverage --min-coverage 100 --exclude-coverage 'lib/main.dart,**/*.g.dart'` |
| `tools/**/*.sh`, `*.sh` | `shellcheck` (if installed) |
| Anything else | no-op (logged) |

Manual invocations:

```bash
./tools/ralph/feedback.sh               # diff vs HEAD + untracked files
./tools/ralph/feedback.sh --base main   # everything since main
./tools/ralph/feedback.sh --all         # full suite at repo root
```

## VGV review pass

After `feedback.sh` is green and before committing, Ralph mirrors `/build` Phase 3 and
dispatches five VGV review agents in parallel — `@vgv-review-agent`,
`@code-simplicity-review-agent`, `@test-quality-review-agent`, `@architecture-review-agent`,
`@pr-readiness-review-agent`. Each writes a report under `docs/reviews/` (gitignored,
deleted at end of iteration). Findings are bucketed Critical / Important / Suggestions;
Critical is fixed in the same commit; Important and Suggestions surface in the PR body
under "Review notes". See `tools/ralph/AGENTS.md` for the full contract.

After the per-task PR is opened, Ralph also runs the `/review` skill against the new PR
number as a defensive pass on the diff a human would see. Blocking findings are fixed
on the same branch and pushed; non-blocking ones are appended to the PR body.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `claude: not found` | Install Claude Code CLI. |
| `gh: not found` | Install GitHub CLI: `brew install gh` or https://cli.github.com |
| `gh: not authenticated` | Run `gh auth login`. |
| `flutter: not found` | Install Flutter SDK or `fvm`. |
| `very_good: not found` | `dart pub global activate very_good_cli` and add `~/.pub-cache/bin` to PATH. |
| Coverage below 100% | Read the lcov summary printed by `very_good test`; add the missing test cases. Never lower `--min-coverage`. |
| Agent picked the wrong task | Edit `.ralph/prd.json` — set `passes: true` on the ones you want skipped, or remove the `ready-for-agent` label on GitHub and re-sync. |
| Agent loops on the same task | Read `.ralph/progress.txt` and the failing output; switch to `ralph-once.sh` to unblock. |
| `<promise>` marker missing | The agent violated the contract — re-read `tools/ralph/prompt.md`. |
| GitHub sync returned no tasks | Confirm issues are open and labelled `ready-for-agent`; check the repo flag. |

# Ralph Loop AGENTS.md

This document is the operating contract for the **Ralph** autonomous coding loop in this
repository. Ralph runs Claude Code CLI (`claude --dangerously-skip-permissions`) in a
capped loop against `tools/ralph/prompt.md`, picking one task per iteration from
`.ralph/prd.json` (synced from GitHub Issues) and committing the result.

If you are an agent invoked by `tools/ralph/ralph-once.sh` or `tools/ralph/afk-ralph.sh`,
this file describes how you must operate. The iteration prompt at `tools/ralph/prompt.md`
adds the per-iteration steps; this file is the broader contract that does not change between
iterations.

## Scope of authority

| Allowed | Forbidden |
|---------|-----------|
| Edit code under `lib/`, `test/`, `docs/`, `tools/`, `assets/`, `pubspec.yaml`, `analysis_options.yaml` | Edit `.git/`, `.env*`, `~/.aws/`, `~/.ssh/`, anything outside the workspace |
| Run `flutter`, `dart`, `very_good`, `git`, `gh`, `claude`, `./tools/*` | Run `git push --force`, `git commit --amend`, `git commit --no-verify`, `git rebase -i`, `git config` |
| Create a per-task branch `gh-NNN-desc` from the base branch | NEVER commit directly to `main` |
| `git push -u origin gh-NNN-desc` (push the feature branch) | Modify pre-commit hooks or skip them |
| `gh pr create` to open a PR linking to the GitHub issue | Run `dart format` (formatting belongs to the developer) |
| Create commits with a GitHub-issue-referenced message (`feat: ... (#NNN)`) | |
| Append to `.ralph/progress.txt`, update `.ralph/prd.json` | Delete or rewrite earlier entries in `.ralph/progress.txt` |

## Where to find context

- `CLAUDE.md` (root) — project-wide principles, tech stack, 1-bit palette rule, state
  management constraints, commit conventions, quality gates.
- `docs/roadmap/` — product spec and epics.
- `docs/plan/progress.md` — task tracker (the human-facing one; Ralph uses GitHub Issues).
- `docs/brainstorm/` and `docs/plan/` — design discussions and implementation plans.

When making a non-trivial change, re-read `CLAUDE.md` to ensure your change still complies.

## Hard project rules (from CLAUDE.md)

1. **2-color palette only** — every theme uses exactly `ink` + `paper`. No third tone,
   no gradients, no shadows, no anti-aliasing. If a task pushes you toward a third
   color, stop and emit `<promise>BLOCKED</promise>`.
2. **State management**: `setState` + `ChangeNotifier` + `package:provider` (DI only).
   Do **not** add Bloc, Riverpod, or any other state-management package.
3. **Quality gates** — every commit must pass:
   - `flutter analyze` → 0 issues (`very_good_analysis` rules)
   - `flutter test --coverage` → all green, **100% line coverage**
   - `lib/main.dart` is excluded from coverage. Generated `*.g.dart` files (when they
     exist) are also excluded.
4. **Blocked tasks** marked `[!]` in `docs/plan/progress.md` require human intervention —
   skip them.

## Feedback loops you must run

Ralph never commits without a green feedback loop. The orchestrator script
`./tools/ralph/feedback.sh` chooses what to run based on the diff:

| Files changed in… | What `feedback.sh` runs |
|-------------------|-------------------------|
| `*.dart`, `pubspec.yaml`, `analysis_options.yaml` | `flutter analyze` and `very_good test --coverage --min-coverage 100` (with `lib/main.dart` excluded) |
| `tools/**/*.sh`, `*.sh` | `shellcheck` (if installed) |
| Anything else (docs, assets) | no-op (logged) |

If `feedback.sh` exits non-zero, fix the failures and re-run before committing. Never
disable a check to make it pass. Never lower `--min-coverage`.

### Why these loops?

- **`flutter analyze`** is the primary lint loop; uses `very_good_analysis` ruleset.
- **`very_good test --coverage --min-coverage 100`** enforces the CLAUDE.md 100%
  line-coverage rule on the changed package, excluding `lib/main.dart`.
- **No Dart formatter** — formatting is owned by the developer. Never run `dart format`.

## VGV review agents (post-feedback, pre-commit)

After `feedback.sh` is green and BEFORE committing, Ralph dispatches the same five review
agents that `/build` runs in Phase 3. All five are launched **in a single message with
parallel tool calls** so they execute concurrently. Each writes a markdown report under
`docs/reviews/`:

| Agent | Report file | Focus |
|-------|-------------|-------|
| `@vgv-review-agent` | `docs/reviews/vgv-review.md` | VGV engineering standards (architecture, state, tests, simplicity) |
| `@code-simplicity-review-agent` | `docs/reviews/code-simplicity-review.md` | YAGNI, premature abstraction, dead code |
| `@test-quality-review-agent` | `docs/reviews/test-quality-review.md` | Coverage gaps, tautological assertions, mocking misuse |
| `@architecture-review-agent` | `docs/reviews/architecture-review.md` | Layer separation, dependency direction, provider wiring |
| `@pr-readiness-review-agent` | `docs/reviews/pr-readiness-review.md` | Formatting, static analysis, debug artifacts, commit hygiene |

After all five complete, consolidate into three buckets:

- **Critical** (must fix this iteration) — bugs, missing tests, layer violations, broken
  analysis. Read the specific report file for details, fix, re-run `feedback.sh`, then
  commit the fixes alongside the implementation.
- **Important** (should fix) — convention deviations, naming, test gaps. Fix if cheap;
  otherwise capture in the PR body under "Review notes".
- **Suggestions** — record in the PR body only.

Only read a review report when it contains Critical findings — do not load all five into
context. After fixes are committed, delete `docs/reviews/` (it is transient workspace
state and never committed).

## Commit conventions

Required format (from CLAUDE.md):
```text
<type>(<scope>): <imperative summary, ≤ 70 chars> (#NNN)
```

Where `type` is one of:

| Type | Meaning |
|---|---|
| `feat` | new user-visible feature |
| `fix` | bug fix |
| `chore` | tooling, deps, CI, config |
| `test` | adding or updating tests |
| `docs` | documentation only |
| `refactor` | code change that neither fixes a bug nor adds a feature |

`#NNN` is the GitHub issue number (e.g. `#42`).

Use a HEREDOC:
```bash
git commit -m "$(cat <<'EOF'
feat(dice): add d20 roll animation (#42)
EOF
)"
```

Never `--amend`, never `--no-verify`, never `--force` push.

## Branch hygiene

Ralph creates **one branch per task** from the base branch. Branch name format:
`gh-NNN-short-description`. The base branch is supplied in the iteration prompt as
`Base branch:` and is **never `main` directly**:

- **AFK mode (`afk-ralph.sh`)** — the driver creates an integration branch
  `ralph/batch/<UTC-timestamp>` from the current branch and pushes it to origin
  before the first iteration. All per-task branches are `gh-NNN-*` off the batch
  branch, and each PR targets the batch branch via `gh pr create --base`. After the
  loop finishes the dev opens **one** release-candidate PR from the batch branch to
  the original branch (usually `main`) — the command is printed at startup and logged.
- **HITL mode (`ralph-once.sh`)** — the base branch is whatever branch the dev was
  on when invoking the script. The single per-task PR targets that branch.

Per-iteration flow:
1. Pick task (`GH-NNN`).
2. `git checkout "$BASE_BRANCH" && git checkout -b gh-NNN-short-description`.
   - If the branch already exists (retry): `git checkout gh-NNN-short-description`
3. Implement + run feedback loops.
4. Run the five VGV review agents in parallel. Fix Critical findings. Delete `docs/reviews/`.
5. Commit.
6. `git push -u origin gh-NNN-short-description`
7. `gh pr create --base "$BASE_BRANCH" ...` (links to `Closes #NNN`)
8. **`/review`** the freshly opened PR. Fix blockers; push fixes. Edit PR body for non-blockers.
9. `git checkout "$BASE_BRANCH"` — return to base before the next iteration.

Never commit directly to `main`. Never open a PR with `--base main` from inside an iteration.

## Session state

```
.ralph/
├── prd.json       # Task list, refreshed by tools/ralph/sync-github.sh
├── progress.txt   # Append-only iteration log (NEVER rewrite)
└── runs/<ts>.log  # Per-AFK-run transcripts
```

`.ralph/` is **not** committed (it's in `.gitignore`). Treat it as session-local.

`prd.json` schema (every iteration must round-trip these fields untouched):

```json
{
  "syncedAt": "2026-05-24T13:00:00Z",
  "filter": {
    "repo": "4rthurmonteiro/onebit-dice",
    "label": "ready-for-agent",
    "limit": 25
  },
  "tasks": [
    {
      "id": "GH-42",
      "title": "Add d20 roll animation",
      "url": "https://github.com/4rthurmonteiro/onebit-dice/issues/42",
      "priority": 2,
      "passes": false,
      "note": ""
    }
  ]
}
```

Notes on the schema:
- `id` is the GitHub issue number in `GH-NNN` format.
- `priority` is derived from GitHub labels (`priority:urgent`=1, `priority:high`=2,
  `priority:normal`=3, `priority:low`=4, none=0). Lower non-zero values come first;
  `0` is sorted last.
- `passes: true` means this iteration successfully implemented and committed the task.

## Stop markers

Every iteration's last line must be exactly one of:

| Marker | Meaning | Driver action |
|--------|---------|---------------|
| `<promise>COMPLETE</promise>` | Every task in `.ralph/prd.json` has `passes: true` | Loop exits 0 |
| `<promise>CONTINUE</promise>` | Work remains | Loop runs another iteration |
| `<promise>BLOCKED</promise>` | Human attention needed | Loop exits 1 with the reason |
| `<promise>NO_TASKS</promise>` | `.ralph/prd.json` empty or missing | Loop exits 1 |
| `<promise>DIRTY_TREE</promise>` | Pre-existing uncommitted changes detected | Loop exits 1 |

The AFK driver greps for these literally — do not rephrase or wrap them.

## Quality bar

This is production code targeting iOS/Android. Match the existing structure
(`lib/core/`, `lib/features/`, `lib/shared/`), the `setState + ChangeNotifier + provider`
pattern, and the `very_good_analysis` lint rules. When in doubt, prefer the smallest
change that satisfies the GitHub issue acceptance criteria and re-read `CLAUDE.md`.

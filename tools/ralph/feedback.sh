#!/usr/bin/env bash
# Description: Run feedback loops for the current diff: flutter analyze + very_good test
#              --coverage --min-coverage 100 (excluding lib/main.dart), plus shellcheck on
#              any changed shell scripts.
# Usage: ./tools/ralph/feedback.sh [--base <ref>] [--all]
#
# Behaviour:
#   - With no args: inspects `git diff --name-only HEAD` plus untracked files. If any
#     Dart/pubspec/analysis_options changed, runs analyze + tests at the repo root.
#   - --base <ref>: diffs against <ref> instead of HEAD (e.g. main for a full-branch run).
#   - --all: runs the full analyze + coverage test suite at the repo root regardless of diff.
#
# Exit codes:
#   0  every feedback loop passed
#   1  at least one loop failed
#   2  bad usage

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

usage() {
  sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

mode="diff"
base_ref="HEAD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)    base_ref="$2"; shift 2 ;;
    --all)     mode="all";    shift ;;
    -h|--help) usage ;;
    *) echo "feedback.sh: unknown arg: $1" >&2; usage ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()  { printf '\033[1;34m[ralph/feedback]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[ralph/feedback FAIL]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ralph/feedback OK]\033[0m %s\n' "$*"; }

failures=""
record_failure() { failures="${failures}${1}"$'\n'; }
failures_count() { [[ -z "$failures" ]] && echo 0 || printf '%s' "$failures" | grep -c .; }

flutter_cmd() {
  if command -v fvm >/dev/null 2>&1; then
    echo "fvm flutter"
  else
    echo "flutter"
  fi
}

# Coverage exclusions per CLAUDE.md: lib/main.dart is excluded; any future *.g.dart too.
coverage_excludes='lib/main.dart,**/*.g.dart'

run_flutter_analyze() {
  local flutter
  flutter="$(flutter_cmd)"
  if ! command -v ${flutter%% *} >/dev/null 2>&1; then
    fail "flutter (or fvm) not found on PATH"
    record_failure "flutter:missing"
    return 1
  fi
  log "flutter analyze"
  if ! (cd "$REPO_ROOT" && $flutter analyze); then
    fail "flutter analyze failed"
    record_failure "flutter-analyze"
  else
    ok "flutter analyze passed"
  fi
}

run_coverage_tests() {
  if ! command -v very_good >/dev/null 2>&1; then
    fail "very_good CLI not found on PATH (install: dart pub global activate very_good_cli)"
    record_failure "very_good:missing"
    return 1
  fi
  log "very_good test --coverage --min-coverage 100 (excludes: $coverage_excludes)"
  if ! (cd "$REPO_ROOT" && very_good test --coverage --min-coverage 100 --exclude-coverage "$coverage_excludes"); then
    fail "very_good test failed (analyze or coverage gate)"
    record_failure "very-good-test"
  else
    ok "very_good test passed (100% line coverage)"
  fi
}

run_shellcheck_for_files() {
  [[ $# -eq 0 ]] && return 0
  if ! command -v shellcheck >/dev/null 2>&1; then
    log "shellcheck not installed — skipping shell lint"
    return 0
  fi
  log "shellcheck: $*"
  if ! shellcheck "$@"; then
    fail "shellcheck reported issues"
    record_failure "shellcheck"
  else
    ok "shellcheck passed"
  fi
}

changed_files() {
  if [[ "$base_ref" == "HEAD" ]]; then
    {
      git diff --name-only HEAD --
      git ls-files --others --exclude-standard
    } | sort -u
  else
    git diff --name-only "$base_ref"...HEAD --
  fi
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

if [[ "$mode" == "all" ]]; then
  log "Mode: --all (full suite at repo root)"
  run_flutter_analyze || true
  run_coverage_tests || true
else
  files=""
  while IFS= read -r line; do
    case "$line" in
      .ralph/*|"") continue ;;
    esac
    files="${files}${line}"$'\n'
  done < <(changed_files)

  if [[ -z "$files" ]]; then
    log "No changed files vs $base_ref — nothing to verify."
    exit 0
  fi
  file_count="$(printf '%s' "$files" | grep -c .)"
  log "Changed files (${file_count}):"
  printf '%s' "$files" | sed 's/^/  - /'

  needs_dart=0
  sh_files=""

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      *.dart | pubspec.yaml | pubspec.lock | analysis_options.yaml)
        needs_dart=1
        ;;
      tools/*.sh|tools/**/*.sh|*.sh)
        sh_files="${sh_files}${REPO_ROOT}/${f}"$'\n'
        ;;
    esac
  done <<< "$files"

  if [[ "$needs_dart" -eq 1 ]]; then
    run_flutter_analyze || true
    run_coverage_tests || true
  fi

  if [[ -n "$sh_files" ]]; then
    sh_args=()
    while IFS= read -r s; do
      [[ -z "$s" ]] && continue
      sh_args+=("$s")
    done < <(printf '%s' "$sh_files" | sort -u)
    run_shellcheck_for_files "${sh_args[@]}"
  fi
fi

if [[ "$(failures_count)" -gt 0 ]]; then
  fail "Feedback loop summary: $(failures_count) failure(s)"
  printf '%s' "$failures" | sed 's/^/  - /'
  exit 1
fi

ok "All feedback loops passed."

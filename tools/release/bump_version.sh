#!/usr/bin/env bash
#
# Bumps the semantic version in pubspec.yaml.
#
# Usage: tools/release/bump_version.sh <major|minor|patch>
#
# The `+build` number is ALWAYS incremented. The semver part is bumped
# according to the level:
#   major  1.2.3+9 -> 2.0.0+10
#   minor  1.2.3+9 -> 1.3.0+10
#   patch  1.2.3+9 -> 1.2.4+10
#
# Prints the new "<semver>+<build>" string to stdout and rewrites pubspec.yaml
# in place. Portable across GNU (CI) and BSD/macOS sed.
set -euo pipefail

level="${1:-patch}"
pubspec="${2:-pubspec.yaml}"

case "$level" in
  major | minor | patch) ;;
  *)
    echo "error: bump level must be major, minor, or patch (got '$level')" >&2
    exit 1
    ;;
esac

current="$(grep -E '^version:' "$pubspec" | head -1 | sed 's/version:[[:space:]]*//')"
if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "error: unexpected version format '$current' (want <major>.<minor>.<patch>+<build>)" >&2
  exit 1
fi

semver="${current%%+*}"
build="${current##*+}"
IFS='.' read -r major minor patch <<<"$semver"

case "$level" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

new="${major}.${minor}.${patch}+$((build + 1))"

tmp="$(mktemp)"
sed "s/^version:.*/version: ${new}/" "$pubspec" >"$tmp" && mv "$tmp" "$pubspec"

echo "$new"

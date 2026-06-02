#!/usr/bin/env bash
#
# Builds a signed release APK and distributes it to Firebase App Distribution.
#
# This is the SINGLE source of truth for releases: you run it on your machine,
# and CI (.github/workflows/release.yml) runs the exact same script. The only
# difference is where the credentials come from:
#
#   Local  — android/key.properties (already on disk) + `firebase login`.
#   CI     — GitHub Secrets, which the workflow exports as the env vars below;
#            this script then materializes them into the same key.properties +
#            service-account file it would find locally.
#
# Usage:
#   tools/release/distribute.sh [--bump major|minor|patch] [--groups qa,beta] \
#                               [--testers a@x.com,b@x.com] [--notes "notes"]
#
# --groups aliases must already exist in the Firebase console (App Distribution
# -> Testers & groups). --testers distributes to individual e-mails directly,
# which needs no group. If neither is given, it defaults to the `qa` group.
#
# Examples (local):
#   firebase login                       # one-time
#   tools/release/distribute.sh --notes "smoke test"        # -> qa group
#   tools/release/distribute.sh --testers you@example.com   # -> just you
#   tools/release/distribute.sh --bump patch --notes "RC"   # bump + distribute
#
# Environment variables (used by CI; optional locally):
#   ANDROID_KEYSTORE_BASE64   base64 of the upload keystore (.jks)
#   ANDROID_STORE_PASSWORD    keystore store password
#   ANDROID_KEY_PASSWORD      key password
#   ANDROID_KEY_ALIAS         key alias
#   FIREBASE_SERVICE_ACCOUNT  service-account JSON *content* (auth for the CLI)
#   FIREBASE_TOKEN            alternative CI auth (firebase CLI reads it natively)
#   FIREBASE_ANDROID_APP_ID   override the default Android App ID
set -euo pipefail

BUMP="none"
GROUPS="${FIREBASE_GROUPS:-}"
TESTERS="${FIREBASE_TESTERS:-}"
NOTES=""
APP_ID="${FIREBASE_ANDROID_APP_ID:-1:590407408363:android:9dd0c4e47f9c2f664b7cae}"

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump) BUMP="${2:?--bump needs a value}"; shift 2 ;;
    --groups) GROUPS="${2:?--groups needs a value}"; shift 2 ;;
    --testers) TESTERS="${2:?--testers needs a value}"; shift 2 ;;
    --notes) NOTES="${2:?--notes needs a value}"; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "error: unknown argument '$1'" >&2; usage >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# --- Resolve the Firebase CLI (global install or npx fallback) -------------
if command -v firebase >/dev/null 2>&1; then
  FIREBASE=(firebase)
elif command -v npx >/dev/null 2>&1; then
  FIREBASE=(npx --yes firebase-tools)
else
  echo "error: Firebase CLI not found. Install it with:" >&2
  echo "  npm install -g firebase-tools   (then: firebase login)" >&2
  exit 1
fi

# --- Signing: materialize key.properties from secrets when it's not present -
# Locally key.properties already exists and points at your keystore, so this
# block is skipped. In CI it rebuilds the same config from the secret env vars.
if [[ ! -f android/key.properties && -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "==> Writing android/key.properties from environment"
  echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode >android/app/upload-keystore.jks
  cat >android/key.properties <<EOF
storePassword=${ANDROID_STORE_PASSWORD:?ANDROID_STORE_PASSWORD is required}
keyPassword=${ANDROID_KEY_PASSWORD:?ANDROID_KEY_PASSWORD is required}
keyAlias=${ANDROID_KEY_ALIAS:?ANDROID_KEY_ALIAS is required}
storeFile=upload-keystore.jks
EOF
elif [[ ! -f android/key.properties ]]; then
  echo "==> WARNING: android/key.properties not found and no keystore secrets" >&2
  echo "    The APK will be signed with the debug key (test-only; not Play-Store ready)." >&2
fi

# --- Firebase auth: service-account JSON content -> temp file ---------------
# If FIREBASE_SERVICE_ACCOUNT / GOOGLE_APPLICATION_CREDENTIALS / FIREBASE_TOKEN
# are all unset, the CLI uses your interactive `firebase login` session.
if [[ -n "${FIREBASE_SERVICE_ACCOUNT:-}" ]]; then
  cred_file="$(mktemp)"
  trap 'rm -f "$cred_file"' EXIT
  printf '%s' "$FIREBASE_SERVICE_ACCOUNT" >"$cred_file"
  export GOOGLE_APPLICATION_CREDENTIALS="$cred_file"
fi

# --- Version bump (optional) ------------------------------------------------
if [[ "$BUMP" != "none" ]]; then
  version="$(tools/release/bump_version.sh "$BUMP")"
  echo "==> Bumped version to $version"
else
  version="$(grep -E '^version:' pubspec.yaml | head -1 | sed 's/version:[[:space:]]*//')"
  echo "==> Using current version $version (no bump)"
fi

[[ -n "$NOTES" ]] || NOTES="1-Bit Dice $version"

# --- Build the signed release APK -------------------------------------------
echo "==> Building release APK"
flutter pub get
flutter build apk --release
apk="build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$apk" ]] || { echo "error: APK not found at $apk" >&2; exit 1; }

# --- Distribute -------------------------------------------------------------
# Default to the `qa` group only when no audience was specified at all.
if [[ -z "$GROUPS" && -z "$TESTERS" ]]; then
  GROUPS="qa"
fi

dist_args=(--app "$APP_ID" --release-notes "$NOTES")
[[ -n "$GROUPS" ]] && dist_args+=(--groups "$GROUPS")
[[ -n "$TESTERS" ]] && dist_args+=(--testers "$TESTERS")

echo "==> Distributing $apk (groups: ${GROUPS:-none}, testers: ${TESTERS:-none})"
if ! "${FIREBASE[@]}" appdistribution:distribute "$apk" "${dist_args[@]}"; then
  echo "" >&2
  echo "error: distribution failed." >&2
  echo "  If the upload succeeded but it failed on 'distributing to testers/groups'" >&2
  echo "  with a 404, the group alias does not exist yet. Either:" >&2
  echo "    - create the group in the Firebase console (App Distribution ->" >&2
  echo "      Testers & groups) and use its alias with --groups, or" >&2
  echo "    - distribute to individual e-mails with --testers a@x.com,b@x.com" >&2
  exit 1
fi

echo "==> Done: $version distributed (groups: ${GROUPS:-none}, testers: ${TESTERS:-none})"

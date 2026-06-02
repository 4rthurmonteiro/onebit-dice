# Firebase App Distribution & Release Automation

How test builds of **1-Bit Dice** reach testers, and how the automated release
pipeline works.

- **Firebase project:** `onebit-dice-am2` (configured in task 0.6)
- **Android App ID:** `1:590407408363:android:9dd0c4e47f9c2f664b7cae`
- **iOS App ID:** `1:590407408363:ios:a380550bd8ee63b24b7cae` _(not yet automated)_

App Distribution is a separate Firebase product from the Crashlytics/Analytics
already integrated. It needs **no app code** — only console setup plus the CI
pipeline described here.

---

## 1. One-time console setup (human)

1. Firebase Console → `onebit-dice-am2` → **Release & Monitor → App
   Distribution** → enable for the Android app.
2. **Testers & Groups** tab → create a group named **`qa`** (the pipeline
   distributes to this group) and add tester e-mails.
3. Each tester accepts the e-mail invite and installs the Firebase App Tester
   app on their device.

## 2. Manual distribution via CLI (validate before relying on CI)

```bash
firebase login            # or use a CI token / service account
flutter build apk --release
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:590407408363:android:9dd0c4e47f9c2f664b7cae \
  --groups "qa" \
  --release-notes "Manual test build — 1-Bit Dice"
```

Confirm a tester receives the invite and can install the build.

## 3. Automated release on merge to `main`

The workflow [`.github/workflows/release.yml`](../../.github/workflows/release.yml)
triggers **only on push to `main`** (a PR merge). `ci.yml` continues to run on
every branch and PR. The release job runs in order:

1. **Gates** — `flutter analyze --fatal-infos`, `flutter test --coverage`, and
   the 100 % coverage check. A broken build is never distributed.
2. **Semver bump** — [`tools/release/bump_version.sh`](../../tools/release/bump_version.sh)
   rewrites `version:` in `pubspec.yaml`. The **`+build` number always
   increments**; the semver part follows the merge commit message
   (Conventional Commits):

   | Commit message               | Bump  | Example           |
   | ---------------------------- | ----- | ----------------- |
   | `feat!:` / `BREAKING CHANGE` | major | `1.0.0+1 → 2.0.0+2` |
   | `feat:`                      | minor | `1.0.0+1 → 1.1.0+2` |
   | anything else                | patch | `1.0.0+1 → 1.0.1+2` |

3. **Build** — `flutter build apk --release`. Signed with the upload key when
   the keystore secrets are present; otherwise falls back to the debug key
   (acceptable for test distribution).
4. **Distribute** — uploads the APK to App Distribution group `qa` via the
   `wzieba/Firebase-Distribution-Github-Action`, using the merge commit message
   as the release notes.
5. **Commit the bump** — pushes `chore(release): bump version to <v> [skip ci]`
   back to `main`. The `chore(release):` prefix (`if:` guard) **and** `[skip
   ci]` both prevent this commit from re-triggering the workflow.

### Required GitHub Secrets

Settings → Secrets and variables → Actions. **Never commit these.**

| Secret                     | Required | Purpose                                                                 |
| -------------------------- | -------- | ----------------------------------------------------------------------- |
| `FIREBASE_SERVICE_ACCOUNT` | yes      | Service-account JSON (contents) with App Distribution Admin on the project. |
| `ANDROID_KEYSTORE_BASE64`  | no\*     | `base64 -i upload-keystore.jks` — the upload keystore.                  |
| `ANDROID_STORE_PASSWORD`   | no\*     | Keystore store password.                                                |
| `ANDROID_KEY_PASSWORD`     | no\*     | Key password.                                                           |
| `ANDROID_KEY_ALIAS`        | no\*     | Key alias (e.g. `upload`).                                              |
| `RELEASE_TOKEN`            | no\*\*   | PAT with `contents: write`, used when branch protection blocks the bot. |

\* If the keystore secrets are omitted the build still succeeds with the debug
key — fine for testers, but **not** an APK you can promote to the Play Store.

\*\* Needed only if `main` is protected against direct pushes. Create a
fine-grained PAT (or use a bypass) so the `github-actions[bot]` version-bump
commit can land. Without it the push step fails on a protected branch.

> The Android App ID is public (it ships in `google-services.json`) so it is
> hard-coded in the workflow rather than stored as a secret.

### Avoiding the release loop

The bump commit must not re-trigger the pipeline. Two independent guards:

- `if: ${{ !startsWith(github.event.head_commit.message, 'chore(release):') }}`
- `[skip ci]` in the commit message (honoured natively by GitHub Actions).

## 4. iOS (deferred)

iOS distribution needs a macOS runner, an ad-hoc provisioning profile, and
registered device UDIDs — all human-gated (see issue #24). When ready, add a
parallel `macos-latest` job that runs `flutter build ipa --release` and
distributes with the iOS App ID above.

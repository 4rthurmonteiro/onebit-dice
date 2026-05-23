---
title: "chore: e01 project setup"
type: chore
date: 2026-05-22
epic: E01
---

## chore: E01 — Project Setup

## Overview

Transforms the default Flutter counter-app scaffold into a production-ready foundation for 1-Bit Dice M1. Covers six areas executed in dependency order: SDK/platform constraints, dependencies, linting, folder structure, CLAUDE.md conventions, and CI pipeline.

No feature code is written in this epic — only infrastructure. Every subsequent epic (E02–E15) depends on this being complete and green.

## Problem Statement / Motivation

The current state is a bare Flutter scaffold with placeholder code, default linting, no CI, and no project conventions. Agents cannot reliably implement features without:

- A clean `pubspec.yaml` with linting and font assets configured
- Strict linting (`very_good_analysis`) to enforce code quality from the first commit
- A folder structure that all feature epics will populate
- A `CLAUDE.md` that encodes project conventions and prevents regressions
- A CI pipeline that gates every push on analyze + test + build + coverage

## Proposed Solution

Execute six sequential sub-tasks in dependency order. Each produces a passing `flutter analyze` before moving to the next.

**Order:** T1 (SDK) → T2 (deps) → T3 (linting) → T4 (structure) → T5 (CLAUDE.md) → T6 (CI)

## Technical Considerations

- `build.gradle.kts` (KTS, not Groovy) — the current `applicationId` is `com.am2.onebitdice.onebit_dice`; must be corrected to `com.am2.onebitdice`
- `very_good_analysis` will flag the default counter app code — `lib/main.dart` and `test/widget_test.dart` must be replaced with VGA-compliant placeholders before running analyze
- `flutter.minSdkVersion` in `build.gradle.kts` delegates to Flutter's default (21); set it explicitly to document the intent
- iOS deployment target lives in both `ios/Runner.xcodeproj/project.pbxproj` and `ios/Podfile` — both must be updated
- Fonts are downloaded as local `.ttf` files (open-source, licensed under OFL); no runtime package needed
- 100% de coverage é obrigatório e verificado via `very_good_coverage`; `lib/main.dart` é excluído (entry point — apenas chama `runApp`); arquivos gerados (`*.g.dart`) são excluídos quando introduzidos em epics futuros

## Acceptance Criteria

- [ ] `flutter pub get` exits 0 with no version conflicts
- [ ] `flutter analyze` exits 0 with zero issues (very_good_analysis rules)
- [ ] `flutter test` passes (smoke test: app renders without crashing)
- [ ] Android `applicationId` and `namespace` are both `com.am2.onebitdice`
- [ ] Android `minSdk = 21` set explicitly
- [ ] iOS `IPHONEOS_DEPLOYMENT_TARGET = 13.0` in `project.pbxproj` and `Podfile`
- [ ] `flutter_lints` replaced by `very_good_analysis` in dev deps
- [ ] Font files present in `assets/fonts/` and declared in `pubspec.yaml`
- [ ] `analysis_options.yaml` includes only `very_good_analysis`
- [ ] Folder structure (`lib/core/`, `lib/features/`, `lib/shared/`, `assets/`) created and registered in `pubspec.yaml`
- [ ] `CLAUDE.md` present at project root with required sections
- [ ] `.github/workflows/ci.yml` created with 4 gates (analyze, test, build, coverage)
- [ ] `flutter test --coverage` gera 100% de line coverage (verificado via `very_good_coverage`)
- [ ] CI pipeline passes on first push

## Implementation Tasks

### T1 — SDK & Platform Constraints

**Files to modify:**

`pubspec.yaml`
- Update `description` to `"A retro 1-bit dice roller for board games and RPG."`
- Keep `sdk: ^3.12.0` (already correct)
- Keep `version: 1.0.0+1`

`android/app/build.gradle.kts`
```kotlin
android {
    namespace = "com.am2.onebitdice"          // fix: was com.am2.onebitdice.onebit_dice
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.am2.onebitdice"  // fix: was com.am2.onebitdice.onebit_dice
        minSdk = 21                           // explicit: was flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    // ... rest unchanged
}
```

`ios/Runner/Info.plist`
```xml
<key>CFBundleDisplayName</key>
<string>1-Bit Dice</string>
```
> Note: `CFBundleIdentifier` in `Info.plist` uses the `$(PRODUCT_BUNDLE_IDENTIFIER)` variable — do not change it here. Set the actual ID in `project.pbxproj`.

`ios/Runner.xcodeproj/project.pbxproj`
- Replace all occurrences of `PRODUCT_BUNDLE_IDENTIFIER = com.example.onebitDice;` with `PRODUCT_BUNDLE_IDENTIFIER = com.am2.onebitdice;`
- Set `IPHONEOS_DEPLOYMENT_TARGET = 13.0;` in all build configurations (Debug, Profile, Release)

`ios/Podfile`
```ruby
platform :ios, '13.0'
```

---

### T2 — Dependencies & Font Assets

Only what E01 actually needs. Every other dep is added in the epic that first uses it.

**`pubspec.yaml` — dev deps:**

Remove `flutter_lints: ^6.0.0`, add `very_good_analysis: ^7.0.0`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^7.0.0
```

**Font files — download and place in `assets/fonts/`:**

| File | Family | Weight |
|---|---|---|
| `Silkscreen-Regular.ttf` | Silkscreen | 400 |
| `Silkscreen-Bold.ttf` | Silkscreen | 700 |
| `VT323-Regular.ttf` | VT323 | 400 |
| `PressStart2P-Regular.ttf` | Press Start 2P | 400 |

All four are open-source (OFL license). Download from fonts.google.com and commit the `.ttf` files.

**`pubspec.yaml` — declare fonts:**

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/fonts/
    - assets/sounds/
    - assets/sprites/
  fonts:
    - family: Silkscreen
      fonts:
        - asset: assets/fonts/Silkscreen-Regular.ttf
        - asset: assets/fonts/Silkscreen-Bold.ttf
          weight: 700
    - family: VT323
      fonts:
        - asset: assets/fonts/VT323-Regular.ttf
    - family: PressStart2P
      fonts:
        - asset: assets/fonts/PressStart2P-Regular.ttf
```

Run: `flutter pub get` — verify `pubspec.lock` generated cleanly.

---

### T3 — Linting

**Files to modify:**

`analysis_options.yaml` — replace entire content:
```yaml
include: package:very_good_analysis/analysis_options.yaml
```

`lib/main.dart` — replace counter app with minimal VGA-compliant placeholder:
```dart
import 'package:flutter/material.dart';
import 'package:onebit_dice/app.dart';

void main() => runApp(const App());
```

`lib/app.dart` — create:
```dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '1-Bit Dice',
      home: Scaffold(
        body: Center(
          child: Text('1-Bit Dice'),
        ),
      ),
    );
  }
}
```

`test/widget_test.dart` — replace with VGA-compliant smoke test:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/app.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('1-Bit Dice'), findsOneWidget);
  });
}
```

Run `flutter analyze` and fix any remaining issues before proceeding.

---

### T4 — Folder Structure

**Directories to create** (add `.gitkeep` in each empty leaf):

```
lib/
├── core/
│   ├── analytics/
│   ├── audio/
│   ├── haptic/
│   ├── models/
│   ├── storage/
│   │   └── models/
│   └── theme/
├── features/
│   ├── dice/
│   │   └── widgets/
│   ├── history/
│   │   └── widgets/
│   ├── presets/
│   │   └── widgets/
│   ├── settings/
│   │   └── widgets/
│   └── splash/
└── shared/
    ├── utils/
    └── widgets/

test/
├── core/
│   ├── analytics/
│   ├── models/
│   └── storage/
└── features/
    ├── dice/
    ├── history/
    ├── presets/
    └── settings/

assets/
├── fonts/
├── sounds/
└── sprites/
```

Asset directories and `pubspec.yaml` flutter section are handled in T2.

---

### T5 — CLAUDE.md

**File to create:** `CLAUDE.md` at project root.

Required sections:

1. **Project** — 1-Bit Dice, AM2 Studio, what it is (dice roller, retro 1-bit aesthetic, iOS + Android)
2. **Stack** — Flutter stable, Dart ^3.12.0
3. **Folder structure** — abbreviated map of `lib/core/`, `lib/features/`, `lib/shared/`
4. **State management** — `setState` + `ChangeNotifier` only; no external state packages in M1
5. **Palette rule** — exactly 2 colors per palette: `ink` (foreground) and `paper` (background); zero intermediate tones
6. **Commit convention** — Conventional Commits: `feat:`, `fix:`, `chore:`, `test:`, `docs:`
7. **Quality gates** — `flutter analyze` (zero issues) + `flutter test --coverage` (all pass, 100% line coverage) before every commit
8. **References** — `docs/roadmap/` for full spec; `docs/plan/progress.md` for task tracker
9. **Blocked tasks** — tasks marked `[!]` in `progress.md` require human intervention; skip and move to next

---

### T6 — CI/CD

**File to create:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: ['**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Cache pub dependencies
        uses: actions/cache@v4
        with:
          path: ~/.pub-cache
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
          restore-keys: ${{ runner.os }}-pub-

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Test
        run: flutter test --coverage

      - name: Build APK (debug)
        run: flutter build apk --debug

      - name: Check 100% coverage
        run: |
          dart pub global activate very_good_coverage
          very_good_coverage --min-coverage 100 --exclude "lib/main.dart"

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/lcov.info
```

---

## Success Metrics

- All 4 CI gates green on first push after this epic
- Zero `flutter analyze` issues throughout all subsequent epics
- Agent loop can start immediately on E02 with no setup friction

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| `very_good_analysis` pode introduzir regras que conflitam com código gerado no futuro (ex: Hive `.g.dart`) | Adicionar `exclude` no `analysis_options.yaml` para `**.g.dart` quando geração de código for introduzida |
| iOS bundle ID: `project.pbxproj` tem múltiplas ocorrências — trocar só uma quebra o build | Buscar e substituir todas as ocorrências do bundle ID antigo |
| Fontes `.ttf` precisam ser commitadas no repo (arquivos binários) | São pequenas (~100–200KB total); sem problema commitar diretamente |

## References & Research

- Brainstorm: [docs/brainstorm/2026-05-22-e01-setup-projeto-brainstorm-doc.md](../brainstorm/2026-05-22-e01-setup-projeto-brainstorm-doc.md)
- Stack decisions: [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md)
- Task tracker: [docs/plan/progress.md](progress.md)
- [very_good_analysis on pub.dev](https://pub.dev/packages/very_good_analysis)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)

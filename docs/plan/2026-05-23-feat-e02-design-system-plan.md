---
title: "feat: e02 design system"
type: feat
date: 2026-05-23
epic: E02
status: planned
---

# feat: e02 design system — Standard

## Overview

Implement the foundational design system for 1-Bit Dice: 7 two-color palettes, a reactive `ThemeProvider`, three canonical pixel typography styles, and three base pixel widgets (`MacButton`, `MacWindow`, `PixelDivider`). Wire it into `lib/app.dart` via `package:provider` so every screen built afterwards (Home in E05, Settings in E08, etc.) consumes `ink`/`paper` through a single source of truth.

The brainstorm document ([2026-05-23-e02-design-system-brainstorm-doc.md](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md)) captured all architectural decisions (D1–D8). This plan turns those decisions into a concrete file-by-file implementation checklist with test scaffolding.

## Problem Statement / Motivation

Every feature epic from E03 onwards depends on having:

1. A way to render UI in 1-bit fidelity (no antialiasing, no gradients, no Material defaults leaking).
2. A reactive palette that can be swapped at runtime (M1 requirement: paleta trocável em tempo real, [01-escopo-m1.md:36](../roadmap/01-escopo-m1.md)).
3. Reusable widgets (`MacButton`, `MacWindow`, `PixelDivider`) that several screens will share — building them ad-hoc per feature creates drift and breaks the 1-bit illusion.

Without E02, every other epic ships either inconsistent visuals or duplicated styling code. E02 is on the critical path: no other feature epic can ship without it.

## Proposed Solution

Match the brainstorm 1-for-1. High-level structure:

```
lib/core/theme/
├── palette.dart              # PaletteId enum + Palette class + 7 constants
├── palette_preference.dart   # PalettePreference interface + InMemoryPalettePreference
├── theme_provider.dart       # ChangeNotifier
├── app_typography.dart       # 3 TextStyles
└── app_theme.dart            # OneBitColors ThemeExtension + buildThemeData(palette)

lib/shared/widgets/
├── mac_button.dart           # StatefulWidget, double border, offset shadow, pressed state
├── mac_window.dart           # CustomPaint striped title bar + bordered body
└── pixel_divider.dart        # 2px ink line

lib/app.dart                  # ChangeNotifierProvider<ThemeProvider> + context.watch theme rebuild

lib/features/_dev/
└── design_system_preview.dart  # // coverage:ignore-file — manual smoke-test screen
```

Wiring: `App` widget wraps the tree in `ChangeNotifierProvider<ThemeProvider>`; an inner `_AppView` calls `context.watch<ThemeProvider>()` and rebuilds `MaterialApp.theme` via `buildThemeData(palette)`.

Consumers of `MacButton`/`MacWindow`/`PixelDivider` read `ink`/`paper` exclusively via `Theme.of(context).extension<OneBitColors>()` — never hardcoded.

## Technical Considerations

- **Architecture**: introduces `package:provider` as the project's DI mechanism for `ChangeNotifier`s. CLAUDE.md was updated in this same change to reflect that (was previously banned). Future epics (E05 `DiceController`, E08 `SettingsController`) follow the same `ChangeNotifierProvider` + `context.watch` pattern.
- **Persistence boundary**: `ThemeProvider` depends on a `PalettePreference` interface. E02 ships `InMemoryPalettePreference` only. E04 will add `SharedPrefsPalettePreference` without modifying `ThemeProvider`.
- **`ColorScheme` completeness**: the Flutter `ColorScheme(...)` constructor requires every named slot (`surface`, `onSurface`, `primary`, `onPrimary`, `secondary`, `onSecondary`, `error`, `onError`, `outline`, `outlineVariant`, `inverseSurface`, `onInverseSurface`, `inversePrimary`, `shadow`, `scrim`, `tertiary`, `onTertiary`, `surfaceContainerHighest`, etc.). Every slot must map to `ink` or `paper` — no defaults left to Material.
- **Performance**: palette swap triggers one full `MaterialApp` rebuild. Acceptable for a 7-palette toggle that users will hit rarely (Settings flow only).
- **Test isolation**: `MacButton`/`MacWindow`/`PixelDivider` widget tests wrap the widget in `MaterialApp(theme: buildThemeData(p))` — no `ChangeNotifierProvider` needed since these widgets only consume `Theme.of(context)`.
- **Pixel rendering**: `FontFeature.disable('liga')` baked into the three `AppTypography` styles. No `FilterQuality.none` work in E02 (no `Image.asset` calls yet — sprite work lives in E03+/E12).
- **Coverage**: `_DesignSystemPreview` is excluded via `// coverage:ignore-file` (manual smoke-test scaffold, will be deleted in E09 when the real shell ships).
- **No security/privacy implications**: E02 ships pure UI code — no user input persisted, no network, no PII.

## Implementation Tasks

Execute in this order. Each step ends with `flutter analyze` + `flutter test --coverage` green.

### Step 0 — Dependency

- [ ] `flutter pub add provider` (target `provider: ^6.1.0` or latest stable in ^6.x)
- [ ] Verify `pubspec.lock` regenerated; commit both files together

### Step 1 — Palette ([F01](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f01--palette--paletteid))

- [ ] Create `lib/core/theme/palette.dart`
  - `enum PaletteId { macClassic, macBeige, gameBoy, c64, zxSpectrum, appleIIGreen, appleIIeAmber }`
  - `@immutable class Palette` with `id`, `name`, `ink`, `paper`
  - `static const Map<PaletteId, Palette> all` with all 7 entries (hex from [02-identidade-visual.md](../roadmap/02-identidade-visual.md#paletas))
  - `static Palette of(PaletteId id) => all[id]!`
- [ ] Create `test/core/theme/palette_test.dart`
  - Assert `Palette.all.length == 7`
  - Assert every `PaletteId` has an entry
  - Assert each palette's hex codes match the roadmap spec (regression guard)

### Step 2 — Typography ([F03](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f03--tipografia))

- [ ] Create `lib/core/theme/app_typography.dart`
  - 3 static `const TextStyle`: `display` (Silkscreen 24), `body` (VT323 18), `micro` (PressStart2P 10)
  - All three apply `[FontFeature.disable('liga')]`
- [ ] Create `test/core/theme/app_typography_test.dart`
  - Assert font families, sizes, and `FontFeature.disable('liga')` presence

### Step 3 — Theme integration ([F04](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f04--theming-integration))

- [ ] Create `lib/core/theme/app_theme.dart`
  - `class OneBitColors extends ThemeExtension<OneBitColors>` with `ink`, `paper`, `copyWith`, `lerp` (returns `this` — no interpolation in 1-bit)
  - `ThemeData buildThemeData(Palette p)`:
    - `brightness` derived from `p.paper.computeLuminance() > 0.5`
    - `scaffoldBackgroundColor: p.paper`
    - Full `ColorScheme(...)` mapping every required slot to `ink` or `paper`
    - `textTheme` built from `AppTypography` styles tinted with `p.ink`
    - `extensions: [OneBitColors(ink: p.ink, paper: p.paper)]`
    - `splashFactory: NoSplash.splashFactory`, `highlightColor: Colors.transparent`
- [ ] Create `test/core/theme/app_theme_test.dart`
  - For each of the 7 palettes: `buildThemeData(p).extension<OneBitColors>()` returns `OneBitColors(ink: p.ink, paper: p.paper)`
  - `scaffoldBackgroundColor == p.paper`
  - `splashFactory` is `NoSplash.splashFactory`
  - `colorScheme.surface == p.paper` and `colorScheme.onSurface == p.ink`
  - `brightness` matches the luminance rule (assert specifically for `macClassic` → light and `c64` → dark, for example)

### Step 4 — ThemeProvider + PalettePreference ([F02](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f02--themeprovider))

- [ ] Create `lib/core/theme/palette_preference.dart`
  - `abstract class PalettePreference { PaletteId? read(); Future<void> write(PaletteId id); }`
  - `class InMemoryPalettePreference implements PalettePreference` with private `PaletteId? _stored`
- [ ] Create `lib/core/theme/theme_provider.dart`
  - `class ThemeProvider extends ChangeNotifier`
  - Constructor `ThemeProvider({PalettePreference? preference})` defaults to `InMemoryPalettePreference()`
  - Reads initial palette from `preference.read() ?? PaletteId.macClassic`
  - `Palette get current`
  - `Future<void> setPalette(PaletteId id)` — early-return if same; updates state, notifies, awaits `preference.write(id)`
- [ ] Create `test/core/theme/palette_preference_test.dart`
  - `InMemoryPalettePreference`: `read()` returns null initially; after `write(gameBoy)`, `read()` returns `gameBoy`
- [ ] Create `test/core/theme/theme_provider_test.dart`
  - Initial `current` is `macClassic` when no preference stored
  - Initial `current` matches preference when stored
  - `setPalette(newId)` calls `notifyListeners` exactly once and updates `current`
  - `setPalette(currentId)` is a no-op (no notification, no preference write)
  - `setPalette` writes to preference (use a fake `PalettePreference` that records calls)

### Step 5 — MacButton ([F05](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f05--macbutton))

- [ ] Create `lib/shared/widgets/mac_button.dart`
  - `class MacButton extends StatefulWidget` with `label: String`, `onPressed: VoidCallback` (non-nullable), `expand: bool = false`
  - Visual per F05: double 2px ink border, 3px solid ink shadow, paper background, `AppTypography.display` label tinted ink, uppercase
  - `_MacButtonState` holds `bool _pressed`; `GestureDetector` with `onTapDown`/`onTapUp`/`onTapCancel`/`onTap`
  - When `_pressed == true`: shadow hidden, content shifted +3px x/y (visually "sunken")
  - Reads `ink`/`paper` exclusively from `Theme.of(context).extension<OneBitColors>()!`
  - When `expand == true`, wraps the button stack in a `SizedBox(width: double.infinity)` (or equivalent)
- [ ] Create `test/shared/widgets/mac_button_test.dart`
  - Pumps `MacButton(label: 'ROLAR', onPressed: () => calls++)` inside `MaterialApp(theme: buildThemeData(Palette.of(PaletteId.macClassic)))`
  - Tap calls `onPressed` exactly once per tap
  - `tester.startGesture` + hold: widget rebuilds with pressed state (assert visual offset or a `Key` swap)
  - Repeat the basic render across 3 palettes (`macClassic`, `gameBoy`, `zxSpectrum`) to verify no hardcoded colors
  - `expand: true` results in finite-width-constrained layout matching parent

### Step 6 — PixelDivider ([F07](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f07--pixeldivider))

- [ ] Create `lib/shared/widgets/pixel_divider.dart`
  - `class PixelDivider extends StatelessWidget` with `thickness: double = 2`, `padding: EdgeInsets = EdgeInsets.zero`
  - Builds `Padding(padding: padding, child: Container(height: thickness, color: ink))`
- [ ] Create `test/shared/widgets/pixel_divider_test.dart`
  - Default height is 2
  - Custom `thickness` honored
  - Color matches `OneBitColors.ink` (test under 2 distinct palettes)

### Step 7 — MacWindow ([F06](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f06--macwindow))

- [ ] Create `lib/shared/widgets/mac_window.dart`
  - `class MacWindow extends StatelessWidget` with `title: String?`, `child: Widget`, `onClose: VoidCallback?`
  - Outer: double 2px ink border around the whole window
  - Title bar: fixed height (~18px), background `paper`, painted by `CustomPainter` drawing horizontal 1px ink lines every 2px
    - Title text (when non-null): centered in a small `paper` rectangle that visually "cuts" the stripes
    - Close button (when `onClose != null`): 12×12 paper square with ink border + X glyph, left-aligned, calls `onClose` on tap
  - Body: `child` wrapped in `Padding(8) + Container(color: paper)`
- [ ] Create `test/shared/widgets/mac_window_test.dart`
  - Render with title + close button: tapping close calls `onClose`
  - Render with `onClose: null`: no close affordance present
  - Render with `title: null`: title rectangle absent (stripes uninterrupted)
  - Render in 2 palettes — verify no hardcoded colors

### Step 8 — App wiring + Design System Preview ([F08](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md#f08--app-wiring))

- [ ] Rewrite `lib/app.dart`
  - `App` (`StatelessWidget`) returns `ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(), child: const _AppView())`
  - `_AppView` (`StatelessWidget`) calls `context.watch<ThemeProvider>().current`, returns `MaterialApp(title: '1-Bit Dice', theme: buildThemeData(palette), home: const DesignSystemPreview())`
- [ ] Create `lib/features/_dev/design_system_preview.dart`
  - First line: `// coverage:ignore-file`
  - `class DesignSystemPreview extends StatelessWidget` (public so it can be imported from `app.dart`)
  - Layout:
    - Wordmark ("1-BIT DICE") in `AppTypography.display.copyWith(fontSize: 48)` at the top
    - `MacWindow` showing each base widget below (sample `MacButton`, sample `PixelDivider`)
    - Bottom row: 7 `Wrap`ped chips (one per palette, paper bg + ink border + palette name in `body` style) — `onTap` calls `context.read<ThemeProvider>().setPalette(id)`
  - Marked as a manual smoke-test in a doc comment
- [ ] Manual verification: run `flutter run` on a simulator and confirm:
  - All 7 chips visible
  - Tapping each chip swaps the theme instantly (no flash, no rebuild artifact)
  - `MacButton` press state visually sinks the button
  - `MacWindow` title bar shows clean 1px stripes at multiple DPRs (test 1x and 2x at minimum)

### Step 9 — Quality gates

- [ ] `flutter analyze` exits 0 with zero issues
- [ ] `flutter test --coverage` passes
- [ ] Inspect `coverage/lcov.info`: 100% line coverage on all new `lib/` files (`_DesignSystemPreview` excluded via `// coverage:ignore-file`)
- [ ] Update `docs/plan/progress.md`: mark EPIC 1 items 1.1–1.8 done; add a 1.x line if any extra files surfaced
- [ ] Commit per CLAUDE.md conventional-commits convention (likely 2 commits: `chore: allow package:provider` + `feat: add e02 design system`)

## Acceptance Criteria

- [ ] `pubspec.yaml` declares `provider: ^6.1.0` (or current ^6.x); `pubspec.lock` regenerated.
- [ ] `lib/core/theme/` contains: `palette.dart`, `palette_preference.dart`, `theme_provider.dart`, `app_typography.dart`, `app_theme.dart`.
- [ ] `lib/shared/widgets/` contains: `mac_button.dart`, `mac_window.dart`, `pixel_divider.dart`.
- [ ] `lib/app.dart` wires `ChangeNotifierProvider<ThemeProvider>` at the root; the inner widget reacts to palette changes via `context.watch`.
- [ ] `lib/features/_dev/design_system_preview.dart` is the temporary home screen and is marked `// coverage:ignore-file`.
- [ ] All 7 palettes from [02-identidade-visual.md](../roadmap/02-identidade-visual.md#paletas) are present in `Palette.all` with matching hex codes.
- [ ] `Theme.of(context).extension<OneBitColors>()` returns a non-null value under every palette.
- [ ] No `Color(0x...)` or `Colors.*` references appear in `mac_button.dart`, `mac_window.dart`, or `pixel_divider.dart` (all colors come from the `OneBitColors` extension).
- [ ] `flutter analyze` exits 0 with zero issues.
- [ ] `flutter test --coverage` passes with 100% line coverage on every new file in `lib/` (preview excluded).
- [ ] Manual smoke test: `flutter run` shows the preview; tapping each of the 7 palette chips swaps the theme in real time without a flash of unstyled content.

## Test Plan

| File under test | Test file | Type | Key assertions |
|---|---|---|---|
| `palette.dart` | `palette_test.dart` | Unit | 7 entries, hex codes match roadmap |
| `app_typography.dart` | `app_typography_test.dart` | Unit | Families/sizes/no-liga feature |
| `app_theme.dart` | `app_theme_test.dart` | Unit | Extension non-null per palette; brightness rule; surface/onSurface mapping |
| `palette_preference.dart` | `palette_preference_test.dart` | Unit | In-memory read/write round-trip |
| `theme_provider.dart` | `theme_provider_test.dart` | Unit | Initial state, notify on change, no-op on same, preference write |
| `mac_button.dart` | `mac_button_test.dart` | Widget | Tap fires `onPressed` once; pressed state; 3 palettes |
| `pixel_divider.dart` | `pixel_divider_test.dart` | Widget | Default 2px; thickness honored; color from extension |
| `mac_window.dart` | `mac_window_test.dart` | Widget | Close button presence/absence; title rendering; 2 palettes |

Test bootstrap helper (proposed inline in each widget test, not extracted yet):

```dart
Widget _harness(Widget child, {PaletteId id = PaletteId.macClassic}) =>
    MaterialApp(theme: buildThemeData(Palette.of(id)), home: Scaffold(body: child));
```

## Success Metrics

- All 7 palettes render in the preview, swappable in real time.
- Zero `flutter analyze` issues after every step.
- 100% line coverage across all new `lib/` files (preview excluded).
- E03 (Dice Engine) can begin immediately after merge with no design-system blockers.

## Dependencies & Risks

**Hard dependencies (must be done first):**
- E01 (Project Setup) — ✅ already shipped (commit `e894daa`).
- Local `.ttf` font files in `assets/fonts/` — ✅ already present, declared in `pubspec.yaml`.

**Adds a new project dependency:** `package:provider ^6.1.0`. CLAUDE.md was updated in this same change set to allow it; no compatibility risks (`provider` 6.x supports Dart `^3.0.0`).

**Risks:**

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `ColorScheme` slot list grows in a future Flutter version, breaking the constructor call | Low | Low | Pinned Flutter stable in CI; bump deliberately when CI fails |
| 1px/1px title-bar stripes look heavy on low-contrast palettes (amber/c64) | Medium | Low | Documented in brainstorm Open Questions; revisit after manual smoke test on device |
| `package:provider` later conflicts with another state-mgmt pkg the team wants | Low | Medium | CLAUDE.md now explicitly bans Bloc/Riverpod; revisit only if a real need surfaces in M2+ |
| Widget tests pass but render differs visually on real device | Medium | Low | Mandatory manual smoke test in Step 8; goldens deferred per D7 |
| `_DesignSystemPreview` accidentally ships in M1 release | Low | Medium | Will be replaced in E09 (navigation shell); add a `progress.md` reminder |

**Blocked (`[!]`) items that don't apply to E02**: none. E02 is fully unblockable.

## References & Research

- Brainstorm: [docs/brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md](../brainstorm/2026-05-23-e02-design-system-brainstorm-doc.md)
- Visual identity spec: [docs/roadmap/02-identidade-visual.md](../roadmap/02-identidade-visual.md)
- Stack technical spec: [docs/roadmap/03-stack-tecnico.md](../roadmap/03-stack-tecnico.md)
- M1 scope: [docs/roadmap/01-escopo-m1.md](../roadmap/01-escopo-m1.md)
- M1 epic list: [docs/roadmap/08-epics-m1.md](../roadmap/08-epics-m1.md)
- Progress tracker (update on completion): [docs/plan/progress.md](progress.md)
- Project conventions: [CLAUDE.md](../../CLAUDE.md) (state-management section updated to allow `package:provider`)
- Prior epic plan (for tone/structure reference): [docs/plan/2026-05-22-chore-e01-project-setup-plan.md](2026-05-22-chore-e01-project-setup-plan.md)
- Flutter `ThemeExtension` reference: https://api.flutter.dev/flutter/material/ThemeExtension-class.html
- `package:provider` (`ChangeNotifierProvider`): https://pub.dev/packages/provider

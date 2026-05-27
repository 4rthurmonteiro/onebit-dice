# Architecture Review — GH-10 Dice Animations

Branch: `gh-10-dice-animations`
Reviewer: architecture-review agent
Date: 2026-05-27

## Summary

The animation work lands cleanly inside the `features/dice` slice. Layer
separation, palette discipline, state-management constraints, and the
100% line-coverage gate are all upheld. No new state-management libraries.
No bleed into `lib/core`.

**Verdict:** Ready to merge.

## Critical
- None.

## Important
- None.

## Suggestions

- `DiceWidget` API change (adding `sides`, default `6`): **agree** with the
  divergence from the plan. The plan's "DiceWidget keeps its current API"
  was written before the cycle-bounding requirement landed. The available
  alternatives were:
  1. Threading `sides` explicitly through the widget tree (chosen).
  2. Reading `DiceController` via `context.watch` inside `DiceAnimator`.
  3. Hard-coding `6` and accepting incorrect faces for D4/D8/D10/D12/D20.
  Option 2 couples a generic animation utility to a feature-specific
  controller and inverts the dependency we want (animations should not
  depend on `DiceController`). Option 3 is wrong. Option 1 keeps the
  data flow explicit, props are immutable, and `DiceScreen` already
  watches `DiceController` exactly once. The default of `6` preserves
  source compatibility for any caller that does not yet care about
  multi-sided dice. Recommend keeping the change.
- `DiceGrid.builder` parameter is defined (`lib/features/dice/widgets/animations/dice_grid.dart:40`)
  and a `_wrap` helper exists, but no current strategy passes a builder.
  Either wire it up in `TabletopAnimation` (the docstring promises
  "per-slot transforms") or drop the parameter to avoid dead API. Not
  blocking — current single-transform approach in `TabletopAnimation`
  works.

## Detailed Findings

### Layer separation — clean

All four new files live under `lib/features/dice/widgets/animations/`.
Their imports (verified by scanning all `^import` lines):

- `drum_animation.dart`, `tabletop_animation.dart`: `dart:math`,
  `flutter/foundation.dart`, `flutter/material.dart`, sibling
  `dice_grid.dart`.
- `fast_animation.dart`: `flutter/material.dart`, sibling `dice_grid.dart`.
- `dice_grid.dart`: `flutter/material.dart`, `core/theme/app_theme.dart`,
  `core/theme/app_typography.dart`.

`features/dice` -> `core/theme` is the allowed direction. Nothing under
`lib/core/` imports from the animations folder. No imports into other
feature slices.

### Provider wiring — correct

- `lib/app.dart:63` provides `AnimationSettingsController` via
  `ChangeNotifierProvider<AnimationSettingsController>.value(...)` at the
  app root inside `MultiProvider`.
- `lib/features/dice/widgets/dice_animator.dart:35` consumes it via
  `context.watch<AnimationSettingsController>()` and rebuilds when style
  or speed change.
- `AnimationSettingsController` is a `ChangeNotifier` (no Bloc/Riverpod)
  hydrated from `AppSettingsPreference`, mirroring `AudioController` /
  `HapticController`.

### State management — within bounds

- Grepped `lib/` for `package:bloc`, `package:flutter_bloc`,
  `package:riverpod`, `package:flutter_riverpod`, `package:get_it`,
  `package:mobx`, `package:signals` — **0 matches**.
- New stateful widgets (`DrumAnimation`, `TabletopAnimation`) use
  `AnimationController` + `setState` only.
- `DiceAnimator` is a `StatelessWidget` that selects a strategy — no
  hidden state.

### Palette / aesthetic — clean

- Grepped `lib/features/dice/widgets/animations/` for `Color(` and
  `Colors.` — **0 matches**. Every color path goes through
  `Theme.of(context).extension<OneBitColors>()` (`ink` / `paper`) in
  `dice_grid.dart:97`.
- Pixel snap verified in `lib/features/dice/widgets/animations/tabletop_animation.dart:147`
  and `:151` — both translate paths apply `.roundToDouble()`.
  `Transform.scale` is wrapped with `filterQuality: FilterQuality.none`
  (`tabletop_animation.dart:125`), which keeps the 1-bit look during
  the settle pulse.

### Dependency direction

- `features/dice` -> `core/theme`: OK (UI feature reads theme).
- `features/dice/widgets/dice_animator.dart` -> `features/settings/animation_settings_controller.dart`:
  cross-feature import, but `animation_settings_controller` is a shared
  user-preference controller already provided at the app root. This is
  the same pattern as `AudioController` / `HapticController` reads
  inside `DiceController`. Acceptable given the project's current
  structure (no `core/settings` slice today). If more features begin
  reading these settings, consider promoting to `lib/core/settings/`.
- No circular dependencies detected.

### Package structure

Single-package Flutter app. Folder structure under
`lib/features/dice/widgets/animations/` is well-scoped:
`dice_grid.dart` (shared layout) + three strategy files, each a single
responsibility. Matches CLAUDE.md folder conventions.

### Quality gates

- `flutter analyze`: **0 issues**.
- `very_good test --coverage`: **passes**, 100% line coverage on every
  changed/new source file in `lib/features/dice/`:
  - `dice_screen.dart` 33/33
  - `dice_widget.dart` 36/36
  - `dice_animator.dart` 22/22
  - `animations/dice_grid.dart` 37/37
  - `animations/drum_animation.dart` 40/40
  - `animations/fast_animation.dart` 10/10
  - `animations/tabletop_animation.dart` 67/67
  - Remaining uncovered lines in the repo are all `*.g.dart` and
    `lib/l10n/app_localizations*.dart` (generated; excluded per
    CLAUDE.md).

# Architecture Review — Dice Screen (E05)

**Branch:** `feat/e05-dice-screen`
**Reviewed files:**

- `lib/features/dice/dice_controller.dart`
- `lib/features/dice/dice_screen.dart`
- `lib/features/dice/widgets/dice_widget.dart`
- `lib/features/dice/widgets/quantity_selector.dart`
- `lib/features/dice/widgets/roll_button.dart`
- `lib/features/dice/widgets/type_selector.dart`
- `lib/app.dart` (provider wiring)

## Layer Separation

This is a single-app Flutter project. The project's documented layers are
`lib/core/` (app-wide services), `lib/features/<slice>/` (one folder per
feature), and `lib/shared/` (reusable UI/utils). Direction-of-dependency rule:
`features` and `shared` may depend on `core`; nothing may depend on `features`;
`shared` must not depend on `features`.

### Verified

- `lib/features/dice/dice_controller.dart` imports only from
  `core/audio`, `core/haptic`, `core/models`, `core/storage`, and
  `shared/utils`. No `features/*` imports outside `dice` itself.
- `lib/features/dice/dice_screen.dart` imports only `core/i18n`,
  `core/theme`, its own `features/dice/...` siblings, and
  `shared/widgets/pixel_divider.dart`.
- `lib/features/dice/widgets/*.dart` import only `core/i18n`,
  `core/models`, `core/theme`, and `shared/widgets/mac_button.dart`.
- Reverse-direction check: `grep -rn "features/" lib/core lib/shared`
  returned no results — neither `core` nor `shared` references the
  dice feature.

### Violations

- None.

## State Management Assessment

`DiceController` is a `ChangeNotifier` distributed via
`ChangeNotifierProvider` in `lib/app.dart` and consumed with
`context.watch<DiceController>()` in `DiceScreen`. This matches the
project rule (`setState` + `ChangeNotifier` + `package:provider` for DI
only). No Bloc, no Riverpod.

### Correct

- **Naming.** `DiceController` is descriptive and consistent with the
  existing `AudioController`, `HapticController`, `ThemeProvider`,
  `LocaleController` family.
- **Encapsulation.** `_selectedType`, `_count`, `_lastResult`, and every
  injected dependency are private. Public surface is read-only getters
  plus three intent-shaped methods: `setType`, `setCount`, `roll`.
- **Immutable state exposed.** `RollResult` is `@immutable` with
  `Equatable`-based equality; the controller swaps the whole reference
  rather than mutating in place. `DiceType` is an enum. `int`/enum
  getters are intrinsically immutable.
- **Business logic location.** Dice generation goes through
  `shared/utils/random_dice.dart#rollDice`; the controller owns the
  side-effect choreography (roll → notify → append → audio → haptic →
  persist) and the clamp-to-`1..10` rule. None of this leaks into the
  widgets.
- **Data access.** UI never touches `HistoryRepository` or
  `LastDiceConfigPreference` directly — both are injected into the
  controller in `lib/app.dart` via `context.read`.
- **Dependency injection.** Constructor takes interfaces
  (`HistoryRepository`, `LastDiceConfigPreference`,
  `AudioController`, `HapticController`) plus an optional `Random?`
  seam for tests. Concrete `InMemory*` implementations are wired at the
  composition root.
- **Notification discipline.** `setType` and `setCount` are no-ops when
  the value would not change, which avoids spurious rebuilds. `roll`
  notifies before awaiting the history write so the UI updates first —
  the doc comment calls this trade-off out explicitly.
- **Widget purity.** `DiceScreen`, `DiceWidget`, `QuantitySelector`,
  `RollButton`, `TypeSelector` are all `StatelessWidget`. They render
  from props or `context.watch`; they hold no state of their own.

### Issues

- **[Important] No `dispose()` override on `DiceController`.**
  `ChangeNotifier` already cleans up its listener list in its own
  `dispose`, but if a future change adds a `StreamSubscription`, a
  `Timer`, or any other resource the override will be missing. Right
  now the only owned resources are plain fields, so there is no leak,
  but adding an explicit `@override void dispose() { super.dispose(); }`
  documents the lifecycle and gives a stable place to extend. The
  `ChangeNotifierProvider` in `app.dart` will correctly call
  `dispose()` when the provider tears down.

- **[Important] `roll()` is not reentrancy-safe.** The class doc
  acknowledges this and defers debouncing to E12 / `RollButton`. The
  concrete risk today: a fast double-tap can fire two overlapping
  `_history.append` and `_lastDiceConfig.write` calls; the second
  `notifyListeners()` will overwrite `_lastResult` from the first. This
  is consistent with the documented decision but it is an
  architectural choice the next reviewer should re-evaluate when the
  Hive-backed repository lands and writes can actually fail.

- **[Suggestion] Side-effect ordering on `setType` / `setCount`.**
  `roll()` clears nothing on the controller side after the write
  (correct — the result is what the user just saw), but `setType` and
  `setCount` set `_lastResult = null` *before* awaiting
  `_lastDiceConfig.write`. If the write throws, the UI is already in
  the cleared state while persistence is out of sync. Acceptable for
  the in-memory preference; worth a retry/rollback policy when the
  `SharedPreferences` implementation goes live.

- **[Suggestion] `RollResult` exposes its `values` list directly.**
  `RollResult.values` is `final List<int>` but not wrapped in
  `UnmodifiableListView`. A consumer could `controller.lastResult!.values.add(...)`
  and silently corrupt the model. Low risk because the controller is
  the only producer, but `List.unmodifiable` (or `UnmodifiableListView`)
  at construction time would make the immutability claim in the
  `@immutable` annotation literally true. (Out of strict scope —
  `roll_result.dart` is in `core/models` — but flagged because
  `DiceController.roll()` constructs it.)

## Dependency Direction

Resolved import graph for the changed files:

```
features/dice/dice_screen.dart
  ├─> features/dice/dice_controller.dart
  │     ├─> core/audio/{audio_controller, sound_player}
  │     ├─> core/haptic/haptic_controller
  │     ├─> core/models/{dice_type, roll_result}
  │     ├─> core/storage/{history_repository, last_dice_config_preference}
  │     └─> shared/utils/random_dice
  ├─> features/dice/widgets/dice_widget        ─> core/i18n, core/theme
  ├─> features/dice/widgets/quantity_selector  ─> core/i18n, core/theme
  ├─> features/dice/widgets/roll_button        ─> core/i18n, shared/widgets/mac_button
  ├─> features/dice/widgets/type_selector      ─> core/models, core/theme
  ├─> core/i18n/l10n_extension
  ├─> core/theme/{app_theme, app_typography}
  └─> shared/widgets/pixel_divider

app.dart
  ├─> core/{audio, haptic, i18n, storage, theme}
  ├─> features/dice/{dice_controller, dice_screen}
  └─> l10n/app_localizations
```

- **Direction:** strictly downward (`app` → `features` → `core` /
  `shared`; `features` → `core` / `shared`). No reverse edges.
- **Circularity:** none detected.
- **Cross-feature imports inside the dice slice:** none.
  `grep` for `features/` inside `lib/features/dice` returns only
  intra-feature paths.

### Violations

- None.

## Package Structure (feature-slice structure)

This is a Flutter app, not a monorepo — no per-feature `pubspec.yaml`
exists, so the package-level checks reduce to feature-slice hygiene.

- [x] Feature lives at `lib/features/dice/` with a screen entry point,
      a single controller, and a co-located `widgets/` folder.
- [x] Folder name `dice` is plain — no leading underscore, no
      `_internal` / `_dev`-style prefix.
- [x] Single, clear responsibility (the roll screen).
- [x] Internal widgets (`DiceWidget`, `QuantitySelector`, `RollButton`,
      `TypeSelector`) are not re-exported from a barrel and are not
      imported by any other feature. They stay private to the dice
      slice. Verified: no `import '.../features/dice/...'` outside the
      dice folder, and no `import '../../dice/...'` from other slices.
- [x] Test folder exists at `test/features/dice/` with parallel
      structure (`dice_controller_test.dart`, `dice_screen_test.dart`,
      `widgets/`).
- [x] `RollButton` is a thin wrapper over the shared `MacButton`
      rather than a re-implementation — correct use of the
      `lib/shared/widgets/` tier.
- [x] `PixelDivider` consumed from `lib/shared/widgets/` rather than
      duplicated in the feature.
- [x] All colors flow through `Theme.of(context).extension<OneBitColors>()`
      using `colors.ink` and `colors.paper`. No `Color(0x...)`,
      no `Colors.*` constants, no third color introduced. The 2-color
      palette rule holds.

### Issues

- **[Suggestion] `RollButton` justification.** The class doc
  ("Exists as a named widget so the dice screen tests can target it
  with `find.byType(RollButton)`, free of locale") makes the case for
  the wrapper. That is a real concern, but the test could just as
  easily key the `MacButton` it cares about. Keep the wrapper if the
  team prefers the named type; flag for the next reviewer as a place
  where the file/widget count could shrink without losing testability.

## Provider Wiring (`lib/app.dart`)

- `MultiProvider` registers, in order: `AudioController`,
  `HapticController`, `ThemeProvider`, `LocaleController`,
  `HistoryRepository`, `LastDiceConfigPreference`, `DiceController`.
- `DiceController` is created with `create: (context) => DiceController(...)`
  pulling its dependencies via `context.read<...>()`, which is the
  correct pattern: each dependency is registered *before* `DiceController`
  in the `providers:` list, so the `read` calls resolve.
- `AudioController` and `HapticController` are injected with
  `.value(value: ...)` because the harness owns their lifecycle (they
  are constructed in `main` ahead of the audio engine init); the
  provider does not call `dispose()` on `.value` providers, which is
  the correct choice here.
- `ThemeProvider`, `LocaleController`, and `DiceController` use
  `create:` and therefore *will* receive `dispose()` from the
  provider when the tree tears down. This is the correct lifecycle
  for objects the provider owns.
- `HistoryRepository` and `LastDiceConfigPreference` are registered as
  `Provider<T>` (non-`ChangeNotifier`), which is correct — they are
  not observable, only depended-on. This also matches the project
  rule that `package:provider` is "exclusively for exposing
  `ChangeNotifier`s" only when the thing is a `ChangeNotifier`; using
  plain `Provider<T>` for the repositories is the standard escape
  hatch and is consistent with how the rest of the app wires
  non-notifying services.
- **[Suggestion]** `InMemoryHistoryRepository` and
  `InMemoryLastDiceConfigPreference` are wired at the root. The doc on
  `HistoryRepository` says "the default before the splash screen wires
  the Hive-backed implementation" — confirm whether E05 ships with the
  Hive wiring or whether the splash flow is still expected to swap the
  implementation. Either way, the architecture supports it via the
  interface, which is what matters here.

## Verdict

Architecture is clean — ship it. The dice feature respects every
documented boundary (layer direction, feature isolation, state-management
rule, 2-color palette, no underscore-prefixed folders), the controller
is properly encapsulated and testable, and the provider wiring at the
composition root is correct.

The findings above are sharpening notes for the next iteration (explicit
`dispose` override, persistence rollback policy, list-immutability on
`RollResult`, reentrancy on `roll`), not blockers. None require changes
before merging E05.

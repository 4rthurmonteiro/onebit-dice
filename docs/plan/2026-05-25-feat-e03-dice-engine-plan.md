---
title: "feat: e03 dice engine"
type: feat
date: 2026-05-25
epic: E03
status: planned
---

# feat: e03 dice engine — Standard

## Overview

Implement the pure-domain dice engine for 1-Bit Dice: the canonical [`DiceType`](../../lib/core/models/dice_type.dart) enum (d4, d6, d8, d10, d12, d20, d100), top-level roll helpers in [`random_dice.dart`](../../lib/shared/utils/random_dice.dart) backed by `Random.secure()` (injectable for tests), and an immutable [`RollResult`](../../lib/core/models/roll_result.dart) value object with derived `total` / `equation`. No UI, no I/O, no controller — this epic only delivers the deterministic core that will be consumed by `DiceController` (E08), persisted as `RollEntry` (E04) and referenced by presets (E10).

The brainstorm document ([2026-05-25-e03-dice-engine-brainstorm-doc.md](../brainstorm/2026-05-25-e03-dice-engine-brainstorm-doc.md)) captured every architectural decision. This plan turns those decisions into a file-by-file checklist with a test scaffolding that ships at 100% line coverage.

## Problem Statement / Motivation

Every downstream epic from E04 onward depends on having:

1. A canonical, exhaustive type representation of the supported dice — needed by the type selector (E08), preset registry (E10) and `RollEntry` Hive adapter (E04).
2. A deterministic, seedable rolling primitive — without an injectable RNG, the controller tests in E08 and the history snapshot tests in E04 cannot be reproducible.
3. An immutable, value-equal result model — both `RollEntry` (E04) and the history list (E06) need stable comparison semantics for tests and (later) diffing.

Without E03 these three concerns leak into the controller layer (E08) and the persistence layer (E04), tangling random number generation, formatting and value equality with widget/Hive code. E03 isolates them as plain Dart, testable without `WidgetTester` or `setUp`/`tearDown` ceremony.

## Proposed Solution

Match the brainstorm 1-for-1. High-level layout:

```
lib/core/models/
├── dice_type.dart       # enum DiceType { d4, d6, d8, d10, d12, d20, d100 } with sides + label
└── roll_result.dart     # @immutable class RollResult extends Equatable

lib/shared/utils/
└── random_dice.dart     # int rollDie(int sides, {Random? rng})
                         # List<int> rollDice(int sides, int count, {Random? rng})
                         # final _defaultRng = Random.secure();   (library-private)

test/core/models/
├── dice_type_test.dart
└── roll_result_test.dart

test/shared/utils/
└── random_dice_test.dart
```

`RollResult` extends [`Equatable`](https://pub.dev/packages/equatable) (new dependency this epic, see [Step 0](#step-0--dependency)) with `props => [timestamp, diceType, diceCount, values]`. `total` and `equation` are pure getters derived from `values` — never stored, never cached.

Roll helpers accept an optional `Random? rng` parameter; when omitted they fall back to a library-private `_defaultRng = Random.secure()` singleton. Tests inject `Random(seed)` for determinism. Validation is `assert`-only: `assert(sides > 0)` and `assert(count >= 1)` — the engine is internal code and the controller (E08) is responsible for clamping user-facing invariants (count 1..10).

## Technical Considerations

- **Architecture**: pure Dart domain layer with no Flutter imports. Lives under `lib/core/models/` and `lib/shared/utils/` per [CLAUDE.md](../../CLAUDE.md) folder rules. No `ChangeNotifier`, no `Provider`, no widgets — this is the deterministic substrate that stateful layers wrap.
- **Equality contract**: `RollResult` uses `package:equatable` rather than handwritten `==`/`hashCode`. The brainstorm flags that the same dep will be reused by `RollEntry` (E04), `CustomPreset` and `Preset` (E10) — paying the dependency cost once here keeps ~5 future classes boilerplate-free.
- **Random source**: `Random.secure()` (cryptographic) over `Random()` because dice rolls are user-perceptible randomness and the cost is negligible at ≤10 rolls per call. The injection pattern (`{Random? rng}`) keeps the API stateless while supporting `Random(seed)` in tests.
- **Validation strategy**: `assert` in debug, no-op in release. Rationale: the engine trusts its caller (the controller clamps `count` to 1..10 and only ever passes `DiceType.sides`, all of which are ≥ 4). Throwing `ArgumentError` would add a release-mode branch with no observable benefit. Negative tests verify that `assert` fires in debug.
- **`equation` format** (locked in by the brainstorm, consistent with the HTML prototype):
  - `count == 1` → `"5"` (the single value, no operators)
  - `count >= 2` → `"3 + 5 + 2 = 10"` (values joined by ` + `, then ` = total`)
- **`timestamp`** is always supplied explicitly by the caller — no `DateTime.now()` default. This keeps `RollResult` pure (no implicit clock dependency) and makes tests trivially deterministic.
- **Coverage budget**: 100% line coverage per [CLAUDE.md](../../CLAUDE.md#quality-gates). Three test files cover three production files; the library-private `_defaultRng` is exercised by calling `rollDie(6)` without a seed and asserting the value lands in `1..6` (range check, not value check).
- **Distribution test pragma**: the 10k-iteration uniformity check uses a *deterministic* seeded `Random(seed)` — never `Random.secure()` — to keep the test reproducible on CI. The chosen seed must produce a histogram where every face stays within ±30% of the expected frequency for a d6 (brainstorm threshold). If the chosen seed flakes the threshold, swap the seed rather than relax the bound.
- **No security/privacy implications**: pure compute, no user input persisted, no network, no PII.
- **No code generation**: no `*.g.dart` files in this epic. `build_runner` enters in E04 with Hive.

## Implementation Tasks

Execute in this order. Each step ends with `flutter analyze` (zero issues) + `flutter test --coverage` (100% line coverage on the new files). Commit between steps using Conventional Commits.

### Step 0 — Dependency

- [ ] `flutter pub add equatable` (targets `equatable: ^2.0.5` or latest stable in `^2.x`)
- [ ] Verify `pubspec.lock` regenerated; commit `pubspec.yaml` + `pubspec.lock` together
- [ ] Commit: `chore: add equatable for value equality in domain models`

### Step 1 — `DiceType` enum

- [ ] Create [lib/core/models/dice_type.dart](../../lib/core/models/dice_type.dart)
  - `enum DiceType { d4, d6, d8, d10, d12, d20, d100 }`
  - Final fields `int sides` and `String label` ('D4', 'D6', …, 'D100') via enhanced enum constructor
  - No `custom` member in M1 (brainstorm: design permits adding without refactor in M2)

  ```dart
  enum DiceType {
    d4(sides: 4, label: 'D4'),
    d6(sides: 6, label: 'D6'),
    d8(sides: 8, label: 'D8'),
    d10(sides: 10, label: 'D10'),
    d12(sides: 12, label: 'D12'),
    d20(sides: 20, label: 'D20'),
    d100(sides: 100, label: 'D100');

    const DiceType({required this.sides, required this.label});

    final int sides;
    final String label;
  }
  ```

- [ ] Create [test/core/models/dice_type_test.dart](../../test/core/models/dice_type_test.dart)
  - `DiceType.values.length == 7`
  - Each entry exposes the correct `sides` and `label` (parameterised over the 7 values)
  - `sides` is strictly positive for every value (regression guard for accidental zero/negative)
- [ ] `flutter analyze` + `flutter test --coverage` green
- [ ] Commit: `feat(e03): add DiceType enum with sides and label`

### Step 2 — `random_dice` helpers

- [ ] Create [lib/shared/utils/random_dice.dart](../../lib/shared/utils/random_dice.dart)
  - Library-private `final Random _defaultRng = Random.secure();`
  - `int rollDie(int sides, {Random? rng})`
    - `assert(sides > 0, 'sides must be > 0');`
    - returns `(rng ?? _defaultRng).nextInt(sides) + 1`
  - `List<int> rollDice(int sides, int count, {Random? rng})`
    - `assert(sides > 0, 'sides must be > 0');`
    - `assert(count >= 1, 'count must be >= 1');`
    - returns `List<int>.generate(count, (_) => rollDie(sides, rng: rng), growable: false)`

  ```dart
  import 'dart:math';

  final Random _defaultRng = Random.secure();

  int rollDie(int sides, {Random? rng}) {
    assert(sides > 0, 'sides must be > 0');
    return (rng ?? _defaultRng).nextInt(sides) + 1;
  }

  List<int> rollDice(int sides, int count, {Random? rng}) {
    assert(sides > 0, 'sides must be > 0');
    assert(count >= 1, 'count must be >= 1');
    return List<int>.generate(
      count,
      (_) => rollDie(sides, rng: rng),
      growable: false,
    );
  }
  ```

- [ ] Create [test/shared/utils/random_dice_test.dart](../../test/shared/utils/random_dice_test.dart)
  - **Range** (`rollDie`): for `sides ∈ {4, 6, 20, 100}`, calling with a seeded `Random(seed)` 1000× yields only values in `1..sides`
  - **Range** (`rollDice`): `rollDice(6, 10, rng: Random(42))` returns a list of length 10, all values in `1..6`
  - **Determinism**: two calls with `Random(seed)` (same seed) produce the same sequence
  - **Default RNG smoke**: `rollDie(6)` (no rng) returns a value in `1..6` — exercises the `_defaultRng` branch for coverage
  - **Distribution** (`rollDice(6, 10000, rng: Random(<chosen-seed>))`): tally faces 1..6; assert every face count is within `[0.7 × 10000/6, 1.3 × 10000/6]` (brainstorm: no face >30% off uniform). Use a fixed seed that satisfies the bound; document it in a one-line comment so future maintainers know it's intentional.
  - **Assert fires** (`assert(sides > 0)`): `expect(() => rollDie(0), throwsA(isA<AssertionError>()))` — guarded so it runs only in debug (`flutter test` runs in checked mode by default)
  - **Assert fires** (`assert(count >= 1)`): `expect(() => rollDice(6, 0), throwsA(isA<AssertionError>()))`
- [ ] `flutter analyze` + `flutter test --coverage` green
- [ ] Commit: `feat(e03): add rollDie and rollDice helpers backed by Random.secure`

### Step 3 — `RollResult` model

- [ ] Create [lib/core/models/roll_result.dart](../../lib/core/models/roll_result.dart)
  - `@immutable class RollResult extends Equatable`
  - Final fields: `DateTime timestamp`, `DiceType diceType`, `int diceCount`, `List<int> values`
  - Constructor: `const RollResult({required …})` — no defaulted `timestamp`
  - `int get total => values.fold(0, (a, b) => a + b);`
  - `String get equation` — single-value path returns `'${values.first}'`; multi-value path returns `'${values.join(' + ')} = $total'`
  - `@override List<Object?> get props => [timestamp, diceType, diceCount, values];`
  - **Equatable + List**: pass `values` directly. `equatable` compares lists element-wise via `DeepCollectionEquality` only when wrapped with `EquatableMixin` defaults; using `props => [values]` works because `Equatable` calls `iterableEquals` on `List` instances. Verify with the equality tests below — if the comparison ever fails for two `RollResult`s built from `==`-equal but identity-different lists, switch to wrapping with `UnmodifiableListView` and document.

  ```dart
  import 'package:equatable/equatable.dart';
  import 'package:flutter/foundation.dart';

  import 'package:onebit_dice/core/models/dice_type.dart';

  @immutable
  class RollResult extends Equatable {
    const RollResult({
      required this.timestamp,
      required this.diceType,
      required this.diceCount,
      required this.values,
    });

    final DateTime timestamp;
    final DiceType diceType;
    final int diceCount;
    final List<int> values;

    int get total => values.fold(0, (sum, v) => sum + v);

    String get equation {
      if (values.length == 1) return '${values.first}';
      return '${values.join(' + ')} = $total';
    }

    @override
    List<Object?> get props => [timestamp, diceType, diceCount, values];
  }
  ```

- [ ] Create [test/core/models/roll_result_test.dart](../../test/core/models/roll_result_test.dart)
  - **`total`**: sums `[3, 5, 2]` → `10`; single-element `[7]` → `7`
  - **`equation` (single)**: `values: [5]` → `'5'`
  - **`equation` (multi)**: `values: [3, 5, 2]` → `'3 + 5 + 2 = 10'`
  - **`equation` (two values)**: `values: [4, 6]` → `'4 + 6 = 10'` (edge between single and multi)
  - **Equality**: two `RollResult`s built with identical field values are `==` and share `hashCode`
  - **Inequality**: changing any single field (`timestamp`, `diceType`, `diceCount`, or `values`) breaks equality
  - **Immutability smoke**: `const RollResult(...)` compiles with all `const` arguments (uses `const` `DateTime` is not possible — use a non-const instance for this case, but verify the class itself is annotated `@immutable` via analyzer not test)
- [ ] `flutter analyze` + `flutter test --coverage` green
- [ ] Commit: `feat(e03): add RollResult immutable model with derived total and equation`

### Step 4 — Wrap-up

- [ ] Update [docs/plan/progress.md](progress.md) — mark `2.1`, `2.2`, `2.3`, `2.4`, `2.5` as `[x]`
- [ ] Run full `flutter analyze` + `flutter test --coverage` one last time; confirm aggregate line coverage is still 100% (excluding `lib/main.dart`)
- [ ] Commit: `chore(e03): mark dice engine tasks complete in progress.md`
- [ ] Open PR against `main` titled `feat: e03 dice engine`

## Acceptance Criteria

- [ ] `lib/core/models/dice_type.dart` exposes a 7-value `DiceType` enum with `sides` and `label` fields; no `custom` member.
- [ ] `lib/shared/utils/random_dice.dart` exposes `rollDie(int sides, {Random? rng})` and `rollDice(int sides, int count, {Random? rng})`, both backed by `Random.secure()` when no `rng` is provided.
- [ ] `lib/core/models/roll_result.dart` exposes an immutable `RollResult` extending `Equatable` with derived `total` and `equation` getters in the format specified in [Technical Considerations](#technical-considerations).
- [ ] All three production files have a matching test file; each test file passes; aggregate line coverage on the new files is 100%.
- [ ] `flutter analyze` exits with zero issues under `very_good_analysis` rules.
- [ ] `package:equatable` is the only new runtime dependency added by this epic.
- [ ] No Flutter widget imports inside `lib/core/models/` or `lib/shared/utils/` (the engine remains pure Dart aside from `package:flutter/foundation.dart` for `@immutable`).
- [ ] Negative assertions fire on `rollDie(0)`, `rollDice(0, 1)`, and `rollDice(6, 0)`.

## Success Metrics

- **Compile/test**: `flutter test --coverage` reports 100% line coverage for the three new files.
- **Determinism**: replaying `rollDice(6, 1000, rng: Random(42))` twice in CI produces byte-identical output.
- **Downstream readiness**: E04 (Hive `RollEntry`) and E08 (`DiceController`) can import these three files without further changes in this epic.

## Dependencies and Risks

- **Adds runtime dep**: `equatable: ^2.x`. Tiny, no transitive bloat, used pervasively across VGV projects. Low risk.
- **Distribution test flakiness risk**: a poorly chosen seed could push one face's tally outside the ±30% band on CI. *Mitigation*: pick a seed locally, run the test 100× to confirm it never flakes, then hard-code it.
- **Equatable + List semantics**: `props => [values]` works because `Equatable` compares list elements via `iterableEquals`. *Mitigation*: dedicated equality tests with two distinct `[1,2,3]` instances assert this behaviour and would fail loudly on regression.
- **No external API or schema dependency** — this epic is self-contained.

## Out of Scope

- `DiceController` (E08) — state, clamp 1..10, exposing `RollResult` to the UI.
- `RollEntry` Hive adapter (E04) — persistence and `RollResult` ↔ `RollEntry` mapping.
- Preset registry consuming `DiceType` (E10).
- UI for selecting a dice type or rendering an equation (E08).
- Custom `DiceType` support (deferred to M2; brainstorm note).
- `equation` localisation (the literal `+` and `=` are mathematical, not translatable).

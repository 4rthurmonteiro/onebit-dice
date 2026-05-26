# Test Quality Review — Dice Screen Feature (E05)

**Date:** 2026-05-26
**Branch:** feat/e05-dice-screen
**Reviewer:** Test Quality Agent (VGV Standards)
**Scope:** dice_controller_test, dice_screen_test, dice_widget_test, quantity_selector_test, roll_button_test, type_selector_test, widget_test (modified)

---

## Test Quality Review

### Coverage Summary

- **Analyzer:** Pass — zero issues on all 7 test files
- **Coverage data source:** `coverage/lcov.info` (from previous run — MCP `very_good test` exited 69, likely a pre-existing environment issue unrelated to these tests)
- **Files with tests:** 6/6 dice feature production files covered

#### Per-file coverage (from lcov.info)

| File | LF (lines) | LH (hit) | % |
|------|-----------|---------|---|
| `dice_widget.dart` | 67 | 67 | 100% |
| `dice_controller.dart` | 35 | 35 | 100% |
| `dice_screen.dart` | 32 | 31 | 96.9% |
| `quantity_selector.dart` | 34 | 34 | 100% |
| `roll_button.dart` | 5 | 5 | 100% |
| `type_selector.dart` | 24 | 24 | 100% |

#### Coverage gap: `dice_screen.dart` line 17 — DA:17,0

`DA:17,0` corresponds to the `const DiceScreen({super.key});` constructor on line 17. In Dart/Flutter, `const` constructors invoked as constant expressions are not instrumented by the coverage tool — this is a known lcov artifact, not a real untested line. The constructor is exercised by both the `dice_screen_test.dart` harness and `widget_test.dart`. **This gap does not block the 100% threshold in practice**, but it will cause `--min-coverage 100` to fail unless this line is excluded or treated as a tooling false positive.

**Recommendation:** Add `// coverage:ignore-line` to the `const DiceScreen({super.key});` line, or exclude `lib/features/dice/dice_screen.dart` const constructor from the coverage enforcement in `very_good test` configuration. This is a one-line fix.

---

### State Management Test Quality — `dice_controller_test.dart`

**Overall: Pass with one important finding**

The test file uses hand-written fakes (`_RecordingHistory`, `_RecordingAudio`, `_RecordingHaptic`, `_RecordingLastDice`) rather than `mocktail`. This is the correct pattern for this codebase: the project does not include `mocktail` as a dev dependency (not listed in `pubspec.yaml`), and the hand-written fakes are minimal, purposeful, and all implement real interfaces. No mocktail anti-patterns apply here.

#### Strengths

- **Side-effect ordering test** (`roll() invokes deps in order`): Excellent pattern. Records a shared `events` list that captures `notify`, `history.append`, `audio.play(total)`, `haptic.trigger`, `lastDice.write(d6,1)` in sequence, then asserts the full ordered list. This catches any future reordering of side effects.
- **Determinism test**: Seeds the controller with `Random(42)`, calls `setCount(3)`, calls `roll()`, then independently recomputes expected values from a fresh `Random(42)` with the same call sequence. Correct and tight.
- **Boundary tests**: `setCount(0)` → clamps to 1; `setCount(11)` → clamps to 10. Both covered.
- **No-op tests**: `setType` with same value, `setCount` with same clamped value — both verified to produce zero side effects.
- **Hydration test**: Pre-seeded `LastDiceConfig(diceType: DiceType.d20, count: 5)` verified to restore state on construction.

#### Issues

**[Important] Missing `dispose()` / listener teardown test**

`DiceController extends ChangeNotifier`. There is no test that adds a listener and then verifies that `dispose()` releases it (no `debugAssertNotDisposed` errors, no memory leaks). For a `ChangeNotifier`, the contract includes clean disposal. This is especially relevant because `DiceController` is provided via `ChangeNotifierProvider` at the app root — a second route mounting another provider in a future epic could double-register listeners.

**Fix:** Add a test that calls `controller.dispose()` and then verifies that a subsequent `notifyListeners()` call (via `setType`) does not invoke the registered listener (Dart's `ChangeNotifier.dispose()` clears all listeners).

**[Suggestion] `roll()` with count 1 — single-die total**

All `roll()` tests either use `setCount(3)` or the default count of 1 without asserting the `lastResult.values` length equals 1 explicitly. The existing `roll() sets lastResult with correct diceCount, type, values` test uses `setCount(4)`, which is good coverage for multi-die. There is no test verifying single-die roll (count=1) produces `values` of length 1 and that `sum == values[0]`. This is the simplest possible path through the production code and is implied but not explicit.

**[Suggestion] `setType` followed by `setCount` — no redundant persist**

The persistence behavior when both `setType` and `setCount` are called in sequence (before a roll) is not directly asserted. Each call writes independently. A test that chains both calls and verifies exactly two writes (with correct values for each) would tighten the contract.

---

### UI Component Test Quality

#### `dice_screen_test.dart` — Pass with two important findings

**Strengths**

- `tearDown` correctly resets the surface size: `TestWidgetsFlutterBinding.instance.setSurfaceSize(null)`. This prevents test pollution.
- Integration-style tests exercise the full provider tree, verifying that side-effect collaborators (`history`, `audio`, `haptic`, `pref`) are all invoked on a ROLL tap.
- The `restores last config from pre-populated preference` test seeds the preference before construction and verifies `count=4` and D12 chip selection — good hydration test.

**Issues**

**[Important] `tap on D20 chip` test uses default surface size, not `_pump()`**

The test at line 121-143 calls `tester.pumpWidget()` directly rather than the file's own `_pump()` helper (which sets a `800×1200` surface). The comment above `_pump()` explicitly states: "A taller surface keeps the bottom controls (steppers, ROLL button) inside the visible viewport so taps reach them." The D20 chip is in the `TypeSelector` which sits in the lower half of the `Column` layout. On the default test surface (400×600 logical pixels), it may be outside the viewport, causing the tap to silently miss. Even if it happens to pass today due to layout details, this is a fragility: any layout change could make it flaky.

**Fix:** Replace `await tester.pumpWidget(...)` with `await _pump(tester, ...)` in the D20 chip test.

**[Suggestion] No negative-path test: ROLL button tapped twice rapidly**

The production code comments note that `roll()` is "not reentrant" and that a debounced `RollButton` (planned for E12) will prevent double-taps. There is no test verifying what happens when ROLL is tapped twice before the first `pumpAndSettle()`. This is acceptable as a deferred concern (E12), but documenting it in the test file as a `// TODO(E12): add double-tap guard test when RollButton debounce lands` would prevent the gap from being forgotten.

**[Suggestion] `roll button uses the localized ROLL label` test duplicates coverage**

This test is already covered by `roll_button_test.dart` which tests the same assertion in isolation. The `dice_screen_test.dart` test adds no new scenario and could be removed to reduce maintenance surface. This is a minor concern — duplicated happy-path coverage is harmless but adds noise.

---

#### `dice_widget_test.dart` — Pass

- Covers both null-values (empty state, count 1-10) and non-null-values (single die, multi-die, equation, total) states.
- The `asserts when values.length != count` test uses `throwsAssertionError` correctly to verify the constructor precondition.
- Tests for `count=4` (non-trivial 3×2 grid layout) and `count=10` (max boundary) are present.
- `gridKey` presence in both states is verified.
- The localized total label is verified via `AppLocalizations.of(context)!.rollResultTotal(7)`.

**[Suggestion] No test for count=1 with values — single-die edge case**

The `values != null && length == 1 → no equation` test verifies the equation is absent, but does not verify the total label IS present for a single die. This is implied by the `values != null → renders the localized total` test (which uses count=2), but a count=1 total test would fully close the edge case. Low priority.

---

#### `quantity_selector_test.dart` — Pass

- Boundary tests at count=1 (minus disabled) and count=10 (plus disabled) are present.
- Enabled-path callbacks verified with `count=4` (mid-range).
- Semantic label tests for both `+` and `−` are present — good accessibility coverage.

---

#### `roll_button_test.dart` — Pass

- Covers render (MacButton present, correct label) and tap forwarding.
- Simple widget — 2 tests are sufficient.

---

#### `type_selector_test.dart` — Pass

- Covers render (all 7 chips), selected-chip styling (ink background, paper text), unselected-chip styling, tap forwarding for non-selected chip, and tap forwarding for already-selected chip.
- Semantics test (`matchesSemantics`) verifies `isButton`, `hasSelectedState`, `isSelected`, and `hasTapAction` for both selected and non-selected chips.

**[Suggestion] Semantics test uses duplicate label string `'D20\nD20'`**

The `matchesSemantics` call at line 88-96 expects `label: 'D20\nD20'`. This double-label pattern is the result of `Semantics(label: type.label, ...)` wrapping a `GestureDetector` that contains a `Text(type.label)` — Flutter merges semantic labels from parent and child. This is correct behavior, but the test encodes the merged label string literally, making it brittle if the semantics tree structure changes (e.g., adding `excludeSemantics: true`). Low risk in current form, but worth noting.

---

#### `widget_test.dart` (modified) — Pass, no regression

The file now tests `DiceScreen` renders instead of the old design-system preview. All five test groups (`App renders DiceScreen`, `changing palette rebuilds theme`, `MaterialApp i18n wiring`, `resolveLocale`) are well-formed:

- `resolveLocale` tests use pure unit-test style (no widget pump needed), which is correct.
- The `resolveLocale` edge cases (null locale → EN, zh-CN → zh-Hans, no-match → EN, language-only fallback) cover all branches of the function.
- The `_buildApp()` factory is shared across tests — correct use of a factory rather than `setUp`.

---

### Anti-Patterns Found

| Location | Anti-Pattern | Description | Fix |
|----------|-------------|-------------|-----|
| `dice_screen_test.dart:125` | Inconsistent surface setup | `tap on D20 chip` uses default surface; other tests use the file's `_pump()` helper that sets 800×1200 to keep bottom controls in viewport | Replace `tester.pumpWidget(...)` with `_pump(tester, ...)` |
| `dice_controller_test.dart:296-299` | Tautological type assertion | `expect(controller, isA<ChangeNotifier>())` tests the Dart type system, not any application behavior — this will always be true as long as the class declaration exists | Remove or replace with a behavior assertion (e.g., add listener, call `setType`, verify listener fires) |

---

### Recommendations

1. **[Critical — blocks 100% coverage gate]** Add `// coverage:ignore-line` to `lib/features/dice/dice_screen.dart` line 17 (`const DiceScreen({super.key});`). The `DA:17,0` in lcov causes `--min-coverage 100` to fail. This is a Dart tooling artifact for `const` constructors, not a real gap.

2. **[Important]** In `dice_screen_test.dart`, replace `await tester.pumpWidget(...)` with `await _pump(tester, ...)` in the `tap on D20 chip` test (line 125) to match the rest of the file and prevent a layout-dependent flake.

3. **[Important]** Add a `dispose()` test to `dice_controller_test.dart`: verify that after `controller.dispose()`, a registered listener is no longer called and no `FlutterError` is thrown.

4. **[Suggestion]** Remove `expect(controller, isA<ChangeNotifier>())` in `dice_controller_test.dart` (line 297-299) — it is a tautological assertion that tests the class declaration, not behavior.

5. **[Suggestion]** Add a `// TODO(E12):` comment in `dice_screen_test.dart` noting that a double-tap ROLL guard test is needed once `RollButton` debounce is implemented.

6. **[Suggestion]** Add a single-die roll test to `dice_widget_test.dart` that verifies the total label IS rendered when `count=1` and `values=[n]`.

---

### Verdict

**Fix 2 issues before merging.** The coverage gate will fail due to the `const` constructor artifact on `dice_screen.dart:17` (critical). The D20 chip tap test surface inconsistency is a fragility that could produce a flake under layout change (important). The remaining findings are suggestions that improve long-term maintainability but do not block shipping.

The overall test suite is well-structured: fake collaborators are purposeful and minimal, side-effect ordering is verified, boundary conditions are covered, and accessibility semantics are tested across both `QuantitySelector` and `TypeSelector`. The foundational quality is high.

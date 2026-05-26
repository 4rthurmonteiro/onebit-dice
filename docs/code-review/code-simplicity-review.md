# Code Simplicity Review — Dice Screen Feature (E05)

**Date:** 2026-05-26
**Scope:** `lib/features/dice/` (new files) + `lib/app.dart` (wiring changes)
**Reviewer:** Code Simplicity Agent

---

## Simplification Analysis

### Core Purpose

Accept a dice type and quantity from the user, roll on demand, display the result. Persist the last config so the app restores it on next launch.

---

### Unnecessary Complexity Found

#### 1. `DiceController` — factory + private constructor split (dice_controller.dart:40–67)

The factory/private-constructor pattern exists solely to run `lastDiceConfig.read()` before calling the private constructor. This is idiomatic but heavier than necessary when the same result is achievable with a simple named constructor or a single default constructor with an initializer list.

```dart
// Current: two constructors, 8 constructor params, factory + private
factory DiceController({ ... }) { ... }
DiceController._( ... );
```

The factory's only job is to call `lastDiceConfig.read()` once and pass the result as two positional arguments. An alternative is to call `lastDiceConfig.read()` inside the constructor body and assign to the fields directly — eliminating the private constructor and the seven positional forwarding parameters entirely. The `rng` injectable is already sufficient for testing; the factory does not provide additional testability beyond what a regular constructor would.

**Suggested simplification:**

```dart
DiceController({
  required HistoryRepository history,
  required AudioController audio,
  required HapticController haptic,
  required LastDiceConfigPreference lastDiceConfig,
  Random? rng,
}) : _history = history,
     _audio = audio,
     _haptic = haptic,
     _lastDiceConfig = lastDiceConfig,
     _rng = rng {
  final stored = lastDiceConfig.read();
  _selectedType = stored?.diceType ?? DiceType.d6;
  _count = stored?.count ?? 1;
}
```

This eliminates the factory, the private constructor, the positional forwarding, and reduces constructor-related code from ~28 lines to ~12.

**Estimated LOC reduction:** ~16 lines

---

#### 2. `DiceController.roll()` — redundant config persist (dice_controller.dart:128–131)

`setType` and `setCount` each call `_lastDiceConfig.write()` every time the user changes anything. `roll()` also calls `_lastDiceConfig.write()` at the end with the exact same `_selectedType` / `_count` that were already persisted by the most recent `setType`/`setCount` call. The only scenario where the `roll()` write would differ from what is already stored is on first launch before any `setType`/`setCount` call — but in that case the values are the defaults (`d6, 1`) which will have been written by any previous `setType`/`setCount` interaction too.

The write in `roll()` adds a redundant async operation on every roll with no observable benefit. The class-level doc comment acknowledges this order but frames it as a deliberate choice about durability, not about correctness of the persisted value.

**Suggested simplification:** Remove lines 128–131 from `roll()`. The persisted config is always up to date from `setType`/`setCount`. If the "persist on first roll with defaults" edge case matters, it can be handled once in the constructor.

**Estimated LOC reduction:** 3 lines plus async overhead

---

#### 3. `_Grid` widget — layout constants passed as constructor parameters (dice_widget.dart:114–163)

`_Grid` is a private widget with a single call site inside `DiceWidget`. Its constructor accepts `slotSize`, `slotSpacing`, and `maxColumns` as parameters, but these values are always the constants `_slotSize`, `_slotSpacing`, and `_maxColumns` defined on `DiceWidget`. There is no call site that passes different values, and as a private class it can never be called from outside the file.

Accepting them as parameters implies configurability that does not exist and adds three fields, three constructor parameters, and three `required` annotations that will never hold anything other than the three constants.

**Suggested simplification:** Replace the three parameter fields with the three constant values directly inside `_Grid.build`, or promote them to file-level constants.

```dart
// Inside _Grid.build, use literals:
const _slotSize = 64.0;
const _slotSpacing = 8.0;
const _maxColumns = 3;
```

Or just inline the constants and delete the parameters entirely. The `key` parameter is legitimately needed for testing and should stay.

**Estimated LOC reduction:** ~9 lines (3 fields + 3 constructor params + 3 `required` annotations)

---

#### 4. `DiceWidget` — `_sum` called twice for the same list (dice_widget.dart:86–95)

In the `hasResult` branch, `_sum(values!)` is called at line 87 (for the `totalKey` text) and again at line 95 (inside the equation string `'${values!.join(' + ')} = ${_sum(values!)}'`). The sum is computed twice for the same immutable list. This is minor at the call scale of a single roll result, but it is pointlessly redundant.

**Suggested simplification:** Compute the sum once into a local variable before the `if (hasResult)` block, or at least before the two uses.

```dart
final total = hasResult ? _sum(values!) : 0;
```

**Estimated LOC reduction:** 0 lines, but removes a duplicate computation.

---

#### 5. `DiceWidget` — double border via nested `DecoratedBox` (dice_widget.dart:54–68)

The outer visual frame is achieved by nesting two `DecoratedBox` widgets each with a 2px border, separated by a 2px `Padding`. This produces the "double border" pixel aesthetic. While intentional for the 1-bit look, the implementation nests four widgets (`DecoratedBox`, `Padding`, `DecoratedBox`, `Padding`) where a single `Container` with a custom `BoxDecoration` using `Border` + a second painted border (or a single `CustomPaint`) would be flatter. However this is a visual/aesthetic tradeoff, not pure over-engineering — the nested approach is readable and the aesthetic is deliberate.

This is flagged as a suggestion only, not a required simplification.

---

#### 6. `RollButton` — thin one-method wrapper around `MacButton` (roll_button.dart)

`RollButton` exists as a named widget containing a single `MacButton` call with three hardcoded arguments. The entire file is 26 lines. The stated justification in the doc comment is: "so the dice screen tests can target it with `find.byType(RollButton)`, free of locale."

This is a legitimate reason to keep a named type — widget tests frequently use `find.byType`. However, an alternative that avoids the extra file is to use a `Key` constant on the `MacButton` directly, as `DiceWidget` already does with `gridKey`, `totalKey`, and `equationKey`. If tests used `find.byKey(DiceWidget.rollButtonKey)`, the named wrapper class would be unnecessary.

Whether to collapse this is a judgment call. The current approach is marginally simpler to test but adds a file and a class for a single-line delegation. Flag as a suggestion.

**Estimated LOC reduction if removed:** ~26 lines, replaced by a `Key` constant and a direct `MacButton` in `DiceScreen`.

---

#### 7. Verbose class-level doc comment on `DiceController` (dice_controller.dart:13–35)

The doc comment is 22 lines and documents: the class purpose (line 13), what `factory DiceController` does (lines 17–18), the default values (line 19), the exact ordered side effects of `roll()` as a numbered list (lines 21–26), and a design rationale paragraph with a forward reference to E12 (lines 28–35).

The numbered side-effect order is also present in the test `'roll() invokes deps in order: notify, append, audio, haptic, write'`, making the comment and the test redundant with each other. If the order matters, the test is the authoritative source of truth. The comment should be trimmed to the "what" and drop the "which step fires in which order" enumeration.

The forward reference to E12 debouncing ("A debounced `RollButton` (E12) will protect against double-taps") is speculative future intent embedded in production code documentation. Per YAGNI, forward-looking milestone references in doc comments add maintenance debt: if E12 changes or is renumbered, the comment will mislead.

**Suggested simplification:** Reduce the class doc to 4–6 lines covering purpose, the hydration default, and the UI-first ordering note. Remove the E12 forward reference.

**Estimated LOC reduction:** ~14 comment lines.

---

#### 8. `DiceScreen` — `LayoutBuilder` wrapping `SingleChildScrollView` + `ConstrainedBox` + `IntrinsicHeight` (dice_screen.dart:29–34)

This four-widget stack exists to make the `Column` fill the viewport when content is short, while also allowing scrolling when content is tall. It is a common Flutter idiom, but `IntrinsicHeight` is documented as expensive (it requires a double-pass layout). On a screen with a fixed number of children and no variable-height widgets, `IntrinsicHeight` is rarely necessary.

The same result — fill viewport, allow scroll — can usually be achieved with a `CustomScrollView` and a single `SliverFillRemaining(hasScrollBody: false)`, which is layout-pass efficient. Alternatively, the `Column` can be replaced with a `Column(mainAxisAlignment: MainAxisAlignment.spaceBetween)` inside a `SizedBox.expand`, avoiding `IntrinsicHeight` entirely.

This is flagged as important because `IntrinsicHeight` has a documented performance cost that accumulates on every rebuild, and `DiceController` calls `notifyListeners()` on every roll and every config change.

---

#### 9. `app.dart` — `resolveLocale` is annotated `@visibleForTesting` but belongs in a utility module

`resolveLocale` is a free function in `app.dart` marked `@visibleForTesting`. Its presence in the root `App` widget file is arbitrary; it has nothing to do with widget construction. For M1, it is a minor concern, but `@visibleForTesting` on a production function signals that it was extracted primarily to be testable, not because it belongs at that call site. If the `LocaleController` or a dedicated locale utility module owned this function, `app.dart` would be simpler and the function would have a more natural home.

This is a suggestion for future cleanup, not a blocker.

---

### Code to Remove

| Location | Reason | Estimated LOC |
|---|---|---|
| `dice_controller.dart:40–57` | Factory constructor; replace with single default constructor | -16 |
| `dice_controller.dart:128–131` | Redundant config persist in `roll()` | -3 |
| `dice_controller.dart:13–35` (partial) | Trim verbose doc comment, remove E12 forward reference | -14 |
| `dice_widget.dart:120–125` (3 fields) + `117–119` (3 params) | `_Grid` layout constants as params — collapse to file-level constants | -9 |
| `dice_widget.dart:95` | Duplicate `_sum(values!)` call | -0 (inline local) |

**Total estimated LOC reduction: ~42 lines**

---

### Simplification Recommendations

**1. Collapse `DiceController` to a single constructor (Most impactful)**
- Current: factory + private constructor, 7 positional forwarding params, 28 lines of constructors
- Proposed: one named constructor with an initializer list + constructor body for `_lastDiceConfig.read()`
- Impact: -16 LOC, removes the factory/private split indirection, cleaner test construction

**2. Remove redundant `_lastDiceConfig.write()` from `roll()` (Important)**
- Current: config is written in `setType`, `setCount`, and `roll()` — the last write in `roll()` is always a no-op
- Proposed: remove lines 128–131 in `roll()`
- Impact: -3 LOC, one fewer `await` on every roll, cleaner async flow

**3. Remove `_Grid` layout constant parameters (Important)**
- Current: `slotSize`, `slotSpacing`, `maxColumns` passed into a private widget from its only call site
- Proposed: promote to file-level `const` values and remove from `_Grid`'s constructor
- Impact: -9 LOC, signals to readers that these values are not variable

**4. Replace `LayoutBuilder` + `ConstrainedBox` + `IntrinsicHeight` in `DiceScreen` (Important)**
- Current: three-widget stack for viewport-fill-with-scroll behavior; `IntrinsicHeight` is double-pass
- Proposed: `CustomScrollView` + `SliverFillRemaining(hasScrollBody: false)` or `Column(mainAxisAlignment: MainAxisAlignment.spaceBetween)` in a `SizedBox.expand`
- Impact: 0 LOC change, but removes a double-pass layout widget that rebuilds on every roll

**5. Trim `DiceController` doc comment (Suggestion)**
- Current: 22-line comment with ordered side-effect enumeration already covered by a test, plus an E12 milestone forward reference
- Proposed: 5-line comment covering purpose and the UI-first ordering rationale only
- Impact: -14 comment lines, removes speculative milestone coupling

**6. Evaluate collapsing `RollButton` to a `Key` + inline `MacButton` (Suggestion)**
- Current: separate 26-line file wrapping a single `MacButton` call, justified by `find.byType` in tests
- Proposed: key constant on the `MacButton` in `DiceScreen`, matching the pattern `DiceWidget` uses for its sub-elements
- Impact: -26 LOC (one file removed), consistent with how other testable sub-elements are keyed

---

### YAGNI Violations

**`_Grid` constructor parameters for `slotSize`, `slotSpacing`, `maxColumns`**
These parameters imply the grid is configurable. It is not — there is one call site with one set of values. YAGNI says: don't make it configurable until you need to configure it. The constants belong at file scope or inlined.

**`roll()` config persist after every roll**
`setType` and `setCount` already keep the persisted config current. Writing it again in `roll()` implies a future scenario where `roll()` could change the config independently of `setType`/`setCount`. No such scenario exists in M1. This is a "just in case" write.

**E12 forward reference in `DiceController` doc comment**
The comment mentions "E12 debouncing" as a future protection mechanism. Documenting features that don't exist yet couples the documentation to a roadmap that may change. The code should document what it does, not what future milestones will add to it.

---

### Final Assessment

**Total potential LOC reduction:** ~42 lines (~11% of the ~380 production lines in scope)

**Complexity score:** Low-to-Medium

The feature is well-structured and mostly minimal. The widget decomposition is appropriate — `TypeSelector`, `QuantitySelector`, `RollButton`, and `DiceWidget` are each focused and composable. The `ChangeNotifier` + `provider` pattern is used correctly and without over-abstraction.

The two clearest simplifications are the `DiceController` constructor refactor (factory/private split is unnecessary complexity for this use case) and removing the redundant config write in `roll()`. The `_Grid` parameter bloat and the `IntrinsicHeight` performance concern are the next priority.

**Recommended action:** Proceed with simplifications (items 1–4 are worthwhile; items 5–6 are optional).

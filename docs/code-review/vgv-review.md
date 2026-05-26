# VGV Code Review — `feat/e05-dice-screen`

## Summary

This branch adds the first real product screen (the dice roller) and wires it into the app shell. The architecture is clean, the controller is well-designed (`ChangeNotifier`-based, dependency-injected, no Bloc as documented), the widget decomposition matches CLAUDE.md's folder rules, and the test suite is unusually thorough for a feature of this size: it covers the controller's state transitions, side-effect ordering, persistence, semantics, and three layers of widget composition.

There are no critical defects: nothing crashes, nothing regresses, no resource leaks, no broken layer boundaries. The most material issues are (1) a stale documentation reference in the existing `widget_test.dart` description that now mis-describes the system, (2) one assertion in `dice_widget_test.dart` that does not actually verify what its name promises, and (3) a small but real race in `DiceController.roll()` whose comment acknowledges the problem without defending against it. Everything else is polish.

Verdict: ready to merge after the suggested cleanups in the "Important" bucket.

---

## 🔴 Critical — Must Fix Before Merge

None.

---

## 🟡 Important — Should Fix

### 1. `widget_test.dart:44-45` — stale test description after `DesignSystemPreview` deletion
- **What**: The first test still reads:
  ```dart
  testWidgets('App renders the design system preview at the Mac Classic '
      'palette by default', (tester) async { ... })
  ```
  but the body now asserts `find.byType(DiceScreen)` and `find.text('1-BIT DICE')`. The description is a relic of the deleted `lib/features/_dev/design_system_preview.dart`.
- **Why**: Test names are the most-read documentation in the codebase. A name that lies about what the test does is worse than no name — it sends future debuggers in the wrong direction.
- **Fix**: Rename to something like `'App renders the DiceScreen at the Mac Classic palette by default'`.

### 2. `dice_screen_test.dart:241-244` — assertion does not match the description
- **What**: The test `'restores last config from pre-populated preference'` ends with:
  ```dart
  // D12 chip is rendered with the inverted (paper) color when selected.
  final selectedText = tester.widget<Text>(find.text('D12'));
  expect(selectedText.style?.color, isNotNull);
  ```
  `isNotNull` is a tautology here — every styled `Text` in this tree has a non-null `style.color`. The comment promises an inversion check that the assertion does not perform. The actual inversion check exists in `type_selector_test.dart`, so this is duplicative intent that has decayed into a no-op.
- **Why**: Tautological assertions create false confidence. If someone later breaks `TypeSelector` so the selected chip is not inverted, this test will still pass.
- **Fix**: Either drop the assertion (the chip's selected behavior is already covered in `type_selector_test.dart`), or assert against the actual palette: `expect(selectedText.style?.color, Palette.of(PaletteId.macClassic).paper);` after importing the palette (mirroring `type_selector_test.dart:40-45`).

### 3. `dice_controller.dart:116-131` — `roll()` is non-reentrant and the doc acknowledges the race without guarding
- **What**: The class doc says: *"Not reentrant — … a second `roll()` started before the first completes will simply race the writes."* `roll()` then calls `await _history.append(...)` and `await _lastDiceConfig.write(...)` with `notifyListeners()` and synchronous `audio.play`/`haptic.trigger` in between. A second tap during the first roll's await window will:
  - overwrite `_lastResult` between the two awaits,
  - emit two `audio.play(SoundEvent.total)` calls,
  - emit two `haptic.trigger` calls,
  - and append two history entries with two different timestamps.
  The deferred mitigation ("E12 debounced `RollButton`") puts the safety contract in a future epic — but `RollButton` is already shipping in this PR.
- **Why**: Today the in-memory implementations make this benign, but the contract drift is real: as soon as someone wires a Hive history or a real haptic, double-taps become a UX bug. Guarding here also lets you drop the comment.
- **Fix**: Either (a) add a one-line `bool _rolling` re-entry guard inside `roll()`:
  ```dart
  Future<void> roll() async {
    if (_rolling) return;
    _rolling = true;
    try {
      // existing body
    } finally {
      _rolling = false;
    }
  }
  ```
  …and add a matching test, or (b) decide explicitly that the debounce belongs in `RollButton` *now* (since you already own that widget). Either is fine; the status quo of "documented race we plan to fix later" is the weakest option.

### 4. `dice_controller.dart:114-131` — `lastDiceConfig.write` is dead-weight on every `roll()`
- **What**: `roll()` calls `_lastDiceConfig.write(LastDiceConfig(diceType: _selectedType, count: _count))`. The current type and count cannot change inside `roll()` itself — they only change in `setType` / `setCount`, both of which already persist. So the write on every roll is unconditionally a no-op write of the existing values.
- **Why**: An unnecessary async write on the hot path costs nothing today (in-memory) but is a real disk write on the SharedPreferences-backed implementation that already exists in this file (`SharedPreferencesLastDiceConfigPreference`). It also means every test of `roll()` has to assert against a `lastDice.write(...)` event that adds noise without verifying behavior (see `dice_controller_test.dart:231-238`).
- **Fix**: Drop the trailing `await _lastDiceConfig.write(...)` from `roll()` and remove `'lastDice.write(d6,1)'` from the ordered-events expectation. The persistence guarantee is already covered by `setType` / `setCount`.

### 5. `dice_widget.dart:54-65` — double-nested `DecoratedBox` looks like a copy-paste bug
- **What**:
  ```dart
  DecoratedBox(
    decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.ink, width: 2)),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: BoxDecoration(color: colors.paper, border: Border.all(color: colors.ink, width: 2)),
        ...
  ```
  The pattern produces two concentric 2px ink borders separated by 2px of paper — a deliberate "Mac System" double-bezel that matches `MacButton`'s look. This is intentional, but the code expresses it as "I copy-pasted a box and forgot to clean up."
- **Why**: This is the kind of structure a future contributor will "simplify" by deleting the inner one, breaking the look. Naming the intent costs one line.
- **Fix**: Add a single-line comment above the outer `DecoratedBox`, e.g. `// Mac-style double bezel: 2px ink / 2px paper / 2px ink.` If the pattern recurs (it already does in `MacButton`), consider lifting it into a shared `PixelDoubleBorder` widget under `lib/shared/widgets/` — but only after a third user appears. (Duplication > wrong abstraction.)

### 6. `dice_screen.dart:22, dice_widget.dart:51, etc.` — repeated `Theme.of(context).extension<OneBitColors>()!` with force-unwrap
- **What**: Five files in the new code do `Theme.of(context).extension<OneBitColors>()!`. The force-unwrap is safe (the extension is registered in `buildThemeData`) but it is the kind of pattern that, when copy-pasted into a test harness that forgets the extension, blows up with a null-check error far from the cause.
- **Why**: Centralising this gives one place to (a) document the invariant, (b) emit a clearer error, and (c) eliminate the bang operators per CLAUDE.md's null-safety stance.
- **Fix**: Add a tiny helper in `lib/core/theme/app_theme.dart`, e.g.
  ```dart
  extension OneBitColorsX on BuildContext {
    OneBitColors get colors {
      final ext = Theme.of(this).extension<OneBitColors>();
      assert(ext != null, 'OneBitColors not registered on this Theme.');
      return ext!;
    }
  }
  ```
  Then `final colors = context.colors;` replaces the force-unwrap everywhere. Not blocking, but the surface area only grows from here.

### 7. `dice_widget.dart:111` — private helper duplicates `RollResult.total`
- **What**: `static int _sum(List<int> xs) => xs.fold(0, (a, b) => a + b);` and the equation `'${values!.join(' + ')} = ${_sum(values!)}'` reimplement two things that `RollResult` already exposes (`total` and `equation`). The widget takes `List<int>? values` instead of `RollResult?`, so it cannot use them.
- **Why**: One source of truth for "what does the total of a roll look like" is better than two. If the equation format ever changes (e.g. add parentheses for d100), it will change in one place.
- **Fix**: Either pass the `RollResult?` straight through to `DiceWidget` and read `result.total` / `result.equation`, or keep the `values` parameter but reuse the formatting logic via a static helper on `RollResult`. Slight preference for passing `RollResult?` — it makes the widget contract more honest ("I render a result").

---

## 🔵 Suggestions — Nice to Have

### S1. `dice_controller.dart:36-67` — factory + private constructor pattern is heavier than needed
The class uses a `factory` to read from `lastDiceConfig` before delegating to a private positional constructor. A simpler shape would be a single generative constructor that initialises with placeholders, then a private `_hydrate` call — but honestly the current pattern is fine and reads well. Suggestion only: if you ever need to add a second hydration source, prefer making the constructor `DiceController({...})` with normal field initialisers and a separate `void _hydrate()` call.

### S2. `dice_widget.dart:114-163` — `_Grid` builds rows/cols with nested `for` + spread
The two nested `for ... ]` spreads with conditional `if (r > 0) SizedBox` and `if (c > 0) SizedBox` are clever but dense. A `Column(children: List.generate(rows, (r) => Padding(top: r == 0 ? 0 : spacing, child: Row(...))))` would scan more easily. Not a blocker — but you said yourself "obvious over clever".

### S3. `dice_widget.dart:80-100` — `if (hasResult) ... values!` pattern uses force-unwrap inside a null-guarded branch
Inside `if (hasResult)` you write `_sum(values!)`, `values!.length > 1`, `values!.join(...)`. With Dart 3 promotion, you can lift `final v = values;` before the `if` (or use `if (values case final v?)` pattern) and have non-null `v` for free. Minor.

### S4. `type_selector_test.dart:88-105` — `matchesSemantics(label: 'D20\nD20', ...)` is brittle
The `'D20\nD20'` label encodes both the wrapping `Semantics(label: type.label)` *and* the underlying `Text(type.label)` accumulating into one semantic node. If anyone ever refactors `_TypeChip` to wrap the `Text` with `ExcludeSemantics` (which would be a perfectly reasonable cleanup), this test will fail for a non-bug. Consider asserting `contains('D20')` instead.

### S5. `quantity_selector.dart:33-51` — `_StepButton` doesn't expose a key for testing
There is no key on `_StepButton`. The widget tests find it via `find.text('+')` / `find.text('−')`, which works today, but the `+` glyph is technically locale-stable while `−` (U+2212 MINUS SIGN) is easy to mistake for the ASCII `-` and break in a refactor. A `@visibleForTesting static const Key increaseKey = ...;` per button would be safer. Optional.

### S6. `dice_screen.dart:36-42` — `appName.toUpperCase()` couples i18n value casing to the screen
The screen forces upper-case on `appName`. Since `appName` is documented as "kept untranslated across locales" (per the `@appName` description in `app_pt_BR.arb`), this is fine, but consider whether the title belongs in `display` typography with its own l10n key (e.g. `screenDiceTitle`) so the casing decision lives at the string level.

### S7. `quantity_selector.dart:8-12` — comment says "disabled steps render identical to enabled ones"
The aesthetic decision is good and worth keeping, but consider an `IgnorePointer` wrapper on disabled steps so screen-reader users hear `enabled: false` and the tap target genuinely doesn't fire. The `Semantics(enabled: enabled, ...)` already does the right thing, so this is just a defensive belt-and-braces note.

### S8. `roll_button.dart` — barely earns its existence
This widget is 27 lines of wrapper around `MacButton` with a hardcoded label and `expand: true`. The doc justifies it as "so dice screen tests can target it with `find.byType(RollButton)`, free of locale." That's a fair test ergonomics argument and I would keep it. Just noting that this is exactly the kind of one-method wrapper that VGV normally flags — and it's fine *here* because the justification is documented inline. Don't let the pattern spread to every CTA.

### S9. `dice_controller_test.dart:209-220` — duplicating the RNG logic in the test
```dart
final expected = <int>[];
final rng = Random(42);
for (var i = 0; i < 3; i++) {
  expected.add(rng.nextInt(DiceType.d6.sides) + 1);
}
```
This is testing `rollDice` more than `DiceController`. The simpler assertion is "given the same seed, two controllers produce the same sequence" — that proves determinism without re-implementing the algorithm in the test (which by definition will pass even if both production and test agree on the wrong formula).

### S10. `dice_controller_test.dart:276-284` — `'default rng uses Random.secure when no rng injected'`
The body rolls five d6s and asserts the first is in `[1, 6]`. That's a smoke test, not the assertion the name promises (which would require inspecting the actual `_rng` field — not worth doing). Consider renaming to `'rolls in range when no rng is injected'` to match the body.

---

## Simplicity Assessment

- **Lines that could be removed**: ~5 (drop `_lastDiceConfig.write` from `roll()` and its matching test expectation; tighten the tautological `expect(..., isNotNull)`).
- **Unnecessary abstractions**: none material. `RollButton` is a borderline one-method wrapper, but the test-ergonomics justification is documented and convincing. `_Slot`, `_Grid`, `_StepButton`, `_TypeChip` are all earning their keep as private classes — they each have non-trivial state-dependent decoration.
- **YAGNI violations**: none. No premature generalisation, no unused parameters, no "framework" code. The grid hardcodes `_maxColumns = 3` instead of taking it as a parameter — exactly right.
- **Complexity verdict**: Already minimal. Minor tweaks only.

## Testing Assessment

- **New code with tests**: ✅ Every new production file has a paired test file. Coverage looks thorough enough to satisfy the 100% line-coverage gate.
- **Test quality**: Meaningful — covers state transitions, side-effect ordering, disabled-state behavior, semantics labels, layout edge cases (1, 4, 10 dice), assertion failures, and config restoration. Two specific weaknesses called out above (Important #2, Suggestion S9, Suggestion S10).
- **State management test coverage**: Complete. `dice_controller_test.dart` exercises hydration, both setters with no-op paths, clamping at both ends, the full `roll()` side-effect chain in order, isolation of the audio event (`total` only), `lastResult` lifecycle on type/count changes, and `ChangeNotifier` contract.
- **UI component test coverage**: Complete. Every visible behaviour has a corresponding `testWidgets` block. Semantics are explicitly verified for `TypeSelector` and `QuantitySelector`. The integration test in `dice_screen_test.dart` exercises end-to-end flows (tap chip → no result yet → pref written; tap ROLL → all side effects fire; tap + after ROLL → result discarded).
- **Test anti-patterns observed**: one tautology (`expect(..., isNotNull)` at line 243), one assertion that duplicates implementation (Suggestion S9), one description-vs-body mismatch (`'default rng uses Random.secure'`). All minor; none invalidate the suite.

---

## What I Liked

- The controller is **dependency-injected through the constructor** with named parameters and a deterministic `rng` hook. That's textbook testability.
- **The side-effect ordering in `roll()` is documented inline** with the rationale (UI-first for snappiness, durability is acceptable trade-off for in-memory). That's the kind of "why" comment VGV asks for.
- **The `@visibleForTesting static const Key`** convention on `DiceWidget` is used correctly — public enough to test, annotated to prevent misuse.
- **No `package:provider` abuse**: the only uses of `context.watch` / `context.read` are at the screen root and in DI wiring, consistent with the CLAUDE.md note that `provider` is allowed "exclusively for exposing `ChangeNotifier`s."
- **Equality of `RollResult` via Equatable** plus the inline assert on `diceCount == values.length` — defensive, not paranoid.
- **The aesthetic constraint is upheld**: no third color sneaks in, no gradients, no shadows that aren't ink-on-paper.

Ship it after the Important bucket.

---
title: "Code Simplicity / YAGNI Review — Design C Tap-to-Roll Dice Screen Redesign"
date: 2026-05-30
branch: feat/redesign
plan: docs/plan/2026-05-30-feat-dice-screen-tap-to-roll-redesign-plan.md
reviewer: code-simplicity-agent
files_reviewed:
  - lib/features/dice/dice_controller.dart
  - lib/features/dice/dice_screen.dart
  - lib/features/dice/widgets/type_selector.dart
  - lib/features/dice/widgets/quantity_selector.dart
  - lib/features/dice/widgets/dice_type_sheet.dart
  - lib/features/dice/widgets/dice_type_badge.dart
  - lib/shared/widgets/hatch_painter.dart
  - lib/features/presets/widgets/create_preset_sheet.dart
---

# Code Simplicity / YAGNI Review — Design C Tap-to-Roll Dice Screen Redesign

## Simplification Analysis

### Core Purpose

Invert the dice screen so the canvas is the roll target, collapse the 7-chip type picker into a compact bottom-sheet flow, and guard the enlarged tap surface against double-rolls. The roll engine, animations, `DiceWidget`, and persistence are deliberately unchanged.

---

### Unnecessary Complexity Found

#### 1. `_DragHandle` is a `StatefulWidget` with no `setState` calls

**File:** `lib/features/dice/widgets/dice_type_sheet.dart` lines 184–222

`_DragHandleState` owns two instance fields: `_dragged` (accumulated drag delta) and `_dismissed` (one-shot guard). Neither field drives a `setState` call — the widget never rebuilds itself. The full `StatefulWidget`/`State` lifecycle exists only to keep these two values alive across gesture callbacks in a single continuous drag gesture.

The `_dismissed` flag is functionally necessary: calling `Navigator.pop()` twice on a route that is already popped will throw. However the flag does not require `State` objects to survive. Since the route builds the panel widget once and never rebuilds it, `build` is called once per route instance. Closure-local mutable variables defined in `build` persist for the lifetime of the GestureDetector, making `StatefulWidget` unnecessary here.

**Fix:** Convert to `StatelessWidget` using closure-local variables in `build`:

```dart
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    var dragged = 0.0;
    var dismissed = false;
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return GestureDetector(
      key: DiceTypeSheet.dragHandleKey,
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) {
        if (dismissed) return;
        dragged += d.delta.dy;
        if (dragged > _threshold) {
          dismissed = true;
          onDismiss();
        }
      },
      onVerticalDragEnd: (_) => dragged = 0,
      child: Container(
        width: double.infinity,
        height: 24,
        color: colors.paper,
        alignment: Alignment.center,
        child: Container(width: 32, height: 4, color: colors.ink),
      ),
    );
  }
}
```

Move `_threshold` to a file-scope constant (it is currently a class-level constant on `_DragHandleState`).

**Estimated removal:** ~12 LOC (one class, one `createState` override, one State subclass).

#### 2. `_DisabledSaveButton` in `create_preset_sheet.dart` duplicates `MacButton` visuals

**File:** `lib/features/presets/widgets/create_preset_sheet.dart` lines 170–192

`_DisabledSaveButton` replicates `MacButton`'s full visual output — identical border, padding, uppercase text, and colors — to represent a disabled/invalid form state. The comment on line 169 acknowledges the visual identity ("Kept identical to the active button on purpose — the 1-bit aesthetic has no grey/disabled state"). This means there is no design reason for two separate widgets: they look the same.

If `MacButton` accepts a nullable `onPressed` (`VoidCallback?`) and ignores taps when it is `null` (standard Flutter pattern), the `if (_isValid) ... else ...` branch collapses to:

```dart
MacButton(
  label: l10n.presetsSheetSave,
  onPressed: _isValid ? _save : null,
  expand: true,
)
```

`_DisabledSaveButton` can then be deleted entirely. Any future visual change to the save button needs to be made in only one place.

Note: `create_preset_sheet.dart` is a modified (not newly added) file in this redesign. `_DisabledSaveButton` pre-dates the redesign but the file is explicitly listed as changed, so the issue is surfaced here.

**Estimated removal:** ~22 LOC.

---

### Code to Remove

| File | Lines | Reason | Est. LOC reduction |
|------|-------|--------|--------------------|
| `dice_type_sheet.dart` | 184–222 | `_DragHandle` `StatefulWidget`/`State` — state machinery not needed | ~12 |
| `create_preset_sheet.dart` | 170–192 | `_DisabledSaveButton` duplicates `MacButton` visuals; fix `MacButton` to accept nullable `onPressed` | ~22 |

**Total estimated reduction: ~34 LOC**

---

### Simplification Recommendations

#### 1. Convert `_DragHandle` to `StatelessWidget` (Important)

**Current:** `_DragHandle` is a `StatefulWidget` with `_DragHandleState` holding `_dragged` and `_dismissed`. The widget never calls `setState`, making the State lifecycle overhead unjustified.

**Proposed:** Use closure-local mutable variables in `build`. The route builds the panel once; closure-local vars persist exactly as long as the GestureDetector's callbacks are live. See the code snippet in Finding 1 above.

**Impact:** ~12 LOC removed. Reduces cognitive load (no misleading implication that this widget has reactive state).

#### 2. Delete `_DisabledSaveButton`; make `MacButton.onPressed` nullable (Important)

**Current:** Two separate widget classes that look identical, maintained in parallel.

**Proposed:** Change `MacButton.onPressed` type from `VoidCallback` to `VoidCallback?`. When `null`, taps are silently ignored (the button looks and lays out identically). Delete `_DisabledSaveButton`. Collapse the `if (_isValid)` conditional to a single `MacButton` call.

**Impact:** ~22 LOC removed from `create_preset_sheet.dart`. Single source of truth for the button visual.

---

### YAGNI Violations

No YAGNI violations were found in the new files (`dice_type_sheet.dart`, `dice_type_badge.dart`, `hatch_painter.dart`) or in the modified `dice_controller.dart`, `dice_screen.dart`, `type_selector.dart`, or `quantity_selector.dart`.

Every component is directly required by the acceptance criteria. Specific items confirmed as non-YAGNI:

- **`DiceTypeBadge` pixel matrices** — required because plan explicitly rules out font glyphs (fallback risk). The `@visibleForTesting` annotation on `matrices` is justified by the badge-per-type test requirement.
- **`HatchPainter`** — required by the 2-color palette rule (no translucent grey scrim). Its `cell` constant is `@visibleForTesting` as required for painter coverage.
- **`hasRolled` and `isRolling` flags on `DiceController`** — both are required and correctly motivated: `hasRolled` cannot be derived from `lastResult == null` (documented rationale in the controller), and `isRolling` is the reentrancy guard needed because `RollButton` was deleted.
- **`_DiceTypeSheetRoute` (custom `PopupRoute`)** — required to own the hatch barrier. `showModalBottomSheet` is explicitly ruled out because it does not expose its barrier for custom painting.
- **`onDismiss` callback on `DiceTypeSheet`** — the callback-based API (vs. calling `Navigator.pop()` directly inside the widget) is necessary for testability: the sheet is pumped in tests outside of a live route context.
- **`@visibleForTesting` keys (`sheetKey`, `barrierKey`, `dragHandleKey`)** — all are required for the specified dismissal-branch tests.
- **The caret pixel matrix in `TypeSelector`** — required for the same font-fallback reason as the badge matrices.

---

### Notes on Intentional Design (Not Flagged)

The following items were inspected and confirmed as intentional design requirements per the plan — not complexity to remove:

- **`_checkmark` pixel matrix vs. `CheckmarkPainter` from `language_picker.dart`:** These are not interchangeable. `CheckmarkPainter` uses `drawLine` with `strokeCap.square`, which can anti-alias at sub-pixel scales. The sheet's `_checkmark` uses a pixel matrix rendered through `PixelIcon` (always crisp, 1-bit). The inverted-row context (paper-on-ink) requires the pixel approach. A comment on `_checkmark` explaining why `CheckmarkPainter` was not reused would prevent a future reader from incorrectly collapsing them.
- **`_DiceTypeSheetRoute.barrierDismissible = false` with `barrierColor = null`:** Correct. The route owns its own opaque hatch barrier and wires dismissal manually. The `barrierLabel = null` is a minor accessibility gap (the framework back-gesture label), but the `Semantics(button: true, label: l10n.actionClose)` on the hatch `GestureDetector` compensates for it adequately.
- **Hard-cut transition (`transitionDuration: Duration.zero`):** Required by the plan — a fade would introduce alpha and violate the 2-color rule.
- **`HatchPainter` fills the background with a `drawRect` first, then draws ink cells:** This is the correct approach. Drawing only ink cells over a transparent background would let the underlying canvas color show through, which would be theme-dependent and could produce a three-color appearance.

---

### Final Assessment

**Total potential LOC reduction: ~34 LOC (~3% of changed files)**
**Complexity score: Low**
**Recommended action: Minor tweaks only**

The implementation is clean and well-aligned with the plan. The two issues worth fixing before merge are:

1. `_DragHandle` carrying unnecessary `StatefulWidget` overhead (no `setState` ever called) — easy conversion to `StatelessWidget`.
2. `_DisabledSaveButton` duplicating `MacButton` visuals — a one-line `MacButton` API change removes ~22 LOC and eliminates the dual-maintenance risk.

Neither issue is a blocker, but both are straightforward improvements that pay ongoing maintenance dividends.

---

---
title: "Code Simplicity / YAGNI Review — GH-10 Dice Roll Animations"
date: 2026-05-27
branch: gh-10-dice-animations
base: ralph/batch/20260527T112536Z
reviewer: simplicity-agent
---

# Code Simplicity / YAGNI Review — GH-10 Dice Roll Animations

**Files reviewed:**
- `lib/features/dice/widgets/dice_animator.dart`
- `lib/features/dice/widgets/animations/dice_grid.dart`
- `lib/features/dice/widgets/animations/fast_animation.dart`
- `lib/features/dice/widgets/animations/drum_animation.dart`
- `lib/features/dice/widgets/animations/tabletop_animation.dart`

---

## Critical

### 1. `DiceGrid.builder` is dead code — never called

**File:** `dice_grid.dart:18,40,79-80`

The `builder` parameter (`Widget Function(int index, Widget slot)?`) is declared,
documented, and dispatched through a `_wrap` helper, but it is never passed at any
call site. All three consumers (`FastAnimation`, `DrumAnimation`,
`TabletopAnimation`) call `DiceGrid(count: ..., values: ...)` with no `builder`
argument. The parameter comment says _"Used by `TabletopAnimation` to apply
per-slot transforms"_, but `TabletopAnimation` wraps the whole `DiceGrid` in
`Transform.translate`/`Transform.scale` at the `AnimatedBuilder` level — it never
uses the per-slot path.

`dice_grid_test.dart` exercises the `builder` path (the "builder wraps each slot"
test), but that test only exists to provide coverage for the dead parameter.

**Fix:** Remove the `builder` field, the `_wrap` helper, and the corresponding
test case. Per-slot transforms can be added if a future animation strategy genuinely
needs them.

**Estimated removal:** ~10 production lines + 1 test case.

---

## Important

### 2. `@visibleForTesting` shims are thin wrappers over private functions

**File:** `tabletop_animation.dart:136-142`

```dart
@visibleForTesting
double tabletopTranslateY(double t, double slotSize) => _translateY(t, slotSize);

@visibleForTesting
double tabletopScale(double t) => _scale(t);
```

These are pure pass-through functions whose sole purpose is to expose private
functions to tests. The correct fix is to make `_translateY` and `_scale`
package-private by removing their leading underscores (e.g., `translateY`,
`tabletopScale`), then have the tests call them directly. Adding public surface
area solely to satisfy test tooling is a YAGNI violation and pollutes the file's
public API.

**Fix:** Rename `_translateY` → `translateY` and `_scale` → `tabletopScale` (or
similar non-conflicting names). Drop the shim functions and the `@visibleForTesting`
annotations. Tests import the renamed functions directly.

**Estimated removal:** 8 lines.

### 3. `FilterQuality.none` on `Transform.scale` has no effect here

**File:** `tabletop_animation.dart:125`

`filterQuality: FilterQuality.none` on a `Transform.scale` only affects rasterised
bitmap children (images, layers promoted to GPU texture via `RepaintBoundary`). The
`DiceGrid` tree is entirely vector: `Container` decorations and `Text` widgets.
Flutter repaints them at native resolution on every frame regardless of
`filterQuality`. The flag has no effect on the 1-bit aesthetic and creates a
misleading hint ("why is this here?") for future readers.

The pixel-snapping goal is already served by `roundToDouble()` in `_translateY`.

**Fix:** Remove `filterQuality: FilterQuality.none`.

**Estimated removal:** 1 line.

### 4. `DiceGrid` layout parameters are premature generics

**File:** `dice_grid.dart:15-17`, `tabletop_animation.dart:25,43`

`slotSize`, `slotSpacing`, and `maxColumns` are optional parameters with defaults
of `64`, `8`, and `3`. They are never overridden at any call site in production
code. Additionally, `TabletopAnimation` independently carries its own `slotSize`
field (`tabletop_animation.dart:25,43`) defaulting to the same `64`, which is only
ever used as the slide travel distance passed to `_translateY` — it is not
forwarded to `DiceGrid`. This creates two independent sources for a value that must
agree.

**Fix:** Hardcode the three values as private top-level constants inside
`dice_grid.dart`. Remove the corresponding parameters, field declarations, and doc
comments. Remove the `slotSize` field from `TabletopAnimation` and replace its use
in `_translateY` with the shared constant. Restore as parameters only when a caller
needs to override them.

**Estimated removal:** ~10 lines production code.

---

## Suggestions

### 5. `FastAnimation` wraps a semantically no-op `AnimatedSwitcher`

**File:** `fast_animation.dart:26-37`

`FastAnimation` is the "no animation — hard cut" strategy. It uses
`AnimatedSwitcher` with `transitionBuilder: (child, _) => child` to suppress the
default fade, but `AnimatedSwitcher` still keeps the outgoing child mounted for
`duration` (100 ms). A plain `KeyedSubtree` keyed on `targetValues` would express
the intent more directly: build a fresh grid on each roll, let Flutter's normal
widget diffing handle the swap. Low priority — 100 ms is imperceptible.

### 6. Duplicated `didUpdateWidget` / `dispose` pattern across cycling animations

**File:** `drum_animation.dart:62-74,95-101`, `tabletop_animation.dart:71-83,104-110`

Both `_DrumAnimationState` and `_TabletopAnimationState` share identical
`didUpdateWidget` bodies, identical `_onStatus` handlers, and identical `dispose`
teardown sequences. The only differences are `_cycleEveryMs` (80 vs 60) and the
phase guard in `_TabletopAnimationState._onTick`. YAGNI — do not extract a shared
mixin now (two sites is the minimum threshold for extraction). Revisit if a third
cycling animation is added.

---

## Summary

| # | Severity | File | Est. LOC removed |
|---|----------|------|-----------------|
| 1 | Critical | `dice_grid.dart` + test | ~11 |
| 2 | Important | `tabletop_animation.dart` | ~8 |
| 3 | Important | `tabletop_animation.dart` | 1 |
| 4 | Important | `dice_grid.dart` + `tabletop_animation.dart` | ~10 |
| 5 | Suggestion | `fast_animation.dart` | ~5 |
| 6 | Suggestion | (informational — no action now) | 0 |

**Total potential reduction:** ~30 lines (~15% of the 5 new files).

**Verdict: Needs work** — 1 critical issue (dead `builder` param and its test
coverage) and 3 important issues must be resolved before merge.

---

---
title: "Code Simplicity / YAGNI Review — E09 App Shell + Splash"
date: 2026-05-26
branch: feat/e09-navegacao
reviewer: simplicity-agent
---

# Code Simplicity / YAGNI Review — E09 App Shell + Splash

## Simplification Analysis

### Core Purpose

Wire a GoRouter-based navigation shell (splash → 4-tab shell → screens) and ship
stub widgets for the three unimplemented tabs. Nothing more.

---

### Unnecessary Complexity Found

#### 1. `app_router.dart` — Four empty branch data classes (lines 66–87)

`DiceBranch`, `HistoryBranch`, `PresetsBranch`, and `SettingsBranch` each contain
nothing but a const constructor and a doc-comment. `go_router_builder` requires a
concrete class for each branch, but these classes carry zero behavior. The
boilerplate is unavoidable given the codegen requirement, however the individual
doc-comments on each class (e.g., "Branch for the dice rolling tab.") add noise
without value — any reader can infer this from the class name and its position
inside the `@TypedStatefulShellRoute` annotation. The comments could simply be
removed, saving 4 lines of doc-comment clutter with no loss of clarity.

**Severity: Suggestion** — purely cosmetic; no behavior change.

#### 2. `app_router.dart` — Four identical `buildPage` methods (lines 97–139)

Every leaf route class (`DiceRoute`, `HistoryRoute`, `PresetsRoute`,
`SettingsRoute`) contains the same one-liner:

```dart
@override
Page<void> buildPage(BuildContext context, GoRouterState state) =>
    const NoTransitionPage(child: XxxScreen());
```

The only variable is the child widget type. Because `go_router_builder` requires
each route to be its own class and the `buildPage` override is required to produce
`NoTransitionPage` instead of the default `MaterialPage`, this duplication is
structural — it cannot be eliminated without abandoning codegen. However, the
`/// Creates a [XxxRoute].` constructor doc-comments on the four const constructors
are mechanical repetitions of the obvious; they add 4 lines with no benefit.

**Severity: Suggestion** — remove the 4 constructor doc-comments.

#### 3. `splash_screen.dart` — Third color violates the palette rule (line 112)

```dart
color: const Color(0xFF888888),
```

`CLAUDE.md` states: "Every theme uses exactly 2 colors: ink and foreground.
Zero intermediate tones. If you find yourself adding a third color, stop and
reconsider." The COCU microcopy uses a literal gray `#888888` — a third color
introduced directly in widget code, outside the palette system.

The plan acknowledges hardcoding `#000000`/`#FFFFFF` for the splash (to match the
native splash before any palette is loaded). That decision is sound. But the
subdued gray on the tagline is a separate aesthetic choice that has not been
justified in the plan or the code. It could be replaced with the same `_ink`
constant already in scope, and the "subdued" effect achieved purely via `fontSize`
(at 6pt PressStart2P on a white background the text is visually subtle without a
gray tint). Alternatively, if the design truly needs a muted tone, it should be
captured as a named constant (`_inkMuted`) with an explicit comment explaining the
deliberate violation of the palette rule.

**Severity: Important** — violates an explicit project rule, undocumented exception.

#### 4. `splash_screen.dart` — `Theme` override wrapping the entire screen (lines 58–59)

```dart
return Theme(
  data: buildThemeData(Palette.of(PaletteId.macClassic)),
  child: ColoredBox(
```

The plan says the splash does NOT read `OneBitColors` — it uses literal constants
`_ink` and `_paper`. That is true for the outer layout. The `Theme` override exists
solely so that the inner `PixelIcon` (which does read `OneBitColors`) paints in
the correct Mac Classic palette during the splash, regardless of the user's
persisted preference.

This is functional but creates a subtle implicit contract: `PixelIcon` silently
depends on `OneBitColors` being present in its theme, which works here only because
of the invisible `Theme` wrapper. A simpler approach would be to pass explicit
`on`/`off` colors directly to the painter — but `PixelIcon`'s current API does not
support that. Alternatively, a named constant `Color _splashInk` and a one-line
note explain why the wrapper exists.

As written, the code is correct. The concern is discoverability: a future reader
who removes the `Theme` wrapper will see `_ink`/`_paper` everywhere and assume
colors are self-contained, only to find the `PixelIcon` breaks. The code comment
at line 55–57 partially addresses this, but a subtle wrapper is easier to miss than
an explicit parameter.

**Severity: Suggestion** — add a TODO comment pointing to the design constraint,
or extract a `_SplashPixelIcon` that passes colors explicitly.

#### 5. `app_router.dart` — `SplashRoute` exposes an unused `path` constant (line 27)

```dart
static const String path = '/';
```

`SplashRoute.path` is never referenced outside `app_router.dart` itself (the
`buildAppRouter` function uses it, and tests reference it by string literal). A
grep of the test suite confirms this: `SplashRoute.path` appears in production code
only as the `initialLocation` argument to `buildAppRouter()`. Exposing the constant
as `public static` is correct for symmetry with the other routes — the plan
explicitly calls this out as the canonical path — but unlike `DiceRoute.path`,
`HistoryRoute.path`, etc., `SplashRoute.path` is never used for navigation (the
router goes to `/` by default; nothing calls `const SplashRoute().go(context)`
except the router itself at boot). It is an honest constant with a clear purpose,
but worth flagging as a potential "dead export" when the splash is eventually
removed in a future epic.

**Severity: Suggestion** — no action needed now; note it as tech debt.

#### 6. `splash_screen.dart` — `splashDieMatrix` duplicates `_iconDice` in `retro_tab_bar.dart`

`lib/features/splash/splash_screen.dart` (lines 154–167) defines `splashDieMatrix`
as a top-level `const List<List<int>>` exposed as `@visibleForTesting`.
`lib/shared/widgets/retro_tab_bar.dart` (lines 124–137) defines `_iconDice` as a
private `const List<List<int>>`.

The two matrices are identical — pixel for pixel, row for row. This is pure
duplication.

The plan acknowledges the icon matrices live in `retro_tab_bar.dart` and that
the splash reuses "a matrix from the design system." The intent was evidently to
share the matrix, but the implementation created a second copy. The canonical home
for this matrix is `retro_tab_bar.dart` (or a dedicated file if more shared icons
accumulate). `splashDieMatrix` in `splash_screen.dart` should be removed and the
splash should reference the shared constant.

**Severity: Important** — two identical constants maintained in two places.
Any pixel change to the d6 icon must be applied twice or will silently diverge.

#### 7. `app_router_test.dart` — `_NoopSoundPlayer` duplicated from `splash_screen_test.dart`

Both `test/app_router_test.dart` and `test/features/splash/splash_screen_test.dart`
define an identical `_NoopSoundPlayer implements SoundPlayer` class with the same
four empty method bodies. This is test boilerplate duplication. The correct fix is
a shared test helper in `test/helpers/noop_sound_player.dart` (a pattern common in
this codebase).

Checking `test/features/dice/dice_screen_test.dart` to confirm scope is not needed
here — even with just two instances, the duplication is worth flagging.

**Severity: Important** — two identical classes to keep in sync; any interface
change to `SoundPlayer` must be applied in both files.

#### 8. `app_router_test.dart` — `_harness` duplicated with minor variations

`test/app_router_test.dart` and `test/features/splash/splash_screen_test.dart`
each define a private `_harness` function that wires the same set of providers
(`HistoryRepository`, `LastDiceConfigPreference`, `AppSettingsPreference`,
`AudioController`, `HapticController`, `DiceController`) and returns a
`MaterialApp.router`. The two versions differ only in whether `AppSettingsPreference`
is exposed as a `Provider` (splash version does; router test does not). A shared
`AppHarness` helper in `test/helpers/` would reduce this duplication and make
future provider additions a single-site change.

**Severity: Suggestion** — acceptable for now but worth tracking.

#### 9. `retro_tab_bar.dart` — `_TabSpec` value class is thin glue (lines 63–67)

```dart
class _TabSpec {
  const _TabSpec({required this.label, required this.matrix});
  final String label;
  final List<List<int>> matrix;
}
```

`_TabSpec` is constructed in a `final items = <_TabSpec>[...]` list and immediately
destructured inside the loop. It is never stored, returned, or passed anywhere else.
A simple `(label, matrix)` record literal (Dart 3 records) or even a plain
two-element local would be more idiomatic and would eliminate the class entirely.
Since the project targets Dart `^3.12.0`, records are available.

However, the class is private, 5 lines total, and the intent is clear. This is a
minor style preference, not a YAGNI violation.

**Severity: Suggestion** — could be a Dart record `({String label, List<List<int>> matrix})`.

#### 10. `app_info.dart` — `kStudioName` constant is likely unnecessary (line 8)

```dart
const String kStudioName = 'am2 studios';
```

`kStudioName` is used in exactly one place: the splash footer interpolation
`'$kAppVersion · $kStudioName'`. The studio name is a proper noun that will never
be internationalized and is trivially inlined. Extracting it as a top-level constant
in a separate file adds indirection for no benefit — a future reader must navigate
to `app_info.dart` to learn it is just the literal string "am2 studios".

`kAppVersion` earns its extraction: it is the single source of truth for a value
that will change per release and is documented to be swapped for `package_info_plus`
in E15. `kStudioName` has no such rationale.

**Severity: Suggestion** — inline `'am2 studios'` at the splash call site and
remove `kStudioName`.

---

### Code to Remove

| File | Lines | Reason | Estimated LOC reduction |
|---|---|---|---|
| `lib/features/splash/splash_screen.dart` | 153–167 (`splashDieMatrix`) | Duplicate of `_iconDice` in `retro_tab_bar.dart` | −15 |
| `lib/core/app_info.dart` | 8 (`kStudioName`) + doc | YAGNI; inline at call site | −3 |
| `test/app_router_test.dart` | 23–32 (`_NoopSoundPlayer`) | Duplicate of same class in `splash_screen_test.dart` | −10 (after extraction) |
| `test/features/splash/splash_screen_test.dart` | 21–30 (`_NoopSoundPlayer`) | Move to shared test helper | −10 (after extraction) |

---

### Simplification Recommendations

1. **Extract the d6 matrix to a shared location and delete `splashDieMatrix`**
   - Current: `splashDieMatrix` in `splash_screen.dart` (exported, `@visibleForTesting`)
     and `_iconDice` in `retro_tab_bar.dart` (private) are identical.
   - Proposed: Promote `_iconDice` to `lib/shared/widgets/pixel_icon.dart` or a new
     `lib/shared/widgets/pixel_matrices.dart` as a `const` named export, then import
     it in both `retro_tab_bar.dart` and `splash_screen.dart`. Remove `splashDieMatrix`.
   - Impact: −15 LOC, eliminates silent divergence risk.

2. **Fix the third color in `splash_screen.dart`**
   - Current: `color: const Color(0xFF888888)` for COCU microcopy.
   - Proposed: Either use `_ink` (the existing black constant already in scope) and
     let font size carry the visual hierarchy, or add `static const Color _inkMuted =
     Color(0xFF888888)` with an explicit comment: "deliberate palette-rule exception
     for COCU microcopy — approved in E09 design review."
   - Impact: Brings code into alignment with the documented palette rule or makes the
     intentional violation explicit and reviewable. 0 net LOC change, but high clarity gain.

3. **Extract `_NoopSoundPlayer` to a test helper**
   - Current: Two identical implementations across two test files.
   - Proposed: `test/helpers/noop_sound_player.dart` with a single definition,
     imported by both test files.
   - Impact: −10 LOC, single place to update when `SoundPlayer` interface changes.

4. **Remove `kStudioName` from `app_info.dart`; inline at call site**
   - Current: Constant declared in a separate file, imported and interpolated.
   - Proposed: `'$kAppVersion · am2 studios'` directly in `splash_screen.dart`.
   - Impact: −3 LOC, removes an indirection that adds no value.

5. **Remove constructor doc-comments from the four empty route data classes**
   - Current: `/// Creates a [DiceBranch].` etc. on trivially obvious constructors.
   - Proposed: Delete. The class name and its position in the annotation are sufficient.
   - Impact: −8 LOC (2 lines per class × 4 classes), cleaner file.

---

### YAGNI Violations

- **`splashDieMatrix` exported as `@visibleForTesting`** — the only reason to export
  this constant is if a test needs to assert on the matrix content. Tests currently
  do not do that (they assert on `find.byType(PixelIcon)`). The export is
  preemptive. The correct approach is to keep the matrix private (or shared via the
  recommended single-source export) and never export it directly from
  `splash_screen.dart`.

- **`kStudioName` as a named constant** — the studio name is not configurable, not
  versioned, not translated. Naming it as a "constant" implies future reuse or
  substitution that does not exist.

---

### What Is Already Minimal and Well-Done

- `AppShell` (6 lines of real code) is exactly right — thin wrapper, no logic.
- `_AppViewState` router-in-`initState` pattern is the canonical solution and is
  clean.
- The three stub screens are uniform, minimal, and correctly themed.
- `PixelIconPainter.shouldRepaint` is precise (checks `matrix`, `on`, `off`), not
  a blanket `return true`.
- `RetroTabBar` avoids index tracking in its own state — delegates entirely to
  `shell.currentIndex`. Clean.
- The `Theme` wrapper in `SplashScreen` is the right trade-off given `PixelIcon`'s
  API; the existing code comment explains it adequately.
- Test helpers (`_pump`, `_harness`) are consistent across files and keep test setup
  readable.
- `resolveLocale` in `app.dart` is a pure function, `@visibleForTesting`, and fully
  tested. Good.

---

### Final Assessment

**Total potential LOC reduction: ~5–7%** of E09-specific code
(primarily from eliminating the duplicate die matrix and collapsing the noop helper).

**Complexity score: Low** — the implementation is clean overall. The issues found
are small and localized.

**Recommended action: Minor tweaks only**

The two Important issues (duplicate die matrix, duplicate `_NoopSoundPlayer`) should
be fixed before merge because they create real maintenance risk. The third color
(`#888888`) should be resolved — either by aligning with the palette rule or by
documenting the exception explicitly, as the current code silently breaks a
documented project constraint. All Suggestions are optional improvements.

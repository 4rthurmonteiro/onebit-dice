---
title: "feat: redesign dice screen with tap-to-roll (Design C)"
type: feat
date: 2026-05-30
brainstorm: docs/brainstorm/2026-05-30-dice-screen-c-redesign-brainstorm-doc.md
epic: EPIC 8 — Feature: Home Screen / Rolagem
---

## ✨ feat: redesign dice screen with tap-to-roll (Design C) - Standard

## Overview

Invert the hierarchy of the **Roll** screen (`DiceScreen`). Today the screen
stacks 7 full-width type chips and pushes a full-width **ROLAR** button below the
fold. In **Design C**, the dice canvas becomes the **hero** and the **roll
control itself**: tapping anywhere on the dice area fires `controller.roll()`
(the existing tabletop/fast/drum animations are preserved). The dedicated
**ROLL** button is removed.

The controls collapse into a **thin bar** above the tab bar, on one row: a
compact **type field** `D20 ▾` on the left (opens a **bottom sheet** — Variant A,
a vertical list of the 7 types) and a compact **quantity stepper** `− N +`
(clamp `1..10`) on the right. The result keeps rendering through the existing
`DiceWidget` (faces + `TOTAL` + equation), centered in the hero canvas.

This is a **layout + interaction redesign** of EPIC 8. The roll engine,
animations, `DiceWidget`, `DiceController` side-effect order, and persistence are
deliberately **preserved**.

## Problem Statement / Motivation

- **The fold problem.** The current screen (`dice_screen.dart:30-71`) wraps
  everything in a `SingleChildScrollView` + `IntrinsicHeight` because the 7
  chips + stepper + full-width button don't fit comfortably; the primary action
  can land below the fold on short devices.
- **The dice should be the hero.** Design C gives the dado the protagonism and
  turns the largest area of the screen into the tap target (Fitts's law — the
  biggest, closest target).
- **Type selection is heavy.** Seven always-visible chips consume vertical space
  that the hero needs. A bottom sheet (Variant A — list) frees the main screen,
  is the most faithful 1-bit treatment (borders + inversion only), and gives each
  item a ≥44px touch target.

## Proposed Solution

Preserve the rendering/animation/controller layers; change **layout** and the
**way a type is chosen**.

1. **Canvas-as-button.** Wrap the centered `DiceWidget` in a
   `GestureDetector(behavior: HitTestBehavior.opaque)` that calls
   `controller.roll()`, with `Semantics(button: true, label: rollCanvasLabel)`.
2. **Tap hint until first roll.** Show `▸ TOQUE PARA ROLAR ◂` on the canvas only
   until the first roll of the session, then hide it permanently. Backed by a new
   session flag `DiceController.hasRolled` (NOT derived from `lastResult == null`,
   because `setType`/`setCount` clear `lastResult` — see
   `dice_controller.dart:91-112` — which would make the hint reappear).
3. **Bottom sheet (Variant A).** A vertical list of the 7 `DiceType`s, each row =
   pixel shape badge + label (`D20`) + sublabel (`N LADOS`); the current type is
   inverted (ink/paper) + pixel checkmark. Title `ESCOLHER DADO`, pixel drag
   handle, dismiss via tap-outside / drag-down / ✕.
4. **1-bit hatched scrim.** Custom checkerboard (4×4 black/white) barrier instead
   of the default translucent grey scrim — no grey, no alpha.
5. **Compact type field + stepper.** Repurpose `type_selector.dart` into the
   compact `{label} ▾` field that opens the sheet; tighten `quantity_selector.dart`
   from full-width (`spaceBetween`) to a snug `− N +` group (`mainAxisSize.min`).
6. **Preset sheet adopts the same flow.** Per the chosen decision (see
   _Dependencies & Risks_), `CreatePresetSheet` switches from the old chip grid to
   the same compact field + sheet, for one consistent type-picker UX app-wide.

### Decision: reentrancy guard (NEW — surfaced by flow analysis)

`roll()` is non-reentrant, and the brainstorm planned the debounce to live in
`RollButton` (E12) — **but this redesign deletes `RollButton`**, so a much larger,
easier-to-double-tap canvas would be left completely unguarded. On tabletop-slow
(~2500ms) every tap during the animation starts a new `roll()`: extra history
rows, overlapping audio, restarted animation. **Move the guard into
`DiceController`:** add `bool get isRolling`, set `true` at the **start** of
`roll()` and back to `false` in a `finally`; `roll()` early-returns if already
rolling. The canvas tap is ignored while `isRolling`. This keeps the logic
testable in the controller and is the natural home now that the button is gone.

### Decision: how the field + sheet are wired

`TypeSelector` (the field) keeps its existing public API — `selectedType` +
`onChanged(DiceType)` — and **encapsulates** opening the sheet on tap. This keeps
both call sites (`DiceScreen` and `CreatePresetSheet`) nearly unchanged: they
already pass `selectedType` + an `onChanged` callback. The field opens
`DiceTypeSheet`, and when a row is picked the sheet pops and the field forwards
the picked type to `onChanged`.

### Decision: shape badges (resolves brainstorm open question)

The mockup glyphs (`▲ ■ ◆ ◇ ⬠ ⬟ %`) are **not reliable** in the pixel fonts
(Silkscreen / Press Start 2P). Use the existing `PixelIcon` (`pixel_icon.dart`)
with a hand-authored `List<List<int>>` matrix per `DiceType` instead — crisp,
palette-aware, no font risk, and already test-covered as a pattern.

### Decision: hatched scrim implementation (resolves brainstorm open question)

Follow the existing crisp-pixel `CustomPainter` precedent (`_StripesPainter` in
`mac_window.dart:136-151`): a `HatchPainter` that fills a 4×4 checkerboard of
1px ink/paper cells with `canvas.drawRect` (no `drawLine`, no anti-aliasing).
Present it via a **custom `ModalRoute`** (or `showGeneralDialog`) with
`barrierColor: Colors.transparent`, so we own the barrier and paint the hatch
ourselves. Tap-outside and drag-down dismissal are wired manually (a
`GestureDetector` over the hatch pops; a vertical-drag handler on the drag handle
pops past a threshold). `showModalBottomSheet` is **not** suitable here because
it does not expose its barrier for custom painting.

**Critical (flow analysis):** the hatch must sit **above an opaque, dismissible
barrier inside the route** — a tap on the hatch must dismiss the sheet and must
**never** fall through to the canvas underneath and fire a roll. The barrier must
also carry the standard dismiss semantics for screen readers, and the hatch must
not become a focusable node. Appearance is a **hard cut** (no fade) — a fade
would require alpha, which violates the 2-color rule.

## Technical Considerations

- **Architecture.** State stays `setState` + `ChangeNotifier` + `provider`. The
  only model change is an in-memory `hasRolled` flag on `DiceController` — nothing
  new is persisted, so there is **no storage / Hive / ERD impact**.
- **Reentrancy.** `roll()` is `async` and explicitly **not reentrant**
  (`dice_controller.dart:32-35`). The canvas is now a much larger, easier-to-
  double-tap target. The redesign must not make double-roll easier than the old
  button did; see edge cases below. (E12 debounce is out of scope but the canvas
  should not regress.)
- **Palette rule.** Strictly 2 colors (ink/paper). The hatch scrim, badges,
  checkmark, drag handle, and ✕ are all pure ink/paper — no intermediate tone,
  no alpha.
- **Accessibility.** `Semantics(button)` on the hero canvas, the type field
  (with `value` = current type), and the stepper. All tap targets ≥44px. The hint
  text must not steal the canvas's button semantics (render it as a decorative
  child / `excludeSemantics`).
- **i18n.** 5 new keys in all 12 locales; template is `app_pt_BR.arb`
  (`l10n.yaml:2`). Run `flutter gen-l10n`.
- **Coverage.** `lib/main.dart` excluded; everything else must hit 100% line
  coverage — including the new painters (`HatchPainter`, badge matrices) and the
  sheet's dismissal branches.

## Implementation Plan (file-by-file)

### New files

- `lib/features/dice/widgets/dice_type_sheet.dart`
  - `DiceTypeSheet` (StatelessWidget) — the sheet body: `MacWindow`-styled panel,
    title `diceTypeSheetTitle` (`ESCOLHER DADO`), pixel drag handle, a `Column`
    of `_DiceTypeRow`s (one per `DiceType.values`), and a ✕ close affordance.
  - `_DiceTypeRow` — badge (`DiceTypeBadge`) + label + `diceTypeSidesLabel(sides)`
    sublabel; inverted (ink fill / paper text) when selected, with a pixel
    checkmark (reuse the `CheckmarkPainter` pattern from `language_picker.dart`).
    `Semantics(button, selected)`, min height 44.
  - `static Future<DiceType?> show(BuildContext, {required DiceType selected})`
    — pushes the custom hatched-barrier route and resolves to the picked type
    (or `null` when dismissed).
  - Exposed `@visibleForTesting` keys: `sheetKey`, `closeKey`, `barrierKey`,
    `dragHandleKey`.
- `lib/features/dice/widgets/dice_type_badge.dart`
  - `DiceTypeBadge` — maps each `DiceType` to a `List<List<int>>` matrix and
    renders it through `PixelIcon`. A single `const` map keeps all 7 matrices.
- `lib/shared/widgets/hatch_painter.dart`
  - `HatchPainter extends CustomPainter` — 4×4 ink/paper checkerboard tiled over
    the canvas with 1px `drawRect`s (mirrors `_StripesPainter`). Used as the
    sheet's barrier fill. `@visibleForTesting`.
  - (Plus the small private `ModalRoute`/`PopupRoute` subclass that hosts the
    barrier + bottom-aligned panel + slide-up transition, kept in
    `dice_type_sheet.dart`.)

### Modified files

- `lib/features/dice/dice_controller.dart`
  - Add `bool _hasRolled = false;` + `bool get hasRolled => _hasRolled;`
  - Set `_hasRolled = true;` at the **start** of `roll()` (so the hint clears the
    instant the user taps, not after the animation resolves).
  - Do **not** reset it in `setType`/`setCount`/`applyConfig` (session-scoped;
    in-memory only, never persisted; only a fresh controller / app restart
    resets it). Document the rationale in the doc comment.
  - Add the reentrancy guard: `bool _isRolling = false;` +
    `bool get isRolling => _isRolling;`; `roll()` early-returns when `_isRolling`,
    sets it `true` at the start and `false` in a `finally`.
- `lib/features/dice/dice_screen.dart`
  - Replace the scroll/IntrinsicHeight scaffold with: `Column` →
    `Expanded(hero canvas)` + thin control bar.
  - Hero canvas: `GestureDetector(opaque, onTap: ...)` that **ignores the tap
    while `controller.isRolling`**, otherwise calls `controller.roll()`.
    `Semantics(button: true, label: l10n.rollCanvasLabel, value: <current TOTAL>,
    liveRegion: true, explicitChildNodes: true)` wrapping the centered
    `DiceWidget`, so the result is announced after each roll and TOTAL/equation
    stay individually readable. Overlay the `rollTapHint` text when
    `!controller.hasRolled` (decorative, `ExcludeSemantics`). The in-between state
    `hasRolled == true && lastResult == null` (after a roll, then type/count
    change) shows bare `?` slots — no hint, no result.
  - Thin bar: `Row(mainAxisAlignment: spaceBetween)` → `TypeSelector` (field) +
    `QuantitySelector` (compact). Keep the `PixelDivider` above the bar.
  - Remove the `RollButton` import + usage. Decide wordmark header treatment
    (keep small or drop — leans toward dropping to maximize hero).
- `lib/features/dice/widgets/type_selector.dart`
  - Repurpose `TypeSelector` from the 7-chip `Wrap` into the compact field:
    `{selectedType.label} ▾` in a ≥44px bordered box; `Semantics(button: true,
    value: selectedType.label)`; on tap, `await DiceTypeSheet.show(...)` then
    `onChanged(picked)` if non-null. Public API (`selectedType`, `onChanged`)
    unchanged. Delete `_TypeChip`.
- `lib/features/dice/widgets/quantity_selector.dart`
  - Change the `Row` from `mainAxisAlignment.spaceBetween` to
    `mainAxisSize: MainAxisSize.min` with explicit gaps; shrink the count
    `fontSize` (40 → ~24) so it fits the thin bar. Keep 44×44 step buttons,
    clamp `1..10`, and the existing `Semantics`.
- `lib/features/presets/widgets/create_preset_sheet.dart`
  - No code change to the `TypeSelector(selectedType, onChanged)` call site
    (the field encapsulates the sheet) — verify the nested-modal flow (a sheet
    opening over the preset sheet) works and looks right.
- i18n — add to **all 12** `.arb` files, template `app_pt_BR.arb` first:
  - `rollTapHint` → `▸ TOQUE PARA ROLAR ◂`
  - `rollCanvasLabel` → semantic label for the tappable canvas (e.g. `Rolar dados`)
  - `diceTypeSheetTitle` → `ESCOLHER DADO`
  - `diceTypeFieldLabel` → semantic/label affordance for the type field
  - `diceTypeSidesLabel` → **ICU plural** keyed on **side count** (e.g. `20`, not
    dice quantity): `{count, plural, one{1 LADO} other{{count} LADOS}}`
    (placeholder `count: int`), so each locale's plural rules apply.
  - Run `flutter gen-l10n`.
- `docs/plan/progress.md` — append the redesign tasks under EPIC 8 (or a new
  "EPIC 8b — Dice Screen Redesign" block).

### Deleted files

- `lib/features/dice/widgets/roll_button.dart`
- `test/features/dice/widgets/roll_button_test.dart`

### Tests (target 100% line coverage)

- `test/features/dice/dice_controller_test.dart` — add: `hasRolled` is `false`
  initially; `true` after `roll()`; **stays `true`** after `setType` / `setCount`
  / `applyConfig`. Plus `isRolling`: a second `roll()` started before the first
  settles is a no-op (one history append, one audio, one haptic); `isRolling`
  returns to `false` afterward.
- `test/features/dice/dice_screen_test.dart` — rewrite: tap the canvas to roll
  (replace `find.byType(RollButton)`); hint visible initially and gone after the
  first roll; hint does not reappear after `setType`/`setCount`; tapping the field
  opens the sheet; stepper still works; remove the "ROLL label" test. Add: a tap
  during an in-flight roll does not start a second roll; selecting the current
  type closes the sheet without clearing the result; tapping the scrim dismisses
  the sheet without rolling.
- `test/features/dice/widgets/type_selector_test.dart` — rewrite for the field:
  renders `{label} ▾`, tap opens `DiceTypeSheet`, `Semantics(button, value)`.
- `test/features/dice/widgets/dice_type_sheet_test.dart` (new) — 7 rows in
  `DiceType.values` order; selected row inverted + checkmark; tapping a row
  forwards the type and pops; dismiss via ✕ / tap-outside (barrier) / drag-down;
  barrier renders the hatch (no translucent grey).
- `test/features/dice/widgets/dice_type_badge_test.dart` (new) — a badge per
  `DiceType`; `PixelIcon` present; painter coverage.
- `test/shared/widgets/hatch_painter_test.dart` (new) — `shouldRepaint` + a paint
  smoke test (CustomPaint pumped) for full branch coverage.
- `test/features/dice/widgets/quantity_selector_test.dart` — keep; add a check
  that the layout is compact (`mainAxisSize.min`) if asserting layout.
- `test/features/presets/widgets/create_preset_sheet_test.dart` — update: the
  type picker now opens a sheet instead of showing inline chips.

## Acceptance Criteria

- [ ] Tapping anywhere on the hero dice canvas triggers a roll (faces animate,
      `TOTAL`/equation appear), with the user's existing animation style.
- [ ] The full-width `RollButton` is gone; `roll_button.dart` + its test deleted.
- [ ] `▸ TOQUE PARA ROLAR ◂` shows before the first roll of the session and
      disappears permanently after it.
- [ ] The hint does **not** reappear after changing type or count post-roll.
- [ ] `DiceController.hasRolled` is `false` initially, `true` after `roll()`, and
      unaffected by `setType`/`setCount`/`applyConfig`.
- [ ] The type field shows `{currentType} ▾`, is ≥44px, and opens the bottom sheet.
- [ ] The sheet lists all 7 types in `DiceType.values` order, each with a pixel
      badge, label, and `N LADOS` sublabel; the current type is inverted + has a
      pixel checkmark.
- [ ] Selecting a type updates the field, persists via `setType`, and closes the
      sheet; the sheet also closes via ✕, tap-outside, and drag-down.
- [ ] The sheet scrim is a 1-bit 4×4 checkerboard hatch (no grey, no alpha,
      no anti-aliasing).
- [ ] The quantity stepper is a compact `− N +` group (clamp `1..10`), 44×44
      buttons, existing semantics intact.
- [ ] `CreatePresetSheet` uses the same field + sheet flow and still saves
      presets correctly.
- [ ] 5 new i18n keys exist in all 12 locales; `flutter gen-l10n` regenerated.
- [ ] Strict 2-color palette preserved everywhere; all tap targets ≥44px;
      `Semantics(button)` on canvas, field, and stepper.
- [ ] Rapid / double taps on the canvas produce exactly **one** roll until the
      current roll's side effects settle (one history append, one audio sequence,
      one haptic) — guarded by `DiceController.isRolling`.
- [ ] Tapping anywhere on the checkerboard scrim dismisses the sheet and **never**
      triggers a roll; the sheet also dismisses via drag-down, ✕, and Android back.
- [ ] Selecting the currently-checked type closes the sheet **without** clearing
      the on-screen result (`setType` no-ops).
- [ ] Screen reader announces the canvas as a single roll button and announces the
      new total after each roll; the type field exposes the current type as its
      value; the stepper exposes value + disabled-at-clamp state.
- [ ] Each type row, the type field, and both stepper buttons keep ≥44px touch
      targets in the new thin bar.
- [ ] No `.notdef` / missing glyphs render for any badge, control symbol (`▾ − +`),
      or hint arrow (`▸ ◂`) in any of the 12 locales.
- [ ] The scrim and sheet appear/disappear with a hard cut (no alpha/grey fade).
- [ ] `flutter analyze` → 0 issues; `flutter test --coverage` → green at 100%
      line coverage.

## Edge Cases & Flow Notes

- **Rapid / double tap on the canvas.** Handled by the new
  `DiceController.isRolling` guard (see decision above) — the canvas ignores taps
  while a roll is in flight. Add a test for "tap during in-flight roll" on the
  slowest (tabletop) animation. Note: the slated E12 debounce lived in
  `RollButton`, which is being deleted, so this guard is now the only protection.
- **Glyph fallback.** Shape badges use `PixelIcon` matrices (no font glyphs). The
  control/hint symbols `▾ − + ▸ ◂` must be verified present in the pixel fonts or
  replaced with painted equivalents; a golden test should guard against `.notdef`
  boxes across locales.
- **Tapping the canvas while the sheet is open.** The hatched barrier must
  intercept taps so a roll cannot fire behind the sheet.
- **Selecting the already-selected type.** Sheet should still close cleanly;
  `setType` is a no-op (`dice_controller.dart:91`), so no spurious persist/clear.
- **App restart.** `hasRolled` resets (in-memory) → the hint shows again on next
  cold start even if a last config was restored. Confirm this is intended (it is:
  "reset apenas em nova sessão").
- **Restored last config + hint.** On launch with a restored type/count, the hint
  still shows until the first roll (no roll has happened this session).
- **Screen reader on the giant canvas.** The canvas exposes a single
  button action; the decorative hint is excluded from semantics so it isn't read
  as a separate node.

- **Sheet open during an in-flight animation.** The user can open the sheet
  mid-animation; the scrim covers the canvas so no roll can fire behind it. If
  they then change type, `setType` clears `lastResult` and the animation stops —
  acceptable; add a test.
- **Preset arrival.** `presets_screen` calls `applyConfig` + navigates without
  auto-rolling; on a fresh session the hint shows (correct — the preset is
  "ready to roll", `applyConfig` doesn't touch `hasRolled`).

_(All of the above were confirmed/added from the `user-flow-analysis-agent` pass
that ran during planning.)_

## Success Metrics

- The primary action (roll) is reachable without scrolling on the smallest
  supported device — the hero canvas fills the area above a single-row control bar.
- No increase in accidental double-rolls vs. the button baseline.
- Type selection reachable in ≤2 taps (open sheet → pick).

## Dependencies & Risks

- **Decision taken:** repurpose `type_selector.dart` into the compact field **and**
  migrate `CreatePresetSheet` to the same field + sheet flow (consistent UX
  app-wide). Risk: preset-sheet behavior + its test change; mitigated by keeping
  the field's public API identical.
- **Custom modal route.** Owning the barrier (for the hatch) means hand-wiring
  tap-outside + drag-down dismissal and a slide transition — more surface to test
  than `showModalBottomSheet`. Mitigation: small route, explicit
  `@visibleForTesting` keys, dismissal-branch tests.
- **Badge glyphs.** Mitigated by using `PixelIcon` matrices instead of font
  glyphs.
- **Coverage on painters.** New `CustomPainter`s need pumped-paint tests to hit
  `paint`/`shouldRepaint`.
- **No persistence/ERD change** — `hasRolled` is in-memory; `DiceType` ordering is
  untouched (the enum reorder warning in `dice_type.dart:7-9` is not triggered).

## References & Research

- Brainstorm: `docs/brainstorm/2026-05-30-dice-screen-c-redesign-brainstorm-doc.md`
- Screen to redesign: `lib/features/dice/dice_screen.dart:30-71`
- Controller (`roll`/`setType`/`setCount`/`applyConfig`, non-reentrancy note):
  `lib/features/dice/dice_controller.dart:91-151`
- Field source (to repurpose): `lib/features/dice/widgets/type_selector.dart`
- Stepper source (to compact): `lib/features/dice/widgets/quantity_selector.dart`
- Result widget (reused as hero): `lib/features/dice/widgets/dice_widget.dart`
- Crisp 1-bit hatch precedent: `lib/shared/widgets/mac_window.dart:136-177`
- Pixel-matrix badge mechanism: `lib/shared/widgets/pixel_icon.dart`
- List-row + checkmark analog: `lib/features/settings/widgets/language_picker.dart`
- Existing sheet pattern (`showModalBottomSheet` + `MacWindow`):
  `lib/features/presets/widgets/create_preset_sheet.dart`
- i18n template + config: `lib/l10n/app_pt_BR.arb`, `l10n.yaml`
- Task tracker / epic: `docs/plan/progress.md:123-133` (EPIC 8)

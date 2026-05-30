# Architecture Review — Tap-to-Roll Dice Screen Redesign (Design C)

**Project:** `onebit_dice` (single-package Flutter app)
**Branch:** `feat/redesign`
**Plan:** `docs/plan/2026-05-30-feat-dice-screen-tap-to-roll-redesign-plan.md`
**Stack detected:** Flutter / Dart `^3.12.0`, state via `setState` + `ChangeNotifier` + `package:provider` (DI only), `very_good_analysis` lints, 100% line-coverage gate. Layers: `core/` (services / models / storage), `features/` (feature slices), `shared/` (reusable UI). Rule of record: presentation must not import data directly; strict 2-color (ink/paper) palette.

---

## Layer Separation

The codebase models a 3-tier layering inside one package: `core/` (data + services + models + theme), `features/` (presentation), `shared/` (reusable UI). I scanned every import in the changed/new files plus the global graph.

**Global invariants verified clean:**
- `lib/shared/**` imports nothing from `features/**` or `core/storage/**` (shared stays portable). Confirmed by grep — `NONE`.
- `lib/core/**` imports nothing from `features/**` or `shared/**` (lowest layer stays independent). Confirmed — `NONE`.

**Changed-file scan (presentation must not touch data directly):**

| File | Cross-layer imports | Verdict |
| --- | --- | --- |
| `lib/features/dice/dice_controller.dart` | `core/audio`, `core/haptic`, `core/models`, `core/storage`, `shared/utils` | Clean — controller is the presentation layer's seam to data; it talks to repositories/services, never the UI to a data source. |
| `lib/features/dice/dice_screen.dart` | `core/i18n`, `core/theme`, `features/dice/*`, `shared/widgets/pixel_divider` | Clean — screen reads `DiceController` via `context.watch`; no data-source access. |
| `lib/features/dice/widgets/type_selector.dart` | `core/i18n`, `core/models/dice_type`, `core/theme`, `features/dice/widgets/*`, `shared/widgets/pixel_icon` | Clean — `DiceType` is a `core/models` enum (domain model), not a data source. |
| `lib/features/dice/widgets/quantity_selector.dart` | `core/i18n`, `core/theme` | Clean. |
| `lib/features/dice/widgets/dice_type_sheet.dart` | `core/i18n`, `core/models/dice_type`, `core/theme`, `features/dice/widgets/dice_type_badge`, `shared/widgets/{hatch_painter,mac_window,pixel_icon}` | Clean — presentation composing shared UI + a core model. |
| `lib/features/dice/widgets/dice_type_badge.dart` | `core/models/dice_type`, `shared/widgets/pixel_icon` | Clean. |
| `lib/shared/widgets/hatch_painter.dart` | `flutter/material` only | Clean — zero project imports; maximally portable, exactly what a `shared/` primitive should be. |
| `lib/features/presets/widgets/create_preset_sheet.dart` | `core/*`, `features/dice/widgets/{type_selector,quantity_selector}`, `shared/widgets/*` | Cross-feature import (presets → dice). See Dependency Direction. |

**Violations found: 0** (no presentation→data-source import; no `shared`→`features`/`data` import; no `core`→`features`/`shared` import).

---

## State Management Assessment

### `DiceController` (the only state unit touched)

The redesign adds two in-memory session flags — `hasRolled` and `isRolling` — and a reentrancy guard. Assessed against VGV `ChangeNotifier` conventions:

- **Reentrancy guard placement — CORRECT, and the right call.** `isRolling` is set `true` at the start of `roll()` and reset in a `finally`; `roll()` early-returns while in flight (`dice_controller.dart:161-183`). This belongs in the controller, not the widget. It is the single source of truth for "a roll is in flight," it is reachable by both tap entry points and any future caller (e.g. a restored preset auto-roll), and it is unit-testable without pumping a widget. Putting the guard in `DiceScreen`'s `GestureDetector` would have leaked roll-lifecycle state into the view and left every other caller unprotected. The doc comment (`:32-37`, `:102-107`) correctly records why the guard moved here from the deleted `RollButton`. Verdict: **correct.**

- **`finally` correctness.** `_isRolling` resets even if `_history.append` throws — important given the UI-first side-effect order documented at `:20-30`. A thrown append still releases the guard, so the canvas never wedges in a permanently-rolling state. Good.

- **`hasRolled` semantics — CORRECT.** Set `true` at the very start of `roll()` (`:164`) so the hint clears on tap, not on animation-settle. Deliberately *not* reset by `setType`/`setCount`/`applyConfig`, which is the correct decision: those clear `lastResult`, and deriving the hint from `lastResult == null` would make it flicker back after every config change. The flag is session-scoped, in-memory, never persisted — no storage/ERD impact, matching the plan. Rationale is documented at `:93-100`.

- **State exposure / immutability.** State is exposed through read-only getters (`selectedType`, `count`, `lastResult`, `hasRolled`, `isRolling`); mutation only via intent methods (`roll`, `setType`, `setCount`, `applyConfig`). `RollResult` is constructed fresh each roll rather than mutated. No mutable state object is leaked. Consistent with VGV `ChangeNotifier` practice.

- **`notifyListeners` correctness.** `roll()` notifies once after computing `lastResult`/flipping flags, *then* runs side effects — so the UI repaints with the new result and `isRolling == true` in the same frame, and the canvas's `onTap: controller.isRolling ? null : controller.roll` (`dice_screen.dart:50`) immediately reflects the guard. One subtlety worth recording: `roll()` does **not** call `notifyListeners()` again when `_isRolling` flips back to `false` in `finally`. That is acceptable — re-enabling the tap does not need its own rebuild (the guard window is brief and any later notification recomputes it), and suppressing the extra notify avoids a spurious rebuild. Not a defect; noting it so a future reader does not "fix" it into an extra rebuild.

- **Business logic location.** All roll logic (RNG, result assembly, history append, audio, haptic, persistence ordering) stays in the controller. `DiceScreen` only computes a display `total` via fold for the semantics `value` (`dice_screen.dart:28-32`) — presentation-only derivation, fine. No business logic leaked into widgets or callbacks.

- **Naming.** `DiceController`, `hasRolled`, `isRolling`, `roll`, `setType`, `setCount`, `applyConfig` are descriptive and intent-revealing. No generic `Manager`/`Handler` smell.

**Verdict: correct.** No issues.

### Widget-local state

- `_CreatePresetSheetState` and `_DragHandleState` use `setState` appropriately for ephemeral form/gesture state. `_DragHandleState` guards against double-firing dismissal with a `_dismissed` latch (`dice_type_sheet.dart:196,205-210`) — correct, prevents a second `pop` if drag updates keep arriving after threshold.

---

## Dependency Direction

The intended graph is one-way: `features` (presentation) → `core`/`shared`; `shared` → nothing project-specific; `core` → nothing higher. Verified:

- **No circular dependencies.** `shared/widgets/hatch_painter.dart` depends only on `flutter/material`; `pixel_icon`, `mac_window` depend only on `core/theme`. No `shared`→`features` edge exists, so the new `dice_type_sheet → shared/hatch_painter` and `→ shared/mac_window` edges cannot close a cycle. Confirmed by grep.
- **No reverse (data→presentation) edges.** `core/` imports nothing from `features`/`shared`. Confirmed.
- **`HatchPainter` placement is correct.** It is palette-driven (`ink`/`paper` passed in, zero project imports) and is a direct analog of the existing `_StripesPainter`/`_CloseGlyphPainter` crisp-pixel painters in `shared/widgets/mac_window.dart`. A reusable, feature-agnostic 1-bit primitive belongs in `shared/`, not in `features/dice`. Had it been left in the dice feature, the next consumer (e.g. a settings or history modal wanting the same scrim) would have had to reach into `features/dice` — a cross-feature edge. Putting it in `shared/` pre-empts that. **Right layer.**

### Cross-feature coupling: `presets` → `dice` (IMPORTANT — design seam to confirm, not a regression)

`create_preset_sheet.dart` imports `features/dice/widgets/type_selector.dart` and `quantity_selector.dart`. This redesign does **not** introduce the edge — it already existed before this change, and `presets_screen.dart:8` already imports `features/dice/dice_controller.dart`. The redesign keeps the same `TypeSelector(selectedType, onChanged)` call site (`create_preset_sheet.dart:133-136`), so the coupling is unchanged in shape while `TypeSelector`'s internals now also pull in `dice_type_badge` and open `DiceTypeSheet`.

Assessment: **acceptable, but it is the one structural smell worth a conscious decision.** `TypeSelector`, `QuantitySelector`, and now `DiceTypeSheet`/`DiceTypeBadge` are genuinely reusable type/quantity-picker UI shared by two features (dice + presets), yet they live under `features/dice/widgets/`. By the project's own rule — "`shared/` = reusable UI and utilities used by multiple features" — these four widgets now meet the definition of shared UI. The cleaner long-term home is `lib/shared/widgets/` (or a `shared/dice_picker/` group), which would erase the `presets → dice` import entirely and make `dice` and `presets` siblings that both depend only on `shared` + `core`.

Why it is not a blocker here: (1) the coupling predates this PR and migrating it is out of scope for a layout/interaction redesign; (2) the dependency direction is still acyclic (`presets → dice → core`, and `dice` does not import `presets`); (3) the shared model (`DiceType`) and the truly-generic primitive (`HatchPainter`) were placed correctly. Flagging it so the team records the decision rather than letting the dice-as-de-facto-shared-widgets pattern grow silently.

- **Direction violations: 0** (no reverse, no circular).
- **Pre-existing cross-feature edges (unchanged by this PR):** `presets → dice` (type/quantity selectors, controller), `dice → settings` (`dice_animator → animation_settings_controller`). Noted for context; not introduced here.

---

## Package Structure

Single-package app, so this reduces to file/folder placement and responsibility:

- `lib/shared/widgets/hatch_painter.dart` — single responsibility (one `CustomPainter`), zero feature deps, `@visibleForTesting cell` exposed for the painter test. Correct location and shape.
- `lib/features/dice/widgets/dice_type_badge.dart` — one widget, one `const` matrix map keyed by `DiceType`, `@visibleForTesting matrices`. Cohesive, dice-specific (maps a dice-domain enum to glyphs), correctly under the dice feature.
- `lib/features/dice/widgets/dice_type_sheet.dart` — sheet body + private `_DiceTypeRow`, `_DragHandle`, and the private `_DiceTypeSheetRoute` (`PopupRoute`). Keeping the route private and co-located with the sheet is good encapsulation; nothing outside needs it. Test keys (`sheetKey`, `barrierKey`, `dragHandleKey`) exposed via `@visibleForTesting`.
- `type_selector.dart` / `quantity_selector.dart` — repurposed in place, public API (`selectedType` + `onChanged`, `count` + `onChanged`) preserved, so the presets call site needs no change. Good API stability (placement caveat under Cross-feature coupling above).
- No new package manifests, lint configs, or test dirs required (single package). The plan commits matching tests for each new file to hold the 100% coverage gate; existence of those tests is a quality-gate item, out of scope for this architecture pass.

**Structure verdict: complete.** Every new file has a single, clear responsibility and is placed in the layer its dependencies imply — with the one open question being whether the dice "picker" widgets should graduate to `shared/`.

---

## Additional Architectural Notes (non-blocking)

- **Barrier cannot fall through to the canvas — verified at the architecture level.** `_DiceTypeSheetRoute` is a `PopupRoute` with `barrierColor = null` and an opaque, full-bleed `GestureDetector(behavior: HitTestBehavior.opaque, onTap: dismiss)` painting the `HatchPainter` (`dice_type_sheet.dart:233-269`). Because the route sits above `DiceScreen` in the navigator and the barrier hit-test is opaque, a tap on the hatch is consumed by `dismiss`, not the canvas underneath. The plan's "must never fire a roll behind the sheet" invariant is satisfied structurally. The barrier also carries `Semantics(button: true, label: actionClose)`, giving screen readers the dismiss affordance.
- **`Theme`/`l10n` access inside `buildPage`.** `_DiceTypeSheetRoute.buildPage` reads `Theme.of(context).extension<OneBitColors>()!` and `context.l10n`. Since the route is pushed onto the app's `Navigator` (below `MaterialApp`/theme/localizations), this resolves correctly — no inherited-widget scoping problem.
- **`Duration.zero` transition** keeps the hard-cut appearance (no alpha fade) — consistent with the palette rule; an architecture-neutral observation that the route honors the 2-color constraint rather than reaching for an animated opacity.

---

## Verdict

**Architecture is clean — ready to merge from a structural standpoint.**

- **Critical: 0.**
- **Important: 1** — `presets → dice` cross-feature coupling: the dice picker widgets (`TypeSelector`, `QuantitySelector`, `DiceTypeSheet`, `DiceTypeBadge`) are now shared by two features but live under `features/dice/`. Pre-existing and out of scope here, but the team should consciously decide whether to promote them to `shared/` before the pattern spreads.
- **Suggestions: 1** — consider promoting the four dice-picker widgets to `lib/shared/widgets/` (or a `shared/` group) to erase the cross-feature edge and let `dice`/`presets` depend only on `shared` + `core`.

Layer separation, dependency direction, controller-owned reentrancy/`hasRolled` state, `HatchPainter` placement in `shared/`, immutability, and provider wiring (`ChangeNotifierProvider<DiceController>` at the app root reading repos/services from `Provider`s — `app.dart:81-88`) are all correct. No blocking violations.

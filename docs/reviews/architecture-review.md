# Architecture Review — E09 (App Shell + Splash)

Branch: `feat/e09-navegacao`
Plan: `docs/plan/2026-05-26-feat-e09-app-shell-and-splash-plan.md`
Reviewer: architecture-review agent
Date: 2026-05-26

## Layer Separation

The project's declared layers (per `CLAUDE.md`):

- `lib/core/` — app-wide services (analytics, audio, haptic, storage, theme, i18n)
- `lib/features/` — feature slices (presentation + per-feature controllers)
- `lib/shared/` — reusable UI/utilities consumed by multiple features
- `lib/app.dart`, `lib/app_router.dart`, `lib/main.dart` — composition root (top of the tree, may depend on everything below)

Dependency direction enforced: composition root → features → (shared | core); shared → core; core → nothing inside the app.

**Scan results (full `lib/` tree, focused on E09-added files):**

- `core/` imports `features/`: **0 violations**.
- `core/` imports `shared/`: **0 violations**.
- `shared/` imports `features/`: **0 violations**.
- `features/<X>/` imports `features/<Y>/` (cross-feature): **0 violations**. The only intra-`features/` imports are inside the dice slice (`dice/dice_screen.dart` importing its own `dice/widgets/*` and `dice/dice_controller.dart`) — that is intra-feature, not cross-feature.
- `shared/widgets/*` imports `core/i18n` and `core/theme` (`shared/widgets/retro_tab_bar.dart:3-5`, `shared/widgets/pixel_icon.dart:2`, `shared/widgets/pixel_divider.dart:2`, `shared/widgets/mac_*.dart`). Per project convention this is acceptable — `core/theme` and `core/i18n` are app-wide infrastructure, not a presentation layer above shared widgets. Same pattern already existed pre-E09. No change required, but worth noting that if `shared/` were ever extracted into a standalone package it would need either an interface abstraction or the theme/i18n primitives would have to be re-homed.

**Conclusion: layer separation is clean.** Every checked file respects the declared boundaries.

## State Management Assessment

Per `CLAUDE.md`, the stack is `setState` + `ChangeNotifier` + `package:provider` (DI only). No Bloc/Riverpod.

- **`_AppView` (`lib/app.dart:79-107`)**: Correct. `StatefulWidget` owning a `late final GoRouter _router = buildAppRouter();` initialized once. Comment on lines 87-90 explicitly documents why this is in `initState`-equivalent (field initializer) and not in `build`. This is the right pattern — palette / locale `notifyListeners` rebuild `_AppView.build`, but `_router` is not recreated, so navigation state survives. `context.watch<ThemeProvider>()` / `context.watch<LocaleController>()` correctly drive theme & locale rebuilds without touching the router.

- **`SplashScreen` (`lib/features/splash/splash_screen.dart`)**: Correct. `StatefulWidget` with a single `Timer?` field, scheduled in `initState`, cancelled in `dispose`. `mounted` check before `const DiceRoute().go(context);` guards against navigation after unmount. `splashDuration` exposed via `@visibleForTesting` for deterministic tests. The local `Theme(...)` wrap on line 58 with a hard-coded Mac Classic palette is a deliberate, documented choice (see comment lines 56-58) — keeps the splash from depending on persisted user state. This is sound.

- **`AppShell` (`lib/features/shell/app_shell.dart`)**: Correct. Pure `StatelessWidget`; receives `StatefulNavigationShell` from the router and renders it as the body. No business logic, no state. Tab state is owned by `go_router`'s shell, which is the right place.

- **`RetroTabBar` (`lib/shared/widgets/retro_tab_bar.dart`)**: Correct. `StatelessWidget`, reads colors from `Theme.of(context).extension<OneBitColors>()`, drives navigation via `shell.goBranch(i, initialLocation: i == shell.currentIndex)` — the canonical pattern for "re-tap active tab resets that branch" with `StatefulShellRoute`. No state stored in the widget.

- **`PixelIcon` / `PixelIconPainter` (`lib/shared/widgets/pixel_icon.dart`)**: Correct. Pure presentation. Painter `shouldRepaint` covers matrix and color changes, so palette swaps repaint automatically.

- **Stubs (`history_screen.dart`, `presets_screen.dart`, `settings_screen.dart`)**: Correct. `StatelessWidget`, theme-aware, l10n-aware, no state. Identical shape — flag for low-cost dedup if a fourth "coming soon" stub ever appears, but with three near-clones it's fine to keep them duplicated rather than introducing a `ComingSoonScreen` abstraction.

No business logic leaks into widgets, no UI-side data fetching, no mutable state on the wrong widget.

## Dependency Direction

Verified import graph for E09-touched files:

- `lib/app.dart` → `app_router.dart`, `core/*`, `features/dice/dice_controller.dart`, `l10n/*`, third-party. Composition root, correct.
- `lib/app_router.dart` → `features/{dice,history,presets,settings,shell,splash}` + `go_router`. Composition over features, correct.
- `features/splash/splash_screen.dart` → `app_router.dart` (for `const DiceRoute().go(context)`), `core/{app_info,i18n,theme}`, `shared/widgets/{pixel_divider,pixel_icon}`. **Note**: importing `app_router.dart` from inside a feature is unavoidable with `go_router_builder` typed routes (the route classes are the public navigation API) and is the typed-route pattern's intended use. Not a violation.
- `features/shell/app_shell.dart` → `shared/widgets/retro_tab_bar.dart` + `go_router`. Correct.
- `features/history|presets|settings/*_screen.dart` → only `core/i18n` and `core/theme`. Correct.
- `shared/widgets/*` → `core/{i18n,theme}` only. Correct.

**Circular dependencies: none detected.** `core/` does not depend on `shared/`, `features/`, or the composition root.

`MultiProvider` in `App.build` sits above `_AppView`, so every provider is in scope inside any route built by the router — verified by reading `lib/app.dart:53-75` followed by `MaterialApp.router` on line 97. This is the right placement.

## Package Structure

The project is a single-package Flutter app (not a multi-package monorepo), so VGV's multi-package layered-architecture checklist (per-package `pubspec.yaml`, `analysis_options.yaml`, etc.) doesn't apply. Within the single package:

- **Feature folders are well-scoped.** Each new `features/<slice>/` contains exactly the files E09 needed:
  - `shell/` — `app_shell.dart`
  - `splash/` — `splash_screen.dart`
  - `history/`, `presets/`, `settings/` — each has `<feature>_screen.dart` + empty `widgets/` placeholder dir (pre-existing). No grab-bag packages.
- **`shared/widgets/` additions** (`pixel_icon.dart`, `retro_tab_bar.dart`) are correctly placed: `PixelIcon` is genuinely reused (splash, tab bar; future use likely in dice/history rendering) and `RetroTabBar` is feature-agnostic infrastructure used by `AppShell`. Both belong in `shared/`.
- **`core/app_info.dart`** is a single-purpose file (constants for version + studio name) and is consistent with how other small core concerns are organized (e.g. `core/audio/`, `core/haptic/` each have their own folder while small leaf files like `app_info.dart` sit at `core/`'s root). No restructuring needed; if `app_info.dart` ever grows past constants, promote it to `core/app_info/` with `app_info.dart` inside.
- **Routing at top of `lib/`** (`app_router.dart` + generated `app_router.g.dart`) is correct — routing is composition, not a feature. Matches the plan's stated layout (plan section "Estrutura nova", lines 35-60).
- **Memory rules verified**:
  - `StatefulShellRoute.indexedStack` used (not manual `IndexedStack`) — `feedback_no_indexed_stack_use_go_router` respected.
  - No underscore-prefixed folder names (`shell/`, `splash/`, not `_shell/` / `_internal/`) — `feedback_no_underscore_prefixed_folders` respected.

## Verdict

Architecture is clean. Ready to merge.

- 0 critical issues
- 0 important issues
- 1 informational note: `shared/widgets/*` imports `core/{theme,i18n}`. Acceptable per project conventions; would need re-homing only if `shared/` were ever extracted to a standalone package.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/history/history_screen.dart';
import 'package:onebit_dice/features/presets/presets_screen.dart';
import 'package:onebit_dice/features/settings/settings_screen.dart';
import 'package:onebit_dice/features/shell/app_shell.dart';
import 'package:onebit_dice/features/splash/splash_screen.dart';

part 'app_router.g.dart';

/// Builds the [GoRouter] that owns the entire navigation stack.
///
/// Single source of truth: created exactly once at app startup. Hand it to
/// `MaterialApp.router(routerConfig: ...)` and never rebuild it — palette
/// and locale changes must not reset the navigation tree.
GoRouter buildAppRouter() =>
    GoRouter(initialLocation: SplashRoute.path, routes: $appRoutes);

/// Top-level route for the initial splash screen.
@TypedGoRoute<SplashRoute>(path: SplashRoute.path)
class SplashRoute extends GoRouteData with $SplashRoute {
  /// Creates a [SplashRoute].
  const SplashRoute();

  /// Canonical path for the splash route.
  static const String path = '/';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: SplashScreen());
}

/// Stateful shell hosting the four bottom-tab branches.
@TypedStatefulShellRoute<MainShellRoute>(
  branches: [
    TypedStatefulShellBranch<DiceBranch>(
      routes: [TypedGoRoute<DiceRoute>(path: DiceRoute.path)],
    ),
    TypedStatefulShellBranch<HistoryBranch>(
      routes: [TypedGoRoute<HistoryRoute>(path: HistoryRoute.path)],
    ),
    TypedStatefulShellBranch<PresetsBranch>(
      routes: [TypedGoRoute<PresetsRoute>(path: PresetsRoute.path)],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: [TypedGoRoute<SettingsRoute>(path: SettingsRoute.path)],
    ),
  ],
)
class MainShellRoute extends StatefulShellRouteData {
  /// Creates a [MainShellRoute].
  const MainShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return AppShell(shell: navigationShell);
  }
}

/// Branch for the dice rolling tab.
class DiceBranch extends StatefulShellBranchData {
  /// Creates a [DiceBranch].
  const DiceBranch();
}

/// Branch for the history tab.
class HistoryBranch extends StatefulShellBranchData {
  /// Creates a [HistoryBranch].
  const HistoryBranch();
}

/// Branch for the presets / games tab.
class PresetsBranch extends StatefulShellBranchData {
  /// Creates a [PresetsBranch].
  const PresetsBranch();
}

/// Branch for the settings tab.
class SettingsBranch extends StatefulShellBranchData {
  /// Creates a [SettingsBranch].
  const SettingsBranch();
}

/// Dice rolling screen, branch index 0.
class DiceRoute extends GoRouteData with $DiceRoute {
  /// Creates a [DiceRoute].
  const DiceRoute();

  /// Canonical path for the dice screen.
  static const String path = '/dice';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: DiceScreen());
}

/// History screen, branch index 1.
class HistoryRoute extends GoRouteData with $HistoryRoute {
  /// Creates a [HistoryRoute].
  const HistoryRoute();

  /// Canonical path for the history screen.
  static const String path = '/history';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: HistoryScreen());
}

/// Presets / games screen, branch index 2.
class PresetsRoute extends GoRouteData with $PresetsRoute {
  /// Creates a [PresetsRoute].
  const PresetsRoute();

  /// Canonical path for the presets screen.
  static const String path = '/presets';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: PresetsScreen());
}

/// Settings screen, branch index 3.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates a [SettingsRoute].
  const SettingsRoute();

  /// Canonical path for the settings screen.
  static const String path = '/settings';

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      const NoTransitionPage(child: SettingsScreen());
}

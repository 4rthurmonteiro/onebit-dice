import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/shared/widgets/retro_tab_bar.dart';
import 'package:provider/provider.dart';

/// The persistent navigation shell hosting the four bottom-tab branches.
///
/// Built by `StatefulShellRoute.indexedStack` and handed the active
/// [shell] — renders that branch as the body and a [RetroTabBar] as the
/// bottom nav.
///
/// Owns the per-branch `screen_view` analytics: it logs the active branch on
/// first mount and again whenever the user switches tabs. `StatefulShellRoute`
/// keeps each branch alive in an `IndexedStack`, so the anchor screens never
/// re-run `initState` on a tab switch — tracking the shell's `currentIndex`
/// from here is the reliable seam for per-tab views.
class AppShell extends StatefulWidget {
  /// Creates an [AppShell] bound to the active [shell].
  const AppShell({required this.shell, super.key});

  /// The shell whose currently-active branch this widget renders.
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// `screen_view` name reported for each branch, indexed by branch position.
  /// Order mirrors the `StatefulShellRoute` branches in `app_router.dart`.
  static const List<String> _branchScreens = [
    'dice',
    'history',
    'presets',
    'settings',
  ];

  @override
  void initState() {
    super.initState();
    _logScreenView(widget.shell.currentIndex);
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shell.currentIndex != widget.shell.currentIndex) {
      _logScreenView(widget.shell.currentIndex);
    }
  }

  void _logScreenView(int index) {
    unawaited(
      context.read<AnalyticsService>().logScreenView(_branchScreens[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: RetroTabBar(shell: widget.shell),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/shared/widgets/retro_tab_bar.dart';

/// The persistent navigation shell hosting the four bottom-tab branches.
///
/// Built by `StatefulShellRoute.indexedStack` and handed the active
/// [shell] — renders that branch as the body and a [RetroTabBar] as the
/// bottom nav.
class AppShell extends StatelessWidget {
  /// Creates an [AppShell] bound to the active [shell].
  const AppShell({required this.shell, super.key});

  /// The shell whose currently-active branch this widget renders.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: RetroTabBar(shell: shell),
    );
  }
}

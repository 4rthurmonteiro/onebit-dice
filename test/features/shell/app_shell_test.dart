import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/shell/app_shell.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/retro_tab_bar.dart';

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () => setState(() => count++),
        child: Text('COUNT=$count'),
      ),
    ),
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/dice',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/dice', builder: (_, _) => const _Counter())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, _) => const Scaffold(body: Center(child: Text('H'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/presets',
              builder: (_, _) => const Scaffold(body: Center(child: Text('P'))),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Center(child: Text('S'))),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _harness(GoRouter router) {
  return MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    routerConfig: router,
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  group('AppShell', () {
    testWidgets('hosts RetroTabBar in bottomNavigationBar', (tester) async {
      await _pump(tester, _harness(_router()));

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(RetroTabBar), findsOneWidget);
      // RetroTabBar is set as bottomNavigationBar.
      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(AppShell),
          matching: find.byType(Scaffold).first,
        ),
      );
      expect(scaffold.bottomNavigationBar, isA<RetroTabBar>());
    });

    testWidgets('tap each tab navigates to that branch', (tester) async {
      await _pump(tester, _harness(_router()));

      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();
      expect(find.text('H'), findsOneWidget);

      await tester.tap(find.text('GAMES'));
      await tester.pumpAndSettle();
      expect(find.text('P'), findsOneWidget);

      await tester.tap(find.text('SETTINGS'));
      await tester.pumpAndSettle();
      expect(find.text('S'), findsOneWidget);

      await tester.tap(find.text('ROLL'));
      await tester.pumpAndSettle();
      expect(find.text('COUNT=0'), findsOneWidget);
    });

    testWidgets('branch state is preserved across tab switches', (
      tester,
    ) async {
      await _pump(tester, _harness(_router()));

      // Increment counter on the dice branch.
      await tester.tap(find.text('COUNT=0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('COUNT=1'));
      await tester.pumpAndSettle();
      expect(find.text('COUNT=2'), findsOneWidget);

      // Visit history, then come back.
      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();
      expect(find.text('H'), findsOneWidget);

      await tester.tap(find.text('ROLL'));
      await tester.pumpAndSettle();

      // Counter state survived.
      expect(find.text('COUNT=2'), findsOneWidget);
    });

    testWidgets('re-tap on the active tab keeps the branch state', (
      tester,
    ) async {
      await _pump(tester, _harness(_router()));
      await tester.tap(find.text('COUNT=0'));
      await tester.pumpAndSettle();
      expect(find.text('COUNT=1'), findsOneWidget);

      // Re-tap ROLL — since the branch has only one route, this is a no-op
      // navigation; state must remain.
      await tester.tap(find.text('ROLL'));
      await tester.pumpAndSettle();
      expect(find.text('COUNT=1'), findsOneWidget);
    });
  });
}

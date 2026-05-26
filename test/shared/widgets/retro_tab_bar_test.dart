import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';
import 'package:onebit_dice/shared/widgets/retro_tab_bar.dart';

class _Page extends StatelessWidget {
  const _Page(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

GoRouter _router() => GoRouter(
  initialLocation: '/dice',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => Scaffold(
        body: shell,
        bottomNavigationBar: RetroTabBar(shell: shell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/dice', builder: (_, _) => const _Page('DICE')),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, _) => const _Page('HISTORY'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/presets',
              builder: (_, _) => const _Page('PRESETS'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const _Page('SETTINGS'),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _harness(GoRouter router, {PaletteId id = PaletteId.macClassic}) {
  return MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(id)),
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
  group('RetroTabBar', () {
    testWidgets('renders 4 PixelIcons and 4 localized labels', (tester) async {
      await _pump(tester, _harness(_router()));

      expect(find.byType(PixelIcon), findsNWidgets(4));
      // Initial branch is /dice so its body text 'DICE' is also visible —
      // the four labels themselves are guaranteed to be exactly one each.
      expect(
        find.descendant(
          of: find.byType(RetroTabBar),
          matching: find.text('ROLL'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RetroTabBar),
          matching: find.text('HISTORY'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RetroTabBar),
          matching: find.text('GAMES'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RetroTabBar),
          matching: find.text('SETTINGS'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('active tab has inverted background and inverted icon', (
      tester,
    ) async {
      await _pump(tester, _harness(_router()));

      final palette = Palette.of(PaletteId.macClassic);
      // Active branch (DICE) — its PixelIcon should be inverted.
      final activeIcon = tester.widget<PixelIcon>(find.byType(PixelIcon).first);
      expect(activeIcon.inverted, isTrue);

      // The fourth tab (SETTINGS) is inactive — not inverted.
      final inactiveIcon = tester.widget<PixelIcon>(
        find.byType(PixelIcon).at(3),
      );
      expect(inactiveIcon.inverted, isFalse);

      // The active tab text uses paper (inverted on ink bg).
      final activeLabel = tester.widget<Text>(find.text('ROLL'));
      expect(activeLabel.style?.color, palette.paper);

      // Inactive tab text uses ink.
      final inactiveLabel = tester.widget<Text>(find.text('SETTINGS'));
      expect(inactiveLabel.style?.color, palette.ink);
    });

    testWidgets('tapping a tab navigates to that branch', (tester) async {
      final router = _router();
      await _pump(tester, _harness(router));

      await tester.tap(find.text('GAMES'));
      await tester.pumpAndSettle();

      expect(find.text('PRESETS'), findsOneWidget);

      // After navigation, GAMES is active and DICE is not.
      final gamesIcon = tester.widget<PixelIcon>(find.byType(PixelIcon).at(2));
      expect(gamesIcon.inverted, isTrue);
    });

    testWidgets('re-tapping the active tab does not throw', (tester) async {
      final router = _router();
      await _pump(tester, _harness(router));

      await tester.tap(find.text('ROLL'));
      await tester.pumpAndSettle();

      expect(find.text('DICE'), findsOneWidget);
    });

    testWidgets('each tab item exposes Semantics(button, selected, label)', (
      tester,
    ) async {
      await _pump(tester, _harness(_router()));

      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text('ROLL'),
            matching: find.byType(MergeSemantics),
          ),
        ),
        matchesSemantics(
          label: 'ROLL',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text('SETTINGS'),
            matching: find.byType(MergeSemantics),
          ),
        ),
        matchesSemantics(
          label: 'SETTINGS',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('top border uses palette ink', (tester) async {
      await _pump(tester, _harness(_router()));
      final palette = Palette.of(PaletteId.macClassic);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(RetroTabBar),
          matching: find.byType(DecoratedBox),
        ),
      );
      final deco = box.decoration as BoxDecoration;
      expect(deco.color, palette.paper);
      expect(deco.border?.top.color, palette.ink);
    });
  });
}

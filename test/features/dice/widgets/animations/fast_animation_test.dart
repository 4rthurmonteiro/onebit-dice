import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';
import 'package:onebit_dice/features/dice/widgets/animations/fast_animation.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

Iterable<int> _faces(WidgetTester tester) =>
    tester.widgetList<PipFace>(find.byType(PipFace)).map((p) => p.value);

void main() {
  group('FastAnimation', () {
    const duration = Duration(milliseconds: 100);

    testWidgets('renders the empty state when targetValues is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const FastAnimation(count: 2, targetValues: null, duration: duration),
        ),
      );
      expect(find.text('?'), findsNWidgets(2));
    });

    testWidgets('renders the supplied values', (tester) async {
      await tester.pumpWidget(
        _harness(
          const FastAnimation(
            count: 2,
            targetValues: [3, 4],
            duration: duration,
          ),
        ),
      );
      await tester.pump(duration);
      expect(_faces(tester), unorderedEquals([3, 4]));
    });

    testWidgets('changing targetValues swaps the grid via AnimatedSwitcher', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const FastAnimation(count: 1, targetValues: [1], duration: duration),
        ),
      );
      await tester.pumpAndSettle();
      expect(_faces(tester), [1]);

      await tester.pumpWidget(
        _harness(
          const FastAnimation(count: 1, targetValues: [6], duration: duration),
        ),
      );
      // Settle past the hard cut so the outgoing grid is fully removed.
      await tester.pumpAndSettle();
      expect(_faces(tester), [6]);
    });

    testWidgets('transitionBuilder returns the child unchanged (hard cut)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const FastAnimation(count: 1, targetValues: [2], duration: duration),
        ),
      );
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      final child = Container(key: const Key('x'));
      final result = switcher.transitionBuilder(
        child,
        const AlwaysStoppedAnimation<double>(1),
      );
      expect(result, same(child));
    });
  });
}

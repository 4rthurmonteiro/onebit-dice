import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';
import 'package:onebit_dice/features/dice/widgets/animations/drum_animation.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

Iterable<int> _faces(WidgetTester tester) =>
    tester.widgetList<PipFace>(find.byType(PipFace)).map((p) => p.value);

void main() {
  group('DrumAnimation', () {
    const duration = Duration(milliseconds: 400);

    testWidgets('initial render with values shows them immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 2,
            targetValues: const [3, 4],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      expect(_faces(tester), unorderedEquals([3, 4]));
    });

    testWidgets(
      'targetValues changing triggers cycling and settles to the target',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            DrumAnimation(
              count: 1,
              targetValues: const [1],
              duration: duration,
              sides: 6,
              random: Random(0),
            ),
          ),
        );

        await tester.pumpWidget(
          _harness(
            DrumAnimation(
              count: 1,
              targetValues: const [6],
              duration: duration,
              sides: 6,
              random: Random(0),
            ),
          ),
        );
        // Mid-animation: a random face (might be 1..6).
        await tester.pump(const Duration(milliseconds: 100));
        // After the duration completes the displayed value snaps to target.
        await tester.pump(duration);
        await tester.pumpAndSettle();
        expect(_faces(tester), [6]);
      },
    );

    testWidgets('targetValues null after non-null stops cycling and clears', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [4],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );

      // First update: kick the controller so isAnimating becomes true.
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [5],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Now drop the target — animation stops and the empty state shows.
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: null,
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('cycled values stay within 1..sides', (tester) async {
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [1],
            duration: duration,
            sides: 4,
            random: Random(0),
          ),
        ),
      );

      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [3],
            duration: duration,
            sides: 4,
            random: Random(0),
          ),
        ),
      );

      // Sample several mid-cycle ticks; every visible pip face must be ≤ 4.
      for (var t = 80; t < 360; t += 80) {
        await tester.pump(const Duration(milliseconds: 80));
        for (final value in _faces(tester)) {
          expect(
            value >= 1 && value <= 4,
            isTrue,
            reason: 'tick=$t produced $value (sides=4)',
          );
        }
      }
    });

    testWidgets('writing the same targetValues twice does not restart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [2],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      // Same target → no animation pump scheduled.
      await tester.pumpWidget(
        _harness(
          DrumAnimation(
            count: 1,
            targetValues: const [2],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pump();
      expect(_faces(tester), [2]);
    });

    testWidgets('uses Random() by default when none is injected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const DrumAnimation(
            count: 1,
            targetValues: [1],
            duration: duration,
            sides: 6,
          ),
        ),
      );
      await tester.pumpWidget(
        _harness(
          const DrumAnimation(
            count: 1,
            targetValues: [5],
            duration: duration,
            sides: 6,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpAndSettle();
      expect(_faces(tester), [5]);
    });
  });
}

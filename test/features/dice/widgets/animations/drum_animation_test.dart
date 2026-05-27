import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/drum_animation.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

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
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
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
        expect(find.text('6'), findsOneWidget);
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

      // Sample several mid-cycle ticks; every visible digit must be ≤ 4.
      for (var t = 80; t < 360; t += 80) {
        await tester.pump(const Duration(milliseconds: 80));
        for (final digit in const ['5', '6', '7', '8', '9']) {
          expect(
            find.text(digit),
            findsNothing,
            reason: 'tick=$t produced $digit (sides=4)',
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
      expect(find.text('2'), findsOneWidget);
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
      expect(find.text('5'), findsOneWidget);
    });
  });
}

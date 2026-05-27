import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/tabletop_animation.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('TabletopAnimation', () {
    const duration = Duration(milliseconds: 800);

    testWidgets('initial render with values shows them immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
            count: 1,
            targetValues: const [3],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('settles on targetValues after duration elapses', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
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
          TabletopAnimation(
            count: 1,
            targetValues: const [6],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('dropping target to null stops the animation and clears', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
            count: 1,
            targetValues: const [4],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
            count: 1,
            targetValues: const [5],
            duration: duration,
            sides: 6,
            random: Random(0),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
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

    testWidgets('cycle phase only produces valid faces (1..sides)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          TabletopAnimation(
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
          TabletopAnimation(
            count: 1,
            targetValues: const [3],
            duration: duration,
            sides: 4,
            random: Random(0),
          ),
        ),
      );
      // Step into the cycle phase (≥ 50% of 800ms = 400ms in).
      for (var t = 0; t < 250; t += 60) {
        await tester.pump(const Duration(milliseconds: 60));
        for (final bad in const ['5', '6', '7', '8', '9']) {
          expect(find.text(bad), findsNothing);
        }
      }
    });

    testWidgets('uses Random() by default when none is injected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const TabletopAnimation(
            count: 1,
            targetValues: [1],
            duration: duration,
            sides: 6,
          ),
        ),
      );
      await tester.pumpWidget(
        _harness(
          const TabletopAnimation(
            count: 1,
            targetValues: [4],
            duration: duration,
            sides: 6,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });
  });

  group('tabletopTranslateY', () {
    test('slide-in phase: returns -slotSize at t=0, near 0 at t=0.25', () {
      expect(tabletopTranslateY(0, 64), -64);
      expect(tabletopTranslateY(0.249, 64).abs() < 2, isTrue);
    });

    test('bounce phase: oscillates within ±2 px', () {
      for (var t = 0.26; t < 0.50; t += 0.05) {
        expect(tabletopTranslateY(t, 64).abs() <= 2, isTrue);
      }
    });

    test('post-bounce phase: returns 0', () {
      expect(tabletopTranslateY(0.5, 64), 0);
      expect(tabletopTranslateY(0.8, 64), 0);
      expect(tabletopTranslateY(1, 64), 0);
    });

    test('always returns whole-number pixels (pixel-snapped)', () {
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        final v = tabletopTranslateY(t, 64);
        expect(v, v.roundToDouble());
      }
    });
  });

  group('tabletopScale', () {
    test('pre-settle phase: scale is 1.0', () {
      expect(tabletopScale(0), 1);
      expect(tabletopScale(0.5), 1);
      expect(tabletopScale(0.79), 1);
    });

    test('settle phase: scale rises to ~1.05 then back to 1.0', () {
      expect(tabletopScale(0.8), closeTo(0.92, 1e-9));
      expect(tabletopScale(0.9), closeTo(1.05, 1e-9));
      expect(tabletopScale(1), closeTo(1, 1e-9));
    });
  });
}

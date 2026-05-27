import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/drum_animation.dart';
import 'package:onebit_dice/features/dice/widgets/animations/fast_animation.dart';
import 'package:onebit_dice/features/dice/widgets/animations/tabletop_animation.dart';
import 'package:onebit_dice/features/dice/widgets/dice_animator.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:provider/provider.dart';

class _Pref extends InMemoryAppSettingsPreference {
  _Pref({AnimationStyle? style, AnimationSpeed? speed}) {
    if (style != null) writeAnimationStyle(style);
    if (speed != null) writeAnimationSpeed(speed);
  }
}

Widget _harness({
  required AnimationStyle style,
  AnimationSpeed speed = AnimationSpeed.medium,
}) {
  final controller = AnimationSettingsController(
    preference: _Pref(style: style, speed: speed),
  );
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(
      body: Center(
        child: ChangeNotifierProvider<AnimationSettingsController>.value(
          value: controller,
          child: const DiceAnimator(count: 1, targetValues: [3], sides: 6),
        ),
      ),
    ),
  );
}

void main() {
  group('DiceAnimator', () {
    testWidgets('AnimationStyle.fast → renders FastAnimation', (tester) async {
      await tester.pumpWidget(_harness(style: AnimationStyle.fast));
      expect(find.byType(FastAnimation), findsOneWidget);
    });

    testWidgets('AnimationStyle.drum → renders DrumAnimation', (tester) async {
      await tester.pumpWidget(_harness(style: AnimationStyle.drum));
      expect(find.byType(DrumAnimation), findsOneWidget);
    });

    testWidgets('AnimationStyle.tabletop → renders TabletopAnimation', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(style: AnimationStyle.tabletop));
      expect(find.byType(TabletopAnimation), findsOneWidget);
    });

    testWidgets('switching style at runtime swaps the strategy', (
      tester,
    ) async {
      final controller = AnimationSettingsController(
        preference: _Pref(style: AnimationStyle.fast),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildThemeData(Palette.of(PaletteId.macClassic)),
          home: Scaffold(
            body: ChangeNotifierProvider<AnimationSettingsController>.value(
              value: controller,
              child: const DiceAnimator(count: 1, targetValues: [2], sides: 6),
            ),
          ),
        ),
      );
      expect(find.byType(FastAnimation), findsOneWidget);

      await controller.setStyle(AnimationStyle.drum);
      await tester.pump();
      expect(find.byType(FastAnimation), findsNothing);
      expect(find.byType(DrumAnimation), findsOneWidget);
    });
  });

  group('resolveDuration', () {
    test('fast ignores speed', () {
      for (final speed in AnimationSpeed.values) {
        expect(
          resolveDuration(AnimationStyle.fast, speed),
          const Duration(milliseconds: 100),
        );
      }
    });

    test('drum durations table', () {
      expect(
        resolveDuration(AnimationStyle.drum, AnimationSpeed.fast),
        const Duration(milliseconds: 400),
      );
      expect(
        resolveDuration(AnimationStyle.drum, AnimationSpeed.medium),
        const Duration(milliseconds: 800),
      );
      expect(
        resolveDuration(AnimationStyle.drum, AnimationSpeed.slow),
        const Duration(milliseconds: 1400),
      );
    });

    test('tabletop durations table', () {
      expect(
        resolveDuration(AnimationStyle.tabletop, AnimationSpeed.fast),
        const Duration(milliseconds: 800),
      );
      expect(
        resolveDuration(AnimationStyle.tabletop, AnimationSpeed.medium),
        const Duration(milliseconds: 1500),
      );
      expect(
        resolveDuration(AnimationStyle.tabletop, AnimationSpeed.slow),
        const Duration(milliseconds: 2500),
      );
    });
  });
}

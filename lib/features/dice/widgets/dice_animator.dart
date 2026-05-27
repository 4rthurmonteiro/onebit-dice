import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/features/dice/widgets/animations/drum_animation.dart';
import 'package:onebit_dice/features/dice/widgets/animations/fast_animation.dart';
import 'package:onebit_dice/features/dice/widgets/animations/tabletop_animation.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:provider/provider.dart';

/// Routes the dice grid render through one of three animation strategies
/// (`fast`, `drum`, `tabletop`) based on the user's stored
/// [AnimationSettingsController.style] and [AnimationSettingsController.speed].
///
/// The chosen strategy receives the resolved [Duration] and the [sides] of
/// the active dice (needed to bound the random faces shown while cycling).
class DiceAnimator extends StatelessWidget {
  /// Creates a [DiceAnimator].
  const DiceAnimator({
    required this.count,
    required this.targetValues,
    required this.sides,
    super.key,
  });

  /// Number of slots to render.
  final int count;

  /// Latest roll values, or null for the empty `?` state.
  final List<int>? targetValues;

  /// Face count of the active dice — bounds the cycled random values.
  final int sides;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AnimationSettingsController>();
    final duration = resolveDuration(settings.style, settings.speed);
    return switch (settings.style) {
      AnimationStyle.fast => FastAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
      ),
      AnimationStyle.drum => DrumAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
        sides: sides,
      ),
      AnimationStyle.tabletop => TabletopAnimation(
        count: count,
        targetValues: targetValues,
        duration: duration,
        sides: sides,
      ),
    };
  }
}

/// Returns the animation [Duration] for the chosen [style] + [speed]
/// combination. `AnimationStyle.fast` ignores [speed] — it is the "no
/// animation" style and is always 100 ms.
@visibleForTesting
Duration resolveDuration(AnimationStyle style, AnimationSpeed speed) =>
    switch ((style, speed)) {
      (AnimationStyle.fast, _) => const Duration(milliseconds: 100),
      (AnimationStyle.drum, AnimationSpeed.fast) => const Duration(
        milliseconds: 400,
      ),
      (AnimationStyle.drum, AnimationSpeed.medium) => const Duration(
        milliseconds: 800,
      ),
      (AnimationStyle.drum, AnimationSpeed.slow) => const Duration(
        milliseconds: 1400,
      ),
      (AnimationStyle.tabletop, AnimationSpeed.fast) => const Duration(
        milliseconds: 800,
      ),
      (AnimationStyle.tabletop, AnimationSpeed.medium) => const Duration(
        milliseconds: 1500,
      ),
      (AnimationStyle.tabletop, AnimationSpeed.slow) => const Duration(
        milliseconds: 2500,
      ),
    };

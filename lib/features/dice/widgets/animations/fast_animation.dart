import 'package:flutter/material.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';

/// "No animation" strategy — the new values appear instantly, with a 100 ms
/// hard cut from the previous slot grid (no fade, no cycling).
class FastAnimation extends StatelessWidget {
  /// Creates a [FastAnimation].
  const FastAnimation({
    required this.count,
    required this.targetValues,
    required this.duration,
    super.key,
  });

  /// Number of slots in the grid.
  final int count;

  /// Latest roll values, or null for the empty `?` state.
  final List<int>? targetValues;

  /// How long [AnimatedSwitcher] keeps the outgoing child mounted.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, _) => child,
      child: DiceGrid(
        key: ValueKey(
          targetValues == null ? 'empty-$count' : targetValues!.join(','),
        ),
        count: count,
        values: targetValues,
      ),
    );
  }
}

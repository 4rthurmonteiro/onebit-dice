import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/widgets/dice_animator.dart';

/// Renders the dice slots and (when a roll has happened) the total and the
/// equation.
///
/// `values == null` paints [count] `?` slots — the empty state shown before
/// a roll or after the user has changed the type/count. `values != null`
/// paints one slot per integer, plus a total below, plus the equation when
/// more than one die was rolled.
///
/// The slot grid is delegated to [DiceAnimator], which picks one of three
/// animation strategies based on the user's persisted
/// `AnimationSettingsController` preference.
class DiceWidget extends StatelessWidget {
  /// Creates a [DiceWidget] showing [count] slots.
  ///
  /// When [values] is provided, its length must equal [count]. [sides] is
  /// forwarded to [DiceAnimator] so cycling animations draw faces from the
  /// correct range; it defaults to 6 (a D6) when not specified.
  const DiceWidget({
    required this.count,
    required this.values,
    this.sides = 6,
    super.key,
  }) : assert(
         values == null || values.length == count,
         'values must be null or match count',
       );

  /// How many slots to render.
  final int count;

  /// The values of the most recent roll, or `null` to render the empty state.
  final List<int>? values;

  /// Face count of the active dice — bounds cycled random values in the
  /// drum/tabletop animations.
  final int sides;

  /// Key tagging the slot grid container.
  @visibleForTesting
  static const Key gridKey = ValueKey('DiceWidget.grid');

  /// Key tagging the total label — present only when [values] is non-null.
  @visibleForTesting
  static const Key totalKey = ValueKey('DiceWidget.total');

  /// Key tagging the equation label — present only when more than one die
  /// has been rolled.
  @visibleForTesting
  static const Key equationKey = ValueKey('DiceWidget.equation');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final hasResult = values != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.ink, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KeyedSubtree(
                    key: gridKey,
                    child: DiceAnimator(
                      count: count,
                      targetValues: values,
                      sides: sides,
                    ),
                  ),
                  if (hasResult) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: colors.ink),
                    const SizedBox(height: 8),
                    Text(
                      key: totalKey,
                      context.l10n.rollResultTotal(_sum(values!)),
                      style: AppTypography.display.copyWith(
                        color: colors.ink,
                        fontSize: 32,
                      ),
                    ),
                    if (values!.length > 1)
                      Text(
                        key: equationKey,
                        '${values!.join(' + ')} = ${_sum(values!)}',
                        style: AppTypography.body.copyWith(
                          color: colors.ink,
                          fontSize: 18,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static int _sum(List<int> xs) => xs.fold(0, (a, b) => a + b);
}

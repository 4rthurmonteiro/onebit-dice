import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/widgets/dice_animator.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:provider/provider.dart';

/// Renders the dice slots and (once a roll's animation has settled) the total
/// and the equation.
///
/// `values == null` paints [count] `?` slots — the empty state shown before
/// a roll or after the user has changed the type/count. `values != null`
/// paints one slot per integer, plus a total below, plus the equation when
/// more than one die was rolled.
///
/// The total and equation are held back until the slot animation has run for
/// its full [resolveDuration] — they appear only once the dice have stopped
/// tumbling, never mid-roll. The slot grid itself is delegated to
/// [DiceAnimator], which picks one of three animation strategies based on the
/// user's persisted `AnimationSettingsController` preference.
class DiceWidget extends StatefulWidget {
  /// Creates a [DiceWidget] showing [count] slots.
  ///
  /// When [values] is provided, its length must equal [count]. [sides] is
  /// forwarded to [DiceAnimator] so cycling animations draw faces from the
  /// correct range and dice with `sides <= 6` render pips; it defaults to 6
  /// (a D6) when not specified.
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
  /// drum/tabletop animations and selects pip vs numeral rendering.
  final int sides;

  /// Key tagging the slot grid container.
  @visibleForTesting
  static const Key gridKey = ValueKey('DiceWidget.grid');

  /// Key tagging the total label — present only once a roll has settled.
  @visibleForTesting
  static const Key totalKey = ValueKey('DiceWidget.total');

  /// Key tagging the equation label — present only when more than one die
  /// has been rolled and the roll has settled.
  @visibleForTesting
  static const Key equationKey = ValueKey('DiceWidget.equation');

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> {
  /// Whether the current [DiceWidget.values] have finished animating and the
  /// total/equation may show. A fresh mount that already carries a result is
  /// considered settled (no animation runs on first build).
  bool _settled = false;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _settled = widget.values != null;
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.values == null) {
      _settleTimer?.cancel();
      _settled = false;
    } else if (!listEquals(widget.values, oldWidget.values)) {
      // A new roll: hide the total and reveal it only after the slot
      // animation has run its course.
      _settled = false;
      _startSettleTimer();
    }
  }

  void _startSettleTimer() {
    _settleTimer?.cancel();
    final settings = context.read<AnimationSettingsController>();
    final duration = resolveDuration(settings.style, settings.speed);
    _settleTimer = Timer(duration, () {
      setState(() => _settled = true);
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final values = widget.values;
    final showResult = values != null && _settled;

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
                    key: DiceWidget.gridKey,
                    child: DiceAnimator(
                      count: widget.count,
                      targetValues: values,
                      sides: widget.sides,
                    ),
                  ),
                  if (showResult) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: colors.ink),
                    const SizedBox(height: 8),
                    Text(
                      key: DiceWidget.totalKey,
                      context.l10n.rollResultTotal(_sum(values)),
                      style: AppTypography.display.copyWith(
                        color: colors.ink,
                        fontSize: 32,
                      ),
                    ),
                    if (values.length > 1)
                      Text(
                        key: DiceWidget.equationKey,
                        '${values.join(' + ')} = ${_sum(values)}',
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

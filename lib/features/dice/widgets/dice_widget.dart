import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders the dice slots and (when a roll has happened) the total and the
/// equation.
///
/// `values == null` paints [count] `?` slots — the empty state shown before
/// a roll or after the user has changed the type/count. `values != null`
/// paints one slot per integer, plus a total below, plus the equation when
/// more than one die was rolled.
///
/// This is a placeholder for E12: when sprite sheets land, the textual
/// slots become pixel sprites, but the slot grid structure stays the same.
class DiceWidget extends StatelessWidget {
  /// Creates a [DiceWidget] showing [count] slots.
  ///
  /// When [values] is provided, its length must equal [count].
  DiceWidget({required this.count, required this.values, super.key})
    : assert(
        values == null || values.length == count,
        'values must be null or match count',
      );

  /// How many slots to render.
  final int count;

  /// The values of the most recent roll, or `null` to render the empty state.
  final List<int>? values;

  /// Key tagging the slot grid.
  @visibleForTesting
  static const Key gridKey = ValueKey('DiceWidget.grid');

  /// Key tagging the total label — present only when [values] is non-null.
  @visibleForTesting
  static const Key totalKey = ValueKey('DiceWidget.total');

  /// Key tagging the equation label — present only when more than one die
  /// has been rolled.
  @visibleForTesting
  static const Key equationKey = ValueKey('DiceWidget.equation');

  static const double _slotSize = 64;
  static const double _slotSpacing = 8;
  static const int _maxColumns = 3;

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
                  _Grid(
                    key: gridKey,
                    count: count,
                    values: values,
                    slotSize: _slotSize,
                    slotSpacing: _slotSpacing,
                    maxColumns: _maxColumns,
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

class _Grid extends StatelessWidget {
  const _Grid({
    required this.count,
    required this.values,
    required this.slotSize,
    required this.slotSpacing,
    required this.maxColumns,
    super.key,
  });

  final int count;
  final List<int>? values;
  final double slotSize;
  final double slotSpacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    final columns = count < maxColumns ? count : maxColumns;
    final rows = (count + columns - 1) ~/ columns;
    return SizedBox(
      width: columns * slotSize + (columns - 1) * slotSpacing,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) SizedBox(height: slotSpacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: slotSpacing),
                  if (r * columns + c < count)
                    _Slot(
                      text: values != null
                          ? '${values![r * columns + c]}'
                          : '?',
                      size: slotSize,
                    )
                  else
                    SizedBox(width: slotSize, height: slotSize),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.ink, width: 2),
      ),
      child: Text(
        text,
        style: AppTypography.display.copyWith(color: colors.ink, fontSize: 32),
      ),
    );
  }
}

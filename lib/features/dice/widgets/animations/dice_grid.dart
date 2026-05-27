import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders [count] dice slots in a row-major grid laid out at up to
/// [maxColumns] columns. When [values] is null, every slot shows `?`.
///
/// Extracted from `DiceWidget` so the animation strategies under
/// `animations/` can reuse it without re-implementing the layout.
class DiceGrid extends StatelessWidget {
  /// Creates a [DiceGrid].
  const DiceGrid({
    required this.count,
    required this.values,
    this.slotSize = 64,
    this.slotSpacing = 8,
    this.maxColumns = 3,
    this.builder,
    super.key,
  });

  /// Number of slots to render.
  final int count;

  /// Latest values shown, or null for the empty `?` state.
  final List<int>? values;

  /// Size of each slot in logical pixels.
  final double slotSize;

  /// Gap between adjacent slots, both directions.
  final double slotSpacing;

  /// Maximum columns before wrapping to a new row.
  final int maxColumns;

  /// Optional per-slot wrapper — receives the slot index and the rendered slot
  /// and returns the widget to insert. Used by `TabletopAnimation` to apply
  /// per-slot transforms (slide/scale) without forking the layout.
  final Widget Function(int index, Widget slot)? builder;

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
                    _wrap(
                      r * columns + c,
                      DiceSlot(
                        text: values != null
                            ? '${values![r * columns + c]}'
                            : '?',
                        size: slotSize,
                      ),
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

  Widget _wrap(int index, Widget slot) =>
      builder != null ? builder!(index, slot) : slot;
}

/// A single dice slot rendering [text] centered in a square of [size]
/// logical pixels, framed by the active palette's ink border.
class DiceSlot extends StatelessWidget {
  /// Creates a [DiceSlot].
  const DiceSlot({required this.text, required this.size, super.key});

  /// Text to render inside the slot.
  final String text;

  /// Side length of the slot in logical pixels.
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

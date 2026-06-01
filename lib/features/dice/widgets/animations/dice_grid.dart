import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders [count] dice slots in a row-major grid laid out at up to
/// [maxColumns] columns. When [values] is null, every slot shows `?`.
///
/// Slots whose die has [sides] `<= 6` and a value in `1..6` render the
/// traditional pip layout (see [PipFace]); everything else (larger dice, the
/// `?` empty state) renders the numeral.
///
/// Extracted from `DiceWidget` so the animation strategies under
/// `animations/` can reuse it without re-implementing the layout.
class DiceGrid extends StatelessWidget {
  /// Creates a [DiceGrid].
  const DiceGrid({
    required this.count,
    required this.values,
    this.sides = 6,
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

  /// Face count of the active dice. Dice with `sides <= 6` render pips.
  final int sides;

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
                        value: values?[r * columns + c],
                        sides: sides,
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

/// A single dice slot framed by the active palette's ink border.
///
/// Renders pips when the die has [sides] `<= 6` and [value] is in `1..6`,
/// otherwise the numeral (or `?` when [value] is null).
class DiceSlot extends StatelessWidget {
  /// Creates a [DiceSlot].
  const DiceSlot({required this.size, this.value, this.sides = 6, super.key});

  /// Value to render, or null for the empty `?` state.
  final int? value;

  /// Face count of the active die. Values on dice with `sides <= 6` render
  /// as pips.
  final int sides;

  /// Side length of the slot in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final value = this.value;
    final usePips = sides <= 6 && value != null && value >= 1 && value <= 6;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.ink, width: 2),
      ),
      child: usePips
          ? PipFace(value: value, color: colors.ink, size: size * 0.72)
          : Text(
              value?.toString() ?? '?',
              style: AppTypography.display.copyWith(
                color: colors.ink,
                fontSize: 32,
              ),
            ),
    );
  }
}

/// Pip cells (indices into a row-major 3×3 grid) lit for each face value.
const Map<int, List<int>> _pipLayouts = {
  1: [4],
  2: [0, 8],
  3: [0, 4, 8],
  4: [0, 2, 6, 8],
  5: [0, 2, 4, 6, 8],
  6: [0, 2, 3, 5, 6, 8],
};

/// Draws the traditional pip layout for [value] (1..6) as square pixels in
/// [color], filling a square of [size] logical pixels.
///
/// Pips are squares — not circles — to stay true to the 1-bit, no-anti-alias
/// aesthetic. Out-of-range values paint nothing.
class PipFace extends StatelessWidget {
  /// Creates a [PipFace].
  const PipFace({
    required this.value,
    required this.color,
    required this.size,
    super.key,
  });

  /// Face value to render (expected in `1..6`).
  final int value;

  /// Pip color (the active palette's ink).
  final Color color;

  /// Side length of the face in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PipPainter(value: value, color: color),
    );
  }
}

class _PipPainter extends CustomPainter {
  const _PipPainter({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cells = _pipLayouts[value];
    if (cells == null) return;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final pip = (size.width * 0.2).roundToDouble();
    for (final cell in cells) {
      final col = cell % 3;
      final row = cell ~/ 3;
      final cx = size.width * (col + 0.5) / 3;
      final cy = size.height * (row + 0.5) / 3;
      final left = (cx - pip / 2).roundToDouble();
      final top = (cy - pip / 2).roundToDouble();
      canvas.drawRect(Rect.fromLTWH(left, top, pip, pip), paint);
    }
  }

  @override
  bool shouldRepaint(_PipPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';

/// A 1-bit icon rendered from a [matrix] of `0`s (paper) and `1`s (ink).
///
/// Reads the active palette's [OneBitColors] from the surrounding theme so
/// the icon recolors automatically when the palette changes. When [inverted]
/// is `true`, ink and paper swap roles — useful for highlighting an active
/// tab against an inverted background.
class PixelIcon extends StatelessWidget {
  /// Creates a [PixelIcon] with the given pixel [matrix].
  const PixelIcon({
    required this.matrix,
    super.key,
    this.size = 24,
    this.inverted = false,
  });

  /// The pixel grid. Outer list is rows top-to-bottom; inner is columns
  /// left-to-right. Cells are `0` (paper / off) or `1` (ink / on).
  final List<List<int>> matrix;

  /// Side length of the painted square in logical pixels.
  final double size;

  /// When `true`, paint ink cells in paper and vice-versa.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final on = inverted ? colors.paper : colors.ink;
    final off = inverted ? colors.ink : colors.paper;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size.square(size),
        painter: PixelIconPainter(matrix: matrix, on: on, off: off),
      ),
    );
  }
}

/// Paints a pixel matrix into the given canvas using [on] for `1` cells and
/// [off] for `0` cells.
@visibleForTesting
class PixelIconPainter extends CustomPainter {
  /// Creates a painter for [matrix] using [on] / [off] colors.
  PixelIconPainter({required this.matrix, required this.on, required this.off});

  /// The pixel grid (see [PixelIcon.matrix]).
  final List<List<int>> matrix;

  /// Color used for `1` cells.
  final Color on;

  /// Color used for `0` cells.
  final Color off;

  @override
  void paint(Canvas canvas, Size size) {
    if (matrix.isEmpty || matrix.first.isEmpty) return;
    final rows = matrix.length;
    final cols = matrix.first.length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final onPaint = Paint()..color = on;
    final offPaint = Paint()..color = off;

    canvas.drawRect(Offset.zero & size, offPaint);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (matrix[r][c] != 1) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH),
          onPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PixelIconPainter oldDelegate) =>
      oldDelegate.matrix != matrix ||
      oldDelegate.on != on ||
      oldDelegate.off != off;
}

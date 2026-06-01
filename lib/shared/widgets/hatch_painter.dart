import 'package:flutter/material.dart';

/// Paints a 1-bit checkerboard hatch — alternating ink/paper [cell]-sized
/// squares tiled across the whole canvas.
///
/// Used as the dismissible barrier behind the dice-type sheet in place of the
/// default translucent grey scrim, which would violate the strict 2-color
/// palette rule (no grey, no alpha). Each square is drawn with
/// [Canvas.drawRect] rather than [Canvas.drawLine] so the result stays crisp
/// 1-bit with no anti-aliasing — mirroring the `_StripesPainter` precedent in
/// `MacWindow`.
class HatchPainter extends CustomPainter {
  /// Creates a [HatchPainter] using [ink] for "on" cells and [paper] for
  /// "off" cells.
  HatchPainter({required this.ink, required this.paper});

  /// Foreground color filling the "on" squares of the checkerboard.
  final Color ink;

  /// Background color filling the "off" squares of the checkerboard.
  final Color paper;

  /// Side of one checkerboard square, in logical pixels. Two cells across and
  /// two down make up the repeating 4×4 tile.
  @visibleForTesting
  static const double cell = 2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final inkPaint = Paint()..color = ink;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell),
            inkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant HatchPainter old) =>
      old.ink != ink || old.paper != paper;
}

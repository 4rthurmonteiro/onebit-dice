import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// A row with a [label] on the left and a Mac-style 1-bit checkbox on the
/// right. Tapping the row toggles [value] via [onChanged].
class ToggleTile extends StatelessWidget {
  /// Creates a [ToggleTile].
  const ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Label shown on the left.
  final String label;

  /// Current toggle state.
  final bool value;

  /// Invoked with the new value when the row is tapped.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      button: true,
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(color: colors.ink),
                ),
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: CheckboxPainter(
                    checked: value,
                    ink: colors.ink,
                    paper: colors.paper,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a 1-bit Mac-style checkbox: a 2px ink border around a paper square,
/// with an `X` glyph stamped inside when [checked] is `true`.
@visibleForTesting
class CheckboxPainter extends CustomPainter {
  /// Creates a [CheckboxPainter].
  CheckboxPainter({
    required this.checked,
    required this.ink,
    required this.paper,
  });

  /// Whether to paint the `X` glyph.
  final bool checked;

  /// Foreground color used for border and `X`.
  final Color ink;

  /// Background color used inside the border.
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final paperPaint = Paint()..color = paper;
    canvas.drawRect(Offset.zero & size, paperPaint);
    final inkPaint = Paint()..color = ink;
    const border = 2.0;
    final rect = Offset.zero & size;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, border), inkPaint)
      ..drawRect(
        Rect.fromLTWH(0, size.height - border, size.width, border),
        inkPaint,
      )
      ..drawRect(Rect.fromLTWH(0, 0, border, size.height), inkPaint)
      ..drawRect(
        Rect.fromLTWH(size.width - border, 0, border, size.height),
        inkPaint,
      );
    if (!checked) return;
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = border
      ..strokeCap = StrokeCap.square;
    canvas
      ..drawLine(
        Offset(rect.left + border, rect.top + border),
        Offset(rect.right - border, rect.bottom - border),
        stroke,
      )
      ..drawLine(
        Offset(rect.right - border, rect.top + border),
        Offset(rect.left + border, rect.bottom - border),
        stroke,
      );
  }

  @override
  bool shouldRepaint(CheckboxPainter old) =>
      old.checked != checked || old.ink != ink || old.paper != paper;
}

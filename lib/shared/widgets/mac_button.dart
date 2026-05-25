import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// A 1-bit Macintosh System 1-style button.
///
/// Double 2px ink border around a paper face, with a 3px offset solid ink
/// shadow. Pressing the button hides the shadow and shifts the face into
/// the shadow's position, mimicking the "sunken" feel of the original Mac
/// OS button.
///
/// All colors come from the active palette via the [OneBitColors]
/// `ThemeExtension` — no hardcoded `Color` values live in this file.
class MacButton extends StatefulWidget {
  /// Creates a [MacButton] showing [label] (upper-cased automatically) and
  /// invoking [onPressed] on tap. When [expand] is `true`, the button takes
  /// the full width of its parent.
  const MacButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.expand = false,
  });

  /// Label text. Rendered upper-case in the display typography.
  final String label;

  /// Tap handler. Always non-null — E02 has no disabled state.
  final VoidCallback onPressed;

  /// When `true`, the button fills its parent's width.
  final bool expand;

  /// Key tagging the offset ink shadow. Hidden while the button is pressed.
  @visibleForTesting
  static const Key shadowKey = ValueKey('MacButton.shadow');

  /// Key tagging the button face — useful for asserting position changes
  /// between pressed and released states.
  @visibleForTesting
  static const Key faceKey = ValueKey('MacButton.face');

  /// Pixel offset applied to the shadow (and to the face while pressed).
  static const double shadowOffset = 3;

  @override
  State<MacButton> createState() => _MacButtonState();
}

class _MacButtonState extends State<MacButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    const offset = MacButton.shadowOffset;

    final face = Container(
      key: MacButton.faceKey,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.ink, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.ink, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          widget.label.toUpperCase(),
          style: AppTypography.display.copyWith(color: colors.ink),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final stack = Stack(
      children: [
        if (!_pressed)
          Positioned(
            key: MacButton.shadowKey,
            left: offset,
            top: offset,
            right: 0,
            bottom: 0,
            child: ColoredBox(color: colors.ink),
          ),
        Padding(
          padding: _pressed
              ? const EdgeInsets.only(left: offset, top: offset)
              : const EdgeInsets.only(right: offset, bottom: offset),
          child: face,
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        child: stack,
      ),
    );
  }
}

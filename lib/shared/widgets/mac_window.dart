import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// A 1-bit Macintosh System 1-style window.
///
/// Renders a double-bordered frame around [child] with an optional striped
/// title bar that holds the [title] label and a small close button (only
/// when [onClose] is non-null).
class MacWindow extends StatelessWidget {
  /// Creates a [MacWindow] wrapping [child].
  const MacWindow({required this.child, super.key, this.title, this.onClose});

  /// Optional title shown centered in the title bar. When `null`, the title
  /// bar shows uninterrupted stripes.
  final String? title;

  /// Body content rendered inside the framed area.
  final Widget child;

  /// When non-null, a small close affordance is shown on the left of the
  /// title bar and its taps are forwarded here.
  final VoidCallback? onClose;

  /// Fixed height of the striped title bar.
  static const double titleBarHeight = 20;

  /// Key tagging the close button — present only when [onClose] is non-null.
  @visibleForTesting
  static const Key closeButtonKey = ValueKey('MacWindow.closeButton');

  /// Key tagging the title rectangle — present only when [title] is non-null.
  @visibleForTesting
  static const Key titleKey = ValueKey('MacWindow.title');

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TitleBar(colors: colors, title: title, onClose: onClose),
              Container(
                color: colors.paper,
                padding: const EdgeInsets.all(8),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.colors, this.title, this.onClose});

  final OneBitColors colors;
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MacWindow.titleBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _StripesPainter(ink: colors.ink)),
          ),
          if (title != null)
            Container(
              key: MacWindow.titleKey,
              color: colors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(
                title!,
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 12,
                ),
              ),
            ),
          if (onClose != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Semantics(
                label: 'Close',
                button: true,
                child: GestureDetector(
                  key: MacWindow.closeButtonKey,
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 32,
                    height: MacWindow.titleBarHeight,
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.paper,
                          border: Border.all(color: colors.ink),
                        ),
                        child: CustomPaint(
                          painter: _CloseGlyphPainter(ink: colors.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ink;
    for (var y = 1.0; y < size.height; y += 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter old) => old.ink != ink;
}

class _CloseGlyphPainter extends CustomPainter {
  _CloseGlyphPainter({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ink;
    // Draw the X one pixel at a time so it stays crisp 1-bit (`drawLine`
    // anti-aliases). The glyph leaves a 2px inset on every side.
    const inset = 2.0;
    final span = size.width - inset * 2;
    for (var i = 0.0; i < span; i++) {
      canvas
        ..drawRect(Rect.fromLTWH(inset + i, inset + i, 1, 1), paint)
        ..drawRect(
          Rect.fromLTWH(size.width - inset - 1 - i, inset + i, 1, 1),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _CloseGlyphPainter old) => old.ink != ink;
}

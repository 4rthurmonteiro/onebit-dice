import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';

/// A horizontal 1-bit divider — a solid ink line of [thickness] pixels.
///
/// Color always comes from the active palette's `ink` via the [OneBitColors]
/// `ThemeExtension`.
class PixelDivider extends StatelessWidget {
  /// Creates a [PixelDivider] with the given [thickness] and outer [padding].
  const PixelDivider({
    super.key,
    this.thickness = 2,
    this.padding = EdgeInsets.zero,
  });

  /// Height of the line in logical pixels. Defaults to 2.
  final double thickness;

  /// Outer padding wrapped around the line.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Padding(
      padding: padding,
      child: Container(height: thickness, color: colors.ink),
    );
  }
}

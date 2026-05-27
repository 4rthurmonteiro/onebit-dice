import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';

/// A titled section in the Settings screen.
///
/// Layout: an upper [PixelDivider], a [title] in display typography, a lower
/// [PixelDivider], and the [child] padded inside the section.
class SettingsSection extends StatelessWidget {
  /// Creates a [SettingsSection] with [title] above [child].
  const SettingsSection({required this.title, required this.child, super.key});

  /// Section header text (rendered upper-case in display typography).
  final String title;

  /// Section content widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PixelDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.display.copyWith(color: colors.ink),
          ),
        ),
        const PixelDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ],
    );
  }
}

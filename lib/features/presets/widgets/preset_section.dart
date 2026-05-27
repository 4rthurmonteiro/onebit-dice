import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// A header with the section [title] above a [Wrap] of [children].
///
/// The header reuses the striped title-bar look (white label over an ink
/// stripe field). Body content is composed by the parent — typically
/// `PresetCard`s for the Presets screen.
class PresetSection extends StatelessWidget {
  /// Creates a [PresetSection].
  const PresetSection({required this.title, required this.children, super.key});

  /// Localized section header text.
  final String title;

  /// Section body — laid out in a [Wrap] so cards reflow on smaller screens.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: colors.ink,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: AppTypography.display.copyWith(
              color: colors.paper,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

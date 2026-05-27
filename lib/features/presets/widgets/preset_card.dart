import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';

/// A tappable [MacWindow] card showing a preset's [label] (top) and dice
/// [notation] (e.g. `2xD6`, bottom).
///
/// Used for both built-in and custom presets — the card itself does not
/// distinguish between the two; the parent supplies the [onTap] callback.
class PresetCard extends StatelessWidget {
  /// Creates a [PresetCard].
  const PresetCard({
    required this.label,
    required this.notation,
    required this.onTap,
    super.key,
  });

  /// Localized user-visible name.
  final String label;

  /// Dice notation rendered below the [label] (e.g. `1xD20`).
  final String notation;

  /// Tap handler — invoked when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      container: true,
      button: true,
      label: '$label $notation',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 140,
          child: ExcludeSemantics(
            child: MacWindow(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: AppTypography.display.copyWith(
                        color: colors.ink,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notation,
                      style: AppTypography.body.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Localized label for an [AnimationStyle] value.
String animationStyleLabel(AppLocalizations l10n, AnimationStyle style) {
  switch (style) {
    case AnimationStyle.fast:
      return l10n.settingsAnimationStyleFast;
    case AnimationStyle.drum:
      return l10n.settingsAnimationStyleDrum;
    case AnimationStyle.tabletop:
      return l10n.settingsAnimationStyleTabletop;
  }
}

/// Localized label for an [AnimationSpeed] value.
String animationSpeedLabel(AppLocalizations l10n, AnimationSpeed speed) {
  switch (speed) {
    case AnimationSpeed.fast:
      return l10n.settingsAnimationSpeedFast;
    case AnimationSpeed.medium:
      return l10n.settingsAnimationSpeedMedium;
    case AnimationSpeed.slow:
      return l10n.settingsAnimationSpeedSlow;
  }
}

/// Animation settings panel: two radio groups (style + speed) backed by
/// [AnimationSettingsController].
class AnimationSection extends StatelessWidget {
  /// Creates an [AnimationSection].
  const AnimationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AnimationSettingsController>();
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsAnimationStyleLabel,
          style: AppTypography.body.copyWith(color: colors.ink),
        ),
        for (final style in AnimationStyle.values)
          RadioRow(
            label: animationStyleLabel(l10n, style),
            selected: controller.style == style,
            onTap: () =>
                context.read<AnimationSettingsController>().setStyle(style),
          ),
        const SizedBox(height: 16),
        Text(
          l10n.settingsAnimationSpeedLabel,
          style: AppTypography.body.copyWith(color: colors.ink),
        ),
        for (final speed in AnimationSpeed.values)
          RadioRow(
            label: animationSpeedLabel(l10n, speed),
            selected: controller.speed == speed,
            onTap: () =>
                context.read<AnimationSettingsController>().setSpeed(speed),
          ),
      ],
    );
  }
}

/// A single tappable row showing a 1-bit radio glyph (`●`/`○`) plus a label.
@visibleForTesting
class RadioRow extends StatelessWidget {
  /// Creates a [RadioRow].
  const RadioRow({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Row label.
  final String label;

  /// Whether the row represents the active value.
  final bool selected;

  /// Tap callback.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(
                  painter: RadioPainter(
                    selected: selected,
                    ink: colors.ink,
                    paper: colors.paper,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a 1-bit radio glyph: a 2px ink-outlined square, filled with ink
/// when [selected] is `true`.
@visibleForTesting
class RadioPainter extends CustomPainter {
  /// Creates a [RadioPainter].
  RadioPainter({
    required this.selected,
    required this.ink,
    required this.paper,
  });

  /// Whether to stamp the filled center.
  final bool selected;

  /// Foreground color.
  final Color ink;

  /// Background color.
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final inkPaint = Paint()..color = ink;
    const t = 2.0;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, t), inkPaint)
      ..drawRect(Rect.fromLTWH(0, size.height - t, size.width, t), inkPaint)
      ..drawRect(Rect.fromLTWH(0, 0, t, size.height), inkPaint)
      ..drawRect(Rect.fromLTWH(size.width - t, 0, t, size.height), inkPaint);
    if (!selected) return;
    final inset = Rect.fromLTWH(
      t * 2,
      t * 2,
      size.width - t * 4,
      size.height - t * 4,
    );
    canvas.drawRect(inset, inkPaint);
  }

  @override
  bool shouldRepaint(RadioPainter old) =>
      old.selected != selected || old.ink != ink || old.paper != paper;
}

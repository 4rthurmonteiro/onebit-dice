import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:provider/provider.dart';

/// Locale picker. "Follow system" appears first, then every entry in
/// [supportedLocales] in its native script. Selecting a row writes the new
/// override (or clears it) via [LocaleController].
class LanguagePicker extends StatelessWidget {
  /// Creates a [LanguagePicker].
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final override = controller.override;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LanguageRow(
          label: context.l10n.settingsLanguageFollowSystem,
          selected: override == null,
          onTap: () => context.read<LocaleController>().clearOverride(),
        ),
        for (final entry in supportedLocales)
          LanguageRow(
            label: entry.nativeName,
            selected: override == entry.locale,
            onTap: () =>
                context.read<LocaleController>().setOverride(entry.locale),
          ),
      ],
    );
  }
}

/// A single tappable language row. Shows the label on the left and a 2px
/// ink `✓`-style marker on the right when [selected].
@visibleForTesting
class LanguageRow extends StatelessWidget {
  /// Creates a [LanguageRow].
  const LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Row label.
  final String label;

  /// Whether the row reflects the active locale.
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
                  painter: CheckmarkPainter(visible: selected, ink: colors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a 1-bit `✓` mark when [visible] is `true`. Otherwise a no-op so
/// the row keeps a stable layout.
@visibleForTesting
class CheckmarkPainter extends CustomPainter {
  /// Creates a [CheckmarkPainter].
  CheckmarkPainter({required this.visible, required this.ink});

  /// Whether to render the mark.
  final bool visible;

  /// Foreground color used for the mark.
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;
    final left = Offset(size.width * 0.15, size.height * 0.55);
    final mid = Offset(size.width * 0.4, size.height * 0.8);
    final right = Offset(size.width * 0.85, size.height * 0.2);
    canvas
      ..drawLine(left, mid, stroke)
      ..drawLine(mid, right, stroke);
  }

  @override
  bool shouldRepaint(CheckmarkPainter old) =>
      old.visible != visible || old.ink != ink;
}

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Maps each [PaletteId] to its localized display name.
String paletteDisplayName(AppLocalizations l10n, PaletteId id) {
  switch (id) {
    case PaletteId.macClassic:
      return l10n.paletteMacClassic;
    case PaletteId.macBeige:
      return l10n.paletteMacBeige;
    case PaletteId.gameBoy:
      return l10n.paletteGameBoy;
    case PaletteId.c64:
      return l10n.paletteC64;
    case PaletteId.zxSpectrum:
      return l10n.paletteZxSpectrum;
    case PaletteId.appleIIGreen:
      return l10n.paletteAppleIIGreen;
    case PaletteId.appleIIeAmber:
      return l10n.paletteAppleIIeAmber;
  }
}

/// Grid of 7 palette swatches. Reads the active palette from [ThemeProvider]
/// and dispatches `setPalette` when a swatch is tapped.
class PaletteSelector extends StatelessWidget {
  /// Creates a [PaletteSelector].
  const PaletteSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ThemeProvider>().current.id;
    final l10n = context.l10n;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final id in PaletteId.values)
          PaletteSwatch(
            id: id,
            name: paletteDisplayName(l10n, id),
            active: id == activeId,
            onTap: () => context.read<ThemeProvider>().setPalette(id),
          ),
      ],
    );
  }
}

/// A single tappable palette swatch. Paints the target palette's `paper`
/// inside a 2px `ink` border; an active swatch fills with `ink` and stamps
/// a paper-colored `✓`-style glyph.
@visibleForTesting
class PaletteSwatch extends StatelessWidget {
  /// Creates a [PaletteSwatch].
  const PaletteSwatch({
    required this.id,
    required this.name,
    required this.active,
    required this.onTap,
    super.key,
  });

  /// Identifier of the palette this swatch represents.
  final PaletteId id;

  /// Localized display name — used as the semantics label.
  final String name;

  /// Whether this swatch reflects the active palette.
  final bool active;

  /// Tap callback.
  final VoidCallback onTap;

  /// Side length of the swatch in logical pixels.
  static const double size = 48;

  @override
  Widget build(BuildContext context) {
    final swatchPalette = Palette.of(id);
    final activeInk = Theme.of(context).extension<OneBitColors>()!.ink;
    return Semantics(
      button: true,
      selected: active,
      label: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: PaletteSwatchPainter(
              fill: swatchPalette.paper,
              border: swatchPalette.ink,
              active: active,
              activeInk: activeInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a single palette swatch.
@visibleForTesting
class PaletteSwatchPainter extends CustomPainter {
  /// Creates a [PaletteSwatchPainter].
  PaletteSwatchPainter({
    required this.fill,
    required this.border,
    required this.active,
    required this.activeInk,
  });

  /// Background color of the swatch (target palette's `paper`).
  final Color fill;

  /// Border color (target palette's `ink`).
  final Color border;

  /// Whether to stamp the active indicator inside.
  final bool active;

  /// `ink` of the currently-active palette — used to paint the active
  /// indicator so it remains visible regardless of the swatch's own colors.
  final Color activeInk;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final borderPaint = Paint()..color = border;
    const t = 2.0;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, size.width, t), borderPaint)
      ..drawRect(Rect.fromLTWH(0, size.height - t, size.width, t), borderPaint)
      ..drawRect(Rect.fromLTWH(0, 0, t, size.height), borderPaint)
      ..drawRect(Rect.fromLTWH(size.width - t, 0, t, size.height), borderPaint);
    if (!active) return;
    // Inner square fill highlight in the currently-active ink so the active
    // swatch is always visually distinct against any palette.
    final inset = Rect.fromLTWH(
      t * 2,
      t * 2,
      size.width - t * 4,
      size.height - t * 4,
    );
    canvas.drawRect(inset, Paint()..color = activeInk);
  }

  @override
  bool shouldRepaint(PaletteSwatchPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.active != active ||
      old.activeInk != activeInk;
}

import 'package:flutter/material.dart';

/// Stable identifier for each of the seven 1-Bit Dice palettes.
///
/// Used as the persistence key (E04) and as the lookup key into
/// [Palette.all].
enum PaletteId {
  /// Default palette — black ink on white paper.
  macClassic,

  /// Black ink on warm beige paper.
  macBeige,

  /// Original Game Boy DMG green-on-green.
  gameBoy,

  /// Commodore 64 purple-on-violet.
  c64,

  /// ZX Spectrum black-on-neon-green.
  zxSpectrum,

  /// Apple II black-on-phosphor-green.
  appleIIGreen,

  /// Apple //e black-on-amber (wildcard).
  appleIIeAmber,
}

/// A two-color 1-bit palette: every UI surface is either [ink] or [paper].
///
/// Hex values mirror `docs/roadmap/02-identidade-visual.md` exactly — the
/// regression test in `palette_test.dart` guards against drift.
@immutable
class Palette {
  /// Creates a palette with the given [id], display [name], and the two
  /// canonical colors [ink] (foreground) and [paper] (background).
  const Palette({
    required this.id,
    required this.name,
    required this.ink,
    required this.paper,
  });

  /// Stable identifier — used for persistence and equality.
  final PaletteId id;

  /// Human-readable display name, e.g. "Mac Classic".
  final String name;

  /// Foreground color — text, icons, borders.
  final Color ink;

  /// Background color — surfaces.
  final Color paper;

  /// Every palette indexed by [PaletteId]. Exactly seven entries.
  static const Map<PaletteId, Palette> all = {
    PaletteId.macClassic: Palette(
      id: PaletteId.macClassic,
      name: 'Mac Classic',
      ink: Color(0xFF000000),
      paper: Color(0xFFFFFFFF),
    ),
    PaletteId.macBeige: Palette(
      id: PaletteId.macBeige,
      name: 'Mac Beige',
      ink: Color(0xFF000000),
      paper: Color(0xFFC7C7C7),
    ),
    PaletteId.gameBoy: Palette(
      id: PaletteId.gameBoy,
      name: 'Game Boy DMG',
      ink: Color(0xFF0F380F),
      paper: Color(0xFF9BBC0F),
    ),
    PaletteId.c64: Palette(
      id: PaletteId.c64,
      name: 'Commodore 64',
      ink: Color(0xFF352879),
      paper: Color(0xFF7869C4),
    ),
    PaletteId.zxSpectrum: Palette(
      id: PaletteId.zxSpectrum,
      name: 'ZX Spectrum',
      ink: Color(0xFF000000),
      paper: Color(0xFF00FF00),
    ),
    PaletteId.appleIIGreen: Palette(
      id: PaletteId.appleIIGreen,
      name: 'Apple II Green',
      ink: Color(0xFF000000),
      paper: Color(0xFF33FF33),
    ),
    PaletteId.appleIIeAmber: Palette(
      id: PaletteId.appleIIeAmber,
      name: 'Apple //e Amber',
      ink: Color(0xFF000000),
      paper: Color(0xFFFF9933),
    ),
  };

  /// Returns the palette registered for [id]. Throws if [id] has no entry.
  static Palette of(PaletteId id) => all[id]!;
}

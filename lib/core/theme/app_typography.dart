import 'package:flutter/painting.dart';

/// The three canonical pixel typography styles used across the 1-Bit Dice app.
///
/// All styles disable ligatures so bitmap fonts render at the intended glyph
/// boundaries. Color is intentionally unset — consumers tint per palette via
/// [TextStyle.copyWith] (typically `palette.ink`).
abstract final class AppTypography {
  static const List<FontFeature> _noLiga = [FontFeature.disable('liga')];

  /// Display / titles. Silkscreen at 24px.
  static const TextStyle display = TextStyle(
    fontFamily: 'Silkscreen',
    fontSize: 24,
    fontFeatures: _noLiga,
  );

  /// Body / UI. VT323 at 18px.
  static const TextStyle body = TextStyle(
    fontFamily: 'VT323',
    fontSize: 18,
    fontFeatures: _noLiga,
  );

  /// Micro / footer. Press Start 2P at 10px.
  static const TextStyle micro = TextStyle(
    fontFamily: 'PressStart2P',
    fontSize: 10,
    fontFeatures: _noLiga,
  );
}

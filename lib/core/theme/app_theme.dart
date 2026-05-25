import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/core/theme/palette.dart';

/// `ThemeExtension` carrying the two canonical 1-bit colors for the active
/// palette.
///
/// Custom widgets (`MacButton`, `MacWindow`, `PixelDivider`) read these via
/// `Theme.of(context).extension<OneBitColors>()!` rather than touching
/// [Palette] directly, so they stay decoupled from how the active palette is
/// distributed.
@immutable
class OneBitColors extends ThemeExtension<OneBitColors> {
  /// Creates a [OneBitColors] extension with the given [ink] and [paper].
  const OneBitColors({required this.ink, required this.paper});

  /// Foreground color — text, borders, icons.
  final Color ink;

  /// Background color — surfaces.
  final Color paper;

  @override
  OneBitColors copyWith({Color? ink, Color? paper}) =>
      OneBitColors(ink: ink ?? this.ink, paper: paper ?? this.paper);

  @override
  OneBitColors lerp(ThemeExtension<OneBitColors>? other, double t) => this;
}

/// Builds the [ThemeData] for [palette].
///
/// Every [ColorScheme] slot is mapped explicitly to `ink` or `paper` so
/// Material never falls back to a derived tonal color (which would break the
/// strict 1-bit rule).
ThemeData buildThemeData(Palette palette) {
  final brightness = palette.paper.computeLuminance() > 0.5
      ? Brightness.light
      : Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.ink,
    onPrimary: palette.paper,
    secondary: palette.ink,
    onSecondary: palette.paper,
    tertiary: palette.ink,
    onTertiary: palette.paper,
    error: palette.ink,
    onError: palette.paper,
    surface: palette.paper,
    onSurface: palette.ink,
    surfaceContainerHighest: palette.paper,
    onSurfaceVariant: palette.ink,
    outline: palette.ink,
    outlineVariant: palette.ink,
    inverseSurface: palette.ink,
    onInverseSurface: palette.paper,
    inversePrimary: palette.paper,
    shadow: palette.ink,
    scrim: palette.ink,
  );

  TextStyle inked(TextStyle s) => s.copyWith(color: palette.ink);
  final textTheme = TextTheme(
    displayLarge: inked(AppTypography.display),
    displayMedium: inked(AppTypography.display),
    displaySmall: inked(AppTypography.display),
    headlineLarge: inked(AppTypography.display),
    headlineMedium: inked(AppTypography.display),
    headlineSmall: inked(AppTypography.display),
    titleLarge: inked(AppTypography.display),
    titleMedium: inked(AppTypography.body),
    titleSmall: inked(AppTypography.body),
    bodyLarge: inked(AppTypography.body),
    bodyMedium: inked(AppTypography.body),
    bodySmall: inked(AppTypography.body),
    labelLarge: inked(AppTypography.micro),
    labelMedium: inked(AppTypography.micro),
    labelSmall: inked(AppTypography.micro),
  );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.paper,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [OneBitColors(ink: palette.ink, paper: palette.paper)],
  );
}

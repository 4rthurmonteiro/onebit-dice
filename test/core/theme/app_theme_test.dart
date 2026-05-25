import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';

void main() {
  group('buildThemeData', () {
    for (final id in PaletteId.values) {
      group(id.name, () {
        final palette = Palette.of(id);
        final theme = buildThemeData(palette);

        test('exposes OneBitColors with ink and paper', () {
          final ext = theme.extension<OneBitColors>();
          expect(ext, isNotNull);
          expect(ext!.ink, palette.ink);
          expect(ext.paper, palette.paper);
        });

        test('scaffoldBackgroundColor == paper', () {
          expect(theme.scaffoldBackgroundColor, palette.paper);
        });

        test('disables splash and highlight', () {
          expect(theme.splashFactory, NoSplash.splashFactory);
          expect(theme.highlightColor, Colors.transparent);
        });

        test('ColorScheme maps every slot to ink or paper', () {
          final cs = theme.colorScheme;
          final allowed = {palette.ink, palette.paper};
          expect(allowed.contains(cs.primary), isTrue);
          expect(allowed.contains(cs.onPrimary), isTrue);
          expect(allowed.contains(cs.secondary), isTrue);
          expect(allowed.contains(cs.onSecondary), isTrue);
          expect(allowed.contains(cs.tertiary), isTrue);
          expect(allowed.contains(cs.onTertiary), isTrue);
          expect(allowed.contains(cs.error), isTrue);
          expect(allowed.contains(cs.onError), isTrue);
          expect(cs.surface, palette.paper);
          expect(cs.onSurface, palette.ink);
          expect(allowed.contains(cs.surfaceContainerHighest), isTrue);
          expect(allowed.contains(cs.onSurfaceVariant), isTrue);
          expect(allowed.contains(cs.outline), isTrue);
          expect(allowed.contains(cs.outlineVariant), isTrue);
          expect(allowed.contains(cs.inverseSurface), isTrue);
          expect(allowed.contains(cs.onInverseSurface), isTrue);
          expect(allowed.contains(cs.inversePrimary), isTrue);
          expect(allowed.contains(cs.shadow), isTrue);
          expect(allowed.contains(cs.scrim), isTrue);
        });

        test('TextTheme tints body and display with ink', () {
          expect(theme.textTheme.bodyMedium?.color, palette.ink);
          expect(theme.textTheme.displayLarge?.color, palette.ink);
          expect(theme.textTheme.labelSmall?.color, palette.ink);
        });
      });
    }

    test('macClassic (white paper) is a light theme', () {
      final theme = buildThemeData(Palette.of(PaletteId.macClassic));
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('c64 (dark paper) is a dark theme', () {
      final theme = buildThemeData(Palette.of(PaletteId.c64));
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });
  });

  group('OneBitColors', () {
    const original = OneBitColors(
      ink: Color(0xFF000000),
      paper: Color(0xFFFFFFFF),
    );

    test('copyWith updates only provided fields', () {
      final updated = original.copyWith(ink: const Color(0xFF111111));
      expect(updated.ink, const Color(0xFF111111));
      expect(updated.paper, const Color(0xFFFFFFFF));

      final paperOnly = original.copyWith(paper: const Color(0xFFEEEEEE));
      expect(paperOnly.ink, const Color(0xFF000000));
      expect(paperOnly.paper, const Color(0xFFEEEEEE));

      final identical = original.copyWith();
      expect(identical.ink, original.ink);
      expect(identical.paper, original.paper);
    });

    test('lerp returns this — no interpolation in 1-bit', () {
      const other = OneBitColors(
        ink: Color(0xFFFFFFFF),
        paper: Color(0xFF000000),
      );
      expect(original.lerp(other, 0.5), same(original));
      expect(original.lerp(null, 0.5), same(original));
    });
  });
}

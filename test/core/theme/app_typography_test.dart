import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

void main() {
  group('AppTypography', () {
    test('display uses Silkscreen at 24px with ligatures disabled', () {
      expect(AppTypography.display.fontFamily, 'Silkscreen');
      expect(AppTypography.display.fontSize, 24);
      expect(
        AppTypography.display.fontFeatures,
        contains(const FontFeature.disable('liga')),
      );
    });

    test('body uses VT323 at 18px with ligatures disabled', () {
      expect(AppTypography.body.fontFamily, 'VT323');
      expect(AppTypography.body.fontSize, 18);
      expect(
        AppTypography.body.fontFeatures,
        contains(const FontFeature.disable('liga')),
      );
    });

    test('micro uses PressStart2P at 10px with ligatures disabled', () {
      expect(AppTypography.micro.fontFamily, 'PressStart2P');
      expect(AppTypography.micro.fontSize, 10);
      expect(
        AppTypography.micro.fontFeatures,
        contains(const FontFeature.disable('liga')),
      );
    });
  });
}

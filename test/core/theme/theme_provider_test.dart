import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';

import '../../support/mock_analytics_service.dart';

class _MockPalettePreference extends Mock implements PalettePreference {}

void main() {
  setUpAll(() => registerFallbackValue(PaletteId.macClassic));

  late _MockPalettePreference preference;
  late MockAnalyticsService analytics;

  setUp(() {
    preference = _MockPalettePreference();
    analytics = createStubbedAnalytics();
    when(() => preference.read()).thenReturn(null);
    when(() => preference.write(any())).thenAnswer((_) async {});
  });

  ThemeProvider build() =>
      ThemeProvider(analytics: analytics, preference: preference);

  group('ThemeProvider', () {
    test('defaults to macClassic when no preference is stored', () {
      expect(build().current.id, PaletteId.macClassic);
    });

    test('reads the initial palette from preference when stored', () {
      when(() => preference.read()).thenReturn(PaletteId.gameBoy);
      expect(build().current.id, PaletteId.gameBoy);
    });

    test('setPalette updates current and notifies exactly once', () async {
      final provider = build();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setPalette(PaletteId.zxSpectrum);

      expect(provider.current.id, PaletteId.zxSpectrum);
      expect(notifications, 1);
    });

    test('setPalette writes the new id to preference', () async {
      final provider = build();

      await provider.setPalette(PaletteId.c64);

      verify(() => preference.write(PaletteId.c64)).called(1);
    });

    test('setPalette is a no-op when id matches current', () async {
      when(() => preference.read()).thenReturn(PaletteId.macBeige);
      final provider = build();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setPalette(PaletteId.macBeige);

      expect(provider.current.id, PaletteId.macBeige);
      expect(notifications, 0);
      verifyNever(() => preference.write(any()));
    });

    test('setPalette logs palette_changed with the palette id', () async {
      final provider = build();

      await provider.setPalette(PaletteId.gameBoy);

      verify(
        () => analytics.logEvent(
          'palette_changed',
          parameters: {'palette_id': 'gameBoy'},
        ),
      ).called(1);
    });

    test('a no-op setPalette does not log', () async {
      when(() => preference.read()).thenReturn(PaletteId.c64);
      final provider = build();

      await provider.setPalette(PaletteId.c64);

      verifyNever(
        () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
      );
    });
  });
}

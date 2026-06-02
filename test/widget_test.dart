import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/features/splash/splash_screen.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'support/mock_analytics_service.dart';
import 'support/mock_history_repository.dart';
import 'support/mock_presets_repository.dart';

class _NoopSoundPlayer implements SoundPlayer {
  @override
  Future<void> init() async {}

  @override
  void play(SoundEvent event) {}

  @override
  Future<void> stopAll() async {}

  @override
  Future<void> dispose() async {}
}

class _MockAppSettings extends Mock implements AppSettingsPreference {}

class _MockLastDice extends Mock implements LastDiceConfigPreference {}

class _MockPalettePreference extends Mock implements PalettePreference {}

class _MockLocalePreference extends Mock implements LocalePreference {}

App _buildApp() {
  registerFallbackValue(PaletteId.macClassic);

  final analytics = createStubbedAnalytics();
  final settings = _MockAppSettings();
  when(settings.readSoundEnabled).thenReturn(null);
  when(settings.readHapticEnabled).thenReturn(null);
  when(settings.readAnimationStyle).thenReturn(null);
  when(settings.readAnimationSpeed).thenReturn(null);

  final lastDice = _MockLastDice();
  when(lastDice.read).thenReturn(null);

  final palettePref = _MockPalettePreference();
  when(palettePref.read).thenReturn(null);
  when(() => palettePref.write(any())).thenAnswer((_) async {});

  final localePref = _MockLocalePreference();
  when(localePref.read).thenReturn(null);

  return App(
    audioController: AudioController(
      preference: settings,
      analytics: analytics,
      player: _NoopSoundPlayer(),
    ),
    hapticController: HapticController(
      preference: settings,
      analytics: analytics,
      trigger: () async {},
    ),
    animationSettingsController: AnimationSettingsController(
      preference: settings,
      analytics: analytics,
    ),
    analyticsService: analytics,
    historyRepository: createFakeHistory(),
    presetsRepository: createFakePresets(),
    lastDiceConfigPreference: lastDice,
    palettePreference: palettePref,
    localePreference: localePref,
  );
}

void main() {
  testWidgets('App shows the splash first, then routes to DiceScreen', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(DiceScreen), findsNothing);

    await tester.pump(SplashScreen.splashDuration);
    await tester.pumpAndSettle();

    expect(find.byType(DiceScreen), findsOneWidget);

    final context = tester.element(find.byType(DiceScreen));
    expect(context.read<ThemeProvider>().current.id, PaletteId.macClassic);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      Palette.of(PaletteId.macClassic).paper,
    );
  });

  testWidgets(
    'changing palette through the provider rebuilds the theme without '
    'resetting the active route',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pump(SplashScreen.splashDuration);
      await tester.pumpAndSettle();

      final provider = tester
          .element(find.byType(DiceScreen))
          .read<ThemeProvider>();
      await provider.setPalette(PaletteId.gameBoy);
      await tester.pumpAndSettle();

      expect(provider.current.id, PaletteId.gameBoy);
      // The dice route stayed active across the palette swap — the router
      // was not rebuilt.
      expect(find.byType(DiceScreen), findsOneWidget);
    },
  );

  group('MaterialApp i18n wiring', () {
    testWidgets('exposes all 10 supported locales', (tester) async {
      await tester.pumpWidget(_buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.supportedLocales.length, 10);
      expect(app.supportedLocales, [
        for (final entry in supportedLocales) entry.locale,
      ]);
    });

    testWidgets('registers AppLocalizations.delegate', (tester) async {
      await tester.pumpWidget(_buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
    });

    testWidgets('uses MaterialApp.router (routerConfig is wired)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.routerConfig, isNotNull);
    });
  });

  group('resolveLocale', () {
    final supported = [for (final entry in supportedLocales) entry.locale];

    test('returns EN when the device locale is null', () {
      expect(resolveLocale(null, supported), const Locale('en'));
    });

    test('returns the exact PT-BR entry for a PT-BR device locale', () {
      expect(
        resolveLocale(const Locale('pt', 'BR'), supported),
        const Locale('pt', 'BR'),
      );
    });

    test('returns the zh-Hans entry when device locale shares the zh language '
        'code but differs in country', () {
      final result = resolveLocale(const Locale('zh', 'CN'), supported);
      expect(result.languageCode, 'zh');
      expect(result.scriptCode, 'Hans');
    });

    test('returns EN when no supported locale shares the language code', () {
      expect(resolveLocale(const Locale('ar'), supported), const Locale('en'));
    });

    test(
      'returns the language-only entry when supported has no country variant',
      () {
        expect(
          resolveLocale(const Locale('en', 'US'), supported),
          const Locale('en'),
        );
      },
    );
  });
}

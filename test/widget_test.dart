import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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

App _buildApp() {
  final settings = InMemoryAppSettingsPreference();
  return App(
    audioController: AudioController(
      preference: settings,
      player: _NoopSoundPlayer(),
    ),
    hapticController: HapticController(
      preference: settings,
      trigger: () async {},
    ),
  );
}

void main() {
  testWidgets('App renders the design system preview at the Mac Classic '
      'palette by default', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pump();

    expect(find.byType(DiceScreen), findsOneWidget);
    expect(find.text('1-BIT DICE'), findsOneWidget);

    final context = tester.element(find.byType(DiceScreen));
    expect(context.read<ThemeProvider>().current.id, PaletteId.macClassic);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      Palette.of(PaletteId.macClassic).paper,
    );
  });

  testWidgets('changing palette through the provider rebuilds the theme', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final provider = tester
        .element(find.byType(DiceScreen))
        .read<ThemeProvider>();
    await provider.setPalette(PaletteId.gameBoy);
    await tester.pumpAndSettle();

    expect(provider.current.id, PaletteId.gameBoy);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Palette.of(PaletteId.gameBoy).paper);
  });

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

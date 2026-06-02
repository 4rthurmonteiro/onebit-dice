import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/features/settings/settings_screen.dart';
import 'package:onebit_dice/features/settings/widgets/about_section.dart';
import 'package:onebit_dice/features/settings/widgets/animation_section.dart';
import 'package:onebit_dice/features/settings/widgets/language_picker.dart';
import 'package:onebit_dice/features/settings/widgets/palette_selector.dart';
import 'package:onebit_dice/features/settings/widgets/settings_section.dart';
import 'package:onebit_dice/features/settings/widgets/toggle_tile.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../support/mock_analytics_service.dart';

class _NoopPlayer implements SoundPlayer {
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

class _MockPalettePreference extends Mock implements PalettePreference {}

class _MockLocalePreference extends Mock implements LocalePreference {}

Widget _harness({Locale locale = const Locale('en')}) {
  registerFallbackValue(AnimationStyle.drum);
  registerFallbackValue(AnimationSpeed.medium);
  registerFallbackValue(PaletteId.macClassic);
  registerFallbackValue(const Locale('en'));

  final analytics = createStubbedAnalytics();
  final prefs = _MockAppSettings();
  when(prefs.readSoundEnabled).thenReturn(null);
  when(prefs.readHapticEnabled).thenReturn(null);
  when(prefs.readAnimationStyle).thenReturn(null);
  when(prefs.readAnimationSpeed).thenReturn(null);
  when(
    () => prefs.writeSoundEnabled(value: any(named: 'value')),
  ).thenAnswer((_) async {});
  when(
    () => prefs.writeHapticEnabled(value: any(named: 'value')),
  ).thenAnswer((_) async {});
  when(() => prefs.writeAnimationStyle(any())).thenAnswer((_) async {});
  when(() => prefs.writeAnimationSpeed(any())).thenAnswer((_) async {});

  final palettePref = _MockPalettePreference();
  when(palettePref.read).thenReturn(null);
  when(() => palettePref.write(any())).thenAnswer((_) async {});

  final localePref = _MockLocalePreference();
  when(localePref.read).thenReturn(null);
  when(() => localePref.write(any())).thenAnswer((_) async {});

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AudioController>(
        create: (_) => AudioController(
          preference: prefs,
          analytics: analytics,
          player: _NoopPlayer(),
        ),
      ),
      ChangeNotifierProvider<HapticController>(
        create: (_) => HapticController(
          preference: prefs,
          analytics: analytics,
          trigger: () async {},
        ),
      ),
      ChangeNotifierProvider<AnimationSettingsController>(
        create: (_) => AnimationSettingsController(
          preference: prefs,
          analytics: analytics,
        ),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) =>
            ThemeProvider(analytics: analytics, preference: palettePref),
      ),
      ChangeNotifierProvider<LocaleController>(
        create: (_) =>
            LocaleController(analytics: analytics, preference: localePref),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders the localized AppBar title', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders the localized AppBar title in pt-BR', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('pt', 'BR')));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes'), findsOneWidget);
    });

    testWidgets('renders the five sections in order', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final sections = tester
          .widgetList<SettingsSection>(find.byType(SettingsSection))
          .toList();
      expect(sections.map((s) => s.title), [
        'Appearance',
        'Feedback',
        'Animation',
        'Language',
        'About',
      ]);
    });

    testWidgets('mounts every section widget exactly once', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.byType(PaletteSelector), findsOneWidget);
      expect(find.byType(AnimationSection), findsOneWidget);
      expect(find.byType(LanguagePicker), findsOneWidget);
      expect(find.byType(AboutSection), findsOneWidget);
      // Feedback section: 2 ToggleTiles (sound + haptic).
      expect(find.byType(ToggleTile), findsNWidgets(2));
    });

    testWidgets('uses palette paper as scaffold background', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Palette.of(PaletteId.macClassic).paper);
    });

    testWidgets('tapping the Sound toggle flips AudioController.soundEnabled', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(SettingsScreen));
      final audio = ctx.read<AudioController>();
      expect(audio.soundEnabled, isTrue);

      await tester.tap(
        find.byWidgetPredicate((w) => w is ToggleTile && w.label == 'Sound'),
      );
      await tester.pumpAndSettle();

      expect(audio.soundEnabled, isFalse);
    });

    testWidgets(
      'tapping the Haptic toggle flips HapticController.hapticEnabled',
      (tester) async {
        await tester.pumpWidget(_harness());
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(SettingsScreen));
        final haptic = ctx.read<HapticController>();
        expect(haptic.hapticEnabled, isTrue);

        await tester.tap(
          find.byWidgetPredicate((w) => w is ToggleTile && w.label == 'Haptic'),
        );
        await tester.pumpAndSettle();

        expect(haptic.hapticEnabled, isFalse);
      },
    );
  });
}

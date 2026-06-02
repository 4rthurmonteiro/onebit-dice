// Store-screenshot harness.
//
// Drives the real [App] through its main screens and captures a PNG of each
// via `binding.takeScreenshot`. Run it against a device/simulator with:
//
//   flutter drive \
//     --driver=integration_test/test_driver/integration_test.dart \
//     --target=integration_test/store_screenshots_test.dart
//
// The driver writes each frame to `docs/store/android/screenshots/<name>.png`.
//
// This is a tooling target, not part of the unit suite (`flutter test` only
// runs `test/`), so it sits outside the 100% line-coverage gate.
import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/features/splash/splash_screen.dart';

import '../test/support/mock_analytics_service.dart';
import '../test/support/mock_history_repository.dart';
import '../test/support/mock_presets_repository.dart';

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

/// A spread of rolls so the History tab shows a populated list (not the
/// empty state). Fixed timestamps keep the capture reproducible.
List<RollResult> _seedHistory() => [
  RollResult(
    timestamp: DateTime(2026, 5, 30, 21, 14),
    diceType: DiceType.d20,
    diceCount: 1,
    values: const [18],
  ),
  RollResult(
    timestamp: DateTime(2026, 5, 30, 21, 12),
    diceType: DiceType.d6,
    diceCount: 3,
    values: const [4, 2, 6],
  ),
  RollResult(
    timestamp: DateTime(2026, 5, 30, 21, 9),
    diceType: DiceType.d8,
    diceCount: 2,
    values: const [7, 3],
  ),
  RollResult(
    timestamp: DateTime(2026, 5, 30, 20, 58),
    diceType: DiceType.d6,
    diceCount: 1,
    values: const [5],
  ),
  RollResult(
    timestamp: DateTime(2026, 5, 30, 20, 51),
    diceType: DiceType.d12,
    diceCount: 1,
    values: const [11],
  ),
];

App _buildApp({
  required Locale locale,
  required PaletteId palette,
  required Key key,
}) {
  registerFallbackValue(PaletteId.macClassic);
  registerFallbackValue(const LastDiceConfig(diceType: DiceType.d6, count: 1));

  final analytics = createStubbedAnalytics();

  final settings = _MockAppSettings();
  when(settings.readSoundEnabled).thenReturn(false);
  when(settings.readHapticEnabled).thenReturn(false);
  // `fast` resolves to a 100ms settle, so a rolled result paints its final
  // faces (and the total) almost immediately — no tumbling mid-capture.
  when(settings.readAnimationStyle).thenReturn(AnimationStyle.fast);
  when(settings.readAnimationSpeed).thenReturn(AnimationSpeed.medium);

  final lastDice = _MockLastDice();
  when(lastDice.read).thenReturn(null);
  when(() => lastDice.write(any())).thenAnswer((_) async {});

  final palettePref = _MockPalettePreference();
  // Boot straight into the requested palette so each capture renders in it.
  when(palettePref.read).thenReturn(palette);
  when(() => palettePref.write(any())).thenAnswer((_) async {});

  final localePref = _MockLocalePreference();
  // Force the requested locale regardless of the device locale.
  when(localePref.read).thenReturn(locale);

  return App(
    key: key,
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
    historyRepository: createFakeHistory(seed: _seedHistory()),
    presetsRepository: createFakePresets(),
    lastDiceConfigPreference: lastDice,
    palettePreference: palettePref,
    localePreference: localePref,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Captures every screen, for every palette, in every supported locale.
  // Output: docs/store/android/screenshots/<locale-tag>/<palette>/NN-screen.png
  testWidgets('captures the full screenshot matrix', (tester) async {
    // No-op on iOS; on Android swaps the surface for an image so screenshots
    // can be captured. Called once for the whole run.
    await binding.convertFlutterSurfaceToImage();

    for (final entry in supportedLocales) {
      final localeTag = entry.locale.toLanguageTag();
      for (final palette in PaletteId.values) {
        final dir = '$localeTag/${palette.name}';

        // A fresh key per combo forces a brand-new element tree (and a new
        // GoRouter starting at the splash) instead of reusing the previous
        // combo's state, which would stay parked on the last route.
        await tester.pumpWidget(
          _buildApp(locale: entry.locale, palette: palette, key: ValueKey(dir)),
        );
        // Let the splash timer auto-route to the dice tab.
        await tester.pump(SplashScreen.splashDuration);
        await tester.pumpAndSettle();
        // DiceScreen is on-screen now; the router persists for the whole combo.
        final router = GoRouter.of(tester.element(find.byType(DiceScreen)));

        // 1 — Home (hero): roll once so the canvas shows a result + total.
        await tester.tap(find.byType(DiceScreen));
        await tester.pump(); // result painted
        await tester.pump(const Duration(milliseconds: 300)); // reveal total
        await binding.takeScreenshot('$dir/01-home-rolled');

        // 2 — Dice type selector sheet open.
        await tester.tap(find.byType(TypeSelector));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$dir/02-dice-type-sheet');
        Navigator.of(tester.element(find.byType(DiceScreen))).pop();
        await tester.pumpAndSettle();

        // 3 — History (seeded list).
        router.go('/history');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$dir/03-history');

        // 4 — Presets / Games (built-ins).
        router.go('/presets');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$dir/04-presets');

        // 5 — Settings (palette + language selectors).
        router.go('/settings');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('$dir/05-settings');
      }
    }
  });
}

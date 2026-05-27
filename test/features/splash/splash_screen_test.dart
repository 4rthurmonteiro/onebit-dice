import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/app_router.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/splash/splash_screen.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';
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

Widget _harness({Locale locale = const Locale('en')}) {
  // Wire just enough providers for `/dice` to mount when the splash navigates.
  final settings = InMemoryAppSettingsPreference();
  return MultiProvider(
    providers: [
      Provider<HistoryRepository>(create: (_) => InMemoryHistoryRepository()),
      Provider<LastDiceConfigPreference>(
        create: (_) => InMemoryLastDiceConfigPreference(),
      ),
      Provider<AppSettingsPreference>.value(value: settings),
      ChangeNotifierProvider<AudioController>(
        create: (_) =>
            AudioController(preference: settings, player: _NoopSoundPlayer()),
      ),
      ChangeNotifierProvider<HapticController>(
        create: (_) =>
            HapticController(preference: settings, trigger: () async {}),
      ),
      ChangeNotifierProvider<DiceController>(
        create: (ctx) => DiceController(
          history: ctx.read(),
          audio: ctx.read(),
          haptic: ctx.read(),
          lastDiceConfig: ctx.read(),
        ),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      routerConfig: buildAppRouter(),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
}

void main() {
  group('SplashScreen', () {
    testWidgets('renders wordmark, tagline, d6 pixel art, and footer', (
      tester,
    ) async {
      await _pump(tester, _harness());
      await tester.pump();

      expect(find.text('1-BIT\nDICE'), findsOneWidget);
      expect(find.text('DICE FOR EVERY GAME'), findsOneWidget);
      expect(find.byType(PixelIcon), findsOneWidget);
      expect(find.byType(PixelDivider), findsOneWidget);
      expect(find.text('v1.0 · am2 studios'), findsOneWidget);
      expect(
        find.text('part of the call of old chico universe'),
        findsOneWidget,
      );
    });

    testWidgets('localizes tagline and microcopy in PT-BR', (tester) async {
      await _pump(tester, _harness(locale: const Locale('pt', 'BR')));
      await tester.pump();

      expect(find.text('DADO PARA TODO JOGO'), findsOneWidget);
      expect(find.text('parte do universo call of old chico'), findsOneWidget);
    });

    testWidgets('uses hard-coded #FFFFFF background, not the palette paper', (
      tester,
    ) async {
      await _pump(tester, _harness());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(Scaffold),
        ),
      );
      expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('COCU microcopy is italic and uses a muted gray color', (
      tester,
    ) async {
      await _pump(tester, _harness());
      await tester.pump();

      final text = tester.widget<Text>(
        find.text('part of the call of old chico universe'),
      );
      expect(text.style?.fontStyle, FontStyle.italic);
      expect(text.style?.color, const Color(0xFF888888));
    });

    testWidgets('navigates to /dice after splashDuration', (tester) async {
      await _pump(tester, _harness());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(DiceScreen), findsNothing);

      await tester.pump(SplashScreen.splashDuration);
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(DiceScreen), findsOneWidget);
    });

    testWidgets(
      'cancels timer in dispose without throwing when the splash unmounts',
      (tester) async {
        await _pump(tester, _harness());
        await tester.pump();

        // Replace the entire tree before the timer fires.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.pump(SplashScreen.splashDuration);
        await tester.pumpAndSettle();

        // No exception should be thrown by the cancelled timer.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('splashDuration is exactly 1500ms', (tester) async {
      expect(SplashScreen.splashDuration, const Duration(milliseconds: 1500));
    });
  });

  group('GoRouter integration', () {
    testWidgets('deep link to /history skips the splash entirely', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: HistoryRoute.path,
        routes: $appRoutes,
      );
      await _pump(
        tester,
        Provider<HistoryRepository>(
          create: (_) => InMemoryHistoryRepository(),
          child: MaterialApp.router(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: buildThemeData(Palette.of(PaletteId.macClassic)),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('History'), findsOneWidget);
    });
  });
}

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
import 'package:onebit_dice/features/history/history_screen.dart';
import 'package:onebit_dice/features/presets/presets_screen.dart';
import 'package:onebit_dice/features/settings/settings_screen.dart';
import 'package:onebit_dice/features/shell/app_shell.dart';
import 'package:onebit_dice/features/splash/splash_screen.dart';
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

Widget _harness(GoRouter router) {
  final settings = InMemoryAppSettingsPreference();
  return MultiProvider(
    providers: [
      Provider<HistoryRepository>(create: (_) => InMemoryHistoryRepository()),
      Provider<LastDiceConfigPreference>(
        create: (_) => InMemoryLastDiceConfigPreference(),
      ),
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
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      routerConfig: router,
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
}

GoRouter _at(String path) =>
    GoRouter(initialLocation: path, routes: $appRoutes);

void main() {
  group('buildAppRouter', () {
    test('SplashRoute.path is "/"', () {
      expect(SplashRoute.path, '/');
    });

    test('exposes 4 branches in the StatefulShellRoute', () {
      final router = buildAppRouter();
      final shell = router.configuration.routes
          .whereType<StatefulShellRoute>()
          .single;
      expect(shell.branches, hasLength(4));
    });

    test('each branch maps to the expected canonical path', () {
      expect(DiceRoute.path, '/dice');
      expect(HistoryRoute.path, '/history');
      expect(PresetsRoute.path, '/presets');
      expect(SettingsRoute.path, '/settings');
    });

    test('every branch and route data class is constructible', () {
      // Const expressions are folded at compile time and never show as hits
      // in coverage. Call each constructor non-const so the declarations
      // actually execute.
      // Non-const so coverage records the constructor call.
      // ignore: prefer_const_constructors
      expect(DiceBranch(), isA<StatefulShellBranchData>());
      // Non-const so coverage records the constructor call.
      // ignore: prefer_const_constructors
      expect(HistoryBranch(), isA<StatefulShellBranchData>());
      // Non-const so coverage records the constructor call.
      // ignore: prefer_const_constructors
      expect(PresetsBranch(), isA<StatefulShellBranchData>());
      // Non-const so coverage records the constructor call.
      // ignore: prefer_const_constructors
      expect(SettingsBranch(), isA<StatefulShellBranchData>());
      // Non-const so coverage records the constructor call.
      // ignore: prefer_const_constructors
      expect(MainShellRoute(), isA<StatefulShellRouteData>());
    });
  });

  group('Route resolution', () {
    testWidgets('/ resolves to SplashScreen', (tester) async {
      await _pump(tester, _harness(buildAppRouter()));
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('/dice resolves to DiceScreen inside AppShell', (tester) async {
      await _pump(tester, _harness(_at(DiceRoute.path)));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(DiceScreen), findsOneWidget);
    });

    testWidgets('/history resolves to HistoryScreen inside AppShell', (
      tester,
    ) async {
      await _pump(tester, _harness(_at(HistoryRoute.path)));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(HistoryScreen), findsOneWidget);
    });

    testWidgets('/presets resolves to PresetsScreen inside AppShell', (
      tester,
    ) async {
      await _pump(tester, _harness(_at(PresetsRoute.path)));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(PresetsScreen), findsOneWidget);
    });

    testWidgets('/settings resolves to SettingsScreen inside AppShell', (
      tester,
    ) async {
      await _pump(tester, _harness(_at(SettingsRoute.path)));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
      'splash navigates to /dice via DiceRoute.go after splashDuration',
      (tester) async {
        await _pump(tester, _harness(buildAppRouter()));
        await tester.pump();
        expect(find.byType(SplashScreen), findsOneWidget);

        await tester.pump(SplashScreen.splashDuration);
        await tester.pumpAndSettle();

        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byType(DiceScreen), findsOneWidget);
        expect(find.byType(AppShell), findsOneWidget);
      },
    );
  });
}

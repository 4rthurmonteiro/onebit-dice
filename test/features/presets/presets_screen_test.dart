import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/app_router.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/presets/preset_data.dart';
import 'package:onebit_dice/features/presets/widgets/add_preset_button.dart';
import 'package:onebit_dice/features/presets/widgets/create_preset_sheet.dart';
import 'package:onebit_dice/features/presets/widgets/preset_card.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';
import 'package:provider/provider.dart';

import '../../support/mock_analytics_service.dart';
import '../../support/mock_history_repository.dart';
import '../../support/mock_presets_repository.dart';

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

Widget _harness({
  required PresetsRepository repository,
  Locale locale = const Locale('en'),
  MockAnalyticsService? analytics,
}) {
  registerFallbackValue(const LastDiceConfig(diceType: DiceType.d6, count: 1));

  final analyticsService = analytics ?? createStubbedAnalytics();
  final settings = _MockAppSettings();
  when(settings.readSoundEnabled).thenReturn(null);
  when(settings.readHapticEnabled).thenReturn(null);
  when(settings.readAnimationStyle).thenReturn(null);
  when(settings.readAnimationSpeed).thenReturn(null);

  final lastDice = _MockLastDice();
  when(lastDice.read).thenReturn(null);
  when(() => lastDice.write(any())).thenAnswer((_) async {});

  final router = GoRouter(
    initialLocation: PresetsRoute.path,
    routes: $appRoutes,
  );
  return MultiProvider(
    providers: [
      Provider<AnalyticsService>.value(value: analyticsService),
      Provider<HistoryRepository>.value(value: createFakeHistory()),
      Provider<PresetsRepository>.value(value: repository),
      Provider<LastDiceConfigPreference>.value(value: lastDice),
      ChangeNotifierProvider<AudioController>(
        create: (_) => AudioController(
          preference: settings,
          analytics: analyticsService,
          player: _NoopSoundPlayer(),
        ),
      ),
      ChangeNotifierProvider<HapticController>(
        create: (_) => HapticController(
          preference: settings,
          analytics: analyticsService,
          trigger: () async {},
        ),
      ),
      ChangeNotifierProvider<AnimationSettingsController>(
        create: (_) => AnimationSettingsController(
          preference: settings,
          analytics: analyticsService,
        ),
      ),
      ChangeNotifierProvider<DiceController>(
        create: (ctx) => DiceController(
          history: ctx.read(),
          audio: ctx.read(),
          haptic: ctx.read(),
          lastDiceConfig: ctx.read(),
          analytics: ctx.read(),
        ),
      ),
    ],
    child: MaterialApp.router(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      routerConfig: router,
    ),
  );
}

void main() {
  group('PresetsScreen', () {
    testWidgets('renders both section headers in EN', (tester) async {
      final repo = createFakePresets();
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('My presets'), findsOneWidget);
    });

    testWidgets('renders the 7 built-in presets in EN', (tester) async {
      final repo = createFakePresets();
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(PresetCard), findsNWidgets(7));
      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text('D&D Attack'), findsOneWidget);
      expect(find.text('Percentile'), findsOneWidget);
    });

    testWidgets('renders pt-BR section headers when locale is pt-BR', (
      tester,
    ) async {
      final repo = createFakePresets();
      await tester.pumpWidget(
        _harness(repository: repo, locale: const Locale('pt', 'BR')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jogos'), findsOneWidget);
      expect(find.text('Meus presets'), findsOneWidget);
    });

    testWidgets('shows + NEW button when canAddMore is true', (tester) async {
      final repo = createFakePresets();
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AddPresetButton), findsOneWidget);
    });

    testWidgets('hides + NEW button when the preset cap is reached', (
      tester,
    ) async {
      final repo = createFakePresets();
      for (var i = 0; i < PresetsRepository.maxPresets; i++) {
        await repo.add(name: 'P$i', diceType: DiceType.d6, diceCount: 1);
      }
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AddPresetButton), findsNothing);
    });

    testWidgets('renders a card for every custom preset', (tester) async {
      final repo = createFakePresets();
      await repo.add(name: 'My D8', diceType: DiceType.d8, diceCount: 3);
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(PresetCard), findsNWidgets(8));
      expect(find.text('My D8'), findsOneWidget);
      expect(find.text('3D8'), findsOneWidget);
    });

    testWidgets(
      'tapping a built-in card applies the config and switches to the roll '
      'tab',
      (tester) async {
        final repo = createFakePresets();
        final analytics = createStubbedAnalytics();
        await tester.pumpWidget(
          _harness(repository: repo, analytics: analytics),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Percentile'));
        await tester.pumpAndSettle();

        final controller = tester
            .element(find.byType(DiceScreen))
            .read<DiceController>();
        expect(controller.selectedType, DiceType.d100);
        expect(controller.count, 1);
        expect(find.byType(DiceScreen), findsOneWidget);
        verify(
          () => analytics.logEvent(
            'preset_used',
            parameters: {'preset_id': 'percentil', 'is_builtin': true},
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping a custom card applies its config and switches to the roll tab',
      (tester) async {
        final repo = createFakePresets();
        final analytics = createStubbedAnalytics();
        await repo.add(name: 'Boss', diceType: DiceType.d12, diceCount: 4);
        final customId = repo.snapshot().single.id;
        await tester.pumpWidget(
          _harness(repository: repo, analytics: analytics),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Boss'));
        await tester.pumpAndSettle();

        final controller = tester
            .element(find.byType(DiceScreen))
            .read<DiceController>();
        expect(controller.selectedType, DiceType.d12);
        expect(controller.count, 4);
        verify(
          () => analytics.logEvent(
            'preset_used',
            parameters: {'preset_id': customId, 'is_builtin': false},
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping + NEW opens the create-preset sheet; saving adds it live',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = createFakePresets();
        await tester.pumpWidget(_harness(repository: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(AddPresetButton));
        await tester.pumpAndSettle();
        expect(find.byType(CreatePresetSheet), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Brand new');
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byType(CreatePresetSheet),
            matching: find.byType(MacButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CreatePresetSheet), findsNothing);
        expect(find.text('Brand new'), findsOneWidget);
      },
    );

    test('builtInPresets has exactly 7 entries', () {
      expect(builtInPresets, hasLength(7));
    });
  });
}

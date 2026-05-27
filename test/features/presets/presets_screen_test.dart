import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/app_router.dart';
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
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';
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

Widget _harness({
  required PresetsRepository repository,
  Locale locale = const Locale('en'),
}) {
  final settings = InMemoryAppSettingsPreference();
  final router = GoRouter(
    initialLocation: PresetsRoute.path,
    routes: $appRoutes,
  );
  return MultiProvider(
    providers: [
      Provider<HistoryRepository>(create: (_) => InMemoryHistoryRepository()),
      Provider<PresetsRepository>.value(value: repository),
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
      final repo = InMemoryPresetsRepository();
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Games'), findsOneWidget);
      expect(find.text('My presets'), findsOneWidget);
    });

    testWidgets('renders the 7 built-in presets in EN', (tester) async {
      final repo = InMemoryPresetsRepository();
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
      final repo = InMemoryPresetsRepository();
      await tester.pumpWidget(
        _harness(repository: repo, locale: const Locale('pt', 'BR')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jogos'), findsOneWidget);
      expect(find.text('Meus presets'), findsOneWidget);
    });

    testWidgets('shows + NEW button when canAddMore is true', (tester) async {
      final repo = InMemoryPresetsRepository();
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AddPresetButton), findsOneWidget);
    });

    testWidgets('hides + NEW button when the preset cap is reached', (
      tester,
    ) async {
      final repo = InMemoryPresetsRepository();
      for (var i = 0; i < PresetsRepository.maxPresets; i++) {
        await repo.add(name: 'P$i', diceType: DiceType.d6, diceCount: 1);
      }
      await tester.pumpWidget(_harness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byType(AddPresetButton), findsNothing);
    });

    testWidgets('renders a card for every custom preset', (tester) async {
      final repo = InMemoryPresetsRepository();
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
        final repo = InMemoryPresetsRepository();
        await tester.pumpWidget(_harness(repository: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Percentile'));
        await tester.pumpAndSettle();

        final controller = tester
            .element(find.byType(DiceScreen))
            .read<DiceController>();
        expect(controller.selectedType, DiceType.d100);
        expect(controller.count, 1);
        expect(find.byType(DiceScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a custom card applies its config and switches to the roll tab',
      (tester) async {
        final repo = InMemoryPresetsRepository();
        await repo.add(name: 'Boss', diceType: DiceType.d12, diceCount: 4);
        await tester.pumpWidget(_harness(repository: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Boss'));
        await tester.pumpAndSettle();

        final controller = tester
            .element(find.byType(DiceScreen))
            .read<DiceController>();
        expect(controller.selectedType, DiceType.d12);
        expect(controller.count, 4);
      },
    );

    testWidgets(
      'tapping + NEW opens the create-preset sheet; saving adds it live',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repo = InMemoryPresetsRepository();
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

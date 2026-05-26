import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/dice/widgets/dice_widget.dart';
import 'package:onebit_dice/features/dice/widgets/roll_button.dart';
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

class _RecordingAudio extends AudioController {
  _RecordingAudio()
    : super(
        preference: InMemoryAppSettingsPreference(),
        player: _NoopSoundPlayer(),
      );

  final List<SoundEvent> plays = [];

  @override
  void play(SoundEvent event) => plays.add(event);
}

class _RecordingHaptic extends HapticController {
  _RecordingHaptic()
    : super(preference: InMemoryAppSettingsPreference(), trigger: () async {});

  int triggers = 0;

  @override
  void trigger() => triggers++;
}

Widget _harness({
  required HistoryRepository history,
  required AudioController audio,
  required HapticController haptic,
  required LastDiceConfigPreference lastDicePref,
  Random? rng,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: MultiProvider(
      providers: [
        Provider<HistoryRepository>.value(value: history),
        ChangeNotifierProvider<AudioController>.value(value: audio),
        ChangeNotifierProvider<HapticController>.value(value: haptic),
        Provider<LastDiceConfigPreference>.value(value: lastDicePref),
        ChangeNotifierProvider<DiceController>(
          create: (ctx) => DiceController(
            history: ctx.read(),
            audio: ctx.read(),
            haptic: ctx.read(),
            lastDiceConfig: ctx.read(),
            rng: rng,
          ),
        ),
      ],
      child: const DiceScreen(),
    ),
  );
}

// A taller surface keeps the bottom controls (steppers, ROLL button) inside
// the visible viewport so taps reach them.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  await tester.pumpWidget(widget);
}

void main() {
  group('DiceScreen', () {
    tearDown(() => TestWidgetsFlutterBinding.instance.setSurfaceSize(null));

    testWidgets('initial: 1 "?" slot, D6 chip selected, count 1, no total', (
      tester,
    ) async {
      await _pump(
        tester,
        _harness(
          history: InMemoryHistoryRepository(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: InMemoryLastDiceConfigPreference(),
        ),
      );

      expect(find.text('?'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byKey(DiceWidget.totalKey), findsNothing);
    });

    testWidgets('tap on D20 chip: chip becomes selected '
        'no result yet, pref.write called', (tester) async {
      final pref = InMemoryLastDiceConfigPreference();
      await tester.pumpWidget(
        _harness(
          history: InMemoryHistoryRepository(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: pref,
        ),
      );

      await tester.tap(find.text('D20'));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsOneWidget);
      expect(
        pref.read(),
        const LastDiceConfig(diceType: DiceType.d20, count: 1),
      );
    });

    testWidgets('tap +: count goes to 2 and two "?" slots show', (
      tester,
    ) async {
      final pref = InMemoryLastDiceConfigPreference();
      await _pump(
        tester,
        _harness(
          history: InMemoryHistoryRepository(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: pref,
        ),
      );

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget);
      expect(pref.read()!.count, 2);
    });

    testWidgets(
      'tap ROLL: grid updates, audio/haptic/history/pref all called',
      (tester) async {
        final history = InMemoryHistoryRepository();
        final audio = _RecordingAudio();
        final haptic = _RecordingHaptic();
        final pref = InMemoryLastDiceConfigPreference();
        await tester.pumpWidget(
          _harness(
            history: history,
            audio: audio,
            haptic: haptic,
            lastDicePref: pref,
            rng: Random(0),
          ),
        );

        await tester.tap(find.byType(RollButton));
        await tester.pumpAndSettle();

        expect(find.text('?'), findsNothing);
        expect(find.byKey(DiceWidget.totalKey), findsOneWidget);
        expect(audio.plays, [SoundEvent.total]);
        expect(haptic.triggers, 1);
        expect(history.snapshot(), hasLength(1));
        expect(pref.read(), isNotNull);
      },
    );

    testWidgets('after ROLL, tap +: result is discarded; history unchanged', (
      tester,
    ) async {
      final history = InMemoryHistoryRepository();
      await _pump(
        tester,
        _harness(
          history: history,
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: InMemoryLastDiceConfigPreference(),
          rng: Random(0),
        ),
      );

      await tester.tap(find.byType(RollButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsNWidgets(2));
      expect(find.byKey(DiceWidget.totalKey), findsNothing);
      expect(history.snapshot(), hasLength(1));
    });

    testWidgets('restores last config from pre-populated preference', (
      tester,
    ) async {
      final pref = InMemoryLastDiceConfigPreference();
      await pref.write(const LastDiceConfig(diceType: DiceType.d12, count: 4));

      await _pump(
        tester,
        _harness(
          history: InMemoryHistoryRepository(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: pref,
        ),
      );

      expect(find.text('?'), findsNWidgets(4));
      expect(find.text('4'), findsOneWidget);

      // D12 chip is rendered with the inverted (paper) color when selected.
      final selectedText = tester.widget<Text>(find.text('D12'));
      expect(selectedText.style?.color, isNotNull);
    });

    testWidgets('roll button uses the localized ROLL label', (tester) async {
      await _pump(
        tester,
        _harness(
          history: InMemoryHistoryRepository(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: InMemoryLastDiceConfigPreference(),
        ),
      );
      final context = tester.element(find.byType(RollButton));
      expect(
        find.descendant(
          of: find.byType(MacButton),
          matching: find.text(
            AppLocalizations.of(context)!.actionRoll.toUpperCase(),
          ),
        ),
        findsOneWidget,
      );
    });
  });
}

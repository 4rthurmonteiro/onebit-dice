import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/dice_screen.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_sheet.dart';
import 'package:onebit_dice/features/dice/widgets/dice_widget.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../support/mock_analytics_service.dart';
import '../../support/mock_history_repository.dart';

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

/// A stubbed [AppSettingsPreference] whose reads all return `null`, suitable
/// for controllers that only hydrate from it.
AppSettingsPreference _stubAppSettings() {
  final preference = _MockAppSettings();
  when(preference.readSoundEnabled).thenReturn(null);
  when(preference.readHapticEnabled).thenReturn(null);
  when(preference.readAnimationStyle).thenReturn(null);
  when(preference.readAnimationSpeed).thenReturn(null);
  return preference;
}

/// A stateful [LastDiceConfigPreference] mock: writes update what reads return.
LastDiceConfigPreference _buildLastDice() {
  registerFallbackValue(const LastDiceConfig(diceType: DiceType.d6, count: 1));
  LastDiceConfig? stored;
  final mock = _MockLastDice();
  when(mock.read).thenAnswer((_) => stored);
  when(() => mock.write(any())).thenAnswer((invocation) async {
    stored = invocation.positionalArguments.first as LastDiceConfig;
  });
  return mock;
}

class _RecordingAudio extends AudioController {
  _RecordingAudio()
    : super(
        preference: _stubAppSettings(),
        analytics: createStubbedAnalytics(),
        player: _NoopSoundPlayer(),
      );

  int sequencesPlayed = 0;

  @override
  Future<void> playRollSequence() async {
    sequencesPlayed++;
  }
}

class _RecordingHaptic extends HapticController {
  _RecordingHaptic()
    : super(
        preference: _stubAppSettings(),
        analytics: createStubbedAnalytics(),
        trigger: _noopTrigger,
      );

  int triggers = 0;

  @override
  void trigger() => triggers++;
}

Future<void> _noopTrigger() async {}

/// History repo whose [append] blocks on a gate, letting a test hold a roll
/// in flight (keeping `DiceController.isRolling` true) across pumps.
class _BlockingHistory implements HistoryRepository {
  final Completer<void> _gate = Completer<void>();
  int appendCount = 0;

  void release() => _gate.complete();

  @override
  Future<void> append(RollResult result) async {
    appendCount++;
    await _gate.future;
  }

  @override
  Future<void> clear() async {}

  @override
  List<RollEntry> snapshot() => const [];

  @override
  Stream<List<RollEntry>> watch() => const Stream.empty();
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
        ChangeNotifierProvider<AnimationSettingsController>(
          create: (_) => AnimationSettingsController(
            preference: _stubAppSettings(),
            analytics: createStubbedAnalytics(),
          ),
        ),
        Provider<LastDiceConfigPreference>.value(value: lastDicePref),
        ChangeNotifierProvider<DiceController>(
          create: (ctx) => DiceController(
            history: ctx.read(),
            audio: ctx.read(),
            haptic: ctx.read(),
            lastDiceConfig: ctx.read(),
            analytics: createStubbedAnalytics(),
            rng: rng,
          ),
        ),
      ],
      child: const DiceScreen(),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
}

String _hint(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(DiceScreen)))!.rollTapHint;

void main() {
  group('DiceScreen', () {
    testWidgets('initial: 1 "?" slot, count 1, hint shown, no total', (
      tester,
    ) async {
      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
        ),
      );

      expect(find.text('?'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byKey(DiceWidget.totalKey), findsNothing);
      expect(find.text(_hint(tester)), findsOneWidget);
    });

    testWidgets('tapping the canvas rolls: grid + side effects + hint gone', (
      tester,
    ) async {
      final history = createFakeHistory();
      final audio = _RecordingAudio();
      final haptic = _RecordingHaptic();
      final pref = _buildLastDice();
      await _pump(
        tester,
        _harness(
          history: history,
          audio: audio,
          haptic: haptic,
          lastDicePref: pref,
          rng: Random(0),
        ),
      );

      final hint = _hint(tester);
      await tester.tap(find.byType(DiceWidget));
      await tester.pumpAndSettle();

      expect(find.text('?'), findsNothing);
      expect(find.byKey(DiceWidget.totalKey), findsOneWidget);
      expect(audio.sequencesPlayed, 1);
      expect(haptic.triggers, 1);
      expect(history.snapshot(), hasLength(1));
      expect(pref.read(), isNotNull);
      expect(find.text(hint), findsNothing);
    });

    testWidgets('tap +: count goes to 2 and two "?" slots show', (
      tester,
    ) async {
      final pref = _buildLastDice();
      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
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

    testWidgets('hint does not reappear after changing count post-roll', (
      tester,
    ) async {
      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
          rng: Random(0),
        ),
      );

      final hint = _hint(tester);
      await tester.tap(find.byType(DiceWidget));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(find.byKey(DiceWidget.totalKey), findsNothing);
      expect(find.text('?'), findsNWidgets(2));
      expect(find.text(hint), findsNothing);
    });

    testWidgets('after roll, tap +: result discarded; history unchanged', (
      tester,
    ) async {
      final history = createFakeHistory();
      await _pump(
        tester,
        _harness(
          history: history,
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
          rng: Random(0),
        ),
      );

      await tester.tap(find.byType(DiceWidget));
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
      final pref = _buildLastDice();
      await pref.write(const LastDiceConfig(diceType: DiceType.d12, count: 4));

      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: pref,
        ),
      );

      expect(find.text('?'), findsNWidgets(4));
      expect(find.text('4'), findsOneWidget);
      // The type field reflects the restored type.
      expect(find.text('D12'), findsOneWidget);
    });

    testWidgets('tapping the type field opens the DiceTypeSheet', (
      tester,
    ) async {
      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
        ),
      );

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();

      expect(find.byType(DiceTypeSheet), findsOneWidget);
    });

    testWidgets('a tap during an in-flight roll does not start a second roll', (
      tester,
    ) async {
      final history = _BlockingHistory();
      await _pump(
        tester,
        _harness(
          history: history,
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
          rng: Random(0),
        ),
      );

      // First tap starts a roll that suspends in history.append (gate closed).
      await tester.tap(find.byType(DiceWidget));
      await tester.pump();
      // Second tap while isRolling: must be ignored.
      await tester.tap(find.byType(DiceWidget));
      await tester.pump();

      history.release();
      await tester.pumpAndSettle();

      expect(history.appendCount, 1);
    });

    testWidgets('selecting the current type closes the sheet, keeps result', (
      tester,
    ) async {
      await _pump(
        tester,
        _harness(
          history: createFakeHistory(),
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
          rng: Random(0),
        ),
      );

      await tester.tap(find.byType(DiceWidget));
      await tester.pumpAndSettle();
      expect(find.byKey(DiceWidget.totalKey), findsOneWidget);

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();
      // D6 is the current type — tap its row in the sheet (the field also
      // shows 'D6' behind the sheet, so scope the finder to the sheet).
      await tester.tap(
        find.descendant(
          of: find.byType(DiceTypeSheet),
          matching: find.text('D6'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DiceTypeSheet), findsNothing);
      expect(find.byKey(DiceWidget.totalKey), findsOneWidget);
    });

    testWidgets('tapping the scrim dismisses the sheet without rolling', (
      tester,
    ) async {
      final history = createFakeHistory();
      await _pump(
        tester,
        _harness(
          history: history,
          audio: _RecordingAudio(),
          haptic: _RecordingHaptic(),
          lastDicePref: _buildLastDice(),
        ),
      );

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DiceTypeSheet.barrierKey));
      await tester.pumpAndSettle();

      expect(find.byType(DiceTypeSheet), findsNothing);
      expect(history.snapshot(), isEmpty);
      expect(find.byKey(DiceWidget.totalKey), findsNothing);
    });
  });
}

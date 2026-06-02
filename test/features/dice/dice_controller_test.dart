import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';

import '../../support/mock_analytics_service.dart';

class _MockHistory extends Mock implements HistoryRepository {}

class _MockAudio extends Mock implements AudioController {}

class _MockHaptic extends Mock implements HapticController {}

class _MockLastDice extends Mock implements LastDiceConfigPreference {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      RollResult(
        timestamp: DateTime.utc(2026),
        diceType: DiceType.d6,
        diceCount: 1,
        values: const [1],
      ),
    );
    registerFallbackValue(
      const LastDiceConfig(diceType: DiceType.d6, count: 1),
    );
  });

  /// Builds a [DiceController] whose dependencies are mocktail mocks. Each
  /// mutating dependency call appends a marker to [events] so tests can assert
  /// the order of side effects. Pass [analytics] to verify analytics calls.
  DiceController build({
    required List<String> events,
    LastDiceConfig? seed,
    Random? rng,
    MockAnalyticsService? analytics,
  }) {
    final history = _MockHistory();
    final audio = _MockAudio();
    final haptic = _MockHaptic();
    final lastDice = _MockLastDice();

    when(() => history.append(any())).thenAnswer((_) async {
      events.add('history.append');
    });
    when(audio.playRollSequence).thenAnswer((_) async {
      events.add('audio.playRollSequence');
    });
    when(haptic.trigger).thenAnswer((_) {
      events.add('haptic.trigger');
    });
    when(lastDice.read).thenReturn(seed);
    when(() => lastDice.write(any())).thenAnswer((invocation) async {
      final config = invocation.positionalArguments.first as LastDiceConfig;
      events.add('lastDice.write(${config.diceType.name},${config.count})');
    });

    return DiceController(
      history: history,
      audio: audio,
      haptic: haptic,
      lastDiceConfig: lastDice,
      analytics: analytics ?? createStubbedAnalytics(),
      rng: rng,
    );
  }

  group('DiceController', () {
    test('defaults to d6 / count 1 when LastDiceConfigPreference is empty', () {
      final controller = build(events: <String>[]);
      expect(controller.selectedType, DiceType.d6);
      expect(controller.count, 1);
      expect(controller.lastResult, isNull);
    });

    test('hydrates from LastDiceConfigPreference when present', () {
      final controller = build(
        events: <String>[],
        seed: const LastDiceConfig(diceType: DiceType.d20, count: 5),
      );
      expect(controller.selectedType, DiceType.d20);
      expect(controller.count, 5);
    });

    test('setType to the same value is a no-op', () async {
      final events = <String>[];
      final controller = build(events: events)
        ..addListener(() => events.add('notify'));

      await controller.setType(DiceType.d6);

      expect(events, isEmpty);
    });

    test(
      'setType to a new value clears lastResult, notifies, persists',
      () async {
        final events = <String>[];
        final controller = build(events: events, rng: Random(0))
          ..addListener(() => events.add('notify'));
        await controller.roll();
        events.clear();

        await controller.setType(DiceType.d20);

        expect(controller.selectedType, DiceType.d20);
        expect(controller.lastResult, isNull);
        expect(events, ['notify', 'lastDice.write(d20,1)']);
      },
    );

    test('setCount clamps below 1 to 1', () async {
      final controller = build(
        events: <String>[],
        seed: const LastDiceConfig(diceType: DiceType.d6, count: 5),
      );

      await controller.setCount(0);

      expect(controller.count, 1);
    });

    test('setCount clamps above 10 to 10', () async {
      final controller = build(events: <String>[]);

      await controller.setCount(11);

      expect(controller.count, 10);
    });

    test('setCount to the same clamped value is a no-op', () async {
      final events = <String>[];
      final controller = build(events: events)
        ..addListener(() => events.add('notify'));

      await controller.setCount(1);

      expect(events, isEmpty);
    });

    test(
      'setCount different value clears lastResult, notifies, persists',
      () async {
        final events = <String>[];
        final controller = build(events: events, rng: Random(0))
          ..addListener(() => events.add('notify'));
        await controller.roll();
        events.clear();

        await controller.setCount(4);

        expect(controller.count, 4);
        expect(controller.lastResult, isNull);
        expect(events, ['notify', 'lastDice.write(d6,4)']);
      },
    );

    test('roll() with injected Random is deterministic', () async {
      final controller = build(events: <String>[], rng: Random(42));
      await controller.setCount(3);
      await controller.roll();

      final expected = <int>[];
      final rng = Random(42);
      for (var i = 0; i < 3; i++) {
        expected.add(rng.nextInt(DiceType.d6.sides) + 1);
      }
      expect(controller.lastResult!.values, expected);
    });

    test(
      'roll() invokes deps in order: notify, append, audio, haptic, write',
      () async {
        final events = <String>[];
        final controller = build(events: events, rng: Random(0))
          ..addListener(() => events.add('notify'));

        await controller.roll();

        expect(events, [
          'notify',
          'history.append',
          'audio.playRollSequence',
          'haptic.trigger',
          'lastDice.write(d6,1)',
        ]);
      },
    );

    test(
      'roll() sets lastResult with correct diceCount, type, values',
      () async {
        final controller = build(events: <String>[], rng: Random(7));
        await controller.setType(DiceType.d20);
        await controller.setCount(4);

        final before = DateTime.now();
        await controller.roll();
        final after = DateTime.now();

        final result = controller.lastResult!;
        expect(result.diceType, DiceType.d20);
        expect(result.diceCount, 4);
        expect(result.values, hasLength(4));
        expect(result.values.every((v) => v >= 1 && v <= 20), isTrue);
        expect(
          !result.timestamp.isBefore(before) &&
              !result.timestamp.isAfter(after),
          isTrue,
        );
      },
    );

    test('default rng uses Random.secure when no rng injected', () async {
      final controller = build(events: <String>[]);

      // Roll a few times — values should be in range, indicating a working rng.
      for (var i = 0; i < 5; i++) {
        await controller.roll();
        expect(controller.lastResult!.values.first, inInclusiveRange(1, 6));
      }
    });

    test('applyConfig with matching type and count is a no-op', () async {
      final events = <String>[];
      final controller = build(events: events)
        ..addListener(() => events.add('notify'));

      await controller.applyConfig(diceType: DiceType.d6, count: 1);

      expect(events, isEmpty);
    });

    test(
      'applyConfig with a new type and count notifies once and persists once',
      () async {
        final events = <String>[];
        final controller = build(events: events, rng: Random(0))
          ..addListener(() => events.add('notify'));
        await controller.roll();
        events.clear();

        await controller.applyConfig(diceType: DiceType.d20, count: 4);

        expect(controller.selectedType, DiceType.d20);
        expect(controller.count, 4);
        expect(controller.lastResult, isNull);
        expect(events, ['notify', 'lastDice.write(d20,4)']);
      },
    );

    test('applyConfig clamps count below 1 to 1', () async {
      final controller = build(events: <String>[]);

      await controller.applyConfig(diceType: DiceType.d20, count: 0);

      expect(controller.count, 1);
      expect(controller.selectedType, DiceType.d20);
    });

    test('applyConfig clamps count above 10 to 10', () async {
      final controller = build(events: <String>[]);

      await controller.applyConfig(diceType: DiceType.d12, count: 99);

      expect(controller.count, 10);
      expect(controller.selectedType, DiceType.d12);
    });

    test(
      'applyConfig with only count changing still applies the new count',
      () async {
        final events = <String>[];
        final controller = build(events: events)
          ..addListener(() => events.add('notify'));

        await controller.applyConfig(diceType: DiceType.d6, count: 5);

        expect(controller.count, 5);
        expect(controller.selectedType, DiceType.d6);
        expect(events, ['notify', 'lastDice.write(d6,5)']);
      },
    );

    test('notifies once per setType call', () async {
      final controller = build(events: <String>[]);
      var notifies = 0;
      controller.addListener(() => notifies++);

      await controller.setType(DiceType.d12);

      expect(notifies, 1);
    });

    test('extends ChangeNotifier so listeners can be added', () {
      final controller = build(events: <String>[]);
      expect(controller, isA<ChangeNotifier>());
    });

    group('hasRolled', () {
      test('is false before any roll', () {
        final controller = build(events: <String>[]);
        expect(controller.hasRolled, isFalse);
      });

      test('becomes true after roll()', () async {
        final controller = build(events: <String>[], rng: Random(0));
        await controller.roll();
        expect(controller.hasRolled, isTrue);
      });

      test('stays true after setType / setCount / applyConfig', () async {
        final controller = build(events: <String>[], rng: Random(0));
        await controller.roll();

        await controller.setType(DiceType.d20);
        expect(controller.hasRolled, isTrue);

        await controller.setCount(3);
        expect(controller.hasRolled, isTrue);

        await controller.applyConfig(diceType: DiceType.d4, count: 2);
        expect(controller.hasRolled, isTrue);
      });
    });

    group('isRolling', () {
      test('is false before and after a completed roll', () async {
        final controller = build(events: <String>[], rng: Random(0));
        expect(controller.isRolling, isFalse);
        await controller.roll();
        expect(controller.isRolling, isFalse);
      });

      test(
        'a second roll() started before the first settles is a no-op',
        () async {
          final events = <String>[];
          final controller = build(events: events, rng: Random(0));

          // Start the first roll but do not await it: it suspends at the
          // awaited history.append with _isRolling already true.
          final first = controller.roll();
          final second = controller.roll();
          await Future.wait([first, second]);

          expect(controller.isRolling, isFalse);
          expect(events.where((e) => e == 'history.append'), hasLength(1));
          expect(
            events.where((e) => e == 'audio.playRollSequence'),
            hasLength(1),
          );
          expect(events.where((e) => e == 'haptic.trigger'), hasLength(1));
        },
      );
    });

    group('analytics', () {
      test('roll() logs dice_rolled with type, count, and total', () async {
        final analytics = createStubbedAnalytics();
        final controller = build(
          events: <String>[],
          rng: Random(0),
          analytics: analytics,
        );
        await controller.setType(DiceType.d20);
        await controller.setCount(3);

        await controller.roll();

        final total = controller.lastResult!.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        verify(
          () => analytics.logEvent(
            'dice_rolled',
            parameters: {'dice_type': 'd20', 'count': 3, 'total': total},
          ),
        ).called(1);
      });

      test('setType logs dice_type_changed with the new type', () async {
        final analytics = createStubbedAnalytics();
        final controller = build(events: <String>[], analytics: analytics);

        await controller.setType(DiceType.d12);

        verify(
          () => analytics.logEvent(
            'dice_type_changed',
            parameters: {'dice_type': 'd12'},
          ),
        ).called(1);
      });

      test('a no-op setType does not log', () async {
        final analytics = createStubbedAnalytics();
        final controller = build(events: <String>[], analytics: analytics);

        await controller.setType(DiceType.d6);

        verifyNever(
          () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
        );
      });
    });
  });
}

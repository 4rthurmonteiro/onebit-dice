import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';

void main() {
  group('RollEntry', () {
    final timestamp = DateTime.utc(2026, 5, 25, 12, 30);

    RollResult buildResult() => RollResult(
      timestamp: timestamp,
      diceType: DiceType.d20,
      diceCount: 3,
      values: const [4, 17, 9],
    );

    test('fromResult mirrors every field of the source RollResult', () {
      final entry = RollEntry.fromResult(buildResult());

      expect(entry.timestamp, timestamp);
      expect(entry.diceTypeIndex, DiceType.d20.index);
      expect(entry.diceCount, 3);
      expect(entry.values, [4, 17, 9]);
    });

    test('fromResult copies values so source mutation does not leak', () {
      final mutableValues = [1, 2, 3];
      final result = RollResult(
        timestamp: timestamp,
        diceType: DiceType.d6,
        diceCount: 3,
        values: mutableValues,
      );

      final entry = RollEntry.fromResult(result);
      mutableValues[0] = 999;

      expect(entry.values, [1, 2, 3]);
    });

    test('toResult round-trips fields and derived getters', () {
      final original = buildResult();
      final entry = RollEntry.fromResult(original);
      final restored = entry.toResult();

      expect(restored, equals(original));
      expect(restored.total, original.total);
      expect(restored.equation, original.equation);
    });

    test('toResult throws StateError when diceTypeIndex is negative', () {
      final entry = RollEntry(
        timestamp: timestamp,
        diceTypeIndex: -1,
        diceCount: 1,
        values: const [1],
      );

      expect(entry.toResult, throwsStateError);
    });

    test('toResult throws StateError when diceTypeIndex is out of range', () {
      final entry = RollEntry(
        timestamp: timestamp,
        diceTypeIndex: DiceType.values.length,
        diceCount: 1,
        values: const [1],
      );

      expect(entry.toResult, throwsStateError);
    });
  });
}

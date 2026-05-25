import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';

void main() {
  group('CustomPreset', () {
    test('create generates distinct ids on successive calls', () {
      final a = CustomPreset.create(
        name: 'A',
        diceType: DiceType.d6,
        diceCount: 2,
      );
      final b = CustomPreset.create(
        name: 'B',
        diceType: DiceType.d6,
        diceCount: 2,
      );
      expect(a.id, isNot(b.id));
    });

    test('create stamps createdAt close to DateTime.now()', () {
      final before = DateTime.now();
      final preset = CustomPreset.create(
        name: 'Crit',
        diceType: DiceType.d20,
        diceCount: 1,
      );
      final after = DateTime.now();
      expect(
        preset.createdAt.isBefore(before),
        isFalse,
        reason: 'createdAt must be >= the call site timestamp',
      );
      expect(
        preset.createdAt.isAfter(after),
        isFalse,
        reason: 'createdAt must be <= the call site timestamp',
      );
    });

    test('create stores the dice type index and count verbatim', () {
      final preset = CustomPreset.create(
        name: 'Damage',
        diceType: DiceType.d8,
        diceCount: 4,
      );
      expect(preset.diceTypeIndex, DiceType.d8.index);
      expect(preset.diceCount, 4);
      expect(preset.diceType, DiceType.d8);
    });

    test('diceType getter throws when diceTypeIndex is negative', () {
      final preset = CustomPreset(
        id: 'x',
        name: 'broken',
        diceTypeIndex: -1,
        diceCount: 1,
        createdAt: DateTime.utc(2026),
      );
      expect(() => preset.diceType, throwsStateError);
    });

    test('diceType getter throws when diceTypeIndex is out of range', () {
      final preset = CustomPreset(
        id: 'x',
        name: 'broken',
        diceTypeIndex: DiceType.values.length,
        diceCount: 1,
        createdAt: DateTime.utc(2026),
      );
      expect(() => preset.diceType, throwsStateError);
    });

    test('constructor asserts name length cap in debug', () {
      expect(
        () => CustomPreset(
          id: 'x',
          name: 'a' * (customPresetMaxNameLength + 1),
          diceTypeIndex: 0,
          diceCount: 1,
          createdAt: DateTime.utc(2026),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWithName replaces only the name', () {
      final original = CustomPreset.create(
        name: 'Old',
        diceType: DiceType.d12,
        diceCount: 2,
      );
      final renamed = original.copyWithName('New');
      expect(renamed.id, original.id);
      expect(renamed.name, 'New');
      expect(renamed.diceTypeIndex, original.diceTypeIndex);
      expect(renamed.diceCount, original.diceCount);
      expect(renamed.createdAt, original.createdAt);
    });
  });
}

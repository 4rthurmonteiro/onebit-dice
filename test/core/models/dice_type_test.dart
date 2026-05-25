import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';

void main() {
  group('DiceType', () {
    test('exposes exactly seven values', () {
      expect(DiceType.values, hasLength(7));
    });

    test('every value reports a strictly positive number of sides', () {
      for (final type in DiceType.values) {
        expect(type.sides, greaterThan(0), reason: '${type.name}.sides');
      }
    });

    const expectations = <(DiceType, int, String)>[
      (DiceType.d4, 4, 'D4'),
      (DiceType.d6, 6, 'D6'),
      (DiceType.d8, 8, 'D8'),
      (DiceType.d10, 10, 'D10'),
      (DiceType.d12, 12, 'D12'),
      (DiceType.d20, 20, 'D20'),
      (DiceType.d100, 100, 'D100'),
    ];

    for (final (type, sides, label) in expectations) {
      test('${type.name} exposes the expected sides and label', () {
        expect(type.sides, sides);
        expect(type.label, label);
      });
    }
  });
}

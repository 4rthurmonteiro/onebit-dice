import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';

void main() {
  final timestamp = DateTime.utc(2026, 5, 25, 12);

  RollResult build({
    required List<int> values,
    DateTime? at,
    DiceType type = DiceType.d6,
    int? count,
  }) {
    return RollResult(
      timestamp: at ?? timestamp,
      diceType: type,
      diceCount: count ?? values.length,
      values: values,
    );
  }

  group('RollResult.total', () {
    test('sums multi-value rolls', () {
      expect(build(values: const [3, 5, 2]).total, 10);
    });

    test('returns the single value for a one-die roll', () {
      expect(build(values: const [7]).total, 7);
    });
  });

  group('RollResult.equation', () {
    test('renders a single value without operators', () {
      expect(build(values: const [5]).equation, '5');
    });

    test('renders multiple values with + and total', () {
      expect(build(values: const [3, 5, 2]).equation, '3 + 5 + 2 = 10');
    });

    test('renders the two-value edge case', () {
      expect(build(values: const [4, 6]).equation, '4 + 6 = 10');
    });
  });

  group('RollResult equality', () {
    test('two instances with identical fields are equal', () {
      final a = build(values: const [3, 5, 2]);
      final b = build(values: [3, 5, 2]);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when timestamp changes', () {
      expect(
        build(values: const [3, 5, 2]),
        isNot(
          build(
            at: timestamp.add(const Duration(seconds: 1)),
            values: const [3, 5, 2],
          ),
        ),
      );
    });

    test('differs when diceType changes', () {
      expect(
        build(values: const [3, 5, 2]),
        isNot(build(type: DiceType.d20, values: const [3, 5, 2])),
      );
    });

    test('differs when values change', () {
      expect(
        build(values: const [3, 5, 2]),
        isNot(build(values: const [1, 5, 2])),
      );
    });
  });

  group('RollResult invariants', () {
    test('asserts diceCount matches values.length', () {
      expect(
        () => RollResult(
          timestamp: timestamp,
          diceType: DiceType.d6,
          diceCount: 5,
          values: const [1, 2, 3],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

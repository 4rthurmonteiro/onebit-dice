import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/shared/utils/random_dice.dart';

void main() {
  group('rollDie', () {
    test('stays within 1..sides over 1000 seeded iterations', () {
      for (final sides in const [4, 6, 20, 100]) {
        final rng = Random(0xC0FFEE);
        for (var i = 0; i < 1000; i++) {
          final value = rollDie(sides, rng: rng);
          expect(value, greaterThanOrEqualTo(1));
          expect(value, lessThanOrEqualTo(sides));
        }
      }
    });

    test('produces the same sequence for the same seed', () {
      final a = List.generate(20, (_) => rollDie(20, rng: Random(7)));
      final b = List.generate(20, (_) => rollDie(20, rng: Random(7)));
      expect(a, b);
    });

    test('returns a value in 1..sides when no rng is provided', () {
      final value = rollDie(6);
      expect(value, greaterThanOrEqualTo(1));
      expect(value, lessThanOrEqualTo(6));
    });

    test('asserts that sides is strictly positive', () {
      expect(() => rollDie(0), throwsA(isA<AssertionError>()));
    });
  });

  group('rollDice', () {
    test('returns a list of the requested length with values in 1..sides', () {
      final values = rollDice(6, 10, rng: Random(42));
      expect(values, hasLength(10));
      for (final v in values) {
        expect(v, greaterThanOrEqualTo(1));
        expect(v, lessThanOrEqualTo(6));
      }
    });

    test('is deterministic when given the same seed', () {
      final a = rollDice(20, 5, rng: Random(123));
      final b = rollDice(20, 5, rng: Random(123));
      expect(a, b);
    });

    // Distribution check on a d6 over 10k seeded rolls. Seed 7 keeps every
    // face within +/-30% of the expected uniform frequency on stable VMs;
    // swap the seed (do not relax the bound) if it ever flakes.
    test('every d6 face stays within +/-30% of uniform over 10k rolls', () {
      const sides = 6;
      const rolls = 10000;
      final histogram = List<int>.filled(sides, 0);
      for (final v in rollDice(sides, rolls, rng: Random(7))) {
        histogram[v - 1] += 1;
      }
      const expected = rolls / sides;
      const lower = expected * 0.7;
      const upper = expected * 1.3;
      for (var face = 0; face < sides; face++) {
        expect(
          histogram[face],
          inInclusiveRange(lower, upper),
          reason: 'face ${face + 1} appeared ${histogram[face]} times',
        );
      }
    });

    test('asserts that sides is strictly positive', () {
      expect(() => rollDice(0, 1), throwsA(isA<AssertionError>()));
    });

    test('asserts that count is at least 1', () {
      expect(() => rollDice(6, 0), throwsA(isA<AssertionError>()));
    });
  });
}

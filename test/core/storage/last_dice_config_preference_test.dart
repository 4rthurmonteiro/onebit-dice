import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LastDiceConfig', () {
    test('value equality holds for identical fields', () {
      const a = LastDiceConfig(diceType: DiceType.d20, count: 3);
      const b = LastDiceConfig(diceType: DiceType.d20, count: 3);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('value equality fails when any field differs', () {
      const base = LastDiceConfig(diceType: DiceType.d20, count: 3);
      expect(
        base,
        isNot(equals(const LastDiceConfig(diceType: DiceType.d6, count: 3))),
      );
      expect(
        base,
        isNot(equals(const LastDiceConfig(diceType: DiceType.d20, count: 2))),
      );
    });
  });

  group('SharedPreferencesLastDiceConfigPreference', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<SharedPreferencesLastDiceConfigPreference> buildPref() async {
      final prefs = await SharedPreferences.getInstance();
      return SharedPreferencesLastDiceConfigPreference(prefs);
    }

    test('read() returns null when nothing has been written', () async {
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test('round-trip preserves the stored configuration', () async {
      final pref = await buildPref();
      const config = LastDiceConfig(diceType: DiceType.d12, count: 4);
      await pref.write(config);
      expect(pref.read(), config);
    });

    test('read() returns null when only the dice type is stored', () async {
      SharedPreferences.setMockInitialValues({'last_dice_type': 0});
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test('read() returns null when only the count is stored', () async {
      SharedPreferences.setMockInitialValues({'last_dice_count': 1});
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test(
      'read() returns null when the dice type index is out of range',
      () async {
        SharedPreferences.setMockInitialValues({
          'last_dice_type': 999,
          'last_dice_count': 3,
        });
        final pref = await buildPref();
        expect(pref.read(), isNull);
      },
    );

    test('read() returns null when the dice type index is negative', () async {
      SharedPreferences.setMockInitialValues({
        'last_dice_type': -1,
        'last_dice_count': 3,
      });
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test('read() returns null when count is below 1', () async {
      SharedPreferences.setMockInitialValues({
        'last_dice_type': 0,
        'last_dice_count': 0,
      });
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test('read() returns null when count is above 10', () async {
      SharedPreferences.setMockInitialValues({
        'last_dice_type': 0,
        'last_dice_count': 11,
      });
      final pref = await buildPref();
      expect(pref.read(), isNull);
    });

    test('read() accepts boundary counts (1 and 10)', () async {
      final pref = await buildPref();
      await pref.write(const LastDiceConfig(diceType: DiceType.d4, count: 1));
      expect(
        pref.read(),
        const LastDiceConfig(diceType: DiceType.d4, count: 1),
      );

      await pref.write(const LastDiceConfig(diceType: DiceType.d4, count: 10));
      expect(
        pref.read(),
        const LastDiceConfig(diceType: DiceType.d4, count: 10),
      );
    });
  });
}

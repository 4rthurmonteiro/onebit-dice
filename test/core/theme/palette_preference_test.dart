import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InMemoryPalettePreference', () {
    test('read() returns null initially', () {
      final pref = InMemoryPalettePreference();
      expect(pref.read(), isNull);
    });

    test('write() persists the value in memory', () async {
      final pref = InMemoryPalettePreference();
      await pref.write(PaletteId.gameBoy);
      expect(pref.read(), PaletteId.gameBoy);

      await pref.write(PaletteId.zxSpectrum);
      expect(pref.read(), PaletteId.zxSpectrum);
    });
  });

  group('SharedPreferencesPalettePreference', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('read() returns null when nothing has been written', () async {
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesPalettePreference(prefs);
      expect(pref.read(), isNull);
    });

    test('round-trip preserves the stored PaletteId', () async {
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesPalettePreference(prefs);

      await pref.write(PaletteId.gameBoy);
      expect(pref.read(), PaletteId.gameBoy);

      await pref.write(PaletteId.appleIIeAmber);
      expect(pref.read(), PaletteId.appleIIeAmber);
    });

    test('read() returns null when stored index is out of range', () async {
      SharedPreferences.setMockInitialValues({'palette_id': 999});
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesPalettePreference(prefs);
      expect(pref.read(), isNull);
    });

    test('read() returns null when stored index is negative', () async {
      SharedPreferences.setMockInitialValues({'palette_id': -1});
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesPalettePreference(prefs);
      expect(pref.read(), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';

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
}

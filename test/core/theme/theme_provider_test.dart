import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';

class _RecordingPreference implements PalettePreference {
  _RecordingPreference([this._stored]);

  PaletteId? _stored;
  final List<PaletteId> writes = [];

  @override
  PaletteId? read() => _stored;

  @override
  Future<void> write(PaletteId id) async {
    writes.add(id);
    _stored = id;
  }
}

void main() {
  group('ThemeProvider', () {
    test('defaults to macClassic when no preference is stored', () {
      final provider = ThemeProvider();
      expect(provider.current.id, PaletteId.macClassic);
    });

    test('reads the initial palette from preference when stored', () {
      final pref = _RecordingPreference(PaletteId.gameBoy);
      final provider = ThemeProvider(preference: pref);
      expect(provider.current.id, PaletteId.gameBoy);
    });

    test('setPalette updates current and notifies exactly once', () async {
      final pref = _RecordingPreference();
      final provider = ThemeProvider(preference: pref);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setPalette(PaletteId.zxSpectrum);

      expect(provider.current.id, PaletteId.zxSpectrum);
      expect(notifications, 1);
    });

    test('setPalette writes the new id to preference', () async {
      final pref = _RecordingPreference();
      final provider = ThemeProvider(preference: pref);

      await provider.setPalette(PaletteId.c64);

      expect(pref.writes, [PaletteId.c64]);
      expect(pref.read(), PaletteId.c64);
    });

    test('setPalette is a no-op when id matches current', () async {
      final pref = _RecordingPreference(PaletteId.macBeige);
      final provider = ThemeProvider(preference: pref);
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setPalette(PaletteId.macBeige);

      expect(provider.current.id, PaletteId.macBeige);
      expect(notifications, 0);
      expect(pref.writes, isEmpty);
    });
  });
}

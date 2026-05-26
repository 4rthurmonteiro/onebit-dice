import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';

void main() {
  group('SoundEvent', () {
    test('declares exactly three events', () {
      expect(SoundEvent.values, hasLength(3));
      expect(
        SoundEvent.values,
        containsAll(<SoundEvent>[
          SoundEvent.roll,
          SoundEvent.stop,
          SoundEvent.total,
        ]),
      );
    });

    test('every event points to a bundled asset under assets/sounds/', () {
      for (final event in SoundEvent.values) {
        expect(event.assetPath, startsWith('assets/sounds/'));
        expect(event.assetPath, endsWith('.mp3'));
      }
    });

    test('asset paths are distinct so events never collide', () {
      final paths = SoundEvent.values.map((e) => e.assetPath).toSet();
      expect(paths, hasLength(SoundEvent.values.length));
    });
  });
}

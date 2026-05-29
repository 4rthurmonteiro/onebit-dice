import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';

void main() {
  group('SoundEvent', () {
    test('declares the three roll phases', () {
      expect(SoundEvent.values, hasLength(3));
      expect(
        SoundEvent.values,
        containsAll(<SoundEvent>[
          SoundEvent.grab,
          SoundEvent.shake,
          SoundEvent.land,
        ]),
      );
    });

    test('every event ships at least one .ogg under assets/sounds/', () {
      for (final event in SoundEvent.values) {
        expect(event.assetPaths, isNotEmpty);
        for (final path in event.assetPaths) {
          expect(path, startsWith('assets/sounds/'));
          expect(path, endsWith('.ogg'));
        }
      }
    });

    test('variant paths are unique within an event', () {
      for (final event in SoundEvent.values) {
        expect(event.assetPaths.toSet(), hasLength(event.assetPaths.length));
      }
    });
  });
}

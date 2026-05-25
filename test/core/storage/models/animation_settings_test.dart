import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';

void main() {
  group('AnimationStyle', () {
    test('exposes three members in declaration order', () {
      expect(AnimationStyle.values, hasLength(3));
      expect(AnimationStyle.values.first, AnimationStyle.fast);
      expect(AnimationStyle.values.last, AnimationStyle.tabletop);
    });

    test('every member has a non-empty label', () {
      for (final style in AnimationStyle.values) {
        expect(style.label, isNotEmpty);
      }
    });

    test('labels are localized in pt-BR', () {
      expect(AnimationStyle.fast.label, 'Rápida');
      expect(AnimationStyle.drum.label, 'Tambor');
      expect(AnimationStyle.tabletop.label, 'Tabuleiro');
    });
  });

  group('AnimationSpeed', () {
    test('exposes three members in declaration order', () {
      expect(AnimationSpeed.values, hasLength(3));
      expect(AnimationSpeed.values.first, AnimationSpeed.fast);
      expect(AnimationSpeed.values.last, AnimationSpeed.slow);
    });

    test('every member has a non-empty label', () {
      for (final speed in AnimationSpeed.values) {
        expect(speed.label, isNotEmpty);
      }
    });

    test('labels are localized in pt-BR', () {
      expect(AnimationSpeed.fast.label, 'Rápido');
      expect(AnimationSpeed.medium.label, 'Médio');
      expect(AnimationSpeed.slow.label, 'Longo');
    });
  });
}

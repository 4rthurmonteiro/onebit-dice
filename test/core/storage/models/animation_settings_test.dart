import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';

void main() {
  group('AnimationStyle', () {
    test('exposes three members in declaration order', () {
      expect(AnimationStyle.values, hasLength(3));
      expect(AnimationStyle.values.first, AnimationStyle.fast);
      expect(AnimationStyle.values.last, AnimationStyle.tabletop);
    });
  });

  group('AnimationSpeed', () {
    test('exposes three members in declaration order', () {
      expect(AnimationSpeed.values, hasLength(3));
      expect(AnimationSpeed.values.first, AnimationSpeed.fast);
      expect(AnimationSpeed.values.last, AnimationSpeed.slow);
    });
  });
}

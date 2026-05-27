import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';

class _RecordingAppSettings extends InMemoryAppSettingsPreference {
  _RecordingAppSettings(this.events);

  final List<String> events;

  @override
  Future<void> writeAnimationStyle(AnimationStyle style) async {
    events.add('writeAnimationStyle(${style.name})');
    await super.writeAnimationStyle(style);
  }

  @override
  Future<void> writeAnimationSpeed(AnimationSpeed speed) async {
    events.add('writeAnimationSpeed(${speed.name})');
    await super.writeAnimationSpeed(speed);
  }
}

void main() {
  group('AnimationSettingsController', () {
    test('defaults to drum + medium when nothing is stored', () {
      final controller = AnimationSettingsController(
        preference: InMemoryAppSettingsPreference(),
      );
      expect(controller.style, AnimationStyle.drum);
      expect(controller.speed, AnimationSpeed.medium);
    });

    test('hydrates style and speed from preference', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeAnimationStyle(AnimationStyle.tabletop);
      await pref.writeAnimationSpeed(AnimationSpeed.slow);

      final controller = AnimationSettingsController(preference: pref);

      expect(controller.style, AnimationStyle.tabletop);
      expect(controller.speed, AnimationSpeed.slow);
    });

    test('setStyle notifies, then persists — in that order', () async {
      final events = <String>[];
      final pref = _RecordingAppSettings(events);
      final controller = AnimationSettingsController(preference: pref)
        ..addListener(() => events.add('notify'));

      await controller.setStyle(AnimationStyle.fast);

      expect(controller.style, AnimationStyle.fast);
      expect(events, ['notify', 'writeAnimationStyle(fast)']);
      expect(pref.readAnimationStyle(), AnimationStyle.fast);
    });

    test('setStyle with the same value is a no-op', () async {
      final pref = InMemoryAppSettingsPreference();
      final controller = AnimationSettingsController(preference: pref);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setStyle(AnimationStyle.drum);

      expect(notifications, 0);
      expect(pref.readAnimationStyle(), isNull);
    });

    test('setSpeed notifies, then persists — in that order', () async {
      final events = <String>[];
      final pref = _RecordingAppSettings(events);
      final controller = AnimationSettingsController(preference: pref)
        ..addListener(() => events.add('notify'));

      await controller.setSpeed(AnimationSpeed.fast);

      expect(controller.speed, AnimationSpeed.fast);
      expect(events, ['notify', 'writeAnimationSpeed(fast)']);
      expect(pref.readAnimationSpeed(), AnimationSpeed.fast);
    });

    test('setSpeed with the same value is a no-op', () async {
      final pref = InMemoryAppSettingsPreference();
      final controller = AnimationSettingsController(preference: pref);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setSpeed(AnimationSpeed.medium);

      expect(notifications, 0);
      expect(pref.readAnimationSpeed(), isNull);
    });
  });
}

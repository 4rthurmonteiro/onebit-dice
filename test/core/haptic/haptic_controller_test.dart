import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

void main() {
  group('HapticController', () {
    test('default constructor falls back to the real trigger', () {
      expect(
        () => HapticController(preference: InMemoryAppSettingsPreference()),
        returnsNormally,
      );
    });

    test('defaults hapticEnabled to true when nothing is stored', () {
      final controller = HapticController(
        preference: InMemoryAppSettingsPreference(),
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isTrue);
    });

    test('hydrates hapticEnabled from preference (false)', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeHapticEnabled(value: false);
      final controller = HapticController(
        preference: pref,
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isFalse);
    });

    test('hydrates hapticEnabled from preference (true)', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeHapticEnabled(value: true);
      final controller = HapticController(
        preference: pref,
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isTrue);
    });

    test('trigger fires the platform pulse when enabled', () {
      var calls = 0;
      HapticController(
        preference: InMemoryAppSettingsPreference(),
        trigger: () async => calls++,
      ).trigger();

      expect(calls, 1);
    });

    test('trigger is a no-op when disabled', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeHapticEnabled(value: false);
      var calls = 0;
      HapticController(
        preference: pref,
        trigger: () async => calls++,
      ).trigger();

      expect(calls, 0);
    });

    test('setHapticEnabled(true→false) notifies once and persists', () async {
      final pref = InMemoryAppSettingsPreference();
      final controller = HapticController(
        preference: pref,
        trigger: () async {},
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setHapticEnabled(value: false);

      expect(controller.hapticEnabled, isFalse);
      expect(notifications, 1);
      expect(pref.readHapticEnabled(), isFalse);
    });

    test('setHapticEnabled(false→true) notifies once and persists', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeHapticEnabled(value: false);
      final controller = HapticController(
        preference: pref,
        trigger: () async {},
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setHapticEnabled(value: true);

      expect(controller.hapticEnabled, isTrue);
      expect(notifications, 1);
      expect(pref.readHapticEnabled(), isTrue);
    });

    test('setHapticEnabled with the same value is a no-op', () async {
      final pref = InMemoryAppSettingsPreference();
      final controller = HapticController(
        preference: pref,
        trigger: () async {},
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setHapticEnabled(value: true);

      expect(notifications, 0);
      expect(pref.readHapticEnabled(), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

import '../../support/mock_analytics_service.dart';

class _MockAppSettings extends Mock implements AppSettingsPreference {}

void main() {
  late _MockAppSettings preference;
  late MockAnalyticsService analytics;

  setUp(() {
    preference = _MockAppSettings();
    analytics = createStubbedAnalytics();
    when(() => preference.readHapticEnabled()).thenReturn(null);
    when(
      () => preference.writeHapticEnabled(value: any(named: 'value')),
    ).thenAnswer((_) async {});
  });

  /// Re-stubs `writeHapticEnabled` to append a marker to [events] so tests can
  /// assert the ordering of the write against other side effects.
  void recordWritesTo(List<String> events) {
    when(
      () => preference.writeHapticEnabled(value: any(named: 'value')),
    ).thenAnswer((invocation) async {
      events.add('writeHapticEnabled(${invocation.namedArguments[#value]})');
    });
  }

  group('HapticController', () {
    test('default constructor falls back to the real trigger', () {
      expect(
        () => HapticController(preference: preference, analytics: analytics),
        returnsNormally,
      );
    });

    test('defaults hapticEnabled to true when nothing is stored', () {
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isTrue);
    });

    test('hydrates hapticEnabled from preference (false)', () {
      when(() => preference.readHapticEnabled()).thenReturn(false);
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isFalse);
    });

    test('hydrates hapticEnabled from preference (true)', () {
      when(() => preference.readHapticEnabled()).thenReturn(true);
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );

      expect(controller.hapticEnabled, isTrue);
    });

    test('trigger fires the platform pulse when enabled', () {
      var calls = 0;
      HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async => calls++,
      ).trigger();

      expect(calls, 1);
    });

    test('trigger is a no-op when disabled', () {
      when(() => preference.readHapticEnabled()).thenReturn(false);
      var calls = 0;
      HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async => calls++,
      ).trigger();

      expect(calls, 0);
    });

    test('setHapticEnabled(true→false) notifies, then persists '
        '— in that order', () async {
      final events = <String>[];
      recordWritesTo(events);
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      )..addListener(() => events.add('notify'));

      await controller.setHapticEnabled(value: false);

      expect(controller.hapticEnabled, isFalse);
      expect(events, ['notify', 'writeHapticEnabled(false)']);
    });

    test('setHapticEnabled(false→true) notifies, then persists '
        '— in that order', () async {
      when(() => preference.readHapticEnabled()).thenReturn(false);
      final events = <String>[];
      recordWritesTo(events);
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      )..addListener(() => events.add('notify'));

      await controller.setHapticEnabled(value: true);

      expect(controller.hapticEnabled, isTrue);
      expect(events, ['notify', 'writeHapticEnabled(true)']);
    });

    test('setHapticEnabled with the same value is a no-op', () async {
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setHapticEnabled(value: true);

      expect(notifications, 0);
      verifyNever(
        () => preference.writeHapticEnabled(value: any(named: 'value')),
      );
    });

    test('setHapticEnabled logs haptic_toggled with the new flag', () async {
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );

      await controller.setHapticEnabled(value: false);

      verify(
        () => analytics.logEvent(
          'haptic_toggled',
          parameters: {'enabled': false},
        ),
      ).called(1);
    });

    test('a no-op haptic toggle does not log', () async {
      final controller = HapticController(
        preference: preference,
        analytics: analytics,
        trigger: () async {},
      );

      // Default hapticEnabled is true; setting true again is a no-op.
      await controller.setHapticEnabled(value: true);

      verifyNever(
        () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
      );
    });
  });
}

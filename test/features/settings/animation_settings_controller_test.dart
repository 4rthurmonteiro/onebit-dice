import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';

import '../../support/mock_analytics_service.dart';

class _MockAppSettings extends Mock implements AppSettingsPreference {}

void main() {
  setUpAll(() {
    registerFallbackValue(AnimationStyle.drum);
    registerFallbackValue(AnimationSpeed.medium);
  });

  late _MockAppSettings preference;
  late MockAnalyticsService analytics;

  setUp(() {
    preference = _MockAppSettings();
    analytics = createStubbedAnalytics();
    when(() => preference.readAnimationStyle()).thenReturn(null);
    when(() => preference.readAnimationSpeed()).thenReturn(null);
    when(() => preference.writeAnimationStyle(any())).thenAnswer((_) async {});
    when(() => preference.writeAnimationSpeed(any())).thenAnswer((_) async {});
  });

  /// Re-stubs the animation writes to append markers to [events] so tests can
  /// assert ordering against other side effects.
  void recordWritesTo(List<String> events) {
    when(() => preference.writeAnimationStyle(any())).thenAnswer((
      invocation,
    ) async {
      final style = invocation.positionalArguments.first as AnimationStyle;
      events.add('writeAnimationStyle(${style.name})');
    });
    when(() => preference.writeAnimationSpeed(any())).thenAnswer((
      invocation,
    ) async {
      final speed = invocation.positionalArguments.first as AnimationSpeed;
      events.add('writeAnimationSpeed(${speed.name})');
    });
  }

  AnimationSettingsController build() =>
      AnimationSettingsController(preference: preference, analytics: analytics);

  group('AnimationSettingsController', () {
    test('defaults to drum + medium when nothing is stored', () {
      final controller = build();
      expect(controller.style, AnimationStyle.drum);
      expect(controller.speed, AnimationSpeed.medium);
    });

    test('hydrates style and speed from preference', () {
      when(
        () => preference.readAnimationStyle(),
      ).thenReturn(AnimationStyle.tabletop);
      when(
        () => preference.readAnimationSpeed(),
      ).thenReturn(AnimationSpeed.slow);

      final controller = build();

      expect(controller.style, AnimationStyle.tabletop);
      expect(controller.speed, AnimationSpeed.slow);
    });

    test('setStyle notifies, then persists — in that order', () async {
      final events = <String>[];
      recordWritesTo(events);
      final controller = build()..addListener(() => events.add('notify'));

      await controller.setStyle(AnimationStyle.fast);

      expect(controller.style, AnimationStyle.fast);
      expect(events, ['notify', 'writeAnimationStyle(fast)']);
    });

    test('setStyle with the same value is a no-op', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setStyle(AnimationStyle.drum);

      expect(notifications, 0);
      verifyNever(() => preference.writeAnimationStyle(any()));
    });

    test('setSpeed notifies, then persists — in that order', () async {
      final events = <String>[];
      recordWritesTo(events);
      final controller = build()..addListener(() => events.add('notify'));

      await controller.setSpeed(AnimationSpeed.fast);

      expect(controller.speed, AnimationSpeed.fast);
      expect(events, ['notify', 'writeAnimationSpeed(fast)']);
    });

    test('setSpeed with the same value is a no-op', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setSpeed(AnimationSpeed.medium);

      expect(notifications, 0);
      verifyNever(() => preference.writeAnimationSpeed(any()));
    });

    test('setStyle logs animation_style_changed with the style name', () async {
      final controller = build();

      await controller.setStyle(AnimationStyle.tabletop);

      verify(
        () => analytics.logEvent(
          'animation_style_changed',
          parameters: {'style': 'tabletop'},
        ),
      ).called(1);
    });

    test('setSpeed logs animation_speed_changed with the speed name', () async {
      final controller = build();

      await controller.setSpeed(AnimationSpeed.slow);

      verify(
        () => analytics.logEvent(
          'animation_speed_changed',
          parameters: {'speed': 'slow'},
        ),
      ).called(1);
    });

    test('no-op style/speed changes do not log', () async {
      final controller = build();

      await controller.setStyle(AnimationStyle.drum);
      await controller.setSpeed(AnimationSpeed.medium);

      verifyNever(
        () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
      );
    });
  });
}

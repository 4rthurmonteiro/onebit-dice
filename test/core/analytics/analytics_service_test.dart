import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/analytics/firebase_analytics_service.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _MockFirebaseCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  group('FirebaseAnalyticsService', () {
    late _MockFirebaseAnalytics analytics;
    late _MockFirebaseCrashlytics crashlytics;
    late FirebaseAnalyticsService service;

    setUp(() {
      analytics = _MockFirebaseAnalytics();
      crashlytics = _MockFirebaseCrashlytics();
      service = FirebaseAnalyticsService(
        analytics: analytics,
        crashlytics: crashlytics,
      );
    });

    test('logEvent forwards name + parameters to FirebaseAnalytics', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.logEvent('dice_rolled', parameters: const {'type': 'd20'});

      verify(
        () => analytics.logEvent(
          name: 'dice_rolled',
          parameters: const {'type': 'd20'},
        ),
      ).called(1);
    });

    test('logEvent encodes bool parameters as 1/0 for Firebase', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.logEvent(
        'sound_toggled',
        parameters: const {'enabled': true, 'muted': false, 'count': 3},
      );

      verify(
        () => analytics.logEvent(
          name: 'sound_toggled',
          parameters: const {'enabled': 1, 'muted': 0, 'count': 3},
        ),
      ).called(1);
    });

    test('logEvent forwards null parameters when omitted', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await service.logEvent('app_opened');

      verify(() => analytics.logEvent(name: 'app_opened')).called(1);
    });

    test('logScreenView forwards the screen name', () async {
      when(
        () => analytics.logScreenView(screenName: any(named: 'screenName')),
      ).thenAnswer((_) async {});

      await service.logScreenView('settings');

      verify(() => analytics.logScreenView(screenName: 'settings')).called(1);
    });

    test('recordError forwards error + stack + fatal to Crashlytics', () async {
      final error = Exception('boom');
      final stack = StackTrace.current;
      when(
        () => crashlytics.recordError(
          any<Object>(),
          any<StackTrace?>(),
          fatal: any(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      await service.recordError(error, stack, fatal: true);

      verify(
        () => crashlytics.recordError(error, stack, fatal: true),
      ).called(1);
    });

    test('recordError defaults fatal to false', () async {
      final error = Exception('boom');
      when(
        () => crashlytics.recordError(
          any<Object>(),
          any<StackTrace?>(),
          fatal: any(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      await service.recordError(error, null);

      verify(() => crashlytics.recordError(error, null)).called(1);
    });
  });
}

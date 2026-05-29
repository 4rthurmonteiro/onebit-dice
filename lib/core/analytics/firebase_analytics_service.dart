import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';

/// [AnalyticsService] implementation backed by Firebase Analytics +
/// Firebase Crashlytics.
class FirebaseAnalyticsService implements AnalyticsService {
  /// Creates a Firebase-backed analytics service. Both clients are injected
  /// so tests can swap them for mocks.
  FirebaseAnalyticsService({
    required this.analytics,
    required this.crashlytics,
  });

  /// Firebase Analytics client used to record events and screen views.
  final FirebaseAnalytics analytics;

  /// Firebase Crashlytics client used to record errors.
  final FirebaseCrashlytics crashlytics;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView(String screenName) {
    return analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) {
    return crashlytics.recordError(error, stack, fatal: fatal);
  }
}

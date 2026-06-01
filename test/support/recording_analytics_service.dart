import 'package:onebit_dice/core/analytics/analytics_service.dart';

/// A single recorded [AnalyticsService.logEvent] call.
class AnalyticsEvent {
  /// Creates an [AnalyticsEvent] capturing the event [name] and [parameters].
  const AnalyticsEvent(this.name, this.parameters);

  /// The event name passed to `logEvent`.
  final String name;

  /// The parameters map passed to `logEvent` (may be `null`).
  final Map<String, Object>? parameters;
}

/// [AnalyticsService] test double that records every call so tests can assert
/// that the expected product events and screen views were fired.
class RecordingAnalyticsService implements AnalyticsService {
  /// Every `logEvent` call, in invocation order.
  final List<AnalyticsEvent> events = [];

  /// Every `logScreenView` name, in invocation order.
  final List<String> screenViews = [];

  /// Convenience view over [events] names, in invocation order.
  List<String> get eventNames => [for (final event in events) event.name];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(AnalyticsEvent(name, parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async {
    screenViews.add(screenName);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}
}

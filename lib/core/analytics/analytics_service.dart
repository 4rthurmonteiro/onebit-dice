/// Project-wide analytics + crash-reporting seam.
///
/// Implementations forward calls to a backend (Firebase) or no-op in
/// tests / opt-out paths. Methods are intentionally narrow: callers send
/// event names and primitive parameters, never typed payloads.
abstract class AnalyticsService {
  /// Records a user-facing event (e.g. dice rolled, palette changed).
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Records a screen view (route name on enter).
  Future<void> logScreenView(String screenName);

  /// Records an error. [fatal] marks the report as a crash on the backend.
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal});
}

/// No-op implementation used in tests and when analytics is unavailable.
class NoOpAnalyticsService implements AnalyticsService {
  /// Creates a no-op analytics service.
  const NoOpAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {}
}

import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';

/// Mocktail mock of [AnalyticsService] shared across the test suite.
///
/// Use [createStubbedAnalytics] to obtain an instance whose methods are
/// already stubbed to no-op, so fire-and-forget analytics calls in
/// controllers don't throw `MissingStubError`. Assert specific calls with
/// `verify(() => analytics.logEvent(...))`.
class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Registers fallback values mocktail needs to match analytics arguments
/// with `any()`. Safe to call repeatedly.
void registerAnalyticsFallbacks() {
  registerFallbackValue(<String, Object>{});
  registerFallbackValue(StackTrace.empty);
}

/// Returns a [MockAnalyticsService] with every method stubbed to a no-op
/// completed future.
MockAnalyticsService createStubbedAnalytics() {
  registerAnalyticsFallbacks();
  final analytics = MockAnalyticsService();
  when(
    () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
  ).thenAnswer((_) async {});
  when(() => analytics.logScreenView(any())).thenAnswer((_) async {});
  when(
    () => analytics.recordError(
      any<Object>(),
      any<StackTrace?>(),
      fatal: any(named: 'fatal'),
    ),
  ).thenAnswer((_) async {});
  return analytics;
}

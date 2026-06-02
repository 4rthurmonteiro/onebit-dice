import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';

import '../../support/mock_analytics_service.dart';

class _MockLocalePreference extends Mock implements LocalePreference {}

void main() {
  setUpAll(() => registerFallbackValue(const Locale('en')));

  late _MockLocalePreference preference;
  late MockAnalyticsService analytics;

  setUp(() {
    preference = _MockLocalePreference();
    analytics = createStubbedAnalytics();
    when(() => preference.read()).thenReturn(null);
    when(() => preference.write(any())).thenAnswer((_) async {});
  });

  LocaleController build() =>
      LocaleController(analytics: analytics, preference: preference);

  group('LocaleController', () {
    test('override is null when preference is empty', () {
      expect(build().override, isNull);
    });

    test('reads initial override from preference when stored', () {
      when(() => preference.read()).thenReturn(const Locale('ja'));
      expect(build().override, const Locale('ja'));
    });

    test(
      'setOverride updates override, notifies once, and writes to preference',
      () async {
        final controller = build();
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.setOverride(const Locale('ko'));

        expect(controller.override, const Locale('ko'));
        expect(notifications, 1);
        verify(() => preference.write(const Locale('ko'))).called(1);
      },
    );

    test('setOverride is a no-op when the locale already matches', () async {
      when(() => preference.read()).thenReturn(const Locale('en'));
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setOverride(const Locale('en'));

      expect(controller.override, const Locale('en'));
      expect(notifications, 0);
      verifyNever(() => preference.write(any()));
    });

    test('setOverride throws ArgumentError for an unsupported locale '
        'and leaves state unchanged', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(
        () => controller.setOverride(const Locale('xx')),
        throwsArgumentError,
      );

      expect(controller.override, isNull);
      expect(notifications, 0);
      verifyNever(() => preference.write(any()));
    });

    test(
      'clearOverride from a non-null state writes null and notifies once',
      () async {
        when(() => preference.read()).thenReturn(const Locale('de'));
        final controller = build();
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.clearOverride();

        expect(controller.override, isNull);
        expect(notifications, 1);
        verify(() => preference.write(null)).called(1);
      },
    );

    test('clearOverride from null is a no-op', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.clearOverride();

      expect(controller.override, isNull);
      expect(notifications, 0);
      verifyNever(() => preference.write(any()));
    });

    test('supports the zh-Hans scripted locale via setOverride', () async {
      final controller = build();

      await controller.setOverride(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );

      expect(
        controller.override,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });

    test('setOverride logs language_changed with the language tag', () async {
      final controller = build();

      await controller.setOverride(const Locale('pt', 'BR'));

      verify(
        () => analytics.logEvent(
          'language_changed',
          parameters: {'locale': 'pt-BR'},
        ),
      ).called(1);
    });

    test('clearOverride logs language_changed with "system"', () async {
      when(() => preference.read()).thenReturn(const Locale('ja'));
      final controller = build();

      await controller.clearOverride();

      verify(
        () => analytics.logEvent(
          'language_changed',
          parameters: {'locale': 'system'},
        ),
      ).called(1);
    });

    test('no-op locale changes do not log', () async {
      final controller = build();

      // clearOverride from null changes nothing.
      await controller.clearOverride();

      verifyNever(
        () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
      );
    });
  });
}

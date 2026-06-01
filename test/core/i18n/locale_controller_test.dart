import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';

import '../../support/recording_analytics_service.dart';

class _RecordingPreference implements LocalePreference {
  _RecordingPreference([this._stored]);

  Locale? _stored;
  final List<Locale?> writes = [];

  @override
  Locale? read() => _stored;

  @override
  Future<void> write(Locale? value) async {
    writes.add(value);
    _stored = value;
  }
}

void main() {
  group('LocaleController', () {
    test('override is null when preference is empty', () {
      final controller = LocaleController();
      expect(controller.override, isNull);
    });

    test('reads initial override from preference when stored', () {
      final pref = _RecordingPreference(const Locale('ja'));
      final controller = LocaleController(preference: pref);
      expect(controller.override, const Locale('ja'));
    });

    test(
      'setOverride updates override, notifies once, and writes to preference',
      () async {
        final pref = _RecordingPreference();
        final controller = LocaleController(preference: pref);
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.setOverride(const Locale('ko'));

        expect(controller.override, const Locale('ko'));
        expect(notifications, 1);
        expect(pref.writes, [const Locale('ko')]);
      },
    );

    test('setOverride is a no-op when the locale already matches', () async {
      final pref = _RecordingPreference(const Locale('en'));
      final controller = LocaleController(preference: pref);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setOverride(const Locale('en'));

      expect(controller.override, const Locale('en'));
      expect(notifications, 0);
      expect(pref.writes, isEmpty);
    });

    test('setOverride throws ArgumentError for an unsupported locale '
        'and leaves state unchanged', () async {
      final pref = _RecordingPreference();
      final controller = LocaleController(preference: pref);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await expectLater(
        () => controller.setOverride(const Locale('xx')),
        throwsArgumentError,
      );

      expect(controller.override, isNull);
      expect(notifications, 0);
      expect(pref.writes, isEmpty);
    });

    test(
      'clearOverride from a non-null state writes null and notifies once',
      () async {
        final pref = _RecordingPreference(const Locale('de'));
        final controller = LocaleController(preference: pref);
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.clearOverride();

        expect(controller.override, isNull);
        expect(notifications, 1);
        expect(pref.writes, [null]);
      },
    );

    test('clearOverride from null is a no-op', () async {
      final pref = _RecordingPreference();
      final controller = LocaleController(preference: pref);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.clearOverride();

      expect(controller.override, isNull);
      expect(notifications, 0);
      expect(pref.writes, isEmpty);
    });

    test('supports the zh-Hans scripted locale via setOverride', () async {
      final pref = _RecordingPreference();
      final controller = LocaleController(preference: pref);

      await controller.setOverride(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );

      expect(
        controller.override,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    });

    test('setOverride logs language_changed with the language tag', () async {
      final analytics = RecordingAnalyticsService();
      final controller = LocaleController(
        preference: _RecordingPreference(),
        analytics: analytics,
      );

      await controller.setOverride(const Locale('pt', 'BR'));

      expect(analytics.eventNames, ['language_changed']);
      expect(analytics.events.single.parameters, {'locale': 'pt-BR'});
    });

    test('clearOverride logs language_changed with "system"', () async {
      final analytics = RecordingAnalyticsService();
      final controller = LocaleController(
        preference: _RecordingPreference(const Locale('ja')),
        analytics: analytics,
      );

      await controller.clearOverride();

      expect(analytics.eventNames, ['language_changed']);
      expect(analytics.events.single.parameters, {'locale': 'system'});
    });

    test('no-op locale changes do not log', () async {
      final analytics = RecordingAnalyticsService();
      final controller = LocaleController(
        preference: _RecordingPreference(),
        analytics: analytics,
      );

      // clearOverride from null and setOverride to... nothing changes.
      await controller.clearOverride();

      expect(analytics.events, isEmpty);
    });
  });
}

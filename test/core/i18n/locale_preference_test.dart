import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesLocalePreference', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('read() returns null when nothing has been written', () async {
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesLocalePreference(prefs);
      expect(pref.read(), isNull);
    });

    test('round-trip preserves each of the 10 supported locales', () async {
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesLocalePreference(prefs);

      for (final entry in supportedLocales) {
        await pref.write(entry.locale);
        expect(pref.read(), entry.locale, reason: 'round-trip ${entry.locale}');
      }
    });

    test('write(null) removes the underlying key', () async {
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesLocalePreference(prefs);

      await pref.write(const Locale('en'));
      await pref.write(null);

      expect(prefs.containsKey('locale_override'), isFalse);
      expect(pref.read(), isNull);
    });

    test('read() returns null when the stored tag is malformed', () async {
      SharedPreferences.setMockInitialValues({
        'locale_override': 'not-a-tag-!!!',
      });
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesLocalePreference(prefs);
      expect(pref.read(), isNull);
    });

    test('read() returns null when the stored tag is empty', () async {
      SharedPreferences.setMockInitialValues({'locale_override': ''});
      final prefs = await SharedPreferences.getInstance();
      final pref = SharedPreferencesLocalePreference(prefs);
      expect(pref.read(), isNull);
    });

    test(
      'read() returns null when the stored tag has empty language code',
      () async {
        SharedPreferences.setMockInitialValues({'locale_override': '-BR'});
        final prefs = await SharedPreferences.getInstance();
        final pref = SharedPreferencesLocalePreference(prefs);
        expect(pref.read(), isNull);
      },
    );
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';

void main() {
  group('supportedLocales', () {
    test('has exactly 10 entries', () {
      expect(supportedLocales, hasLength(10));
    });

    test('PT-BR is at index 0 and EN is at index 1', () {
      expect(supportedLocales[0].locale, const Locale('pt', 'BR'));
      expect(supportedLocales[1].locale, const Locale('en'));
    });

    test('every entry has a non-empty native name', () {
      for (final entry in supportedLocales) {
        expect(
          entry.nativeName,
          isNotEmpty,
          reason: 'native name for ${entry.locale}',
        );
      }
    });

    test('zh-Hans entry carries both language code and script code', () {
      final zh = supportedLocales.firstWhere(
        (entry) => entry.locale.languageCode == 'zh',
      );
      expect(zh.locale.languageCode, 'zh');
      expect(zh.locale.scriptCode, 'Hans');
    });
  });

  group('SupportedLocale', () {
    test('holds the locale and native name fields passed at construction', () {
      const entry = SupportedLocale(locale: Locale('ja'), nativeName: '日本語');
      expect(entry.locale, const Locale('ja'));
      expect(entry.nativeName, '日本語');
    });
  });
}

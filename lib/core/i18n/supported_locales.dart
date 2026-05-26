import 'package:flutter/widgets.dart';

/// Pairs a supported [Locale] with its display name in that locale's own
/// script.
@immutable
class SupportedLocale {
  /// Creates a [SupportedLocale] pairing.
  const SupportedLocale({required this.locale, required this.nativeName});

  /// The locale this entry represents.
  final Locale locale;

  /// The locale's name written in its own script.
  final String nativeName;
}

/// All locales supported at M1 launch.
///
/// Order matters for Flutter's fallback resolution:
///   index 0 — pt-BR (codebase default, source of truth)
///   index 1 — en    (global fallback, forced by `localeResolutionCallback`
///                    when the device locale matches nothing supported)
///
/// Remaining entries are alphabetical by language code.
const List<SupportedLocale> supportedLocales = [
  SupportedLocale(locale: Locale('pt', 'BR'), nativeName: 'Português (Brasil)'),
  SupportedLocale(locale: Locale('en'), nativeName: 'English'),
  SupportedLocale(locale: Locale('de'), nativeName: 'Deutsch'),
  SupportedLocale(locale: Locale('es'), nativeName: 'Español'),
  SupportedLocale(locale: Locale('fr'), nativeName: 'Français'),
  SupportedLocale(locale: Locale('it'), nativeName: 'Italiano'),
  SupportedLocale(locale: Locale('ja'), nativeName: '日本語'),
  SupportedLocale(locale: Locale('ko'), nativeName: '한국어'),
  SupportedLocale(locale: Locale('ru'), nativeName: 'Русский'),
  SupportedLocale(
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    nativeName: '中文（简体）',
  ),
];

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';

/// Owns the user-selected locale override and notifies listeners whenever
/// it changes.
///
/// Distributed via `ChangeNotifierProvider<LocaleController>` at the root of
/// the app (see `lib/app.dart`). Consumers read it with `context.watch` and
/// feed [override] into `MaterialApp.locale`.
///
/// When [override] is `null`, the app follows the system locale via
/// Flutter's `MaterialApp.localeResolutionCallback`.
class LocaleController extends ChangeNotifier {
  /// Creates a [LocaleController] backed by the given locale preference. The
  /// initial override is read synchronously from `preference.read()`.
  LocaleController({required this._analytics, required this._preference}) {
    _override = _preference.read();
  }

  final LocalePreference _preference;
  final AnalyticsService _analytics;
  Locale? _override;

  /// The active locale override, or `null` when the app follows the system
  /// locale.
  Locale? get override => _override;

  /// Sets the active locale override to [locale]. No-op (no notify, no
  /// write) when [locale] already matches the current override.
  ///
  /// Throws [ArgumentError] when [locale] is not part of
  /// [supportedLocales] — UIs should only ever offer supported locales, so
  /// this is treated as a programmer bug.
  Future<void> setOverride(Locale locale) async {
    final isSupported = supportedLocales.any((entry) => entry.locale == locale);
    if (!isSupported) {
      throw ArgumentError.value(
        locale,
        'locale',
        'Locale is not part of supportedLocales',
      );
    }
    if (_override == locale) return;
    _override = locale;
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'language_changed',
        parameters: {'locale': locale.toLanguageTag()},
      ),
    );
    await _preference.write(locale);
  }

  /// Clears the manual override so the app follows the system locale again.
  /// No-op (no notify, no write) when no override is currently set.
  Future<void> clearOverride() async {
    if (_override == null) return;
    _override = null;
    notifyListeners();
    unawaited(
      _analytics.logEvent('language_changed', parameters: {'locale': 'system'}),
    );
    await _preference.write(null);
  }
}

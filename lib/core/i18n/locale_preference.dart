import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over the storage backend that persists the user's manual
/// locale override.
///
/// The preference is a dumb persistence seam: it stores and retrieves a
/// [Locale] (or `null` meaning "no override; follow system") without
/// validating that the locale is one of the app's supported locales —
/// that responsibility belongs to `LocaleController`.
abstract interface class LocalePreference {
  /// Returns the stored locale override, or `null` when no override is set.
  Locale? read();

  /// Persists [value] as the active override. Passing `null` clears it.
  Future<void> write(Locale? value);
}

/// [LocalePreference] backed by `SharedPreferences`.
///
/// The locale override is stored as a BCP-47 language tag via
/// [Locale.toLanguageTag] (e.g. `pt-BR`, `zh-Hans`). Malformed or
/// unparseable stored tags are treated as "no override" rather than
/// throwing — graceful degradation if the storage has been tampered with.
class SharedPreferencesLocalePreference implements LocalePreference {
  /// Creates a preference reading from / writing to the given `prefs`
  /// instance.
  SharedPreferencesLocalePreference(this._prefs);

  static const String _key = 'locale_override';

  final SharedPreferences _prefs;

  @override
  Locale? read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return _parseLanguageTag(raw);
  }

  @override
  Future<void> write(Locale? value) async {
    if (value == null) {
      await _prefs.remove(_key);
      return;
    }
    await _prefs.setString(_key, value.toLanguageTag());
  }

  /// Parses a BCP-47 language tag into a [Locale]. Recognizes only the
  /// shapes the app actually persists — `lang`, `lang-REGION`, and
  /// `lang-SCRIPT`. Anything else returns `null`.
  Locale? _parseLanguageTag(String tag) {
    final parts = tag.split('-');
    if (parts[0].isEmpty) return null;

    switch (parts.length) {
      case 1:
        return Locale(parts[0]);
      case 2:
        final language = parts[0];
        final subtag = parts[1];
        // Script subtags are 4 letters (e.g. `Hans`); region subtags are 2.
        if (subtag.length == 4) {
          return Locale.fromSubtags(languageCode: language, scriptCode: subtag);
        }
        if (subtag.length == 2) {
          return Locale(language, subtag);
        }
        return null;
      default:
        return null;
    }
  }
}

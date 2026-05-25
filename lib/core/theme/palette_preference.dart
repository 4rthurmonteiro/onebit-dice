import 'package:onebit_dice/core/theme/palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over the storage backend that persists the user's chosen
/// palette.
///
/// E02 shipped only the [InMemoryPalettePreference]; E04 adds
/// [SharedPreferencesPalettePreference] behind the same interface so the
/// `ThemeProvider` does not need to change.
abstract interface class PalettePreference {
  /// Returns the stored [PaletteId], or `null` if nothing has been persisted.
  PaletteId? read();

  /// Persists [id] as the active palette.
  Future<void> write(PaletteId id);
}

/// In-memory [PalettePreference] used as the default during E02. It holds
/// the value for the lifetime of the process only.
class InMemoryPalettePreference implements PalettePreference {
  PaletteId? _stored;

  @override
  PaletteId? read() => _stored;

  @override
  Future<void> write(PaletteId id) async {
    _stored = id;
  }
}

/// [PalettePreference] backed by `SharedPreferences`.
///
/// The selected palette is persisted as `PaletteId.index` so that renaming a
/// member does not invalidate stored data — but reordering [PaletteId] would.
/// Corrupted or out-of-range values are treated as "nothing stored" instead
/// of throwing.
class SharedPreferencesPalettePreference implements PalettePreference {
  /// Creates a preference reading from / writing to the given `prefs`
  /// instance.
  SharedPreferencesPalettePreference(this._prefs);

  static const String _key = 'palette_id';

  final SharedPreferences _prefs;

  @override
  PaletteId? read() {
    final raw = _prefs.getInt(_key);
    if (raw == null || raw < 0 || raw >= PaletteId.values.length) return null;
    return PaletteId.values[raw];
  }

  @override
  Future<void> write(PaletteId id) => _prefs.setInt(_key, id.index);
}

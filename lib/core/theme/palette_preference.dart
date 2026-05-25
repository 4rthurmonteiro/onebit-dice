import 'package:onebit_dice/core/theme/palette.dart';

/// Abstraction over the storage backend that persists the user's chosen
/// palette.
///
/// E02 ships only the [InMemoryPalettePreference]; E04 (Storage) will add a
/// shared-preferences-backed implementation behind the same interface so the
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

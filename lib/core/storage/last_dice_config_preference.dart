import 'package:equatable/equatable.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of the user's last dice configuration: the chosen
/// [DiceType] and the chosen [count] of dice (between 1 and 10).
class LastDiceConfig extends Equatable {
  /// Creates a snapshot for [diceType] and [count].
  const LastDiceConfig({required this.diceType, required this.count});

  /// Last dice kind selected by the user.
  final DiceType diceType;

  /// Last quantity of dice selected — always within `1..10`.
  final int count;

  @override
  List<Object?> get props => [diceType, count];
}

/// Abstraction over the storage backend that persists the user's last
/// dice configuration so the app can restore it on next launch (E05).
abstract interface class LastDiceConfigPreference {
  /// Returns the stored configuration, or `null` if nothing valid has been
  /// persisted.
  LastDiceConfig? read();

  /// Persists [config] as the last selected configuration.
  Future<void> write(LastDiceConfig config);
}

/// [LastDiceConfigPreference] backed by `SharedPreferences`.
///
/// Persists two ints: `last_dice_type` (a [DiceType] index) and
/// `last_dice_count` (1..10). [read] returns `null` if either key is
/// missing or holds an out-of-range value — never throws.
class SharedPreferencesLastDiceConfigPreference
    implements LastDiceConfigPreference {
  /// Creates a preference reading from / writing to the given `prefs`
  /// instance.
  SharedPreferencesLastDiceConfigPreference(this._prefs);

  static const String _diceTypeKey = 'last_dice_type';
  static const String _countKey = 'last_dice_count';

  final SharedPreferences _prefs;

  @override
  LastDiceConfig? read() {
    final typeIndex = _prefs.getInt(_diceTypeKey);
    final count = _prefs.getInt(_countKey);
    if (typeIndex == null || count == null) return null;
    if (typeIndex < 0 || typeIndex >= DiceType.values.length) return null;
    if (count < 1 || count > 10) return null;
    return LastDiceConfig(diceType: DiceType.values[typeIndex], count: count);
  }

  @override
  Future<void> write(LastDiceConfig config) async {
    await _prefs.setInt(_diceTypeKey, config.diceType.index);
    await _prefs.setInt(_countKey, config.count);
  }
}

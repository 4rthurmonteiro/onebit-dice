import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over the storage backend for user-tweakable app settings:
/// sound on/off, haptic on/off, animation style and animation speed.
///
/// Each field has its own atomic read/write pair so the UI can persist a
/// single toggle without rewriting unrelated values.
abstract interface class AppSettingsPreference {
  /// Returns the persisted "sound enabled" flag, or `null` when nothing has
  /// been stored yet.
  bool? readSoundEnabled();

  /// Persists [value] as the new "sound enabled" flag.
  Future<void> writeSoundEnabled({required bool value});

  /// Returns the persisted "haptic enabled" flag, or `null` when nothing has
  /// been stored yet.
  bool? readHapticEnabled();

  /// Persists [value] as the new "haptic enabled" flag.
  Future<void> writeHapticEnabled({required bool value});

  /// Returns the persisted [AnimationStyle], or `null` when nothing valid
  /// has been stored yet.
  AnimationStyle? readAnimationStyle();

  /// Persists [style] as the active animation style.
  Future<void> writeAnimationStyle(AnimationStyle style);

  /// Returns the persisted [AnimationSpeed], or `null` when nothing valid
  /// has been stored yet.
  AnimationSpeed? readAnimationSpeed();

  /// Persists [speed] as the active animation speed.
  Future<void> writeAnimationSpeed(AnimationSpeed speed);
}

/// In-memory [AppSettingsPreference]: holds values for the lifetime of the
/// process only. Useful as a test double and as the default until E06 wires
/// the shared-preferences-backed implementation.
class InMemoryAppSettingsPreference implements AppSettingsPreference {
  bool? _soundEnabled;
  bool? _hapticEnabled;
  AnimationStyle? _animationStyle;
  AnimationSpeed? _animationSpeed;

  @override
  bool? readSoundEnabled() => _soundEnabled;

  @override
  Future<void> writeSoundEnabled({required bool value}) async {
    _soundEnabled = value;
  }

  @override
  bool? readHapticEnabled() => _hapticEnabled;

  @override
  Future<void> writeHapticEnabled({required bool value}) async {
    _hapticEnabled = value;
  }

  @override
  AnimationStyle? readAnimationStyle() => _animationStyle;

  @override
  Future<void> writeAnimationStyle(AnimationStyle style) async {
    _animationStyle = style;
  }

  @override
  AnimationSpeed? readAnimationSpeed() => _animationSpeed;

  @override
  Future<void> writeAnimationSpeed(AnimationSpeed speed) async {
    _animationSpeed = speed;
  }
}

/// [AppSettingsPreference] backed by `SharedPreferences`.
///
/// Enums are persisted as `index`. Out-of-range or otherwise corrupt values
/// are reported as "nothing stored" (`null`) rather than thrown.
class SharedPreferencesAppSettingsPreference implements AppSettingsPreference {
  /// Creates a preference reading from / writing to the given `prefs`
  /// instance.
  SharedPreferencesAppSettingsPreference(this._prefs);

  static const String _soundKey = 'sound_enabled';
  static const String _hapticKey = 'haptic_enabled';
  static const String _animationStyleKey = 'animation_style';
  static const String _animationSpeedKey = 'animation_speed';

  final SharedPreferences _prefs;

  @override
  bool? readSoundEnabled() => _prefs.getBool(_soundKey);

  @override
  Future<void> writeSoundEnabled({required bool value}) =>
      _prefs.setBool(_soundKey, value);

  @override
  bool? readHapticEnabled() => _prefs.getBool(_hapticKey);

  @override
  Future<void> writeHapticEnabled({required bool value}) =>
      _prefs.setBool(_hapticKey, value);

  @override
  AnimationStyle? readAnimationStyle() {
    final raw = _prefs.getInt(_animationStyleKey);
    if (raw == null || raw < 0 || raw >= AnimationStyle.values.length) {
      return null;
    }
    return AnimationStyle.values[raw];
  }

  @override
  Future<void> writeAnimationStyle(AnimationStyle style) =>
      _prefs.setInt(_animationStyleKey, style.index);

  @override
  AnimationSpeed? readAnimationSpeed() {
    final raw = _prefs.getInt(_animationSpeedKey);
    if (raw == null || raw < 0 || raw >= AnimationSpeed.values.length) {
      return null;
    }
    return AnimationSpeed.values[raw];
  }

  @override
  Future<void> writeAnimationSpeed(AnimationSpeed speed) =>
      _prefs.setInt(_animationSpeedKey, speed.index);
}

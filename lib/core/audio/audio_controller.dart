import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:onebit_dice/core/audio/soloud_sound_player.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

/// Orchestrates the audio engine, the persisted `soundEnabled` flag, and the
/// app lifecycle.
///
/// Distributed via `ChangeNotifierProvider<AudioController>` in
/// `lib/app.dart`. The flag defaults to `true` when
/// [AppSettingsPreference.readSoundEnabled] returns `null` (first launch).
class AudioController extends ChangeNotifier with WidgetsBindingObserver {
  /// Creates an [AudioController] backed by [preference]. Pass [player] to
  /// inject a fake in tests; production code can rely on the default
  /// [SoLoudSoundPlayer].
  AudioController({
    required AppSettingsPreference preference,
    SoundPlayer? player,
  }) : _preference = preference,
       _player = player ?? SoLoudSoundPlayer(),
       _soundEnabled = preference.readSoundEnabled() ?? true;

  final AppSettingsPreference _preference;
  final SoundPlayer _player;
  bool _soundEnabled;
  bool _initialized = false;

  /// Whether SFX should play. Driven by the persisted preference and the
  /// settings toggle.
  bool get soundEnabled => _soundEnabled;

  /// Loads SFX assets and starts observing the app lifecycle. Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    await _player.init();
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }

  /// Plays [event] when sound is enabled. No-op otherwise.
  void play(SoundEvent event) {
    if (!_soundEnabled) return;
    _player.play(event);
  }

  /// Updates the flag and notifies listeners immediately, then persists in
  /// the background. When [value] is `false`, any in-flight SFX is stopped
  /// first.
  Future<void> setSoundEnabled({required bool value}) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
    if (!value) {
      await _player.stopAll();
    }
    await _preference.writeSoundEnabled(value: value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    unawaited(_player.stopAll());
  }

  @override
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_player.dispose());
    }
    super.dispose();
  }
}

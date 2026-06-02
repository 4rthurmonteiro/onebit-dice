import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
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
    required this._analytics,
    SoundPlayer? player,
  }) : _preference = preference,
       _player = player ?? SoLoudSoundPlayer(),
       _soundEnabled = preference.readSoundEnabled() ?? true;

  /// Delay between the `grab` and `shake` phases of [playRollSequence].
  /// Tuned to let the grab transient finish before the shake layer enters.
  @visibleForTesting
  static const Duration shakeOffset = Duration(milliseconds: 120);

  /// Delay between the `shake` and `land` phases of [playRollSequence].
  /// Matches the body length of the shake takes so `land` lines up with
  /// the visual settle.
  @visibleForTesting
  static const Duration landOffset = Duration(milliseconds: 500);

  final AppSettingsPreference _preference;
  final SoundPlayer _player;
  final AnalyticsService _analytics;
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

  /// Plays the full dice-roll sound sequence — `grab` immediately, then
  /// `shake` after [shakeOffset], then `land` after a further [landOffset].
  ///
  /// No-op when sound is disabled. Each phase re-checks the flag, so a
  /// toggle mid-sequence stops further phases. Callers typically
  /// `unawaited` the returned Future — completion only indicates the
  /// `land` phase was triggered, not that the audio has finished playing.
  Future<void> playRollSequence() async {
    if (!_soundEnabled) return;
    _player.play(SoundEvent.grab);
    await Future<void>.delayed(shakeOffset);
    if (!_soundEnabled) return;
    _player.play(SoundEvent.shake);
    await Future<void>.delayed(landOffset);
    if (!_soundEnabled) return;
    _player.play(SoundEvent.land);
  }

  /// Updates the flag and notifies listeners immediately for snappy UI,
  /// then stops in-flight SFX (when [value] is `false`), then persists the
  /// new value. The order is deliberate: UX > durability for a sound
  /// toggle.
  Future<void> setSoundEnabled({required bool value}) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
    unawaited(
      _analytics.logEvent('sound_toggled', parameters: {'enabled': value}),
    );
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

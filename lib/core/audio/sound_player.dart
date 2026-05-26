/// The set of one-shot sound effects the app can play, paired with the
/// bundled asset that backs each one.
///
/// The ordering of members is not persisted (unlike enums in
/// `lib/core/storage/models/animation_settings.dart`), so reordering is safe.
enum SoundEvent {
  /// Played while the dice are rolling.
  roll(assetPath: 'assets/sounds/roll.mp3'),

  /// Played when the rolling animation finishes and individual dice settle.
  stop(assetPath: 'assets/sounds/stop.mp3'),

  /// Played when the final total is revealed.
  total(assetPath: 'assets/sounds/total.mp3');

  const SoundEvent({required this.assetPath});

  /// The bundled asset path for this SFX, suitable for `loadAsset`.
  final String assetPath;
}

/// Contract for a minimal audio engine that plays short, one-shot SFX.
///
/// Production implementation: `SoLoudSoundPlayer`. Tests pass a fake that
/// records calls — there is no reason to instantiate the real engine in unit
/// tests.
abstract interface class SoundPlayer {
  /// Boots the engine and pre-loads every [SoundEvent]. Idempotent: calling
  /// this more than once is a no-op.
  Future<void> init();

  /// Plays [event]. Fire-and-forget. No-op when [init] has not run yet.
  void play(SoundEvent event);

  /// Stops any SFX currently playing. Idempotent. No-op when [init] has not
  /// run yet.
  Future<void> stopAll();

  /// Releases engine resources. The player must not be used after this.
  Future<void> dispose();
}

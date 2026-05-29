/// The set of one-shot sound effects the app can play, paired with the
/// bundled assets that back each one.
///
/// Each phase ships multiple takes — the player picks one at random per
/// trigger so repeated rolls don't sound identical.
///
/// The ordering of members is not persisted (unlike enums in
/// `lib/core/storage/models/animation_settings.dart`), so reordering is safe.
enum SoundEvent {
  /// Played when a roll starts — the "pick up the dice" beat.
  grab(
    assetPaths: [
      'assets/sounds/dice-grab-1.ogg',
      'assets/sounds/dice-grab-2.ogg',
    ],
  ),

  /// Played mid-roll — the dice tumbling in the cup.
  shake(
    assetPaths: [
      'assets/sounds/dice-shake-1.ogg',
      'assets/sounds/dice-shake-2.ogg',
      'assets/sounds/dice-shake-3.ogg',
    ],
  ),

  /// Played when the dice hit the table — the closing beat.
  land(
    assetPaths: [
      'assets/sounds/dice-throw-1.ogg',
      'assets/sounds/dice-throw-2.ogg',
      'assets/sounds/dice-throw-3.ogg',
    ],
  );

  const SoundEvent({required this.assetPaths});

  /// Bundled asset paths for this phase. The player loads every entry and
  /// picks one at random each time the event fires.
  final List<String> assetPaths;
}

/// Contract for a minimal audio engine that plays short, one-shot SFX.
///
/// Production implementation: `SoLoudSoundPlayer`. Tests pass a fake that
/// records calls — there is no reason to instantiate the real engine in unit
/// tests.
abstract interface class SoundPlayer {
  /// Boots the engine and pre-loads every [SoundEvent] variant. Idempotent:
  /// calling this more than once is a no-op.
  Future<void> init();

  /// Plays a random variant of [event]. Fire-and-forget. No-op when [init]
  /// has not run yet.
  void play(SoundEvent event);

  /// Stops any SFX currently playing. Idempotent. No-op when [init] has not
  /// run yet.
  Future<void> stopAll();

  /// Releases engine resources. The player must not be used after this.
  Future<void> dispose();
}

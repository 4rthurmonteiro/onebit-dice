// coverage:ignore-file
//
// This file is a thin passthrough over `SoLoud.instance` and has no unit
// tests. The contract surface is verified indirectly via
// `SoLoudSoundPlayer`, which is exercised against a fake gateway in
// `test/core/audio/soloud_sound_player_test.dart`. Running the real engine
// requires a native audio device, which is unavailable in CI.

import 'package:flutter_soloud/flutter_soloud.dart';

/// Seam over `SoLoud.instance` that isolates every call we make into the
/// native engine. Exists so tests can substitute a fake and so the surface
/// area we depend on stays small and explicit.
///
/// Method shapes mirror the SoLoud 4.x API:
/// - [play] and [deinit] are synchronous on `SoLoud.instance`.
/// - [stop] targets a single playing handle; `SoLoudSoundPlayer` calls it
///   per active handle so loaded sources stay in memory across lifecycle
///   transitions.
abstract interface class SoLoudGateway {
  /// Whether the underlying engine has been booted.
  bool get isInitialized;

  /// Boots the engine. Idempotent at the engine level: a second `init`
  /// without a `deinit` between is a no-op on the native side.
  Future<void> init();

  /// Releases native engine resources synchronously.
  void deinit();

  /// Loads [path] (an asset bundle key) into memory. The default
  /// `autoDispose: false` from SoLoud is what we want — sources persist
  /// across plays and lifecycle transitions.
  Future<AudioSource> loadAsset(String path);

  /// Plays [source] once. Returns the handle of the new instance.
  SoundHandle play(AudioSource source);

  /// Stops the single playing instance identified by [handle]. The
  /// underlying source remains loaded.
  Future<void> stop(SoundHandle handle);
}

/// Production [SoLoudGateway] that delegates straight to `SoLoud.instance`.
class RealSoLoudGateway implements SoLoudGateway {
  @override
  bool get isInitialized => SoLoud.instance.isInitialized;

  @override
  Future<void> init() => SoLoud.instance.init();

  @override
  void deinit() => SoLoud.instance.deinit();

  @override
  Future<AudioSource> loadAsset(String path) => SoLoud.instance.loadAsset(path);

  @override
  SoundHandle play(AudioSource source) => SoLoud.instance.play(source);

  @override
  Future<void> stop(SoundHandle handle) => SoLoud.instance.stop(handle);
}

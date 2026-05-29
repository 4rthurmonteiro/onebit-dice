import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:onebit_dice/core/audio/soloud_gateway.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';

/// [SoundPlayer] backed by `flutter_soloud`.
///
/// Every [SoundEvent] variant is loaded once during [init] and held in
/// memory for the process lifetime. [play] picks a random variant per call
/// so consecutive rolls don't sound identical. Failures are logged via
/// `debugPrint` but never thrown — sensory feedback must never break a
/// dice roll.
///
/// Hot restart can leave the native engine thread orphaned; [init] defends
/// against that by `deinit`-ing first when the gateway is already in an
/// initialized state.
class SoLoudSoundPlayer implements SoundPlayer {
  /// Creates a [SoLoudSoundPlayer]. Pass [gateway] to inject a fake in
  /// tests; production code can use the default [RealSoLoudGateway]. Pass
  /// [random] to make variant selection deterministic in tests.
  SoLoudSoundPlayer({SoLoudGateway? gateway, Random? random})
    : _gateway = gateway ?? RealSoLoudGateway(),
      _random = random ?? Random();

  final SoLoudGateway _gateway;
  final Random _random;
  final Map<SoundEvent, List<AudioSource>> _sources = {};
  final Set<SoundHandle> _activeHandles = {};
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    // Target platforms are iOS and Android. `flutter_soloud` has no web
    // JS bindings wired here, so attempting init is guaranteed noise.
    if (kIsWeb) return; // coverage:ignore-line
    if (_gateway.isInitialized) {
      _gateway.deinit();
    }
    try {
      await _gateway.init();
      for (final event in SoundEvent.values) {
        final variants = <AudioSource>[];
        for (final path in event.assetPaths) {
          variants.add(await _gateway.loadAsset(path));
        }
        _sources[event] = variants;
      }
      _initialized = true;
    } on Object catch (error, stackTrace) {
      // Audio is sensory feedback — never block app startup. Stays
      // uninitialized; `play` becomes a no-op until a future `init`.
      _sources.clear();
      debugPrint('SoLoudSoundPlayer.init failed: $error\n$stackTrace');
    }
  }

  @override
  void play(SoundEvent event) {
    if (!_initialized) return;
    final variants = _sources[event];
    if (variants == null || variants.isEmpty) return;
    final source = variants[_random.nextInt(variants.length)];
    try {
      _activeHandles.add(_gateway.play(source));
    } on Object catch (error, stackTrace) {
      debugPrint('SoLoudSoundPlayer.play($event) failed: $error\n$stackTrace');
    }
  }

  @override
  Future<void> stopAll() async {
    if (!_initialized) return;
    final handles = List<SoundHandle>.of(_activeHandles);
    _activeHandles.clear();
    for (final handle in handles) {
      try {
        await _gateway.stop(handle);
      } on Object catch (error, stackTrace) {
        debugPrint(
          'SoLoudSoundPlayer.stop($handle) failed: $error\n$stackTrace',
        );
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    _gateway.deinit();
    _sources.clear();
    _activeHandles.clear();
    _initialized = false;
  }
}

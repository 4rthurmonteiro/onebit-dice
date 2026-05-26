// The fake gateway constructs SoLoud AudioSource / SoundHash instances
// directly. Their constructors are annotated `@internal`, which is fine in
// test code that is exercising the seam.
// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/soloud_gateway.dart';
import 'package:onebit_dice/core/audio/soloud_sound_player.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';

class _FakeSoLoudGateway implements SoLoudGateway {
  _FakeSoLoudGateway({this.preInitialized = false});

  bool preInitialized;
  bool engineInitialized = false;
  bool throwOnPlay = false;
  bool throwOnStop = false;

  int initCalls = 0;
  int deinitCalls = 0;
  final List<String> loadedAssets = [];
  final List<AudioSource> playedSources = [];
  final List<SoundHandle> stoppedHandles = [];

  int _nextHandle = 1;
  int _nextHash = 1;

  @override
  bool get isInitialized {
    if (initCalls == 0) {
      return preInitialized;
    }
    return engineInitialized;
  }

  @override
  Future<void> init() async {
    initCalls++;
    engineInitialized = true;
  }

  @override
  void deinit() {
    deinitCalls++;
    engineInitialized = false;
  }

  @override
  Future<AudioSource> loadAsset(String path) async {
    loadedAssets.add(path);
    return AudioSource(SoundHash(_nextHash++));
  }

  @override
  SoundHandle play(AudioSource source) {
    if (throwOnPlay) {
      throw StateError('boom');
    }
    playedSources.add(source);
    return SoundHandle(_nextHandle++);
  }

  @override
  Future<void> stop(SoundHandle handle) async {
    if (throwOnStop) {
      throw StateError('boom');
    }
    stoppedHandles.add(handle);
  }
}

void main() {
  group('SoLoudSoundPlayer', () {
    test('default constructor falls back to the real gateway', () {
      expect(SoLoudSoundPlayer.new, returnsNormally);
    });

    test('init boots the gateway and loads every SoundEvent asset', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.init();

      expect(gateway.initCalls, 1);
      expect(gateway.deinitCalls, 0);
      expect(
        gateway.loadedAssets,
        SoundEvent.values.map((e) => e.assetPath).toList(),
      );
    });

    test('init is a no-op when called a second time', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.init();
      await player.init();

      expect(gateway.initCalls, 1);
      expect(gateway.loadedAssets, hasLength(SoundEvent.values.length));
    });

    test('init calls deinit first when the gateway is already initialized '
        '(hot restart defense)', () async {
      final gateway = _FakeSoLoudGateway(preInitialized: true);
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.init();

      expect(gateway.deinitCalls, 1);
      expect(gateway.initCalls, 1);
    });

    test('play before init is a no-op', () {
      final gateway = _FakeSoLoudGateway();
      SoLoudSoundPlayer(gateway: gateway).play(SoundEvent.roll);

      expect(gateway.playedSources, isEmpty);
    });

    test('play after init forwards the loaded source to the gateway', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);
      await player.init();

      player
        ..play(SoundEvent.roll)
        ..play(SoundEvent.total);

      expect(gateway.playedSources, hasLength(2));
    });

    test('play swallows engine errors instead of propagating', () async {
      final gateway = _FakeSoLoudGateway()..throwOnPlay = true;
      final player = SoLoudSoundPlayer(gateway: gateway);
      await player.init();

      expect(() => player.play(SoundEvent.stop), returnsNormally);
    });

    test('stopAll before init is a no-op', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.stopAll();

      expect(gateway.stoppedHandles, isEmpty);
    });

    test(
      'stopAll stops every handle returned from play and clears the set',
      () async {
        final gateway = _FakeSoLoudGateway();
        final player = SoLoudSoundPlayer(gateway: gateway);
        await player.init();
        player
          ..play(SoundEvent.roll)
          ..play(SoundEvent.stop)
          ..play(SoundEvent.total);

        await player.stopAll();

        expect(gateway.stoppedHandles, hasLength(3));
        // Subsequent stopAll has nothing left to stop.
        await player.stopAll();
        expect(gateway.stoppedHandles, hasLength(3));
      },
    );

    test('stopAll swallows engine errors', () async {
      final gateway = _FakeSoLoudGateway()..throwOnStop = true;
      final player = SoLoudSoundPlayer(gateway: gateway);
      await player.init();
      player.play(SoundEvent.roll);

      await expectLater(player.stopAll(), completes);
    });

    test('dispose before init is a no-op', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.dispose();

      expect(gateway.deinitCalls, 0);
    });

    test(
      'dispose deinitializes the gateway and disables further plays',
      () async {
        final gateway = _FakeSoLoudGateway();
        final player = SoLoudSoundPlayer(gateway: gateway);
        await player.init();
        player.play(SoundEvent.roll);
        final playsBeforeDispose = gateway.playedSources.length;

        await player.dispose();

        expect(gateway.deinitCalls, 1);
        player.play(SoundEvent.stop);
        expect(gateway.playedSources, hasLength(playsBeforeDispose));
      },
    );
  });
}

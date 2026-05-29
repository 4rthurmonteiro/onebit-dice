// The fake gateway constructs SoLoud AudioSource / SoundHash instances
// directly. Their constructors are annotated `@internal`, which is fine in
// test code that is exercising the seam.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/soloud_gateway.dart';
import 'package:onebit_dice/core/audio/soloud_sound_player.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';

class _FakeSoLoudGateway implements SoLoudGateway {
  _FakeSoLoudGateway({this.engineInitialized = false});

  bool engineInitialized;
  bool throwOnInit = false;
  bool throwOnPlay = false;
  bool throwOnStop = false;

  int initCalls = 0;
  int deinitCalls = 0;
  final List<String> loadedAssets = [];
  final Map<String, AudioSource> sourcesByPath = {};
  final List<AudioSource> playedSources = [];
  final List<SoundHandle> stoppedHandles = [];

  int _nextHandle = 1;
  int _nextHash = 1;

  @override
  bool get isInitialized => engineInitialized;

  @override
  Future<void> init() async {
    initCalls++;
    if (throwOnInit) {
      throw StateError('boom');
    }
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
    final source = AudioSource(SoundHash(_nextHash++));
    sourcesByPath[path] = source;
    return source;
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

int _totalVariantCount() =>
    SoundEvent.values.fold(0, (sum, e) => sum + e.assetPaths.length);

void main() {
  group('SoLoudSoundPlayer', () {
    test('default constructor falls back to the real gateway', () {
      expect(SoLoudSoundPlayer.new, returnsNormally);
    });

    test(
      'init boots the gateway and loads every variant of every SoundEvent',
      () async {
        final gateway = _FakeSoLoudGateway();
        final player = SoLoudSoundPlayer(gateway: gateway);

        await player.init();

        expect(gateway.initCalls, 1);
        expect(gateway.deinitCalls, 0);
        expect(gateway.loadedAssets, [
          for (final e in SoundEvent.values) ...e.assetPaths,
        ]);
      },
    );

    test('init is a no-op when called a second time', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.init();
      await player.init();

      expect(gateway.initCalls, 1);
      expect(gateway.loadedAssets, hasLength(_totalVariantCount()));
    });

    test('init calls deinit first when the gateway is already initialized '
        '(hot restart defense)', () async {
      final gateway = _FakeSoLoudGateway(engineInitialized: true);
      final player = SoLoudSoundPlayer(gateway: gateway);

      await player.init();

      expect(gateway.deinitCalls, 1);
      expect(gateway.initCalls, 1);
    });

    test(
      'init swallows engine errors and leaves the player uninitialized',
      () async {
        final gateway = _FakeSoLoudGateway()..throwOnInit = true;
        final player = SoLoudSoundPlayer(gateway: gateway);

        await expectLater(player.init(), completes);

        // Subsequent play is a no-op because init failed.
        player.play(SoundEvent.grab);
        expect(gateway.playedSources, isEmpty);
      },
    );

    test('play before init is a no-op', () {
      final gateway = _FakeSoLoudGateway();
      SoLoudSoundPlayer(gateway: gateway).play(SoundEvent.grab);

      expect(gateway.playedSources, isEmpty);
    });

    test('play after init picks a variant from the requested event', () async {
      final gateway = _FakeSoLoudGateway();
      final player = SoLoudSoundPlayer(gateway: gateway, random: Random(0));
      await player.init();

      player.play(SoundEvent.grab);

      expect(gateway.playedSources, hasLength(1));
      final grabSources = [
        for (final p in SoundEvent.grab.assetPaths) gateway.sourcesByPath[p],
      ];
      expect(grabSources, contains(gateway.playedSources.single));
    });

    test(
      'play with a seeded Random selects deterministically across phases',
      () async {
        final gateway = _FakeSoLoudGateway();
        final player = SoLoudSoundPlayer(gateway: gateway, random: Random(0));
        await player.init();

        player
          ..play(SoundEvent.grab)
          ..play(SoundEvent.shake)
          ..play(SoundEvent.land);

        // Replay the same RNG to predict the variant indices the player
        // walked through, then map those back to the loaded sources.
        final oracle = Random(0);
        final expected = [
          gateway.sourcesByPath[SoundEvent.grab.assetPaths[oracle.nextInt(
            SoundEvent.grab.assetPaths.length,
          )]],
          gateway.sourcesByPath[SoundEvent.shake.assetPaths[oracle.nextInt(
            SoundEvent.shake.assetPaths.length,
          )]],
          gateway.sourcesByPath[SoundEvent.land.assetPaths[oracle.nextInt(
            SoundEvent.land.assetPaths.length,
          )]],
        ];
        expect(gateway.playedSources, expected);
      },
    );

    test('play swallows engine errors instead of propagating', () async {
      final gateway = _FakeSoLoudGateway()..throwOnPlay = true;
      final player = SoLoudSoundPlayer(gateway: gateway);
      await player.init();

      expect(() => player.play(SoundEvent.shake), returnsNormally);
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
          ..play(SoundEvent.grab)
          ..play(SoundEvent.shake)
          ..play(SoundEvent.land);

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
      player.play(SoundEvent.grab);

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
        player.play(SoundEvent.grab);
        final playsBeforeDispose = gateway.playedSources.length;

        await player.dispose();

        expect(gateway.deinitCalls, 1);
        player.play(SoundEvent.shake);
        expect(gateway.playedSources, hasLength(playsBeforeDispose));
      },
    );
  });
}

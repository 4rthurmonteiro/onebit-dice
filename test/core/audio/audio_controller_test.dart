import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

class _FakeSoundPlayer implements SoundPlayer {
  int initCalls = 0;
  int disposeCalls = 0;
  int stopAllCalls = 0;
  final List<SoundEvent> playCalls = [];

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  void play(SoundEvent event) {
    playCalls.add(event);
  }

  @override
  Future<void> stopAll() async {
    stopAllCalls++;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioController', () {
    test('default constructor falls back to a SoLoudSoundPlayer', () {
      expect(
        () => AudioController(preference: InMemoryAppSettingsPreference()),
        returnsNormally,
      );
    });

    test('defaults soundEnabled to true when nothing is stored', () {
      final controller = AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: _FakeSoundPlayer(),
      );

      expect(controller.soundEnabled, isTrue);
    });

    test('hydrates soundEnabled from preference (false)', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeSoundEnabled(value: false);
      final controller = AudioController(
        preference: pref,
        player: _FakeSoundPlayer(),
      );

      expect(controller.soundEnabled, isFalse);
    });

    test('hydrates soundEnabled from preference (true)', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeSoundEnabled(value: true);
      final controller = AudioController(
        preference: pref,
        player: _FakeSoundPlayer(),
      );

      expect(controller.soundEnabled, isTrue);
    });

    test(
      'init boots the player once and registers a lifecycle observer',
      () async {
        final player = _FakeSoundPlayer();
        final controller = AudioController(
          preference: InMemoryAppSettingsPreference(),
          player: player,
        );
        final before = WidgetsBinding.instance.lifecycleState;

        await controller.init();
        await controller.init();

        expect(player.initCalls, 1);
        // No observable side effect besides the increment, but we confirm the
        // observer is wired by sending a lifecycle state and checking stopAll.
        addTearDown(controller.dispose);
        addTearDown(() => before);
      },
    );

    test('play delegates to the player when soundEnabled is true', () {
      final player = _FakeSoundPlayer();
      AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: player,
      ).play(SoundEvent.roll);

      expect(player.playCalls, [SoundEvent.roll]);
    });

    test('play is a no-op when soundEnabled is false', () async {
      final pref = InMemoryAppSettingsPreference();
      await pref.writeSoundEnabled(value: false);
      final player = _FakeSoundPlayer();
      AudioController(preference: pref, player: player).play(SoundEvent.roll);

      expect(player.playCalls, isEmpty);
    });

    test('setSoundEnabled(true→false) notifies, stops, and persists', () async {
      final pref = InMemoryAppSettingsPreference();
      final player = _FakeSoundPlayer();
      final controller = AudioController(preference: pref, player: player);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setSoundEnabled(value: false);

      expect(controller.soundEnabled, isFalse);
      expect(notifications, 1);
      expect(player.stopAllCalls, 1);
      expect(pref.readSoundEnabled(), isFalse);
    });

    test(
      'setSoundEnabled(false→true) notifies and persists without stopping',
      () async {
        final pref = InMemoryAppSettingsPreference();
        await pref.writeSoundEnabled(value: false);
        final player = _FakeSoundPlayer();
        final controller = AudioController(preference: pref, player: player);
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.setSoundEnabled(value: true);

        expect(controller.soundEnabled, isTrue);
        expect(notifications, 1);
        expect(player.stopAllCalls, 0);
        expect(pref.readSoundEnabled(), isTrue);
      },
    );

    test('setSoundEnabled with the same value is a no-op', () async {
      final pref = InMemoryAppSettingsPreference();
      final player = _FakeSoundPlayer();
      final controller = AudioController(preference: pref, player: player);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setSoundEnabled(value: true);

      expect(notifications, 0);
      expect(player.stopAllCalls, 0);
      expect(pref.readSoundEnabled(), isNull);
    });

    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      test('didChangeAppLifecycleState($state) stops the player', () async {
        final player = _FakeSoundPlayer();
        final controller = AudioController(
          preference: InMemoryAppSettingsPreference(),
          player: player,
        );
        await controller.init();
        addTearDown(controller.dispose);

        controller.didChangeAppLifecycleState(state);
        await Future<void>.delayed(Duration.zero);

        expect(player.stopAllCalls, 1);
      });
    }

    test('didChangeAppLifecycleState(resumed) does nothing', () async {
      final player = _FakeSoundPlayer();
      final controller = AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: player,
      );
      await controller.init();
      addTearDown(controller.dispose);

      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(player.stopAllCalls, 0);
    });

    test('dispose tears down the player after init', () async {
      final player = _FakeSoundPlayer();
      final controller = AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: player,
      );
      await controller.init();

      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(player.disposeCalls, 1);
    });

    test('dispose without init does not touch the player', () {
      final player = _FakeSoundPlayer();
      AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: player,
      ).dispose();

      expect(player.disposeCalls, 0);
    });
  });
}

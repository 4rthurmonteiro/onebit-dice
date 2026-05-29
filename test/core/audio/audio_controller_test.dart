import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/audio/sound_player.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

class _FakeSoundPlayer implements SoundPlayer {
  _FakeSoundPlayer([this.events]);

  /// Optional shared log so an enclosing test can assert the relative order
  /// of player calls against other side effects.
  final List<String>? events;

  int initCalls = 0;
  int disposeCalls = 0;
  int stopAllCalls = 0;
  final List<SoundEvent> playCalls = [];

  @override
  Future<void> init() async {
    initCalls++;
    events?.add('init');
  }

  @override
  void play(SoundEvent event) {
    playCalls.add(event);
    events?.add('play($event)');
  }

  @override
  Future<void> stopAll() async {
    stopAllCalls++;
    events?.add('stopAll');
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    events?.add('dispose');
  }
}

class _RecordingAppSettings extends InMemoryAppSettingsPreference {
  _RecordingAppSettings(this.events);

  final List<String> events;

  @override
  Future<void> writeSoundEnabled({required bool value}) async {
    events.add('writeSoundEnabled($value)');
    await super.writeSoundEnabled(value: value);
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

    test('init boots the player once', () async {
      final player = _FakeSoundPlayer();
      final controller = AudioController(
        preference: InMemoryAppSettingsPreference(),
        player: player,
      );
      addTearDown(controller.dispose);

      await controller.init();
      await controller.init();

      expect(player.initCalls, 1);
    });

    test(
      'init registers a lifecycle observer that forwards to stopAll',
      () async {
        final player = _FakeSoundPlayer();
        final controller = AudioController(
          preference: InMemoryAppSettingsPreference(),
          player: player,
        );
        addTearDown(controller.dispose);

        await controller.init();
        // Sanity: a controller that has never been init-ed should not receive
        // lifecycle callbacks, while ours should.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await Future<void>.delayed(Duration.zero);

        expect(player.stopAllCalls, 1);
      },
    );

    group('playRollSequence', () {
      test('fires grab → shake → land with the configured offsets', () {
        fakeAsync((async) {
          final player = _FakeSoundPlayer();
          final controller = AudioController(
            preference: InMemoryAppSettingsPreference(),
            player: player,
          );

          unawaited(controller.playRollSequence());

          expect(player.playCalls, [SoundEvent.grab]);

          async.elapse(AudioController.shakeOffset);
          expect(player.playCalls, [SoundEvent.grab, SoundEvent.shake]);

          async.elapse(AudioController.landOffset);
          expect(player.playCalls, [
            SoundEvent.grab,
            SoundEvent.shake,
            SoundEvent.land,
          ]);
        });
      });

      test('is a no-op when sound is disabled at the start', () async {
        final pref = InMemoryAppSettingsPreference();
        await pref.writeSoundEnabled(value: false);
        final player = _FakeSoundPlayer();
        final controller = AudioController(preference: pref, player: player);

        await controller.playRollSequence();

        expect(player.playCalls, isEmpty);
      });

      test('aborts mid-sequence when sound is toggled off after grab', () {
        fakeAsync((async) {
          final player = _FakeSoundPlayer();
          final controller = AudioController(
            preference: InMemoryAppSettingsPreference(),
            player: player,
          );

          unawaited(controller.playRollSequence());
          expect(player.playCalls, [SoundEvent.grab]);

          unawaited(controller.setSoundEnabled(value: false));
          async
            ..flushMicrotasks()
            ..elapse(AudioController.shakeOffset + AudioController.landOffset);

          expect(player.playCalls, [SoundEvent.grab]);
        });
      });
    });

    test('setSoundEnabled(true→false) notifies, then stops, then persists '
        '— in that order', () async {
      final events = <String>[];
      final pref = _RecordingAppSettings(events);
      final player = _FakeSoundPlayer(events);
      final controller = AudioController(preference: pref, player: player)
        ..addListener(() => events.add('notify'));

      await controller.setSoundEnabled(value: false);

      expect(controller.soundEnabled, isFalse);
      expect(events, ['notify', 'stopAll', 'writeSoundEnabled(false)']);
      expect(pref.readSoundEnabled(), isFalse);
    });

    test(
      'setSoundEnabled(false→true) notifies and persists without stopping',
      () async {
        final events = <String>[];
        final pref = _RecordingAppSettings(events);
        await pref.writeSoundEnabled(value: false);
        events.clear();
        final player = _FakeSoundPlayer(events);
        final controller = AudioController(preference: pref, player: player)
          ..addListener(() => events.add('notify'));

        await controller.setSoundEnabled(value: true);

        expect(controller.soundEnabled, isTrue);
        expect(events, ['notify', 'writeSoundEnabled(true)']);
        expect(player.stopAllCalls, 0);
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

    test(
      'dispose tears down the player and removes the lifecycle observer',
      () async {
        final player = _FakeSoundPlayer();
        final controller = AudioController(
          preference: InMemoryAppSettingsPreference(),
          player: player,
        );
        await controller.init();

        controller.dispose();
        await Future<void>.delayed(Duration.zero);
        // After dispose, the observer must have been removed. Dispatch a
        // lifecycle event and confirm stopAll is not called again.
        WidgetsBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );
        await Future<void>.delayed(Duration.zero);

        expect(player.disposeCalls, 1);
        expect(player.stopAllCalls, 0);
      },
    );

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

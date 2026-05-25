import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';

void main() {
  Future<void> fillToCap(PresetsRepository repo) async {
    for (var i = 0; i < PresetsRepository.maxPresets; i++) {
      await repo.add(name: 'Preset $i', diceType: DiceType.d6, diceCount: 1);
    }
  }

  group('InMemoryPresetsRepository', () {
    test('snapshot is empty and canAddMore is true for a fresh repository', () {
      final repo = InMemoryPresetsRepository();
      expect(repo.snapshot(), isEmpty);
      expect(repo.canAddMore, isTrue);
    });

    test('add appends presets up to the cap', () async {
      final repo = InMemoryPresetsRepository();
      await fillToCap(repo);
      expect(repo.snapshot(), hasLength(PresetsRepository.maxPresets));
      expect(repo.canAddMore, isFalse);
    });

    test('add throws StateError when the cap is reached', () async {
      final repo = InMemoryPresetsRepository();
      await fillToCap(repo);

      expect(
        () => repo.add(name: 'overflow', diceType: DiceType.d6, diceCount: 1),
        throwsStateError,
      );
    });

    test('remove(id) drops the matching preset', () async {
      final repo = InMemoryPresetsRepository();
      final preset = await repo.add(
        name: 'Crit',
        diceType: DiceType.d20,
        diceCount: 1,
      );
      await repo.remove(preset.id);
      expect(repo.snapshot(), isEmpty);
    });

    test('remove(id) is a no-op when the id is unknown', () async {
      final repo = InMemoryPresetsRepository();
      await repo.add(name: 'A', diceType: DiceType.d6, diceCount: 1);
      await repo.remove('does-not-exist');
      expect(repo.snapshot(), hasLength(1));
    });

    test('rename(id, newName) replaces the name', () async {
      final repo = InMemoryPresetsRepository();
      final preset = await repo.add(
        name: 'Old',
        diceType: DiceType.d6,
        diceCount: 1,
      );
      await repo.rename(preset.id, 'New');
      expect(repo.snapshot().single.name, 'New');
    });

    test('rename throws StateError when the id is unknown', () async {
      final repo = InMemoryPresetsRepository();
      expect(() => repo.rename('missing', 'whatever'), throwsStateError);
    });

    test(
      'watch emits initial snapshot then again after every mutation',
      () async {
        final repo = InMemoryPresetsRepository();
        final preset = await repo.add(
          name: 'A',
          diceType: DiceType.d6,
          diceCount: 1,
        );

        final emissions = <int>[];
        final sub = repo.watch().listen((s) => emissions.add(s.length));

        await Future<void>.value();
        await repo.add(name: 'B', diceType: DiceType.d6, diceCount: 1);
        await repo.rename(preset.id, 'A2');
        await repo.remove(preset.id);
        await Future<void>.value();
        await sub.cancel();

        expect(emissions, [1, 2, 2, 1]);
      },
    );
  });

  group('HivePresetsRepository', () {
    late Directory tempDir;
    late Box<CustomPreset> box;
    late HivePresetsRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('presets_repo_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CustomPresetAdapter());
      }
      box = await Hive.openBox<CustomPreset>('custom_presets');
      repo = HivePresetsRepository(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('custom_presets');
      await tempDir.delete(recursive: true);
    });

    test('snapshot is empty and canAddMore is true for a fresh box', () {
      expect(repo.snapshot(), isEmpty);
      expect(repo.canAddMore, isTrue);
    });

    test('add persists the preset and snapshot reads it back', () async {
      final preset = await repo.add(
        name: 'Crit',
        diceType: DiceType.d20,
        diceCount: 1,
      );
      expect(repo.snapshot().single.id, preset.id);
    });

    test('add throws StateError when the cap is reached', () async {
      await fillToCap(repo);
      expect(
        () => repo.add(name: 'overflow', diceType: DiceType.d6, diceCount: 1),
        throwsStateError,
      );
    });

    test('remove drops the matching entry', () async {
      final preset = await repo.add(
        name: 'A',
        diceType: DiceType.d6,
        diceCount: 1,
      );
      await repo.remove(preset.id);
      expect(repo.snapshot(), isEmpty);
    });

    test('remove is a no-op for unknown ids', () async {
      await repo.add(name: 'A', diceType: DiceType.d6, diceCount: 1);
      await repo.remove('does-not-exist');
      expect(repo.snapshot(), hasLength(1));
    });

    test('rename replaces the stored name', () async {
      final preset = await repo.add(
        name: 'Old',
        diceType: DiceType.d6,
        diceCount: 1,
      );
      await repo.rename(preset.id, 'New');
      expect(repo.snapshot().single.name, 'New');
    });

    test('rename throws StateError when the id is unknown', () async {
      expect(() => repo.rename('missing', 'whatever'), throwsStateError);
    });

    test('watch emits initial snapshot then again after add', () async {
      await repo.add(name: 'A', diceType: DiceType.d6, diceCount: 1);

      final emissions = <int>[];
      final sub = repo.watch().listen((s) => emissions.add(s.length));

      await Future<void>.value();
      await repo.add(name: 'B', diceType: DiceType.d6, diceCount: 1);
      await Future<void>.value();
      await sub.cancel();

      expect(emissions.first, 1);
      expect(emissions, contains(2));
    });

    test('watch eventually shows the renamed value', () async {
      final preset = await repo.add(
        name: 'Old',
        diceType: DiceType.d6,
        diceCount: 1,
      );

      final names = <String>[];
      final sub = repo.watch().listen(
        (s) => names.addAll(s.map((p) => p.name)),
      );

      await Future<void>.value();
      await repo.rename(preset.id, 'New');
      await Future<void>.value();
      await sub.cancel();

      expect(names.last, 'New');
    });

    test('watch eventually drops removed entries', () async {
      final preset = await repo.add(
        name: 'A',
        diceType: DiceType.d6,
        diceCount: 1,
      );

      final emissions = <int>[];
      final sub = repo.watch().listen((s) => emissions.add(s.length));

      await Future<void>.value();
      await repo.remove(preset.id);
      await Future<void>.value();
      await sub.cancel();

      expect(emissions.first, 1);
      expect(emissions.last, 0);
    });
  });
}

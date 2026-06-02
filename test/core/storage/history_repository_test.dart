import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';

RollResult _result({required int seed}) => RollResult(
  timestamp: DateTime.utc(2026, 5, 25, 12, seed),
  diceType: DiceType.d6,
  diceCount: 1,
  values: [seed],
);

void main() {
  group('HiveHistoryRepository', () {
    late Directory tempDir;
    late Box<RollEntry> box;
    late HiveHistoryRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('history_repo_test');
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(RollEntryAdapter());
      }
      box = await Hive.openBox<RollEntry>('roll_history');
      repo = HiveHistoryRepository(box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('roll_history');
      await tempDir.delete(recursive: true);
    });

    test('snapshot is empty for a fresh box', () {
      expect(repo.snapshot(), isEmpty);
    });

    test('append persists entries that snapshot reads back', () async {
      await repo.append(_result(seed: 3));
      await repo.append(_result(seed: 4));

      final snapshot = repo.snapshot();
      expect(snapshot.map((e) => e.values), [
        [3],
        [4],
      ]);
    });

    test('clear empties the box', () async {
      await repo.append(_result(seed: 5));
      await repo.clear();
      expect(repo.snapshot(), isEmpty);
    });

    test('watch emits initial snapshot then again after each append', () async {
      await repo.append(_result(seed: 1));

      final emissions = <int>[];
      final sub = repo.watch().listen((snap) => emissions.add(snap.length));

      await Future<void>.value();
      await repo.append(_result(seed: 2));
      await Future<void>.value();
      await sub.cancel();

      expect(emissions.first, 1);
      expect(emissions, contains(2));
    });

    test('watch eventually reflects an empty snapshot after clear', () async {
      await repo.append(_result(seed: 1));
      await repo.append(_result(seed: 2));

      final emissions = <int>[];
      final sub = repo.watch().listen((snap) => emissions.add(snap.length));

      await Future<void>.value();
      await repo.clear();
      // Give the broadcast stream a few microtasks to drain the
      // per-key deletion notifications that `Box.clear()` emits.
      for (var i = 0; i < 5; i++) {
        await Future<void>.value();
      }
      await sub.cancel();

      expect(emissions.first, 2);
      expect(emissions.last, 0);
    });
  });
}

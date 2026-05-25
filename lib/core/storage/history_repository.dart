import 'dart:async';

import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';

/// Persistent, append-only log of every roll the user has made.
///
/// Snapshots are returned in the order the entries were inserted. Streams
/// emit the current snapshot immediately on subscription and then again
/// after every mutation. Errors are surfaced loudly: callers can assume
/// reads succeed under normal operation.
abstract interface class HistoryRepository {
  /// Returns the current list of entries, oldest first.
  List<RollEntry> snapshot();

  /// Emits the current snapshot followed by a new snapshot after every
  /// [append] / [clear].
  Stream<List<RollEntry>> watch();

  /// Appends [result] to the history.
  Future<void> append(RollResult result);

  /// Removes every entry.
  Future<void> clear();
}

/// In-memory [HistoryRepository] used as a test double and as the default
/// before the splash screen wires the Hive-backed implementation.
class InMemoryHistoryRepository implements HistoryRepository {
  /// Creates an empty in-memory history repository.
  InMemoryHistoryRepository();

  final List<RollEntry> _entries = [];
  final StreamController<List<RollEntry>> _controller =
      StreamController<List<RollEntry>>.broadcast();

  @override
  List<RollEntry> snapshot() => List<RollEntry>.unmodifiable(_entries);

  @override
  Stream<List<RollEntry>> watch() {
    late final StreamController<List<RollEntry>> output;
    StreamSubscription<List<RollEntry>>? sub;
    output = StreamController<List<RollEntry>>(
      onListen: () {
        sub = _controller.stream.listen(output.add);
        output.add(snapshot());
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );
    return output.stream;
  }

  @override
  Future<void> append(RollResult result) async {
    _entries.add(RollEntry.fromResult(result));
    _controller.add(snapshot());
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _controller.add(snapshot());
  }
}

/// [HistoryRepository] backed by a Hive box of [RollEntry] values.
class HiveHistoryRepository implements HistoryRepository {
  /// Creates a repository over an already-opened Hive `box`.
  HiveHistoryRepository(this._box);

  final Box<RollEntry> _box;

  @override
  List<RollEntry> snapshot() => _box.values.toList(growable: false);

  @override
  Stream<List<RollEntry>> watch() {
    late final StreamController<List<RollEntry>> output;
    StreamSubscription<BoxEvent>? sub;
    output = StreamController<List<RollEntry>>(
      onListen: () {
        sub = _box.watch().listen((_) => output.add(snapshot()));
        output.add(snapshot());
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );
    return output.stream;
  }

  @override
  Future<void> append(RollResult result) =>
      _box.add(RollEntry.fromResult(result));

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

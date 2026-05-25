import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';

part 'roll_entry.g.dart';

/// Persisted shape of a single dice roll. typeId `0`, reserved by the
/// E04 brainstorm (see `HiveInit` for the full typeId table).
///
/// `RollEntry` is intentionally separate from `RollResult` so that the
/// in-memory domain model stays free of Hive annotations and storage
/// concerns. Conversion happens through [RollEntry.fromResult] /
/// [RollEntry.toResult].
///
/// SCHEMA MIGRATION POLICY: novos campos devem ser `nullable` ou ter default
/// explícito. Nunca renumerar/remover `@HiveField`. Campos removidos viram
/// `@deprecated` — Hive ignora ausências silenciosamente.
@HiveType(typeId: 0)
class RollEntry {
  /// Creates a [RollEntry] with raw fields — used by the generated adapter
  /// and by tests. Application code should prefer [RollEntry.fromResult].
  RollEntry({
    required this.timestamp,
    required this.diceTypeIndex,
    required this.diceCount,
    required this.values,
  });

  /// Builds a [RollEntry] from a domain [RollResult]. Copies [values] so the
  /// stored list is independent of the source.
  factory RollEntry.fromResult(RollResult result) => RollEntry(
    timestamp: result.timestamp,
    diceTypeIndex: result.diceType.index,
    diceCount: result.diceCount,
    values: List<int>.of(result.values),
  );

  /// When the roll occurred.
  @HiveField(0)
  final DateTime timestamp;

  /// `DiceType.index` of the rolled die. Stored as an int to survive enum
  /// renames; reordering [DiceType] would break stored data.
  @HiveField(1)
  final int diceTypeIndex;

  /// How many dice were rolled.
  @HiveField(2)
  final int diceCount;

  /// Per-die results in roll order.
  @HiveField(3)
  final List<int> values;

  /// Rehydrates a domain [RollResult] from this entry.
  ///
  /// Throws [StateError] if [diceTypeIndex] is out of range — that signals
  /// data corruption and we want it surfaced loudly rather than silently
  /// substituted.
  RollResult toResult() {
    if (diceTypeIndex < 0 || diceTypeIndex >= DiceType.values.length) {
      throw StateError(
        'Corrupted RollEntry: invalid diceTypeIndex $diceTypeIndex',
      );
    }
    return RollResult(
      timestamp: timestamp,
      diceType: DiceType.values[diceTypeIndex],
      diceCount: diceCount,
      values: List<int>.unmodifiable(values),
    );
  }
}

import 'dart:math';

import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';

part 'custom_preset.g.dart';

/// Maximum allowed length for a [CustomPreset.name] (inclusive).
const int customPresetMaxNameLength = 24;

/// User-created roll configuration that lives in the `custom_presets` Hive
/// box. typeId `1`, reserved by the E04 brainstorm.
///
/// SCHEMA MIGRATION POLICY: novos campos devem ser `nullable` ou ter default
/// explícito. Nunca renumerar/remover `@HiveField`. Campos removidos viram
/// `@deprecated` — Hive ignora ausências silenciosamente.
@HiveType(typeId: 1)
class CustomPreset {
  /// Creates a [CustomPreset] with raw fields — used by the generated
  /// adapter and by tests when an exact `id`/`createdAt` is needed.
  /// Application code should prefer [CustomPreset.create].
  CustomPreset({
    required this.id,
    required this.name,
    required this.diceTypeIndex,
    required this.diceCount,
    required this.createdAt,
  }) {
    if (name.length > customPresetMaxNameLength) {
      throw ArgumentError.value(
        name,
        'name',
        'CustomPreset.name must be <= $customPresetMaxNameLength chars',
      );
    }
  }

  /// Builds a brand-new preset, generating [id] and [createdAt] internally.
  ///
  /// [name] must not exceed [customPresetMaxNameLength] characters.
  /// [diceType] is stored as its index.
  factory CustomPreset.create({
    required String name,
    required DiceType diceType,
    required int diceCount,
  }) {
    final now = DateTime.now();
    final id = _generateId(now);
    return CustomPreset(
      id: id,
      name: name,
      diceTypeIndex: diceType.index,
      diceCount: diceCount,
      createdAt: now,
    );
  }

  /// Stable identifier — used as the key in the `custom_presets` Hive box.
  @HiveField(0)
  final String id;

  /// User-visible name (max [customPresetMaxNameLength] characters).
  @HiveField(1)
  final String name;

  /// `DiceType.index` of the preset's die.
  @HiveField(2)
  final int diceTypeIndex;

  /// Number of dice (1..10).
  @HiveField(3)
  final int diceCount;

  /// When the preset was created.
  @HiveField(4)
  final DateTime createdAt;

  /// Resolves [diceTypeIndex] back to a [DiceType].
  ///
  /// Throws [StateError] if the persisted index falls outside the current
  /// enum — same loud-failure policy as `RollEntry.toResult`.
  DiceType get diceType {
    if (diceTypeIndex < 0 || diceTypeIndex >= DiceType.values.length) {
      throw StateError(
        'Corrupted CustomPreset: invalid diceTypeIndex $diceTypeIndex',
      );
    }
    return DiceType.values[diceTypeIndex];
  }

  /// Returns a copy of this preset with [name] replaced.
  CustomPreset copyWithName(String newName) => CustomPreset(
    id: id,
    name: newName,
    diceTypeIndex: diceTypeIndex,
    diceCount: diceCount,
    createdAt: createdAt,
  );

  static final _random = Random();

  static String _generateId(DateTime now) {
    final ts = now.microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 16).toRadixString(36);
    return '$ts-$salt';
  }
}

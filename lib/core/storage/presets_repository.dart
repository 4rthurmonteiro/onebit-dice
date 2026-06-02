import 'dart:async';

import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';

/// Repository of user-created [CustomPreset]s.
///
/// Capped at [PresetsRepository.maxPresets] entries — attempting to add when
/// the cap is reached throws [StateError]. The UI should consult
/// [canAddMore] before exposing an "add" affordance.
abstract interface class PresetsRepository {
  /// Maximum number of [CustomPreset] entries the user may create.
  static const int maxPresets = 10;

  /// Returns the current presets, in insertion order.
  List<CustomPreset> snapshot();

  /// Emits the current snapshot followed by a new snapshot after every
  /// mutation.
  Stream<List<CustomPreset>> watch();

  /// `true` when [snapshot] length is below [maxPresets].
  bool get canAddMore;

  /// Creates and stores a new preset.
  ///
  /// Throws [StateError] if [canAddMore] is `false`.
  Future<CustomPreset> add({
    required String name,
    required DiceType diceType,
    required int diceCount,
  });

  /// Removes the preset with [id]. No-op when the id is unknown.
  Future<void> remove(String id);

  /// Renames the preset with [id] to [newName].
  ///
  /// Throws [StateError] if [id] is unknown.
  Future<void> rename(String id, String newName);
}

/// [PresetsRepository] backed by a Hive box of [CustomPreset] values.
///
/// Presets are stored keyed by [CustomPreset.id] so that [remove] and
/// [rename] are O(1).
class HivePresetsRepository implements PresetsRepository {
  /// Creates a repository over an already-opened Hive `box`.
  HivePresetsRepository(this._box);

  final Box<CustomPreset> _box;

  @override
  List<CustomPreset> snapshot() => _box.values.toList(growable: false);

  @override
  Stream<List<CustomPreset>> watch() {
    late final StreamController<List<CustomPreset>> output;
    StreamSubscription<BoxEvent>? sub;
    output = StreamController<List<CustomPreset>>(
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
  bool get canAddMore => _box.length < PresetsRepository.maxPresets;

  @override
  Future<CustomPreset> add({
    required String name,
    required DiceType diceType,
    required int diceCount,
  }) async {
    if (!canAddMore) {
      throw StateError(
        'Preset cap reached (max $PresetsRepository.maxPresets)',
      );
    }
    final preset = CustomPreset.create(
      name: name,
      diceType: diceType,
      diceCount: diceCount,
    );
    await _box.put(preset.id, preset);
    return preset;
  }

  @override
  Future<void> remove(String id) => _box.delete(id);

  @override
  Future<void> rename(String id, String newName) async {
    final preset = _box.get(id);
    if (preset == null) {
      throw StateError('Unknown preset id: $id');
    }
    await _box.put(id, preset.copyWithName(newName));
  }
}

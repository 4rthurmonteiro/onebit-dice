import 'dart:async';

import 'package:hive_ce/hive_ce.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';

/// Maximum number of [CustomPreset] entries the user may create.
const int presetsRepositoryMaxPresets = 10;

/// Repository of user-created [CustomPreset]s.
///
/// Capped at [presetsRepositoryMaxPresets] entries — attempting to add when
/// the cap is reached throws [StateError]. The UI should consult
/// [canAddMore] before exposing an "add" affordance.
abstract interface class PresetsRepository {
  /// Returns the current presets, in insertion order.
  List<CustomPreset> snapshot();

  /// Emits the current snapshot followed by a new snapshot after every
  /// mutation.
  Stream<List<CustomPreset>> watch();

  /// `true` when [snapshot] length is below
  /// [presetsRepositoryMaxPresets].
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

/// In-memory [PresetsRepository] used as a test double and as the default
/// before the splash screen wires the Hive-backed implementation.
class InMemoryPresetsRepository implements PresetsRepository {
  /// Creates an empty in-memory presets repository.
  InMemoryPresetsRepository();

  final List<CustomPreset> _presets = [];
  final StreamController<List<CustomPreset>> _controller =
      StreamController<List<CustomPreset>>.broadcast();

  @override
  List<CustomPreset> snapshot() => List<CustomPreset>.unmodifiable(_presets);

  @override
  Stream<List<CustomPreset>> watch() {
    late final StreamController<List<CustomPreset>> output;
    StreamSubscription<List<CustomPreset>>? sub;
    output = StreamController<List<CustomPreset>>(
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
  bool get canAddMore => _presets.length < presetsRepositoryMaxPresets;

  @override
  Future<CustomPreset> add({
    required String name,
    required DiceType diceType,
    required int diceCount,
  }) async {
    if (!canAddMore) {
      throw StateError('Preset cap reached (max $presetsRepositoryMaxPresets)');
    }
    final preset = CustomPreset.create(
      name: name,
      diceType: diceType,
      diceCount: diceCount,
    );
    _presets.add(preset);
    _controller.add(snapshot());
    return preset;
  }

  @override
  Future<void> remove(String id) async {
    final before = _presets.length;
    _presets.removeWhere((p) => p.id == id);
    if (_presets.length != before) {
      _controller.add(snapshot());
    }
  }

  @override
  Future<void> rename(String id, String newName) async {
    final index = _presets.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw StateError('Unknown preset id: $id');
    }
    _presets[index] = _presets[index].copyWithName(newName);
    _controller.add(snapshot());
  }
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
  bool get canAddMore => _box.length < presetsRepositoryMaxPresets;

  @override
  Future<CustomPreset> add({
    required String name,
    required DiceType diceType,
    required int diceCount,
  }) async {
    if (!canAddMore) {
      throw StateError('Preset cap reached (max $presetsRepositoryMaxPresets)');
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
  Future<void> remove(String id) async {
    if (!_box.containsKey(id)) return;
    await _box.delete(id);
  }

  @override
  Future<void> rename(String id, String newName) async {
    final preset = _box.get(id);
    if (preset == null) {
      throw StateError('Unknown preset id: $id');
    }
    await _box.put(id, preset.copyWithName(newName));
  }
}

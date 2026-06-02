import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';

/// Mocktail mock of [PresetsRepository].
class MockPresetsRepository extends Mock implements PresetsRepository {}

/// Returns a [MockPresetsRepository] that behaves like the real repository:
/// snapshot/watch reflect every add/remove/rename and the
/// [PresetsRepository.maxPresets] cap is enforced. [seed] pre-populates it.
MockPresetsRepository createFakePresets({List<CustomPreset> seed = const []}) {
  registerFallbackValue(DiceType.d6);

  final presets = [...seed];
  final controller = StreamController<List<CustomPreset>>.broadcast();
  final mock = MockPresetsRepository();

  when(
    mock.snapshot,
  ).thenAnswer((_) => List<CustomPreset>.unmodifiable(presets));
  when(
    () => mock.canAddMore,
  ).thenAnswer((_) => presets.length < PresetsRepository.maxPresets);
  when(mock.watch).thenAnswer((_) {
    late final StreamController<List<CustomPreset>> output;
    StreamSubscription<List<CustomPreset>>? sub;
    output = StreamController<List<CustomPreset>>(
      onListen: () {
        sub = controller.stream.listen(output.add);
        output.add(List<CustomPreset>.unmodifiable(presets));
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );
    return output.stream;
  });
  when(
    () => mock.add(
      name: any(named: 'name'),
      diceType: any(named: 'diceType'),
      diceCount: any(named: 'diceCount'),
    ),
  ).thenAnswer((invocation) async {
    if (presets.length >= PresetsRepository.maxPresets) {
      throw StateError('Preset cap reached');
    }
    final preset = CustomPreset.create(
      name: invocation.namedArguments[#name] as String,
      diceType: invocation.namedArguments[#diceType] as DiceType,
      diceCount: invocation.namedArguments[#diceCount] as int,
    );
    presets.add(preset);
    controller.add(List<CustomPreset>.unmodifiable(presets));
    return preset;
  });
  when(() => mock.remove(any())).thenAnswer((invocation) async {
    final id = invocation.positionalArguments.first as String;
    final before = presets.length;
    presets.removeWhere((p) => p.id == id);
    if (presets.length != before) {
      controller.add(List<CustomPreset>.unmodifiable(presets));
    }
  });
  when(() => mock.rename(any(), any())).thenAnswer((invocation) async {
    final id = invocation.positionalArguments[0] as String;
    final newName = invocation.positionalArguments[1] as String;
    final index = presets.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw StateError('Unknown preset id: $id');
    }
    presets[index] = presets[index].copyWithName(newName);
    controller.add(List<CustomPreset>.unmodifiable(presets));
  });

  return mock;
}

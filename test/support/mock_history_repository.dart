import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';

/// Mocktail mock of [HistoryRepository].
class MockHistoryRepository extends Mock implements HistoryRepository {}

/// Returns a [MockHistoryRepository] that behaves like a real append-only log:
/// [HistoryRepository.snapshot] and [HistoryRepository.watch] reflect every
/// [HistoryRepository.append] / [HistoryRepository.clear], so widget tests can
/// exercise reactive updates. [seed] pre-populates the log.
MockHistoryRepository createFakeHistory({List<RollResult> seed = const []}) {
  registerFallbackValue(
    RollResult(
      timestamp: DateTime.utc(2026),
      diceType: DiceType.d6,
      diceCount: 1,
      values: const [1],
    ),
  );

  final entries = [for (final result in seed) RollEntry.fromResult(result)];
  final controller = StreamController<List<RollEntry>>.broadcast();
  final mock = MockHistoryRepository();

  when(mock.snapshot).thenAnswer((_) => List<RollEntry>.unmodifiable(entries));
  when(mock.watch).thenAnswer((_) {
    late final StreamController<List<RollEntry>> output;
    StreamSubscription<List<RollEntry>>? sub;
    output = StreamController<List<RollEntry>>(
      onListen: () {
        sub = controller.stream.listen(output.add);
        output.add(List<RollEntry>.unmodifiable(entries));
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );
    return output.stream;
  });
  when(() => mock.append(any())).thenAnswer((invocation) async {
    final result = invocation.positionalArguments.first as RollResult;
    entries.add(RollEntry.fromResult(result));
    controller.add(List<RollEntry>.unmodifiable(entries));
  });
  when(mock.clear).thenAnswer((_) async {
    entries.clear();
    controller.add(List<RollEntry>.unmodifiable(entries));
  });

  return mock;
}

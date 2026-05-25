import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:onebit_dice/core/models/dice_type.dart';

/// Immutable result of a single dice roll.
///
/// Holds the per-die [values] in roll order and exposes derived [total]
/// and [equation] views. Equality is value-based via [Equatable], so two
/// results with identical fields compare equal even when constructed from
/// distinct list instances.
@immutable
class RollResult extends Equatable {
  /// Creates a [RollResult] for [diceCount] dice of [diceType], rolled at
  /// [timestamp], producing [values] in roll order.
  const RollResult({
    required this.timestamp,
    required this.diceType,
    required this.diceCount,
    required this.values,
  });

  /// When the roll occurred. Always supplied explicitly by the caller.
  final DateTime timestamp;

  /// The kind of dice that were rolled.
  final DiceType diceType;

  /// How many dice were rolled. Matches `values.length` in well-formed
  /// instances.
  final int diceCount;

  /// Per-die results in roll order.
  final List<int> values;

  /// Sum of every entry in [values].
  int get total => values.fold(0, (sum, v) => sum + v);

  /// Human-readable equation:
  ///
  /// * single value → `'5'`
  /// * multiple values → `'3 + 5 + 2 = 10'`
  String get equation {
    if (values.length == 1) return '${values.first}';
    return '${values.join(' + ')} = $total';
  }

  @override
  List<Object?> get props => [timestamp, diceType, diceCount, values];
}

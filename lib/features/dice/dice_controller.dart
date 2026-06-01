import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/shared/utils/random_dice.dart';

/// Orchestrates the dice roll screen — owns `selectedType`, `count`, and the
/// latest [RollResult], and translates user intent into the side effects that
/// follow a roll.
///
/// On construction, hydrates `selectedType` and `count` from
/// [LastDiceConfigPreference]. Defaults to `d6` × 1 on first launch.
///
/// `roll()` runs its side effects in a deliberate order:
///   1. compute the [RollResult] and notify listeners (UI updates first)
///   2. append to [HistoryRepository]
///   3. kick off [AudioController.playRollSequence] (fire-and-forget)
///   4. fire a haptic pulse
///   5. persist the current config
///
/// The UI-first order favors a snappy view at the cost of durability: if the
/// history append throws, the result is already on screen. That trade-off is
/// fine for the in-memory repo in E05; revisit if/when the Hive-backed repo
/// can fail in production.
///
/// Not reentrant — `roll()` is `async` because two of its side effects are
/// awaited. The dice canvas is now the roll target (the dedicated `RollButton`
/// was removed in the Design C redesign), so the reentrancy guard lives here:
/// [isRolling] flips `true` for the duration of a `roll()` and a second call
/// started before the first settles early-returns. That keeps a rapid double
/// tap on the large canvas from appending two history rows / overlapping audio.
class DiceController extends ChangeNotifier {
  /// Creates a [DiceController] hydrated from [lastDiceConfig].
  ///
  /// Pass [rng] to seed [rollDice] deterministically in tests.
  factory DiceController({
    required HistoryRepository history,
    required AudioController audio,
    required HapticController haptic,
    required LastDiceConfigPreference lastDiceConfig,
    AnalyticsService analytics = const NoOpAnalyticsService(),
    Random? rng,
  }) {
    final stored = lastDiceConfig.read();
    return DiceController._(
      history,
      audio,
      haptic,
      lastDiceConfig,
      analytics,
      rng,
      stored?.diceType ?? DiceType.d6,
      stored?.count ?? 1,
    );
  }

  DiceController._(
    this._history,
    this._audio,
    this._haptic,
    this._lastDiceConfig,
    this._analytics,
    this._rng,
    this._selectedType,
    this._count,
  );

  final HistoryRepository _history;
  final AudioController _audio;
  final HapticController _haptic;
  final LastDiceConfigPreference _lastDiceConfig;
  final AnalyticsService _analytics;
  final Random? _rng;

  DiceType _selectedType;
  int _count;
  RollResult? _lastResult;
  bool _hasRolled = false;
  bool _isRolling = false;

  /// The currently selected [DiceType].
  DiceType get selectedType => _selectedType;

  /// The currently selected dice count, in `1..10`.
  int get count => _count;

  /// The most recent roll, or `null` when none has happened in this session
  /// or the user has changed the type/count since the last roll.
  RollResult? get lastResult => _lastResult;

  /// Whether at least one [roll] has happened since this controller was built.
  ///
  /// Session-scoped and in-memory only — never persisted. Deliberately **not**
  /// reset by [setType] / [setCount] / [applyConfig] (those clear [lastResult]
  /// but a config change is not "un-rolling"), so the tap-to-roll hint clears
  /// permanently after the first tap and only a fresh controller / app restart
  /// brings it back.
  bool get hasRolled => _hasRolled;

  /// Whether a [roll] is currently in flight.
  ///
  /// The dice canvas is the roll target now that `RollButton` is gone, so this
  /// guards the larger, easier-to-double-tap surface: a second [roll] started
  /// before the first settles is a no-op.
  bool get isRolling => _isRolling;

  /// Selects [type]. No-op when [type] already matches [selectedType].
  /// Otherwise clears [lastResult], notifies listeners, and persists.
  Future<void> setType(DiceType type) async {
    if (type == _selectedType) return;
    _selectedType = type;
    _lastResult = null;
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'dice_type_changed',
        parameters: {'dice_type': type.name},
      ),
    );
    await _lastDiceConfig.write(LastDiceConfig(diceType: type, count: _count));
  }

  /// Sets the dice count to [value], clamped to `1..10`.
  ///
  /// No-op when the clamped value already matches [count]. Otherwise clears
  /// [lastResult], notifies listeners, and persists.
  Future<void> setCount(int value) async {
    final clamped = value.clamp(1, 10);
    if (clamped == _count) return;
    _count = clamped;
    _lastResult = null;
    notifyListeners();
    await _lastDiceConfig.write(
      LastDiceConfig(diceType: _selectedType, count: clamped),
    );
  }

  /// Applies an external config atomically — used by the preset tap flow so
  /// the type/count change is a single [notifyListeners] + a single
  /// [LastDiceConfigPreference.write].
  ///
  /// [count] is clamped to `1..10`. No-op when both fields already match.
  Future<void> applyConfig({
    required DiceType diceType,
    required int count,
  }) async {
    final clamped = count.clamp(1, 10);
    if (diceType == _selectedType && clamped == _count) return;
    _selectedType = diceType;
    _count = clamped;
    _lastResult = null;
    notifyListeners();
    await _lastDiceConfig.write(
      LastDiceConfig(diceType: diceType, count: clamped),
    );
  }

  /// Rolls [count] dice of [selectedType], applies the side effects, and
  /// updates [lastResult].
  ///
  /// Non-reentrant: a call made while [isRolling] is `true` early-returns
  /// without producing a second result, history append, audio, or haptic.
  /// Sets [hasRolled] `true` at the very start so the tap-to-roll hint clears
  /// the instant the user taps, not after the animation resolves.
  Future<void> roll() async {
    if (_isRolling) return;
    _isRolling = true;
    _hasRolled = true;
    try {
      final values = rollDice(_selectedType.sides, _count, rng: _rng);
      _lastResult = RollResult(
        timestamp: DateTime.now(),
        diceType: _selectedType,
        diceCount: _count,
        values: values,
      );
      notifyListeners();
      unawaited(
        _analytics.logEvent(
          'dice_rolled',
          parameters: {
            'dice_type': _selectedType.name,
            'count': _count,
            'total': values.fold<int>(0, (sum, value) => sum + value),
          },
        ),
      );
      await _history.append(_lastResult!);
      unawaited(_audio.playRollSequence());
      _haptic.trigger();
      await _lastDiceConfig.write(
        LastDiceConfig(diceType: _selectedType, count: _count),
      );
    } finally {
      _isRolling = false;
    }
  }
}

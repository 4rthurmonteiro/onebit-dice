import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';

/// "Drum" strategy — when [targetValues] changes, cycles random values across
/// the grid for [duration], then settles to [targetValues].
///
/// Random faces are drawn from `1..sides`. Cycling fires roughly every 80 ms
/// (≈12 fps) — fast enough to read as motion, slow enough not to thrash on
/// older devices.
class DrumAnimation extends StatefulWidget {
  /// Creates a [DrumAnimation].
  const DrumAnimation({
    required this.count,
    required this.targetValues,
    required this.duration,
    required this.sides,
    this.random,
    super.key,
  });

  /// Number of slots in the grid.
  final int count;

  /// Final values to settle on once the animation completes.
  final List<int>? targetValues;

  /// Total length of the cycling phase.
  final Duration duration;

  /// Face count of the active dice — bounds the cycled random values.
  final int sides;

  /// Optional [Random] seed so tests get deterministic output.
  final Random? random;

  @override
  State<DrumAnimation> createState() => _DrumAnimationState();
}

class _DrumAnimationState extends State<DrumAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Random _rng = widget.random ?? Random();
  List<int>? _displayed;
  int _lastCycleMs = -1000;

  static const int _cycleEveryMs = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    _displayed = widget.targetValues;
  }

  @override
  void didUpdateWidget(covariant DrumAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetValues != null &&
        !listEquals(widget.targetValues, oldWidget.targetValues)) {
      _lastCycleMs = -1000;
      _controller
        ..duration = widget.duration
        ..forward(from: 0);
    } else if (widget.targetValues == null && oldWidget.targetValues != null) {
      _controller.stop();
      setState(() => _displayed = null);
    }
  }

  void _onTick() {
    final ms = _controller.lastElapsedDuration?.inMilliseconds ?? 0;
    if (ms - _lastCycleMs < _cycleEveryMs) return;
    _lastCycleMs = ms;
    setState(() {
      _displayed = List<int>.generate(
        widget.count,
        (_) => _rng.nextInt(widget.sides) + 1,
      );
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() => _displayed = widget.targetValues);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiceGrid(count: widget.count, values: _displayed);
  }
}

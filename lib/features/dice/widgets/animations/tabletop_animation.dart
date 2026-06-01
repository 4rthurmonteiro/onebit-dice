import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';

/// "Tabletop" strategy — slides the grid in from the top, bounces, cycles
/// random values, then settles with a small scale pulse.
///
/// Phases (fractions of [duration]):
///
/// - `0.00–0.25` slide-in: `Transform.translate(0, -slotSize → 0)`
/// - `0.25–0.50` bounce: two sin oscillations of ±2 px on Y
/// - `0.50–0.80` cycle: random face values every ~60 ms (per-die randomisation)
/// - `0.80–1.00` settle: scale `0.92 → 1.05 → 1.0`
///
/// All translates round to whole pixels to keep the 1-bit aesthetic crisp.
class TabletopAnimation extends StatefulWidget {
  /// Creates a [TabletopAnimation].
  const TabletopAnimation({
    required this.count,
    required this.targetValues,
    required this.duration,
    required this.sides,
    this.slotSize = 64,
    this.random,
    super.key,
  });

  /// Number of slots in the grid.
  final int count;

  /// Final values to settle on once the animation completes.
  final List<int>? targetValues;

  /// Total length of the slide+bounce+cycle+settle sequence.
  final Duration duration;

  /// Face count of the active dice — bounds the cycled random values.
  final int sides;

  /// Slot side length in logical pixels, used as the slide travel distance.
  final double slotSize;

  /// Optional [Random] seed so tests get deterministic output.
  final Random? random;

  @override
  State<TabletopAnimation> createState() => _TabletopAnimationState();
}

class _TabletopAnimationState extends State<TabletopAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Random _rng = widget.random ?? Random();
  List<int>? _displayed;
  int _lastCycleMs = -1000;

  static const int _cycleEveryMs = 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    _displayed = widget.targetValues;
  }

  @override
  void didUpdateWidget(covariant TabletopAnimation oldWidget) {
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
    final t = _controller.value;
    if (t < 0.50 || t >= 0.80) return;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final dy = _translateY(_controller.value, widget.slotSize);
        final scale = _scale(_controller.value);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            filterQuality: FilterQuality.none,
            child: DiceGrid(
              count: widget.count,
              values: _displayed,
              sides: widget.sides,
            ),
          ),
        );
      },
    );
  }
}

/// Vertical offset (in logical pixels, pixel-snapped) for the tabletop phase
/// progress [t] (0..1) given a slot side length of [slotSize].
@visibleForTesting
double tabletopTranslateY(double t, double slotSize) =>
    _translateY(t, slotSize);

/// Scale factor for the tabletop phase progress [t] (0..1).
@visibleForTesting
double tabletopScale(double t) => _scale(t);

double _translateY(double t, double slotSize) {
  if (t < 0.25) {
    final p = t / 0.25;
    return (-slotSize * (1 - p)).roundToDouble();
  }
  if (t < 0.50) {
    final p = (t - 0.25) / 0.25;
    return (sin(p * pi * 2) * 2).roundToDouble();
  }
  return 0;
}

double _scale(double t) {
  if (t < 0.80) return 1;
  final p = (t - 0.80) / 0.20;
  if (p < 0.5) {
    return 0.92 + (1.05 - 0.92) * (p / 0.5);
  }
  return 1.05 + (1.0 - 1.05) * ((p - 0.5) / 0.5);
}

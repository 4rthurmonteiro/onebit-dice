import 'dart:math';

final Random _defaultRng = Random.secure();

/// Rolls a single die with [sides] faces and returns a value in `1..sides`.
///
/// Pass [rng] to inject a deterministic source (e.g. `Random(seed)` in
/// tests). When omitted, a library-private `Random.secure()` is used.
int rollDie(int sides, {Random? rng}) {
  assert(sides > 0, 'sides must be > 0');
  return (rng ?? _defaultRng).nextInt(sides) + 1;
}

/// Rolls [count] dice with [sides] faces each and returns the results in
/// roll order.
///
/// Pass [rng] to inject a deterministic source (e.g. `Random(seed)` in
/// tests). When omitted, a library-private `Random.secure()` is used.
List<int> rollDice(int sides, int count, {Random? rng}) {
  assert(sides > 0, 'sides must be > 0');
  assert(count >= 1, 'count must be >= 1');
  return List<int>.generate(
    count,
    (_) => rollDie(sides, rng: rng),
    growable: false,
  );
}

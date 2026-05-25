/// Canonical set of dice supported by 1-Bit Dice.
///
/// Each member exposes the number of [sides] and a display [label] used
/// across the type selector (E08), the preset registry (E10), and the
/// `RollEntry` Hive adapter (E04).
///
/// AVISO: `RollEntry` e `CustomPreset` persistem `DiceType.index`.
/// Reordenar membros desta enum quebra a deserialização de dados já
/// gravados em disco — não reordenar sem coordenar uma migração.
enum DiceType {
  /// Four-sided die.
  d4(sides: 4, label: 'D4'),

  /// Six-sided die.
  d6(sides: 6, label: 'D6'),

  /// Eight-sided die.
  d8(sides: 8, label: 'D8'),

  /// Ten-sided die.
  d10(sides: 10, label: 'D10'),

  /// Twelve-sided die.
  d12(sides: 12, label: 'D12'),

  /// Twenty-sided die.
  d20(sides: 20, label: 'D20'),

  /// Hundred-sided die (percentile).
  d100(sides: 100, label: 'D100');

  const DiceType({required this.sides, required this.label});

  /// Number of faces on the die. Always strictly positive.
  final int sides;

  /// Human-readable label (e.g. `'D6'`).
  final String label;
}

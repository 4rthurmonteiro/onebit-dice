import 'package:flutter/material.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders the seven [DiceType] options as a wrap of tappable chips.
///
/// The chip matching [selectedType] is rendered inverted (ink fill, paper
/// label); the others use the regular paper fill with an ink border. Tapping
/// any chip — including the already-selected one — invokes [onChanged]; the
/// controller decides whether that is a no-op.
class TypeSelector extends StatelessWidget {
  /// Creates a [TypeSelector] for the given [selectedType].
  const TypeSelector({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  /// Currently selected [DiceType], used to invert one chip.
  final DiceType selectedType;

  /// Invoked with the tapped [DiceType].
  final ValueChanged<DiceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in DiceType.values)
          _TypeChip(
            type: type,
            isSelected: type == selectedType,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final DiceType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      label: type.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.ink : colors.paper,
            border: Border.all(color: colors.ink, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            type.label,
            style: AppTypography.display.copyWith(
              color: isSelected ? colors.paper : colors.ink,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

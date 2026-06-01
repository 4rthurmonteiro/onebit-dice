import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_badge.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_sheet.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

/// Compact `{label} ▾` field that opens [DiceTypeSheet] to pick a [DiceType].
///
/// Encapsulates the sheet so both call sites (the dice screen and the
/// create-preset sheet) stay a plain `selectedType` + `onChanged` pair: when
/// the sheet resolves to a type, that type is forwarded to [onChanged]; a
/// dismissal forwards nothing. The dropdown caret is a painted [PixelIcon]
/// triangle rather than a font glyph, so it can never render as `.notdef` in
/// the bitmap display font.
class TypeSelector extends StatelessWidget {
  /// Creates a [TypeSelector] reflecting [selectedType].
  const TypeSelector({
    required this.selectedType,
    required this.onChanged,
    super.key,
  });

  /// Currently selected [DiceType], shown in the field.
  final DiceType selectedType;

  /// Invoked with the picked [DiceType] when the sheet resolves to one.
  final ValueChanged<DiceType> onChanged;

  /// Downward caret silhouette painted via [PixelIcon].
  static const List<List<int>> _caret = [
    [0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0],
    [0, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0],
  ];

  Future<void> _open(BuildContext context) async {
    final picked = await DiceTypeSheet.show(context, selected: selectedType);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      button: true,
      label: context.l10n.diceTypeFieldLabel,
      value: selectedType.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.ink, width: 2),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DiceTypeBadge(type: selectedType, size: 20),
                const SizedBox(width: 8),
                Text(
                  selectedType.label,
                  style: AppTypography.display.copyWith(
                    color: colors.ink,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const PixelIcon(matrix: _caret, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// One row of the History list — renders a single [RollEntry] with timestamp,
/// notation, values and total.
///
/// Calling [RollEntry.toResult] can throw [StateError] when the persisted
/// entry is corrupted. We catch that here and render a `?` placeholder so a
/// single bad entry does not collapse the whole list. Every other field is
/// taken from the entry directly.
class HistoryEntryTile extends StatelessWidget {
  /// Creates a [HistoryEntryTile] for [entry].
  const HistoryEntryTile({required this.entry, super.key});

  /// The persisted roll to render.
  final RollEntry entry;

  /// Key tagging the corrupted-entry placeholder.
  @visibleForTesting
  static const Key corruptedKey = ValueKey('HistoryEntryTile.corrupted');

  /// Minimum tile height — keeps the tap target above the 44pt threshold.
  static const double minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final ml = MaterialLocalizations.of(context);
    final timestamp =
        '${ml.formatCompactDate(entry.timestamp)} '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(entry.timestamp))}';

    if (entry.diceTypeIndex < 0 ||
        entry.diceTypeIndex >= DiceType.values.length) {
      return _Frame(
        key: corruptedKey,
        colors: colors,
        topLeft: timestamp,
        topRight: '?',
        bottom: '? · [?]',
      );
    }
    final result = entry.toResult();
    final notation = '${result.diceCount}${result.diceType.label}';
    final values = result.values.join(', ');
    return _Frame(
      colors: colors,
      topLeft: timestamp,
      topRight: '${result.total}',
      bottom: '$notation · [$values]',
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.colors,
    required this.topLeft,
    required this.topRight,
    required this.bottom,
    super.key,
  });

  final OneBitColors colors;
  final String topLeft;
  final String topRight;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: HistoryEntryTile.minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topLeft,
                    style: AppTypography.display.copyWith(
                      color: colors.ink,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  topRight,
                  style: AppTypography.display.copyWith(
                    color: colors.ink,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(bottom, style: AppTypography.body.copyWith(color: colors.ink)),
          ],
        ),
      ),
    );
  }
}

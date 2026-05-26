import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders a `[−] [count] [+]` row used to choose how many dice to roll.
///
/// Hard-clamps to `1..10`: the `−` step is inert when [count] is `1`; the `+`
/// step is inert when [count] is `10`. Disabled steps render identical to
/// enabled ones — the 1-bit aesthetic has no grey state — only the callback
/// goes silent.
class QuantitySelector extends StatelessWidget {
  /// Creates a [QuantitySelector] reflecting [count].
  const QuantitySelector({
    required this.count,
    required this.onChanged,
    super.key,
  });

  /// The currently displayed count. Must already be in `1..10`.
  final int count;

  /// Invoked with the requested new count when a step is tapped while enabled.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StepButton(
          symbol: '−',
          enabled: count > 1,
          onTap: () => onChanged(count - 1),
          semanticLabel: l10n.diceCountDecreaseLabel,
        ),
        Text(
          '$count',
          style: AppTypography.display.copyWith(
            color: colors.ink,
            fontSize: 40,
          ),
        ),
        _StepButton(
          symbol: '+',
          enabled: count < 10,
          onTap: () => onChanged(count + 1),
          semanticLabel: l10n.diceCountIncreaseLabel,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.symbol,
    required this.enabled,
    required this.onTap,
    required this.semanticLabel,
  });

  final String symbol;
  final bool enabled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.paper,
            border: Border.all(color: colors.ink, width: 2),
          ),
          child: Text(
            symbol,
            style: AppTypography.display.copyWith(
              color: colors.ink,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}

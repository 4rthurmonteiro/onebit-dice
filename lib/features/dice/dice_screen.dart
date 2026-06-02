import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/widgets/dice_widget.dart';
import 'package:onebit_dice/features/dice/widgets/quantity_selector.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:provider/provider.dart';

/// Top-level dice rolling screen (Design C).
///
/// The dice canvas is the hero **and** the roll control: tapping anywhere on
/// it fires [DiceController.roll]. A thin control bar below it holds the
/// compact [TypeSelector] field and the [QuantitySelector] stepper. The
/// dedicated roll button is gone.
///
/// `onTap` is wired unconditionally — reentrancy is handled inside
/// [DiceController.roll] itself, which early-returns while a roll is in
/// flight. Gating `onTap` on [DiceController.isRolling] here would be unsafe:
/// `isRolling` flips back to `false` inside `roll`'s `finally` *without* a
/// `notifyListeners`, so a rebuild that landed while the roll was in flight
/// would leave `onTap` stuck `null` and the canvas permanently unresponsive
/// until an unrelated rebuild.
class DiceScreen extends StatelessWidget {
  /// Creates a [DiceScreen].
  const DiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiceController>();
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    final lastResult = controller.lastResult;
    final total = lastResult == null
        ? null
        : l10n.rollResultTotal(
            lastResult.values.fold(0, (sum, value) => sum + value),
          );

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: l10n.rollCanvasLabel,
                  value: total,
                  liveRegion: true,
                  explicitChildNodes: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.roll,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DiceWidget(
                            count: controller.count,
                            values: lastResult?.values,
                            sides: controller.selectedType.sides,
                          ),
                          if (!controller.hasRolled) ...[
                            const SizedBox(height: 16),
                            ExcludeSemantics(
                              child: Text(
                                l10n.rollTapHint,
                                style: AppTypography.display.copyWith(
                                  color: colors.ink,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const PixelDivider(padding: EdgeInsets.symmetric(vertical: 12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TypeSelector(
                    selectedType: controller.selectedType,
                    onChanged: controller.setType,
                  ),
                  QuantitySelector(
                    count: controller.count,
                    onChanged: controller.setCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

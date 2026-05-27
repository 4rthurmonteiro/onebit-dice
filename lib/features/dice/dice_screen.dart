import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/dice/widgets/dice_widget.dart';
import 'package:onebit_dice/features/dice/widgets/quantity_selector.dart';
import 'package:onebit_dice/features/dice/widgets/roll_button.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:provider/provider.dart';

/// Top-level dice rolling screen — composes the type selector, quantity
/// stepper, dice grid, and roll button around a [DiceController].
class DiceScreen extends StatelessWidget {
  /// Creates a [DiceScreen].
  const DiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DiceController>();
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Text(
                          context.l10n.appName.toUpperCase(),
                          style: AppTypography.display.copyWith(
                            color: colors.ink,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Center(
                            child: DiceWidget(
                              count: controller.count,
                              values: controller.lastResult?.values,
                              sides: controller.selectedType.sides,
                            ),
                          ),
                        ),
                        const PixelDivider(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        TypeSelector(
                          selectedType: controller.selectedType,
                          onChanged: controller.setType,
                        ),
                        const SizedBox(height: 12),
                        QuantitySelector(
                          count: controller.count,
                          onChanged: controller.setCount,
                        ),
                        const SizedBox(height: 16),
                        RollButton(onPressed: controller.roll),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

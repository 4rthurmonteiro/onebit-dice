import 'package:flutter/material.dart';
import 'package:onebit_dice/app_router.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/presets/preset_data.dart';
import 'package:onebit_dice/features/presets/widgets/add_preset_button.dart';
import 'package:onebit_dice/features/presets/widgets/create_preset_sheet.dart';
import 'package:onebit_dice/features/presets/widgets/preset_card.dart';
import 'package:onebit_dice/features/presets/widgets/preset_section.dart';
import 'package:provider/provider.dart';

/// Top-level Presets/Games screen.
///
/// Renders the seven built-in presets in a "Games" section and the user's
/// custom presets in a "My presets" section (streamed live from
/// [PresetsRepository.watch]). A "+ NEW" button below the custom section
/// opens [CreatePresetSheet] when the repository has room for more presets.
///
/// Tapping any card applies the preset's config to [DiceController] and
/// switches the navigation shell to the Roll tab — the user still has to
/// tap ROLL.
class PresetsScreen extends StatelessWidget {
  /// Creates a [PresetsScreen].
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final repository = context.read<PresetsRepository>();
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: StreamBuilder<List<CustomPreset>>(
          stream: repository.watch(),
          initialData: repository.snapshot(),
          builder: (context, snapshot) {
            final customs = snapshot.data ?? const <CustomPreset>[];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PresetSection(
                    title: context.l10n.presetsSectionBuiltIn,
                    children: [
                      for (final preset in builtInPresets)
                        PresetCard(
                          label: preset.localizedName(context),
                          notation: preset.notation,
                          onTap: () => _applyAndGo(
                            context,
                            diceType: preset.diceType,
                            count: preset.diceCount,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PresetSection(
                    title: context.l10n.presetsSectionCustom,
                    children: [
                      for (final preset in customs)
                        PresetCard(
                          label: preset.name,
                          notation:
                              '${preset.diceCount}${preset.diceType.label}',
                          onTap: () => _applyAndGo(
                            context,
                            diceType: preset.diceType,
                            count: preset.diceCount,
                          ),
                        ),
                    ],
                  ),
                  if (repository.canAddMore) ...[
                    const SizedBox(height: 16),
                    AddPresetButton(
                      onPressed: () => CreatePresetSheet.show(
                        context,
                        repository: repository,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _applyAndGo(
    BuildContext context, {
    required DiceType diceType,
    required int count,
  }) {
    context.read<DiceController>().applyConfig(
      diceType: diceType,
      count: count,
    );
    const DiceRoute().go(context);
  }
}

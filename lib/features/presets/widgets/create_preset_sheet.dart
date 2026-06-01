import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/custom_preset.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/features/dice/widgets/quantity_selector.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';
import 'package:provider/provider.dart';

/// Bottom-sheet body for creating a new [CustomPreset].
///
/// Validates the name (non-empty, ≤ [customPresetMaxNameLength]) and the
/// quantity (`1..10`). The Save button is disabled until the name is valid.
/// On save, calls [PresetsRepository.add] and pops the sheet.
class CreatePresetSheet extends StatefulWidget {
  /// Creates a [CreatePresetSheet].
  const CreatePresetSheet({required this.repository, super.key});

  /// Repository that will receive the new preset.
  final PresetsRepository repository;

  /// Convenience helper to show the sheet via [showModalBottomSheet].
  static Future<void> show(
    BuildContext context, {
    required PresetsRepository repository,
  }) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.paper,
      builder: (_) => CreatePresetSheet(repository: repository),
    );
  }

  @override
  State<CreatePresetSheet> createState() => _CreatePresetSheetState();
}

class _CreatePresetSheetState extends State<CreatePresetSheet> {
  late final TextEditingController _nameController;
  DiceType _diceType = DiceType.d6;
  int _count = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final analytics = context.read<AnalyticsService>();
    await widget.repository.add(
      name: _nameController.text.trim(),
      diceType: _diceType,
      diceCount: _count,
    );
    unawaited(
      analytics.logEvent(
        'preset_created',
        parameters: {'dice_type': _diceType.name, 'count': _count},
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MacWindow(
          title: l10n.presetsSheetTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.presetsSheetNameLabel,
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _nameController,
                maxLength: customPresetMaxNameLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(customPresetMaxNameLength),
                ],
                style: AppTypography.body.copyWith(color: colors.ink),
                cursorColor: colors.ink,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: colors.ink, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: colors.ink, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.presetsSheetDiceLabel,
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              TypeSelector(
                selectedType: _diceType,
                onChanged: (t) => setState(() => _diceType = t),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.presetsSheetCountLabel,
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              QuantitySelector(
                count: _count,
                onChanged: (v) => setState(() => _count = v),
              ),
              const SizedBox(height: 16),
              if (_isValid)
                MacButton(
                  label: l10n.presetsSheetSave,
                  onPressed: _save,
                  expand: true,
                )
              else
                _DisabledSaveButton(label: l10n.presetsSheetSave),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inert visual twin of [MacButton], rendered when the form is invalid so the
/// save action can't fire. Kept identical to the active button on purpose —
/// the 1-bit aesthetic has no grey/disabled state.
class _DisabledSaveButton extends StatelessWidget {
  const _DisabledSaveButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.ink, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: AppTypography.display.copyWith(color: colors.ink),
      ),
    );
  }
}

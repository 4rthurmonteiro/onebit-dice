import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

/// "+ NEW" button shown below the custom-presets section.
///
/// A thin wrapper around [MacButton] that hard-codes the label to
/// `l10n.presetsAddNew`, so the presets screen can target it by type in
/// widget tests.
class AddPresetButton extends StatelessWidget {
  /// Creates an [AddPresetButton] that calls [onPressed] on tap.
  const AddPresetButton({required this.onPressed, super.key});

  /// Tap handler — opens the create-preset sheet.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MacButton(label: context.l10n.presetsAddNew, onPressed: onPressed);
  }
}

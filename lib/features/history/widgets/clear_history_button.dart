import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

/// Bottom-of-screen "CLEAR" action for the History screen.
///
/// Opens a 1-bit confirmation [AlertDialog]; calls [onConfirm] only when the
/// user accepts. Cancelling (or dismissing via barrier) is a no-op.
class ClearHistoryButton extends StatelessWidget {
  /// Creates a [ClearHistoryButton] that invokes [onConfirm] on confirmation.
  const ClearHistoryButton({required this.onConfirm, super.key});

  /// Called once when the user confirms the clear action.
  final VoidCallback onConfirm;

  /// Key tagging the confirm action button inside the dialog.
  @visibleForTesting
  static const Key confirmKey = ValueKey('ClearHistoryButton.confirm');

  /// Key tagging the cancel action button inside the dialog.
  @visibleForTesting
  static const Key cancelKey = ValueKey('ClearHistoryButton.cancel');

  @override
  Widget build(BuildContext context) {
    return MacButton(
      label: context.l10n.actionClear,
      expand: true,
      onPressed: () => _confirm(context),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const _ConfirmDialog(),
    );
    if (confirmed ?? false) onConfirm();
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: colors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.ink, width: 2),
      ),
      title: Text(
        l10n.historyClearConfirmTitle,
        style: AppTypography.display.copyWith(color: colors.ink, fontSize: 18),
      ),
      content: Text(
        l10n.historyClearConfirmBody,
        style: AppTypography.body.copyWith(color: colors.ink),
      ),
      actions: [
        TextButton(
          key: ClearHistoryButton.cancelKey,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.actionCancel,
            style: AppTypography.display.copyWith(
              color: colors.ink,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          key: ClearHistoryButton.confirmKey,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.actionConfirm,
            style: AppTypography.display.copyWith(
              color: colors.ink,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

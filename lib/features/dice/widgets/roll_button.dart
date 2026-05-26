import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

/// Full-width "ROLL" CTA at the bottom of the dice screen.
///
/// A thin wrapper around [MacButton] that hard-codes the label to
/// `l10n.actionRoll` and `expand: true`. Exists as a named widget so the
/// dice screen tests can target it with `find.byType(RollButton)`, free of
/// locale.
class RollButton extends StatelessWidget {
  /// Creates a [RollButton] that calls [onPressed] when tapped.
  const RollButton({required this.onPressed, super.key});

  /// Tap handler, forwarded straight to the underlying [MacButton].
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MacButton(
      label: context.l10n.actionRoll,
      onPressed: onPressed,
      expand: true,
    );
  }
}

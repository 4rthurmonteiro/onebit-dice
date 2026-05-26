import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';

/// Placeholder screen for the Settings tab — replaced in EPIC 11.
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen] stub.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: Center(child: Text(context.l10n.commonComingSoon)),
    );
  }
}

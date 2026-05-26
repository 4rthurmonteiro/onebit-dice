import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';

/// Placeholder screen for the Presets / Games tab — replaced in EPIC 10.
class PresetsScreen extends StatelessWidget {
  /// Creates a [PresetsScreen] stub.
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: Text(context.l10n.presetsTitle)),
      body: Center(child: Text(context.l10n.commonComingSoon)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';

/// Placeholder screen for the History tab — replaced by the real list in E09b.
class HistoryScreen extends StatelessWidget {
  /// Creates a [HistoryScreen] stub.
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: Text(context.l10n.historyTitle)),
      body: Center(child: Text(context.l10n.commonComingSoon)),
    );
  }
}

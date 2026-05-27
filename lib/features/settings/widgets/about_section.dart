import 'package:flutter/material.dart';
import 'package:onebit_dice/core/app_info.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';

/// Renders the app name, version, and studio in plain text. All values come
/// from the hard-coded constants in `lib/core/app_info.dart`.
class AboutSection extends StatelessWidget {
  /// Creates an [AboutSection].
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final l10n = context.l10n;
    final body = AppTypography.body.copyWith(color: colors.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.appName, style: body),
        Text('${l10n.settingsAboutVersion} $kAppVersion', style: body),
        Text(kStudioName, style: body),
      ],
    );
  }
}

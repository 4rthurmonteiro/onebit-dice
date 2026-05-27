import 'package:flutter/material.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/features/settings/widgets/about_section.dart';
import 'package:onebit_dice/features/settings/widgets/animation_section.dart';
import 'package:onebit_dice/features/settings/widgets/language_picker.dart';
import 'package:onebit_dice/features/settings/widgets/palette_selector.dart';
import 'package:onebit_dice/features/settings/widgets/settings_section.dart';
import 'package:onebit_dice/features/settings/widgets/toggle_tile.dart';
import 'package:provider/provider.dart';

/// The Settings tab. Composes the five sections (Appearance, Feedback,
/// Animation, Language, About) from existing controllers and the new
/// `AnimationSettingsController`.
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final audio = context.watch<AudioController>();
    final haptic = context.watch<HapticController>();
    return Scaffold(
      backgroundColor: Theme.of(context).extension<OneBitColors>()!.paper,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SettingsSection(
              title: l10n.settingsSectionAppearance,
              child: const PaletteSelector(),
            ),
            SettingsSection(
              title: l10n.settingsSectionFeedback,
              child: Column(
                children: [
                  ToggleTile(
                    label: l10n.settingsToggleSound,
                    value: audio.soundEnabled,
                    onChanged: (v) => context
                        .read<AudioController>()
                        .setSoundEnabled(value: v),
                  ),
                  ToggleTile(
                    label: l10n.settingsToggleHaptic,
                    value: haptic.hapticEnabled,
                    onChanged: (v) => context
                        .read<HapticController>()
                        .setHapticEnabled(value: v),
                  ),
                ],
              ),
            ),
            SettingsSection(
              title: l10n.settingsSectionAnimation,
              child: const AnimationSection(),
            ),
            SettingsSection(
              title: l10n.settingsSectionLanguage,
              child: const LanguagePicker(),
            ),
            SettingsSection(
              title: l10n.settingsSectionAbout,
              child: const AboutSection(),
            ),
          ],
        ),
      ),
    );
  }
}

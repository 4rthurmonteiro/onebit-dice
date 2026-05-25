// coverage:ignore-file
//
// Manual smoke-test scaffold for the E02 design system. Not a production
// screen — it shows every base widget and a palette picker so the dev can
// confirm the theme swap works on a real simulator. Slated for deletion in
// E09 (Navigation) when the real app shell ships.

import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:provider/provider.dart';

/// Manual smoke-test preview for the 1-Bit Dice design system.
class DesignSystemPreview extends StatelessWidget {
  /// Creates the design system preview.
  const DesignSystemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                '1-BIT DICE',
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 48,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              MacWindow(
                title: 'Design System',
                onClose: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MacButton(label: 'Rolar', onPressed: () {}, expand: true),
                    const PixelDivider(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    Text(
                      'Body text in VT323',
                      style: AppTypography.body.copyWith(color: colors.ink),
                    ),
                    Text(
                      'micro text in PressStart2P',
                      style: AppTypography.micro.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Palettes',
                style: AppTypography.display.copyWith(
                  color: colors.ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in PaletteId.values) _PaletteChip(id: id),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({required this.id});

  final PaletteId id;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OneBitColors>()!;
    final palette = Palette.of(id);
    return GestureDetector(
      onTap: () => context.read<ThemeProvider>().setPalette(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border.all(color: colors.ink, width: 2),
        ),
        child: Text(
          palette.name,
          style: AppTypography.body.copyWith(color: colors.ink),
        ),
      ),
    );
  }
}

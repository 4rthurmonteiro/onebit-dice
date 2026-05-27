import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onebit_dice/app_router.dart';
import 'package:onebit_dice/core/app_info.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/app_typography.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

/// The two-stage splash entry point — sits at `/` and navigates to
/// `/dice` after [splashDuration].
///
/// Colors are hard-coded (`#FFFFFF` / `#000000`) so the splash matches the
/// native splash even before the user's persisted palette is loaded.
class SplashScreen extends StatefulWidget {
  /// Creates a [SplashScreen].
  const SplashScreen({super.key});

  /// How long the Flutter-side splash is visible before routing to `/dice`.
  @visibleForTesting
  static const Duration splashDuration = Duration(milliseconds: 1500);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  static const Color _ink = Color(0xFF000000);
  static const Color _paper = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.splashDuration, _navigate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    const DiceRoute().go(context);
  }

  @override
  Widget build(BuildContext context) {
    // Pin the palette to Mac Classic for the splash so `PixelIcon` (which
    // reads `OneBitColors`) paints the d6 in the same ink/paper as the rest
    // of the splash — without the splash itself reading any palette state.
    return Theme(
      data: buildThemeData(Palette.of(PaletteId.macClassic)),
      child: Scaffold(
        backgroundColor: _paper,
        body: SafeArea(
          child: Column(
            children: [
              const _MacTitleBar(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '1-BIT\nDICE',
                      textAlign: TextAlign.center,
                      style: AppTypography.micro.copyWith(
                        color: _ink,
                        fontSize: 56,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(width: 180, child: PixelDivider()),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.appTagline.toUpperCase(),
                      style: AppTypography.body.copyWith(
                        color: _ink,
                        fontSize: 22,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const PixelIcon(matrix: splashDieMatrix, size: 144),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  children: [
                    Text(
                      '$kAppVersion · $kStudioName',
                      style: AppTypography.micro.copyWith(
                        color: _ink,
                        fontSize: 8,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.splashUniverseTagline,
                      style: AppTypography.micro.copyWith(
                        color: const Color(0xFF888888),
                        fontSize: 6,
                        letterSpacing: 0.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacTitleBar extends StatelessWidget {
  const _MacTitleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide()),
      ),
      child: Text(
        '1-BIT DICE',
        style: AppTypography.micro.copyWith(
          color: const Color(0xFF000000),
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// 12×12 d6 pixel matrix used by the splash centerpiece.
@visibleForTesting
const List<List<int>> splashDieMatrix = [
  [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
];

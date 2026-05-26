import 'package:flutter/material.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/_dev/design_system_preview.dart';
import 'package:provider/provider.dart';

/// Root widget of the 1-Bit Dice application.
class App extends StatelessWidget {
  /// Creates the root [App] widget.
  const App({
    required this.audioController,
    required this.hapticController,
    super.key,
  });

  /// Owns the audio engine, persisted sound flag, and lifecycle observer.
  final AudioController audioController;

  /// Owns the persisted haptic flag and the platform pulse.
  final HapticController hapticController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioController>.value(value: audioController),
        ChangeNotifierProvider<HapticController>.value(value: hapticController),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().current;
    return MaterialApp(
      title: '1-Bit Dice',
      theme: buildThemeData(palette),
      home: const DesignSystemPreview(),
    );
  }
}

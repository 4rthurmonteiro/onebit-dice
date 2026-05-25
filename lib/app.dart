import 'package:flutter/material.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/_dev/design_system_preview.dart';
import 'package:provider/provider.dart';

/// Root widget of the 1-Bit Dice application.
class App extends StatelessWidget {
  /// Creates the root [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
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

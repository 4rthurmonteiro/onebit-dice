import 'package:flutter/material.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/_dev/design_system_preview.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Resolves the locale Flutter should render at when the user hasn't
/// chosen a manual override.
///
/// Prefers an entry from [supported] that matches the device locale on
/// both language and country; falls back to a language-only match; then
/// to English when nothing matches — this is the project's chosen global
/// fallback (the registry order would otherwise default to PT-BR).
@visibleForTesting
Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  if (deviceLocale == null) return const Locale('en');

  Locale? languageOnlyMatch;
  for (final locale in supported) {
    if (locale.languageCode != deviceLocale.languageCode) continue;
    if (locale.countryCode == deviceLocale.countryCode) return locale;
    languageOnlyMatch ??= locale;
  }
  return languageOnlyMatch ?? const Locale('en');
}

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
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
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
    final locale = context.watch<LocaleController>().override;
    return MaterialApp(
      title: '1-Bit Dice',
      theme: buildThemeData(palette),
      locale: locale,
      supportedLocales: [for (final entry in supportedLocales) entry.locale],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveLocale,
      home: const DesignSystemPreview(),
    );
  }
}

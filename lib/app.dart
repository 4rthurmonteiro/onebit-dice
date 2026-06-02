import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:onebit_dice/app_router.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/storage/last_dice_config_preference.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/dice/dice_controller.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
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
    required this.animationSettingsController,
    required this.analyticsService,
    required this.historyRepository,
    required this.presetsRepository,
    required this.lastDiceConfigPreference,
    required this.palettePreference,
    required this.localePreference,
    super.key,
  });

  /// Owns the audio engine, persisted sound flag, and lifecycle observer.
  final AudioController audioController;

  /// Owns the persisted haptic flag and the platform pulse.
  final HapticController hapticController;

  /// Owns the persisted dice-animation style and speed preferences.
  final AnimationSettingsController animationSettingsController;

  /// Records analytics events and crash reports.
  final AnalyticsService analyticsService;

  /// Persistent log of every roll the user has made.
  final HistoryRepository historyRepository;

  /// Persistent store of the user's custom presets.
  final PresetsRepository presetsRepository;

  /// Persists the user's last dice configuration across launches.
  final LastDiceConfigPreference lastDiceConfigPreference;

  /// Persists the user's chosen palette across launches.
  final PalettePreference palettePreference;

  /// Persists the user's manual locale override across launches.
  final LocalePreference localePreference;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AnalyticsService>.value(value: analyticsService),
        ChangeNotifierProvider<AudioController>.value(value: audioController),
        ChangeNotifierProvider<HapticController>.value(value: hapticController),
        ChangeNotifierProvider<AnimationSettingsController>.value(
          value: animationSettingsController,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(
            analytics: context.read<AnalyticsService>(),
            preference: palettePreference,
          ),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (context) => LocaleController(
            analytics: context.read<AnalyticsService>(),
            preference: localePreference,
          ),
        ),
        Provider<HistoryRepository>.value(value: historyRepository),
        Provider<PresetsRepository>.value(value: presetsRepository),
        Provider<LastDiceConfigPreference>.value(
          value: lastDiceConfigPreference,
        ),
        ChangeNotifierProvider<DiceController>(
          create: (context) => DiceController(
            history: context.read<HistoryRepository>(),
            audio: context.read<AudioController>(),
            haptic: context.read<HapticController>(),
            lastDiceConfig: context.read<LastDiceConfigPreference>(),
            analytics: context.read<AnalyticsService>(),
          ),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // The router owns the navigation stack and must outlive every
  // `notifyListeners` of `ThemeProvider` / `LocaleController` — rebuilding it
  // here in `initState` (instead of inside `build`) is what keeps the tab
  // selection from resetting when the user changes palette or language.
  late final GoRouter _router = buildAppRouter();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().current;
    final locale = context.watch<LocaleController>().override;
    return MaterialApp.router(
      title: '1-Bit Dice',
      theme: buildThemeData(palette),
      locale: locale,
      supportedLocales: [for (final entry in supportedLocales) entry.locale],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveLocale,
      routerConfig: _router,
    );
  }
}

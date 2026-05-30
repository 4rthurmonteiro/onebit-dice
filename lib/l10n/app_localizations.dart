import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// App name — kept untranslated across locales
  ///
  /// In pt_BR, this message translates to:
  /// **'1-Bit Dice'**
  String get appName;

  /// Primary CTA on the Roll screen
  ///
  /// In pt_BR, this message translates to:
  /// **'ROLAR'**
  String get actionRoll;

  /// Generic clear action (e.g. clear history)
  ///
  /// In pt_BR, this message translates to:
  /// **'LIMPAR'**
  String get actionClear;

  /// Confirm action in dialogs
  ///
  /// In pt_BR, this message translates to:
  /// **'CONFIRMAR'**
  String get actionConfirm;

  /// Cancel action in dialogs
  ///
  /// In pt_BR, this message translates to:
  /// **'CANCELAR'**
  String get actionCancel;

  /// Close action in dialogs / sheets
  ///
  /// In pt_BR, this message translates to:
  /// **'FECHAR'**
  String get actionClose;

  /// Bottom tab label for the Roll screen
  ///
  /// In pt_BR, this message translates to:
  /// **'ROLAR'**
  String get tabRoll;

  /// Bottom tab label for the History screen
  ///
  /// In pt_BR, this message translates to:
  /// **'HISTÓRICO'**
  String get tabHistory;

  /// Bottom tab label for the Presets/Games screen
  ///
  /// In pt_BR, this message translates to:
  /// **'JOGOS'**
  String get tabPresets;

  /// Bottom tab label for the Settings screen
  ///
  /// In pt_BR, this message translates to:
  /// **'AJUSTES'**
  String get tabSettings;

  /// Status text shown while a roll is in progress
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{Rolando 1 dado} other{Rolando {count} dados}}'**
  String rollingNDice(int count);

  /// Final total of a roll
  ///
  /// In pt_BR, this message translates to:
  /// **'Total: {total}'**
  String rollResultTotal(int total);

  /// Hint overlaid on the dice canvas before the first roll of the session, telling the user to tap to roll
  ///
  /// In pt_BR, this message translates to:
  /// **'▸ TOQUE PARA ROLAR ◂'**
  String get rollTapHint;

  /// Accessibility label for the tappable dice canvas that triggers a roll
  ///
  /// In pt_BR, this message translates to:
  /// **'Rolar dados'**
  String get rollCanvasLabel;

  /// Title of the bottom sheet that lists the dice types to choose from
  ///
  /// In pt_BR, this message translates to:
  /// **'ESCOLHER DADO'**
  String get diceTypeSheetTitle;

  /// Accessibility label for the compact dice-type field that opens the type sheet
  ///
  /// In pt_BR, this message translates to:
  /// **'Tipo de dado'**
  String get diceTypeFieldLabel;

  /// Sublabel under each dice-type row stating how many sides the die has
  ///
  /// In pt_BR, this message translates to:
  /// **'{count, plural, one{1 LADO} other{{count} LADOS}}'**
  String diceTypeSidesLabel(int count);

  /// Empty state for the History screen
  ///
  /// In pt_BR, this message translates to:
  /// **'Nenhuma rolagem ainda.'**
  String get historyEmpty;

  /// Title of the confirm dialog when clearing history
  ///
  /// In pt_BR, this message translates to:
  /// **'Limpar histórico?'**
  String get historyClearConfirmTitle;

  /// Body of the confirm dialog when clearing history
  ///
  /// In pt_BR, this message translates to:
  /// **'Isso apaga todas as rolagens registradas.'**
  String get historyClearConfirmBody;

  /// Section header for the 7 built-in dice presets
  ///
  /// In pt_BR, this message translates to:
  /// **'Jogos'**
  String get presetsSectionBuiltIn;

  /// Section header for user-created presets
  ///
  /// In pt_BR, this message translates to:
  /// **'Meus presets'**
  String get presetsSectionCustom;

  /// Label for the button that opens the create-preset sheet
  ///
  /// In pt_BR, this message translates to:
  /// **'+ NOVO'**
  String get presetsAddNew;

  /// Title of the create-preset bottom sheet
  ///
  /// In pt_BR, this message translates to:
  /// **'Novo preset'**
  String get presetsSheetTitle;

  /// Field label for the preset name input
  ///
  /// In pt_BR, this message translates to:
  /// **'Nome'**
  String get presetsSheetNameLabel;

  /// Field label for the dice-type chip group
  ///
  /// In pt_BR, this message translates to:
  /// **'Dado'**
  String get presetsSheetDiceLabel;

  /// Field label for the dice-count stepper
  ///
  /// In pt_BR, this message translates to:
  /// **'Quantidade'**
  String get presetsSheetCountLabel;

  /// Save action in the create-preset sheet
  ///
  /// In pt_BR, this message translates to:
  /// **'Salvar'**
  String get presetsSheetSave;

  /// Built-in preset name — Ludo (1×D6)
  ///
  /// In pt_BR, this message translates to:
  /// **'Ludo'**
  String get presetBuiltInLudo;

  /// Built-in preset name — Banco Imobiliário (2×D6)
  ///
  /// In pt_BR, this message translates to:
  /// **'Banco Imobiliário'**
  String get presetBuiltInBancoImobiliario;

  /// Built-in preset name — War (3×D6)
  ///
  /// In pt_BR, this message translates to:
  /// **'War'**
  String get presetBuiltInWar;

  /// Built-in preset name — Yahtzee (5×D6)
  ///
  /// In pt_BR, this message translates to:
  /// **'Yahtzee'**
  String get presetBuiltInYahtzee;

  /// Built-in preset name — D&D Ataque (1×D20)
  ///
  /// In pt_BR, this message translates to:
  /// **'D&D Ataque'**
  String get presetBuiltInDndAtaque;

  /// Built-in preset name — Magic Vida (1×D20)
  ///
  /// In pt_BR, this message translates to:
  /// **'Magic Vida'**
  String get presetBuiltInMagicVida;

  /// Built-in preset name — Percentil (1×D100)
  ///
  /// In pt_BR, this message translates to:
  /// **'Percentil'**
  String get presetBuiltInPercentil;

  /// Settings section: appearance
  ///
  /// In pt_BR, this message translates to:
  /// **'Aparência'**
  String get settingsSectionAppearance;

  /// Settings section: audio + haptic feedback
  ///
  /// In pt_BR, this message translates to:
  /// **'Feedback'**
  String get settingsSectionFeedback;

  /// Settings section: dice animation
  ///
  /// In pt_BR, this message translates to:
  /// **'Animação'**
  String get settingsSectionAnimation;

  /// Settings section: language picker
  ///
  /// In pt_BR, this message translates to:
  /// **'Idioma'**
  String get settingsSectionLanguage;

  /// Settings section: about / credits / version
  ///
  /// In pt_BR, this message translates to:
  /// **'Sobre'**
  String get settingsSectionAbout;

  /// Option label that clears the manual locale override
  ///
  /// In pt_BR, this message translates to:
  /// **'Seguir sistema'**
  String get settingsLanguageFollowSystem;

  /// Semantic label for the + button in the dice quantity stepper
  ///
  /// In pt_BR, this message translates to:
  /// **'Aumentar quantidade de dados'**
  String get diceCountIncreaseLabel;

  /// Semantic label for the − button in the dice quantity stepper
  ///
  /// In pt_BR, this message translates to:
  /// **'Diminuir quantidade de dados'**
  String get diceCountDecreaseLabel;

  /// Tagline shown under the wordmark on the splash screen
  ///
  /// In pt_BR, this message translates to:
  /// **'Dado para todo jogo'**
  String get appTagline;

  /// Placeholder body text for screens not yet implemented
  ///
  /// In pt_BR, this message translates to:
  /// **'EM BREVE'**
  String get commonComingSoon;

  /// Italic microcopy in the splash footer linking to the COCU universe
  ///
  /// In pt_BR, this message translates to:
  /// **'parte do universo call of old chico'**
  String get splashUniverseTagline;

  /// AppBar title for the History tab stub
  ///
  /// In pt_BR, this message translates to:
  /// **'Histórico'**
  String get historyTitle;

  /// AppBar title for the Presets/Games tab stub
  ///
  /// In pt_BR, this message translates to:
  /// **'Jogos'**
  String get presetsTitle;

  /// AppBar title for the Settings tab stub
  ///
  /// In pt_BR, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// Toggle label for SFX in Settings > Feedback
  ///
  /// In pt_BR, this message translates to:
  /// **'Som'**
  String get settingsToggleSound;

  /// Toggle label for haptic feedback in Settings > Feedback
  ///
  /// In pt_BR, this message translates to:
  /// **'Vibração'**
  String get settingsToggleHaptic;

  /// Group label for animation style radios in Settings > Animation
  ///
  /// In pt_BR, this message translates to:
  /// **'Estilo'**
  String get settingsAnimationStyleLabel;

  /// Animation style — result appears instantly
  ///
  /// In pt_BR, this message translates to:
  /// **'Rápida'**
  String get settingsAnimationStyleFast;

  /// Animation style — short drum-roll-style shake
  ///
  /// In pt_BR, this message translates to:
  /// **'Tambor'**
  String get settingsAnimationStyleDrum;

  /// Animation style — long tabletop-style roll
  ///
  /// In pt_BR, this message translates to:
  /// **'Tabuleiro'**
  String get settingsAnimationStyleTabletop;

  /// Group label for animation speed radios in Settings > Animation
  ///
  /// In pt_BR, this message translates to:
  /// **'Velocidade'**
  String get settingsAnimationSpeedLabel;

  /// Animation speed — short duration
  ///
  /// In pt_BR, this message translates to:
  /// **'Rápido'**
  String get settingsAnimationSpeedFast;

  /// Animation speed — medium duration
  ///
  /// In pt_BR, this message translates to:
  /// **'Médio'**
  String get settingsAnimationSpeedMedium;

  /// Animation speed — long duration
  ///
  /// In pt_BR, this message translates to:
  /// **'Longo'**
  String get settingsAnimationSpeedSlow;

  /// Label preceding the app version in Settings > About
  ///
  /// In pt_BR, this message translates to:
  /// **'Versão'**
  String get settingsAboutVersion;

  /// Palette name — Mac Classic (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Mac Classic'**
  String get paletteMacClassic;

  /// Palette name — Mac Beige (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Mac Beige'**
  String get paletteMacBeige;

  /// Palette name — Game Boy DMG (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Game Boy DMG'**
  String get paletteGameBoy;

  /// Palette name — Commodore 64 (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Commodore 64'**
  String get paletteC64;

  /// Palette name — ZX Spectrum (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'ZX Spectrum'**
  String get paletteZxSpectrum;

  /// Palette name — Apple II Green (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Apple II Green'**
  String get paletteAppleIIGreen;

  /// Palette name — Apple //e Amber (kept untranslated)
  ///
  /// In pt_BR, this message translates to:
  /// **'Apple //e Amber'**
  String get paletteAppleIIeAmber;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

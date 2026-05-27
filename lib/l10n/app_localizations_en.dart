// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'ROLL';

  @override
  String get actionClear => 'CLEAR';

  @override
  String get actionConfirm => 'CONFIRM';

  @override
  String get actionCancel => 'CANCEL';

  @override
  String get actionClose => 'CLOSE';

  @override
  String get tabRoll => 'ROLL';

  @override
  String get tabHistory => 'HISTORY';

  @override
  String get tabPresets => 'GAMES';

  @override
  String get tabSettings => 'SETTINGS';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rolling $count dice',
      one: 'Rolling 1 die',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get historyEmpty => 'No rolls yet.';

  @override
  String get historyClearConfirmTitle => 'Clear history?';

  @override
  String get historyClearConfirmBody => 'This deletes every recorded roll.';

  @override
  String get presetsSectionBuiltIn => 'Games';

  @override
  String get presetsSectionCustom => 'My presets';

  @override
  String get presetsAddNew => '+ NEW';

  @override
  String get presetsSheetTitle => 'New preset';

  @override
  String get presetsSheetNameLabel => 'Name';

  @override
  String get presetsSheetDiceLabel => 'Die';

  @override
  String get presetsSheetCountLabel => 'Count';

  @override
  String get presetsSheetSave => 'Save';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Attack';

  @override
  String get presetBuiltInMagicVida => 'Magic Life';

  @override
  String get presetBuiltInPercentil => 'Percentile';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAnimation => 'Animation';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguageFollowSystem => 'Follow system';

  @override
  String get diceCountIncreaseLabel => 'Increase dice count';

  @override
  String get diceCountDecreaseLabel => 'Decrease dice count';

  @override
  String get appTagline => 'Dice for every game';

  @override
  String get commonComingSoon => 'COMING SOON';

  @override
  String get splashUniverseTagline => 'part of the call of old chico universe';

  @override
  String get historyTitle => 'History';

  @override
  String get presetsTitle => 'Games';

  @override
  String get settingsTitle => 'Settings';
}

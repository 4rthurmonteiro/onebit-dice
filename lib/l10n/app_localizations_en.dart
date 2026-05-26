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
  String get presetsSectionClassic => 'Classic Games';

  @override
  String get presetsSectionCustom => 'Custom';

  @override
  String get presetLudo => 'Ludo';

  @override
  String get presetWar => 'War';

  @override
  String get presetYahtzee => 'Yahtzee';

  @override
  String get presetCraps => 'Craps';

  @override
  String get presetBunco => 'Bunco';

  @override
  String get presetFarkle => 'Farkle';

  @override
  String get presetLiarsDice => 'Liar\'s Dice';

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
}

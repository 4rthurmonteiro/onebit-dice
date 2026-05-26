// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'WÜRFELN';

  @override
  String get actionClear => 'LÖSCHEN';

  @override
  String get actionConfirm => 'BESTÄTIGEN';

  @override
  String get actionCancel => 'ABBRECHEN';

  @override
  String get actionClose => 'SCHLIESSEN';

  @override
  String get tabRoll => 'WÜRFELN';

  @override
  String get tabHistory => 'VERLAUF';

  @override
  String get tabPresets => 'SPIELE';

  @override
  String get tabSettings => 'EINSTELLUNGEN';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfel werden geworfen',
      one: '1 Würfel wird geworfen',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Gesamt: $total';
  }

  @override
  String get historyEmpty => 'Noch keine Würfe.';

  @override
  String get historyClearConfirmTitle => 'Verlauf löschen?';

  @override
  String get historyClearConfirmBody =>
      'Dies löscht alle aufgezeichneten Würfe.';

  @override
  String get presetsSectionClassic => 'Klassische Spiele';

  @override
  String get presetsSectionCustom => 'Benutzerdefiniert';

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
  String get settingsSectionAppearance => 'Darstellung';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAnimation => 'Animation';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsSectionAbout => 'Über';

  @override
  String get settingsLanguageFollowSystem => 'System folgen';

  @override
  String get diceCountIncreaseLabel => 'Würfelanzahl erhöhen';

  @override
  String get diceCountDecreaseLabel => 'Würfelanzahl verringern';
}

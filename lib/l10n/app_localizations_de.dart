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
  String get presetsSectionBuiltIn => 'Spiele';

  @override
  String get presetsSectionCustom => 'Meine Presets';

  @override
  String get presetsAddNew => '+ NEU';

  @override
  String get presetsSheetTitle => 'Neues Preset';

  @override
  String get presetsSheetNameLabel => 'Name';

  @override
  String get presetsSheetDiceLabel => 'Würfel';

  @override
  String get presetsSheetCountLabel => 'Anzahl';

  @override
  String get presetsSheetSave => 'Speichern';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Attacke';

  @override
  String get presetBuiltInMagicVida => 'Magic Leben';

  @override
  String get presetBuiltInPercentil => 'Perzentil';

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

  @override
  String get appTagline => 'Würfel für jedes Spiel';

  @override
  String get commonComingSoon => 'DEMNÄCHST';

  @override
  String get splashUniverseTagline => 'teil des call of old chico universums';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get presetsTitle => 'Spiele';

  @override
  String get settingsTitle => 'Einstellungen';
}

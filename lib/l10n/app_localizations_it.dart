// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'LANCIA';

  @override
  String get actionClear => 'CANCELLA';

  @override
  String get actionConfirm => 'CONFERMA';

  @override
  String get actionCancel => 'ANNULLA';

  @override
  String get actionClose => 'CHIUDI';

  @override
  String get tabRoll => 'LANCIA';

  @override
  String get tabHistory => 'CRONOLOGIA';

  @override
  String get tabPresets => 'GIOCHI';

  @override
  String get tabSettings => 'IMPOSTAZIONI';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lancio di $count dadi',
      one: 'Lancio di 1 dado',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Totale: $total';
  }

  @override
  String get historyEmpty => 'Nessun lancio ancora.';

  @override
  String get historyClearConfirmTitle => 'Cancellare la cronologia?';

  @override
  String get historyClearConfirmBody =>
      'Questo elimina tutti i lanci registrati.';

  @override
  String get presetsSectionClassic => 'Giochi Classici';

  @override
  String get presetsSectionCustom => 'Personalizzati';

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
  String get settingsSectionAppearance => 'Aspetto';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAnimation => 'Animazione';

  @override
  String get settingsSectionLanguage => 'Lingua';

  @override
  String get settingsSectionAbout => 'Informazioni';

  @override
  String get settingsLanguageFollowSystem => 'Segui sistema';
}

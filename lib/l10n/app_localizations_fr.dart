// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'LANCER';

  @override
  String get actionClear => 'EFFACER';

  @override
  String get actionConfirm => 'CONFIRMER';

  @override
  String get actionCancel => 'ANNULER';

  @override
  String get actionClose => 'FERMER';

  @override
  String get tabRoll => 'LANCER';

  @override
  String get tabHistory => 'HISTORIQUE';

  @override
  String get tabPresets => 'JEUX';

  @override
  String get tabSettings => 'RÉGLAGES';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lancement de $count dés',
      one: 'Lancement de 1 dé',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Total : $total';
  }

  @override
  String get historyEmpty => 'Aucun lancer pour le moment.';

  @override
  String get historyClearConfirmTitle => 'Effacer l\'historique ?';

  @override
  String get historyClearConfirmBody =>
      'Cela supprime tous les lancers enregistrés.';

  @override
  String get presetsSectionClassic => 'Jeux Classiques';

  @override
  String get presetsSectionCustom => 'Personnalisés';

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
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionFeedback => 'Retour';

  @override
  String get settingsSectionAnimation => 'Animation';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsLanguageFollowSystem => 'Suivre le système';

  @override
  String get diceCountIncreaseLabel => 'Augmenter le nombre de dés';

  @override
  String get diceCountDecreaseLabel => 'Diminuer le nombre de dés';
}

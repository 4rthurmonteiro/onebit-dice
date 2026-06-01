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
  String get rollTapHint => '▸ TOUCHEZ POUR LANCER ◂';

  @override
  String get rollCanvasLabel => 'Lancer les dés';

  @override
  String get diceTypeSheetTitle => 'CHOISIR LE DÉ';

  @override
  String get diceTypeFieldLabel => 'Type de dé';

  @override
  String diceTypeSidesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count FACES',
      one: '1 FACE',
    );
    return '$_temp0';
  }

  @override
  String get historyEmpty => 'Aucun lancer pour le moment.';

  @override
  String get historyClearConfirmTitle => 'Effacer l\'historique ?';

  @override
  String get historyClearConfirmBody =>
      'Cela supprime tous les lancers enregistrés.';

  @override
  String get presetsSectionBuiltIn => 'Jeux';

  @override
  String get presetsSectionCustom => 'Mes presets';

  @override
  String get presetsAddNew => '+ NOUVEAU';

  @override
  String get presetsSheetTitle => 'Nouveau preset';

  @override
  String get presetsSheetNameLabel => 'Nom';

  @override
  String get presetsSheetDiceLabel => 'Dé';

  @override
  String get presetsSheetCountLabel => 'Quantité';

  @override
  String get presetsSheetSave => 'Enregistrer';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Attaque';

  @override
  String get presetBuiltInMagicVida => 'Magic Vie';

  @override
  String get presetBuiltInPercentil => 'Percentile';

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

  @override
  String get appTagline => 'Des dés pour chaque jeu';

  @override
  String get commonComingSoon => 'BIENTÔT';

  @override
  String get splashUniverseTagline => 'partie de l\'univers call of old chico';

  @override
  String get historyTitle => 'Historique';

  @override
  String get presetsTitle => 'Jeux';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsToggleSound => 'Son';

  @override
  String get settingsToggleHaptic => 'Vibration';

  @override
  String get settingsAnimationStyleLabel => 'Style';

  @override
  String get settingsAnimationStyleFast => 'Rapide';

  @override
  String get settingsAnimationStyleDrum => 'Tambour';

  @override
  String get settingsAnimationStyleTabletop => 'Plateau';

  @override
  String get settingsAnimationSpeedLabel => 'Vitesse';

  @override
  String get settingsAnimationSpeedFast => 'Rapide';

  @override
  String get settingsAnimationSpeedMedium => 'Moyen';

  @override
  String get settingsAnimationSpeedSlow => 'Lent';

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String get paletteMacClassic => 'Mac Classic';

  @override
  String get paletteMacBeige => 'Mac Beige';

  @override
  String get paletteGameBoy => 'Game Boy DMG';

  @override
  String get paletteC64 => 'Commodore 64';

  @override
  String get paletteZxSpectrum => 'ZX Spectrum';

  @override
  String get paletteAppleIIGreen => 'Apple II Green';

  @override
  String get paletteAppleIIeAmber => 'Apple //e Amber';
}

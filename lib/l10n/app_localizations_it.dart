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
  String get rollTapHint => '▸ TOCCA PER LANCIARE ◂';

  @override
  String get rollCanvasLabel => 'Lancia i dadi';

  @override
  String get diceTypeSheetTitle => 'SCEGLI DADO';

  @override
  String get diceTypeFieldLabel => 'Tipo di dado';

  @override
  String diceTypeSidesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count LATI',
      one: '1 LATO',
    );
    return '$_temp0';
  }

  @override
  String get historyEmpty => 'Nessun lancio ancora.';

  @override
  String get historyClearConfirmTitle => 'Cancellare la cronologia?';

  @override
  String get historyClearConfirmBody =>
      'Questo elimina tutti i lanci registrati.';

  @override
  String get presetsSectionBuiltIn => 'Giochi';

  @override
  String get presetsSectionCustom => 'I miei preset';

  @override
  String get presetsAddNew => '+ NUOVO';

  @override
  String get presetsSheetTitle => 'Nuovo preset';

  @override
  String get presetsSheetNameLabel => 'Nome';

  @override
  String get presetsSheetDiceLabel => 'Dado';

  @override
  String get presetsSheetCountLabel => 'Quantità';

  @override
  String get presetsSheetSave => 'Salva';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Attacco';

  @override
  String get presetBuiltInMagicVida => 'Magic Vita';

  @override
  String get presetBuiltInPercentil => 'Percentile';

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

  @override
  String get diceCountIncreaseLabel => 'Aumenta numero di dadi';

  @override
  String get diceCountDecreaseLabel => 'Diminuisci numero di dadi';

  @override
  String get appTagline => 'Dadi per ogni gioco';

  @override
  String get commonComingSoon => 'IN ARRIVO';

  @override
  String get splashUniverseTagline => 'parte dell\'universo call of old chico';

  @override
  String get historyTitle => 'Cronologia';

  @override
  String get presetsTitle => 'Giochi';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsToggleSound => 'Suono';

  @override
  String get settingsToggleHaptic => 'Vibrazione';

  @override
  String get settingsAnimationStyleLabel => 'Stile';

  @override
  String get settingsAnimationStyleFast => 'Veloce';

  @override
  String get settingsAnimationStyleDrum => 'Tamburo';

  @override
  String get settingsAnimationStyleTabletop => 'Tavolo';

  @override
  String get settingsAnimationSpeedLabel => 'Velocità';

  @override
  String get settingsAnimationSpeedFast => 'Veloce';

  @override
  String get settingsAnimationSpeedMedium => 'Medio';

  @override
  String get settingsAnimationSpeedSlow => 'Lento';

  @override
  String get settingsAboutVersion => 'Versione';

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

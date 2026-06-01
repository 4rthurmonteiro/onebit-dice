// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'TIRAR';

  @override
  String get actionClear => 'BORRAR';

  @override
  String get actionConfirm => 'CONFIRMAR';

  @override
  String get actionCancel => 'CANCELAR';

  @override
  String get actionClose => 'CERRAR';

  @override
  String get tabRoll => 'TIRAR';

  @override
  String get tabHistory => 'HISTORIAL';

  @override
  String get tabPresets => 'JUEGOS';

  @override
  String get tabSettings => 'AJUSTES';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tirando $count dados',
      one: 'Tirando 1 dado',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get rollTapHint => '▸ TOCA PARA TIRAR ◂';

  @override
  String get rollCanvasLabel => 'Tirar dados';

  @override
  String get diceTypeSheetTitle => 'ELEGIR DADO';

  @override
  String get diceTypeFieldLabel => 'Tipo de dado';

  @override
  String diceTypeSidesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count LADOS',
      one: '1 LADO',
    );
    return '$_temp0';
  }

  @override
  String get historyEmpty => 'Aún no hay tiradas.';

  @override
  String get historyClearConfirmTitle => '¿Borrar historial?';

  @override
  String get historyClearConfirmBody =>
      'Esto elimina todas las tiradas registradas.';

  @override
  String get presetsSectionBuiltIn => 'Juegos';

  @override
  String get presetsSectionCustom => 'Mis presets';

  @override
  String get presetsAddNew => '+ NUEVO';

  @override
  String get presetsSheetTitle => 'Nuevo preset';

  @override
  String get presetsSheetNameLabel => 'Nombre';

  @override
  String get presetsSheetDiceLabel => 'Dado';

  @override
  String get presetsSheetCountLabel => 'Cantidad';

  @override
  String get presetsSheetSave => 'Guardar';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Ataque';

  @override
  String get presetBuiltInMagicVida => 'Magic Vida';

  @override
  String get presetBuiltInPercentil => 'Percentil';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionFeedback => 'Comentarios';

  @override
  String get settingsSectionAnimation => 'Animación';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsLanguageFollowSystem => 'Seguir sistema';

  @override
  String get diceCountIncreaseLabel => 'Aumentar cantidad de dados';

  @override
  String get diceCountDecreaseLabel => 'Disminuir cantidad de dados';

  @override
  String get appTagline => 'Dados para cada juego';

  @override
  String get commonComingSoon => 'PRÓXIMAMENTE';

  @override
  String get splashUniverseTagline => 'parte del universo call of old chico';

  @override
  String get historyTitle => 'Historial';

  @override
  String get presetsTitle => 'Juegos';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsToggleSound => 'Sonido';

  @override
  String get settingsToggleHaptic => 'Vibración';

  @override
  String get settingsAnimationStyleLabel => 'Estilo';

  @override
  String get settingsAnimationStyleFast => 'Rápida';

  @override
  String get settingsAnimationStyleDrum => 'Tambor';

  @override
  String get settingsAnimationStyleTabletop => 'Mesa';

  @override
  String get settingsAnimationSpeedLabel => 'Velocidad';

  @override
  String get settingsAnimationSpeedFast => 'Rápido';

  @override
  String get settingsAnimationSpeedMedium => 'Medio';

  @override
  String get settingsAnimationSpeedSlow => 'Lento';

  @override
  String get settingsAboutVersion => 'Versión';

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

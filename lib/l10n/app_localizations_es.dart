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
  String get historyEmpty => 'Aún no hay tiradas.';

  @override
  String get historyClearConfirmTitle => '¿Borrar historial?';

  @override
  String get historyClearConfirmBody =>
      'Esto elimina todas las tiradas registradas.';

  @override
  String get presetsSectionClassic => 'Juegos Clásicos';

  @override
  String get presetsSectionCustom => 'Personalizados';

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

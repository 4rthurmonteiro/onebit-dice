// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'ROLAR';

  @override
  String get actionClear => 'LIMPAR';

  @override
  String get actionConfirm => 'CONFIRMAR';

  @override
  String get actionCancel => 'CANCELAR';

  @override
  String get actionClose => 'FECHAR';

  @override
  String get tabRoll => 'ROLAR';

  @override
  String get tabHistory => 'HISTÓRICO';

  @override
  String get tabPresets => 'JOGOS';

  @override
  String get tabSettings => 'AJUSTES';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rolando $count dados',
      one: 'Rolando 1 dado',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get historyEmpty => 'Nenhuma rolagem ainda.';

  @override
  String get historyClearConfirmTitle => 'Limpar histórico?';

  @override
  String get historyClearConfirmBody =>
      'Isso apaga todas as rolagens registradas.';

  @override
  String get presetsSectionClassic => 'Jogos Clássicos';

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
  String get settingsSectionAppearance => 'Aparência';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAnimation => 'Animação';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsLanguageFollowSystem => 'Seguir sistema';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'ROLAR';

  @override
  String get actionClear => 'LIMPAR';

  @override
  String get actionConfirm => 'CONFIRMAR';

  @override
  String get actionCancel => 'CANCELAR';

  @override
  String get actionClose => 'FECHAR';

  @override
  String get tabRoll => 'ROLAR';

  @override
  String get tabHistory => 'HISTÓRICO';

  @override
  String get tabPresets => 'JOGOS';

  @override
  String get tabSettings => 'AJUSTES';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rolando $count dados',
      one: 'Rolando 1 dado',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get historyEmpty => 'Nenhuma rolagem ainda.';

  @override
  String get historyClearConfirmTitle => 'Limpar histórico?';

  @override
  String get historyClearConfirmBody =>
      'Isso apaga todas as rolagens registradas.';

  @override
  String get presetsSectionClassic => 'Jogos Clássicos';

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
  String get settingsSectionAppearance => 'Aparência';

  @override
  String get settingsSectionFeedback => 'Feedback';

  @override
  String get settingsSectionAnimation => 'Animação';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsLanguageFollowSystem => 'Seguir sistema';
}

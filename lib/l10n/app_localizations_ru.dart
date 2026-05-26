// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'БРОСИТЬ';

  @override
  String get actionClear => 'ОЧИСТИТЬ';

  @override
  String get actionConfirm => 'ПОДТВЕРДИТЬ';

  @override
  String get actionCancel => 'ОТМЕНА';

  @override
  String get actionClose => 'ЗАКРЫТЬ';

  @override
  String get tabRoll => 'БРОСИТЬ';

  @override
  String get tabHistory => 'ИСТОРИЯ';

  @override
  String get tabPresets => 'ИГРЫ';

  @override
  String get tabSettings => 'НАСТРОЙКИ';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Бросаем $count кубиков',
      many: 'Бросаем $count кубиков',
      few: 'Бросаем $count кубика',
      one: 'Бросаем 1 кубик',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return 'Итого: $total';
  }

  @override
  String get historyEmpty => 'Бросков пока нет.';

  @override
  String get historyClearConfirmTitle => 'Очистить историю?';

  @override
  String get historyClearConfirmBody => 'Это удалит все записанные броски.';

  @override
  String get presetsSectionClassic => 'Классические игры';

  @override
  String get presetsSectionCustom => 'Пользовательские';

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
  String get settingsSectionAppearance => 'Оформление';

  @override
  String get settingsSectionFeedback => 'Отклик';

  @override
  String get settingsSectionAnimation => 'Анимация';

  @override
  String get settingsSectionLanguage => 'Язык';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String get settingsLanguageFollowSystem => 'Как в системе';
}

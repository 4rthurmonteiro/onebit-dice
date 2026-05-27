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
  String get presetsSectionBuiltIn => 'Игры';

  @override
  String get presetsSectionCustom => 'Мои пресеты';

  @override
  String get presetsAddNew => '+ НОВЫЙ';

  @override
  String get presetsSheetTitle => 'Новый пресет';

  @override
  String get presetsSheetNameLabel => 'Имя';

  @override
  String get presetsSheetDiceLabel => 'Кубик';

  @override
  String get presetsSheetCountLabel => 'Количество';

  @override
  String get presetsSheetSave => 'Сохранить';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D Атака';

  @override
  String get presetBuiltInMagicVida => 'Magic Жизнь';

  @override
  String get presetBuiltInPercentil => 'Процентиль';

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

  @override
  String get diceCountIncreaseLabel => 'Увеличить количество кубиков';

  @override
  String get diceCountDecreaseLabel => 'Уменьшить количество кубиков';

  @override
  String get appTagline => 'Кубики для любой игры';

  @override
  String get commonComingSoon => 'СКОРО';

  @override
  String get splashUniverseTagline => 'часть вселенной call of old chico';

  @override
  String get historyTitle => 'История';

  @override
  String get presetsTitle => 'Игры';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsToggleSound => 'Звук';

  @override
  String get settingsToggleHaptic => 'Вибрация';

  @override
  String get settingsAnimationStyleLabel => 'Стиль';

  @override
  String get settingsAnimationStyleFast => 'Быстрая';

  @override
  String get settingsAnimationStyleDrum => 'Барабан';

  @override
  String get settingsAnimationStyleTabletop => 'Стол';

  @override
  String get settingsAnimationSpeedLabel => 'Скорость';

  @override
  String get settingsAnimationSpeedFast => 'Быстро';

  @override
  String get settingsAnimationSpeedMedium => 'Средне';

  @override
  String get settingsAnimationSpeedSlow => 'Медленно';

  @override
  String get settingsAboutVersion => 'Версия';

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

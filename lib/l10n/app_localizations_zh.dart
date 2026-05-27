// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => '投掷';

  @override
  String get actionClear => '清除';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClose => '关闭';

  @override
  String get tabRoll => '投掷';

  @override
  String get tabHistory => '历史';

  @override
  String get tabPresets => '游戏';

  @override
  String get tabSettings => '设置';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在投掷 $count 颗骰子',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return '总计：$total';
  }

  @override
  String get historyEmpty => '暂无投掷记录。';

  @override
  String get historyClearConfirmTitle => '清除历史？';

  @override
  String get historyClearConfirmBody => '这将删除所有已记录的投掷。';

  @override
  String get presetsSectionClassic => '经典游戏';

  @override
  String get presetsSectionCustom => '自定义';

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
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionFeedback => '反馈';

  @override
  String get settingsSectionAnimation => '动画';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsLanguageFollowSystem => '跟随系统';

  @override
  String get diceCountIncreaseLabel => '增加骰子数量';

  @override
  String get diceCountDecreaseLabel => '减少骰子数量';

  @override
  String get appTagline => '每个游戏都有骰子';

  @override
  String get commonComingSoon => '即将推出';

  @override
  String get splashUniverseTagline => 'call of old chico 宇宙的一部分';

  @override
  String get historyTitle => '历史';

  @override
  String get presetsTitle => '游戏';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsToggleSound => '声音';

  @override
  String get settingsToggleHaptic => '振动';

  @override
  String get settingsAnimationStyleLabel => '风格';

  @override
  String get settingsAnimationStyleFast => '快速';

  @override
  String get settingsAnimationStyleDrum => '鼓动';

  @override
  String get settingsAnimationStyleTabletop => '桌面';

  @override
  String get settingsAnimationSpeedLabel => '速度';

  @override
  String get settingsAnimationSpeedFast => '快';

  @override
  String get settingsAnimationSpeedMedium => '中';

  @override
  String get settingsAnimationSpeedSlow => '慢';

  @override
  String get settingsAboutVersion => '版本';

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

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => '投掷';

  @override
  String get actionClear => '清除';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClose => '关闭';

  @override
  String get tabRoll => '投掷';

  @override
  String get tabHistory => '历史';

  @override
  String get tabPresets => '游戏';

  @override
  String get tabSettings => '设置';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '正在投掷 $count 颗骰子',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return '总计：$total';
  }

  @override
  String get historyEmpty => '暂无投掷记录。';

  @override
  String get historyClearConfirmTitle => '清除历史？';

  @override
  String get historyClearConfirmBody => '这将删除所有已记录的投掷。';

  @override
  String get presetsSectionClassic => '经典游戏';

  @override
  String get presetsSectionCustom => '自定义';

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
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionFeedback => '反馈';

  @override
  String get settingsSectionAnimation => '动画';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsLanguageFollowSystem => '跟随系统';

  @override
  String get diceCountIncreaseLabel => '增加骰子数量';

  @override
  String get diceCountDecreaseLabel => '减少骰子数量';

  @override
  String get appTagline => '每个游戏都有骰子';

  @override
  String get commonComingSoon => '即将推出';

  @override
  String get splashUniverseTagline => 'call of old chico 宇宙的一部分';

  @override
  String get historyTitle => '历史';

  @override
  String get presetsTitle => '游戏';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsToggleSound => '声音';

  @override
  String get settingsToggleHaptic => '振动';

  @override
  String get settingsAnimationStyleLabel => '风格';

  @override
  String get settingsAnimationStyleFast => '快速';

  @override
  String get settingsAnimationStyleDrum => '鼓动';

  @override
  String get settingsAnimationStyleTabletop => '桌面';

  @override
  String get settingsAnimationSpeedLabel => '速度';

  @override
  String get settingsAnimationSpeedFast => '快';

  @override
  String get settingsAnimationSpeedMedium => '中';

  @override
  String get settingsAnimationSpeedSlow => '慢';

  @override
  String get settingsAboutVersion => '版本';

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

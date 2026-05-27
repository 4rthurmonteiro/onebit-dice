// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => 'ふる';

  @override
  String get actionClear => 'クリア';

  @override
  String get actionConfirm => 'けってい';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionClose => 'とじる';

  @override
  String get tabRoll => 'ふる';

  @override
  String get tabHistory => 'りれき';

  @override
  String get tabPresets => 'ゲーム';

  @override
  String get tabSettings => 'せってい';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のダイスをふっています',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return '合計: $total';
  }

  @override
  String get historyEmpty => 'まだダイスをふっていません。';

  @override
  String get historyClearConfirmTitle => 'りれきを消しますか？';

  @override
  String get historyClearConfirmBody => '記録されたすべてのダイスのりれきが削除されます。';

  @override
  String get presetsSectionBuiltIn => 'ゲーム';

  @override
  String get presetsSectionCustom => 'マイプリセット';

  @override
  String get presetsAddNew => '+ 新規';

  @override
  String get presetsSheetTitle => '新しいプリセット';

  @override
  String get presetsSheetNameLabel => '名前';

  @override
  String get presetsSheetDiceLabel => 'ダイス';

  @override
  String get presetsSheetCountLabel => '数';

  @override
  String get presetsSheetSave => '保存';

  @override
  String get presetBuiltInLudo => 'Ludo';

  @override
  String get presetBuiltInBancoImobiliario => 'Banco Imobiliário';

  @override
  String get presetBuiltInWar => 'War';

  @override
  String get presetBuiltInYahtzee => 'Yahtzee';

  @override
  String get presetBuiltInDndAtaque => 'D&D アタック';

  @override
  String get presetBuiltInMagicVida => 'Magic ライフ';

  @override
  String get presetBuiltInPercentil => 'パーセンタイル';

  @override
  String get settingsSectionAppearance => '外観';

  @override
  String get settingsSectionFeedback => 'フィードバック';

  @override
  String get settingsSectionAnimation => 'アニメーション';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsSectionAbout => 'アプリについて';

  @override
  String get settingsLanguageFollowSystem => 'システムに従う';

  @override
  String get diceCountIncreaseLabel => 'サイコロを増やす';

  @override
  String get diceCountDecreaseLabel => 'サイコロを減らす';

  @override
  String get appTagline => 'あらゆるゲームにサイコロを';

  @override
  String get commonComingSoon => '近日公開';

  @override
  String get splashUniverseTagline => 'call of old chico ユニバースの一部';

  @override
  String get historyTitle => '履歴';

  @override
  String get presetsTitle => 'ゲーム';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsToggleSound => 'サウンド';

  @override
  String get settingsToggleHaptic => '振動';

  @override
  String get settingsAnimationStyleLabel => 'スタイル';

  @override
  String get settingsAnimationStyleFast => '高速';

  @override
  String get settingsAnimationStyleDrum => 'ドラム';

  @override
  String get settingsAnimationStyleTabletop => 'テーブル';

  @override
  String get settingsAnimationSpeedLabel => '速度';

  @override
  String get settingsAnimationSpeedFast => '速い';

  @override
  String get settingsAnimationSpeedMedium => '中';

  @override
  String get settingsAnimationSpeedSlow => '遅い';

  @override
  String get settingsAboutVersion => 'バージョン';

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

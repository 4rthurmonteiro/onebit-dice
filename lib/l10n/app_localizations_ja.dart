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
  String get presetsSectionClassic => 'クラシックゲーム';

  @override
  String get presetsSectionCustom => 'カスタム';

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
}

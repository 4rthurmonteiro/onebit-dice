// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '1-Bit Dice';

  @override
  String get actionRoll => '굴리기';

  @override
  String get actionClear => '지우기';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionCancel => '취소';

  @override
  String get actionClose => '닫기';

  @override
  String get tabRoll => '굴리기';

  @override
  String get tabHistory => '기록';

  @override
  String get tabPresets => '게임';

  @override
  String get tabSettings => '설정';

  @override
  String rollingNDice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '주사위 $count개를 굴리는 중',
    );
    return '$_temp0';
  }

  @override
  String rollResultTotal(int total) {
    return '합계: $total';
  }

  @override
  String get historyEmpty => '아직 굴린 기록이 없습니다.';

  @override
  String get historyClearConfirmTitle => '기록을 지울까요?';

  @override
  String get historyClearConfirmBody => '기록된 모든 굴림이 삭제됩니다.';

  @override
  String get presetsSectionClassic => '클래식 게임';

  @override
  String get presetsSectionCustom => '사용자 지정';

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
  String get settingsSectionAppearance => '테마';

  @override
  String get settingsSectionFeedback => '피드백';

  @override
  String get settingsSectionAnimation => '애니메이션';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsLanguageFollowSystem => '시스템 설정 따르기';

  @override
  String get diceCountIncreaseLabel => '주사위 개수 늘리기';

  @override
  String get diceCountDecreaseLabel => '주사위 개수 줄이기';

  @override
  String get appTagline => '모든 게임을 위한 주사위';

  @override
  String get commonComingSoon => '출시 예정';

  @override
  String get splashUniverseTagline => 'call of old chico 세계관의 일부';

  @override
  String get historyTitle => '기록';

  @override
  String get presetsTitle => '게임';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsToggleSound => '소리';

  @override
  String get settingsToggleHaptic => '진동';

  @override
  String get settingsAnimationStyleLabel => '스타일';

  @override
  String get settingsAnimationStyleFast => '빠름';

  @override
  String get settingsAnimationStyleDrum => '드럼';

  @override
  String get settingsAnimationStyleTabletop => '테이블';

  @override
  String get settingsAnimationSpeedLabel => '속도';

  @override
  String get settingsAnimationSpeedFast => '빠름';

  @override
  String get settingsAnimationSpeedMedium => '중간';

  @override
  String get settingsAnimationSpeedSlow => '느림';

  @override
  String get settingsAboutVersion => '버전';

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

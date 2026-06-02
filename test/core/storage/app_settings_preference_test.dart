import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesAppSettingsPreference', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<SharedPreferencesAppSettingsPreference> buildPref() async {
      final prefs = await SharedPreferences.getInstance();
      return SharedPreferencesAppSettingsPreference(prefs);
    }

    test('every field reads null when nothing has been written', () async {
      final pref = await buildPref();
      expect(pref.readSoundEnabled(), isNull);
      expect(pref.readHapticEnabled(), isNull);
      expect(pref.readAnimationStyle(), isNull);
      expect(pref.readAnimationSpeed(), isNull);
    });

    test('round-trip preserves bool fields', () async {
      final pref = await buildPref();

      await pref.writeSoundEnabled(value: true);
      await pref.writeHapticEnabled(value: false);

      expect(pref.readSoundEnabled(), isTrue);
      expect(pref.readHapticEnabled(), isFalse);
    });

    test('round-trip preserves animation enums', () async {
      final pref = await buildPref();

      await pref.writeAnimationStyle(AnimationStyle.tabletop);
      await pref.writeAnimationSpeed(AnimationSpeed.medium);

      expect(pref.readAnimationStyle(), AnimationStyle.tabletop);
      expect(pref.readAnimationSpeed(), AnimationSpeed.medium);
    });

    test(
      'readAnimationStyle returns null when stored index is invalid',
      () async {
        SharedPreferences.setMockInitialValues({'animation_style': 999});
        final pref = await buildPref();
        expect(pref.readAnimationStyle(), isNull);
      },
    );

    test(
      'readAnimationStyle returns null when stored index is negative',
      () async {
        SharedPreferences.setMockInitialValues({'animation_style': -1});
        final pref = await buildPref();
        expect(pref.readAnimationStyle(), isNull);
      },
    );

    test(
      'readAnimationSpeed returns null when stored index is invalid',
      () async {
        SharedPreferences.setMockInitialValues({'animation_speed': 7});
        final pref = await buildPref();
        expect(pref.readAnimationSpeed(), isNull);
      },
    );

    test(
      'readAnimationSpeed returns null when stored index is negative',
      () async {
        SharedPreferences.setMockInitialValues({'animation_speed': -1});
        final pref = await buildPref();
        expect(pref.readAnimationSpeed(), isNull);
      },
    );
  });
}

import 'package:flutter/widgets.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final appSettings = SharedPreferencesAppSettingsPreference(prefs);
  final audioController = AudioController(preference: appSettings);
  await audioController.init();
  final hapticController = HapticController(preference: appSettings);
  runApp(
    App(audioController: audioController, hapticController: hapticController),
  );
}

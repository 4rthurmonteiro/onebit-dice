import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/analytics/firebase_analytics_service.dart';
import 'package:onebit_dice/core/audio/audio_controller.dart';
import 'package:onebit_dice/core/haptic/haptic_controller.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  final analyticsService = FirebaseAnalyticsService(
    analytics: FirebaseAnalytics.instance,
    crashlytics: crashlytics,
  );

  final prefs = await SharedPreferences.getInstance();
  final appSettings = SharedPreferencesAppSettingsPreference(prefs);
  final audioController = AudioController(preference: appSettings);
  await audioController.init();
  final hapticController = HapticController(preference: appSettings);
  final animationSettingsController = AnimationSettingsController(
    preference: appSettings,
  );
  runApp(
    App(
      audioController: audioController,
      hapticController: hapticController,
      animationSettingsController: animationSettingsController,
      analyticsService: analyticsService,
    ),
  );
}

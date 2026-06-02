import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';

/// Function-shaped seam over `HapticFeedback.mediumImpact` so the
/// controller is testable without binding the platform channel.
typedef HapticTrigger = Future<void> Function();

/// Default [HapticTrigger] used in production.
// coverage:ignore-start
Future<void> defaultHapticTrigger() => HapticFeedback.mediumImpact();
// coverage:ignore-end

/// Orchestrates the persisted `hapticEnabled` flag and the haptic trigger.
///
/// Symmetrical to `AudioController` but simpler: no async init, no lifecycle
/// observer (haptics are instantaneous). Defaults to `true` when
/// [AppSettingsPreference.readHapticEnabled] returns `null`.
class HapticController extends ChangeNotifier {
  /// Creates a [HapticController] backed by [preference]. Pass [trigger] to
  /// inject a fake in tests; production code can rely on
  /// [defaultHapticTrigger].
  HapticController({
    required AppSettingsPreference preference,
    required this._analytics,
    HapticTrigger? trigger,
  }) : _preference = preference,
       _trigger = trigger ?? defaultHapticTrigger,
       _hapticEnabled = preference.readHapticEnabled() ?? true;

  final AppSettingsPreference _preference;
  final HapticTrigger _trigger;
  final AnalyticsService _analytics;
  bool _hapticEnabled;

  /// Whether haptic pulses should fire. Driven by the persisted preference
  /// and the settings toggle.
  bool get hapticEnabled => _hapticEnabled;

  /// Fires a medium-impact pulse when haptic is enabled. No-op otherwise.
  /// Fire-and-forget — never awaits the platform channel.
  void trigger() {
    if (!_hapticEnabled) return;
    unawaited(_trigger());
  }

  /// Updates the flag, notifies listeners immediately, then persists.
  Future<void> setHapticEnabled({required bool value}) async {
    if (_hapticEnabled == value) return;
    _hapticEnabled = value;
    notifyListeners();
    unawaited(
      _analytics.logEvent('haptic_toggled', parameters: {'enabled': value}),
    );
    await _preference.writeHapticEnabled(value: value);
  }
}

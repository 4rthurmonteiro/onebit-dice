import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';

/// Owns the user's persisted dice animation [style] and [speed].
///
/// Mirrors `AudioController` / `HapticController`: hydrates from
/// [AppSettingsPreference] on construction, applies sensible defaults
/// (`AnimationStyle.drum`, `AnimationSpeed.medium`) when nothing is stored,
/// and persists writes asynchronously after notifying listeners.
class AnimationSettingsController extends ChangeNotifier {
  /// Creates an [AnimationSettingsController] backed by [preference].
  AnimationSettingsController({
    required AppSettingsPreference preference,
    this._analytics = const NoOpAnalyticsService(),
  }) : _preference = preference,
       _style = preference.readAnimationStyle() ?? AnimationStyle.drum,
       _speed = preference.readAnimationSpeed() ?? AnimationSpeed.medium;

  final AppSettingsPreference _preference;
  final AnalyticsService _analytics;
  AnimationStyle _style;
  AnimationSpeed _speed;

  /// Active animation style.
  AnimationStyle get style => _style;

  /// Active animation speed.
  AnimationSpeed get speed => _speed;

  /// Updates the style and notifies listeners immediately, then persists.
  /// No-op (no notify, no write) when [value] already matches.
  Future<void> setStyle(AnimationStyle value) async {
    if (_style == value) return;
    _style = value;
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'animation_style_changed',
        parameters: {'style': value.name},
      ),
    );
    await _preference.writeAnimationStyle(value);
  }

  /// Updates the speed and notifies listeners immediately, then persists.
  /// No-op (no notify, no write) when [value] already matches.
  Future<void> setSpeed(AnimationSpeed value) async {
    if (_speed == value) return;
    _speed = value;
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'animation_speed_changed',
        parameters: {'speed': value.name},
      ),
    );
    await _preference.writeAnimationSpeed(value);
  }
}

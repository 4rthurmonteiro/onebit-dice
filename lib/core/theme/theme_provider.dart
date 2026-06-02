import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';

/// Owns the active [Palette] and notifies listeners whenever the user (or
/// startup logic) swaps it.
///
/// Distributed via `ChangeNotifierProvider<ThemeProvider>` at the root of the
/// app (see `lib/app.dart`). Consumers read it with `context.watch` and
/// rebuild the `MaterialApp` theme on change.
class ThemeProvider extends ChangeNotifier {
  /// Creates a [ThemeProvider] backed by [preference]. The initial palette
  /// comes from `preference.read()` when present; otherwise
  /// [PaletteId.macClassic].
  ThemeProvider({
    required this._analytics,
    required PalettePreference preference,
  }) : _preference = preference,
       _current = Palette.of(preference.read() ?? PaletteId.macClassic);

  final PalettePreference _preference;
  final AnalyticsService _analytics;
  Palette _current;

  /// The active palette.
  Palette get current => _current;

  /// Switches the active palette to [id]. No-op (no notify, no write) when
  /// [id] already matches the current palette.
  Future<void> setPalette(PaletteId id) async {
    if (_current.id == id) return;
    _current = Palette.of(id);
    notifyListeners();
    unawaited(
      _analytics.logEvent(
        'palette_changed',
        parameters: {'palette_id': id.name},
      ),
    );
    await _preference.write(id);
  }
}

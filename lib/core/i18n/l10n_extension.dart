import 'package:flutter/widgets.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)` with a clear failure mode.
///
/// `AppLocalizations.of` only returns `null` when the [AppLocalizations]
/// delegate is missing from the surrounding `MaterialApp` — a wiring bug,
/// not a runtime condition. Surface that as a descriptive [StateError]
/// rather than a generic null-check failure.
extension L10nX on BuildContext {
  /// The [AppLocalizations] instance for the surrounding locale.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ??
      (throw StateError(
        'AppLocalizations missing from context. Did you forget to add '
        'AppLocalizations.localizationsDelegates to MaterialApp?',
      ));
}

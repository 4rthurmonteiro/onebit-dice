import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/presets/widgets/add_preset_button.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

Widget _harness(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('AddPresetButton', () {
    testWidgets('renders the localized "+ NEW" label in EN', (tester) async {
      await tester.pumpWidget(_harness(AddPresetButton(onPressed: () {})));
      expect(find.text('+ NEW'), findsOneWidget);
    });

    testWidgets('renders the localized "+ NOVO" label in pt-BR', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          AddPresetButton(onPressed: () {}),
          locale: const Locale('pt', 'BR'),
        ),
      );
      expect(find.text('+ NOVO'), findsOneWidget);
    });

    testWidgets('wraps a MacButton and forwards the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(AddPresetButton(onPressed: () => taps++)),
      );

      expect(find.byType(MacButton), findsOneWidget);
      await tester.tap(find.byType(MacButton));
      expect(taps, 1);
    });
  });
}

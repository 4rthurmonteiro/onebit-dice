import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/roll_button.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('RollButton', () {
    testWidgets('renders a MacButton with label = l10n.actionRoll', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(RollButton(onPressed: () {})));
      final context = tester.element(find.byType(RollButton));
      final expected = AppLocalizations.of(context)!.actionRoll.toUpperCase();

      expect(find.byType(MacButton), findsOneWidget);
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('tap forwards to onPressed', (tester) async {
      var calls = 0;
      await tester.pumpWidget(_harness(RollButton(onPressed: () => calls++)));

      await tester.tap(find.byType(RollButton));
      await tester.pump();
      expect(calls, 1);
    });
  });
}

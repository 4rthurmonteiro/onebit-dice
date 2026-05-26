import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/settings_screen.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

Widget _harness({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: const SettingsScreen(),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('renders localized AppBar title and COMING SOON body in EN', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
    });

    testWidgets('renders localized strings in PT-BR', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('pt', 'BR')));
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('EM BREVE'), findsOneWidget);
    });

    testWidgets('uses palette paper as scaffold background', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Palette.of(PaletteId.macClassic).paper);
    });
  });
}

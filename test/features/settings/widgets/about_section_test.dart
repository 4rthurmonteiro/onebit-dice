import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/app_info.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/widgets/about_section.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

Widget _harness({Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: const Scaffold(body: AboutSection()),
  );
}

void main() {
  group('AboutSection', () {
    testWidgets('renders the app name', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.text('1-Bit Dice'), findsOneWidget);
    });

    testWidgets('renders the version constant', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.text('Version $kAppVersion'), findsOneWidget);
    });

    testWidgets('renders the studio credit', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();
      expect(find.text(kStudioName), findsOneWidget);
    });

    testWidgets('uses the localized version label in pt-BR', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('pt', 'BR')));
      await tester.pumpAndSettle();
      expect(find.text('Versão $kAppVersion'), findsOneWidget);
    });
  });
}

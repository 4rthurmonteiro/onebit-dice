import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/history/widgets/clear_history_button.dart';
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
  group('ClearHistoryButton', () {
    testWidgets('renders a MacButton with the CLEAR label', (tester) async {
      await tester.pumpWidget(_harness(ClearHistoryButton(onConfirm: () {})));

      expect(find.byType(MacButton), findsOneWidget);
      expect(find.text('CLEAR'), findsOneWidget);
    });

    testWidgets('tap opens the confirm dialog', (tester) async {
      await tester.pumpWidget(_harness(ClearHistoryButton(onConfirm: () {})));

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();

      expect(find.text('Clear history?'), findsOneWidget);
      expect(find.text('This deletes every recorded roll.'), findsOneWidget);
      expect(find.byKey(ClearHistoryButton.confirmKey), findsOneWidget);
      expect(find.byKey(ClearHistoryButton.cancelKey), findsOneWidget);
    });

    testWidgets('confirming the dialog invokes onConfirm once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(ClearHistoryButton(onConfirm: () => calls++)),
      );

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ClearHistoryButton.confirmKey));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('cancelling the dialog does not invoke onConfirm', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(ClearHistoryButton(onConfirm: () => calls++)),
      );

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ClearHistoryButton.cancelKey));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });

    testWidgets('dismissing the dialog via the barrier does not confirm', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(ClearHistoryButton(onConfirm: () => calls++)),
      );

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();
      // Tapping outside the dialog (above the AlertDialog box) dismisses it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}

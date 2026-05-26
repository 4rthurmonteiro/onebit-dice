import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/dice_widget.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('DiceWidget', () {
    testWidgets('values == null → renders count slots, each showing "?"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const DiceWidget(count: 3, values: null)),
      );
      expect(find.text('?'), findsNWidgets(3));
      expect(find.byKey(DiceWidget.totalKey), findsNothing);
      expect(find.byKey(DiceWidget.equationKey), findsNothing);
    });

    testWidgets('values != null → renders one slot per value', (tester) async {
      await tester.pumpWidget(
        _harness(DiceWidget(count: 3, values: const [4, 5, 6])),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('?'), findsNothing);
    });

    testWidgets('values != null && length > 1 → renders the equation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(DiceWidget(count: 3, values: const [2, 3, 5])),
      );
      expect(find.byKey(DiceWidget.equationKey), findsOneWidget);
      expect(find.text('2 + 3 + 5 = 10'), findsOneWidget);
    });

    testWidgets('values != null && length == 1 → no equation', (tester) async {
      await tester.pumpWidget(
        _harness(DiceWidget(count: 1, values: const [4])),
      );
      expect(find.byKey(DiceWidget.equationKey), findsNothing);
    });

    testWidgets('values != null → renders the localized total', (tester) async {
      await tester.pumpWidget(
        _harness(DiceWidget(count: 2, values: const [3, 4])),
      );
      final context = tester.element(find.byType(DiceWidget));
      expect(
        find.text(AppLocalizations.of(context)!.rollResultTotal(7)),
        findsOneWidget,
      );
    });

    testWidgets('grid key is present in both states', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceWidget(count: 2, values: null)),
      );
      expect(find.byKey(DiceWidget.gridKey), findsOneWidget);

      await tester.pumpWidget(
        _harness(DiceWidget(count: 2, values: const [1, 2])),
      );
      expect(find.byKey(DiceWidget.gridKey), findsOneWidget);
    });

    test('asserts when values.length != count', () {
      expect(
        () => DiceWidget(count: 3, values: const [1, 2]),
        throwsAssertionError,
      );
    });

    testWidgets('renders 4 slots in a 3×2 layout when count is 4', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const DiceWidget(count: 4, values: null)),
      );
      expect(find.text('?'), findsNWidgets(4));
    });

    testWidgets('renders up to count 10 slots', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceWidget(count: 10, values: null)),
      );
      expect(find.text('?'), findsNWidgets(10));
    });
  });
}

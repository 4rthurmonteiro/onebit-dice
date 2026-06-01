import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/quantity_selector.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

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
  group('QuantitySelector', () {
    testWidgets('renders count between the steppers', (tester) async {
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 3, onChanged: (_) {})),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
      expect(find.text('−'), findsOneWidget);
    });

    testWidgets('lays out as a compact group (mainAxisSize.min)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 3, onChanged: (_) {})),
      );
      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(QuantitySelector),
          matching: find.byType(Row),
        ),
      );
      expect(row.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('− is disabled (no callback) when count == 1', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 1, onChanged: (_) => calls++)),
      );

      await tester.tap(find.text('−'));
      expect(calls, 0);
    });

    testWidgets('+ is disabled (no callback) when count == 10', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 10, onChanged: (_) => calls++)),
      );

      await tester.tap(find.text('+'));
      expect(calls, 0);
    });

    testWidgets('+ calls onChanged(count + 1) when enabled', (tester) async {
      int? next;
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 4, onChanged: (v) => next = v)),
      );

      await tester.tap(find.text('+'));
      expect(next, 5);
    });

    testWidgets('− calls onChanged(count - 1) when enabled', (tester) async {
      int? next;
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 4, onChanged: (v) => next = v)),
      );

      await tester.tap(find.text('−'));
      expect(next, 3);
    });

    testWidgets('+ exposes the increase semantic label', (tester) async {
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 5, onChanged: (_) {})),
      );
      final context = tester.element(find.byType(QuantitySelector));
      final expected = AppLocalizations.of(context)!.diceCountIncreaseLabel;

      final semantics = tester.getSemantics(find.text('+'));
      expect(semantics.label, contains(expected));
    });

    testWidgets('− exposes the decrease semantic label', (tester) async {
      await tester.pumpWidget(
        _harness(QuantitySelector(count: 5, onChanged: (_) {})),
      );
      final context = tester.element(find.byType(QuantitySelector));
      final expected = AppLocalizations.of(context)!.diceCountDecreaseLabel;

      final semantics = tester.getSemantics(find.text('−'));
      expect(semantics.label, contains(expected));
    });
  });
}

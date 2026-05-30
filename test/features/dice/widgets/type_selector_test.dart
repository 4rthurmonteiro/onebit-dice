import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_sheet.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
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

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_harness(child));
}

void main() {
  group('TypeSelector', () {
    testWidgets('shows the selected type label', (tester) async {
      await _pump(
        tester,
        TypeSelector(selectedType: DiceType.d20, onChanged: (_) {}),
      );
      expect(find.text('D20'), findsOneWidget);
    });

    testWidgets('exposes Semantics(button, label, value)', (tester) async {
      await _pump(
        tester,
        TypeSelector(selectedType: DiceType.d12, onChanged: (_) {}),
      );
      final context = tester.element(find.byType(TypeSelector));
      final fieldLabel = AppLocalizations.of(context)!.diceTypeFieldLabel;

      expect(
        tester.getSemantics(find.byType(TypeSelector)),
        matchesSemantics(
          label: fieldLabel,
          value: 'D12',
          isButton: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('tapping the field opens the DiceTypeSheet', (tester) async {
      await _pump(
        tester,
        TypeSelector(selectedType: DiceType.d6, onChanged: (_) {}),
      );

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();

      expect(find.byType(DiceTypeSheet), findsOneWidget);
    });

    testWidgets('picking a row forwards the type and closes the sheet', (
      tester,
    ) async {
      DiceType? picked;
      await _pump(
        tester,
        TypeSelector(
          selectedType: DiceType.d6,
          onChanged: (type) => picked = type,
        ),
      );

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();
      await tester.tap(find.text('D20'));
      await tester.pumpAndSettle();

      expect(picked, DiceType.d20);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('dismissing the sheet does not call onChanged', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        TypeSelector(selectedType: DiceType.d6, onChanged: (_) => calls++),
      );

      await tester.tap(find.byType(TypeSelector));
      await tester.pumpAndSettle();
      // Tap the hatch barrier to dismiss without selecting.
      await tester.tap(find.byKey(DiceTypeSheet.barrierKey));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });
  });
}

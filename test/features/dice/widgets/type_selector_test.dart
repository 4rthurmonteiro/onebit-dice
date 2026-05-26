import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TypeSelector', () {
    testWidgets('renders 7 chips, one per DiceType.values, in order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(TypeSelector(selectedType: DiceType.d6, onChanged: (_) {})),
      );

      for (final type in DiceType.values) {
        expect(find.text(type.label), findsOneWidget);
      }
    });

    testWidgets('the chip matching selectedType has the ink background', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(TypeSelector(selectedType: DiceType.d12, onChanged: (_) {})),
      );

      final ink = Palette.of(PaletteId.macClassic).ink;
      final paper = Palette.of(PaletteId.macClassic).paper;

      // Selected chip: ink background, paper text color.
      final selectedText = tester.widget<Text>(find.text('D12'));
      expect(selectedText.style?.color, paper);

      // Non-selected chip: paper background, ink text color.
      final otherText = tester.widget<Text>(find.text('D6'));
      expect(otherText.style?.color, ink);
    });

    testWidgets(
      'tapping a non-selected chip invokes onChanged with that DiceType',
      (tester) async {
        DiceType? tapped;
        await tester.pumpWidget(
          _harness(
            TypeSelector(
              selectedType: DiceType.d6,
              onChanged: (type) => tapped = type,
            ),
          ),
        );

        await tester.tap(find.text('D20'));
        expect(tapped, DiceType.d20);
      },
    );

    testWidgets('tapping the already-selected chip still invokes onChanged', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          TypeSelector(selectedType: DiceType.d6, onChanged: (_) => calls++),
        ),
      );

      await tester.tap(find.text('D6'));
      expect(calls, 1);
    });

    testWidgets('each chip exposes Semantics(label, button, selected)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(TypeSelector(selectedType: DiceType.d6, onChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.text('D20')),
        matchesSemantics(
          label: 'D20\nD20',
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('D6')),
        matchesSemantics(
          label: 'D6\nD6',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
    });
  });
}

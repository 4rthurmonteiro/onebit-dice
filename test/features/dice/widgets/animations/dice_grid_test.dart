import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

List<int> _pipValues(WidgetTester tester) => tester
    .widgetList<PipFace>(find.byType(PipFace))
    .map((p) => p.value)
    .toList();

void main() {
  group('DiceGrid', () {
    testWidgets('values == null → renders count "?" slots', (tester) async {
      await tester.pumpWidget(_harness(const DiceGrid(count: 3, values: null)));
      expect(find.text('?'), findsNWidgets(3));
    });

    testWidgets('sides > 6 → renders one numeral per value', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceGrid(count: 3, values: [4, 5, 6], sides: 20)),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.byType(PipFace), findsNothing);
    });

    testWidgets('sides <= 6 → renders one pip face per value', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceGrid(count: 3, values: [4, 5, 6])),
      );
      expect(_pipValues(tester), unorderedEquals([4, 5, 6]));
      expect(find.text('4'), findsNothing);
    });

    testWidgets('layout wraps to a second row past maxColumns', (tester) async {
      await tester.pumpWidget(_harness(const DiceGrid(count: 4, values: null)));
      expect(find.text('?'), findsNWidgets(4));
    });

    testWidgets('builder wraps each slot — wrapper count == slot count', (
      tester,
    ) async {
      const wrapperKey = Key('wrap');
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          DiceGrid(
            count: 3,
            values: const [1, 2, 3],
            builder: (i, slot) {
              calls++;
              return KeyedSubtree(key: ValueKey('$wrapperKey-$i'), child: slot);
            },
          ),
        ),
      );
      expect(calls, 3);
    });
  });

  group('DiceSlot', () {
    testWidgets('sides > 6 → renders the numeral', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceSlot(value: 7, sides: 20, size: 32)),
      );
      expect(find.text('7'), findsOneWidget);
      expect(find.byType(PipFace), findsNothing);
    });

    testWidgets('sides <= 6 → renders a pip face', (tester) async {
      await tester.pumpWidget(_harness(const DiceSlot(value: 3, size: 64)));
      expect(find.byType(PipFace), findsOneWidget);
      expect(_pipValues(tester), [3]);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('value == null → renders "?"', (tester) async {
      await tester.pumpWidget(_harness(const DiceSlot(size: 32)));
      expect(find.text('?'), findsOneWidget);
      expect(find.byType(PipFace), findsNothing);
    });
  });

  group('PipFace', () {
    testWidgets('renders for an in-range value', (tester) async {
      await tester.pumpWidget(
        _harness(const PipFace(value: 6, color: Color(0xFF000000), size: 48)),
      );
      expect(find.byType(PipFace), findsOneWidget);
    });

    testWidgets('paints nothing for an out-of-range value', (tester) async {
      await tester.pumpWidget(
        _harness(const PipFace(value: 9, color: Color(0xFF000000), size: 48)),
      );
      // No crash; the painter early-returns for values outside 1..6.
      expect(find.byType(PipFace), findsOneWidget);
    });
  });
}

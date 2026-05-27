import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/animations/dice_grid.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: buildThemeData(Palette.of(PaletteId.macClassic)),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('DiceGrid', () {
    testWidgets('values == null → renders count "?" slots', (tester) async {
      await tester.pumpWidget(_harness(const DiceGrid(count: 3, values: null)));
      expect(find.text('?'), findsNWidgets(3));
    });

    testWidgets('values != null → renders one slot per value', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceGrid(count: 3, values: [4, 5, 6])),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
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
    testWidgets('renders the supplied text', (tester) async {
      await tester.pumpWidget(_harness(const DiceSlot(text: '7', size: 32)));
      expect(find.text('7'), findsOneWidget);
    });
  });
}

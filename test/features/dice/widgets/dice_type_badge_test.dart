import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_badge.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('DiceTypeBadge', () {
    test('matrices maps every DiceType to a non-empty 8x8 grid', () {
      expect(DiceTypeBadge.matrices.keys.toSet(), DiceType.values.toSet());
      for (final matrix in DiceTypeBadge.matrices.values) {
        expect(matrix, hasLength(8));
        for (final row in matrix) {
          expect(row, hasLength(8));
        }
      }
    });

    for (final type in DiceType.values) {
      testWidgets("renders a PixelIcon with $type's matrix", (tester) async {
        await tester.pumpWidget(_harness(DiceTypeBadge(type: type)));

        final icon = tester.widget<PixelIcon>(find.byType(PixelIcon));
        expect(icon.matrix, DiceTypeBadge.matrices[type]);
      });
    }

    testWidgets('honors a custom size', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceTypeBadge(type: DiceType.d6, size: 40)),
      );
      expect(tester.getSize(find.byType(PixelIcon)), const Size(40, 40));
    });

    testWidgets('forwards inverted to the PixelIcon', (tester) async {
      await tester.pumpWidget(
        _harness(const DiceTypeBadge(type: DiceType.d20, inverted: true)),
      );
      expect(tester.widget<PixelIcon>(find.byType(PixelIcon)).inverted, isTrue);
    });
  });
}

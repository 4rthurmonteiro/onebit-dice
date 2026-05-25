import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';

Widget _harness(Widget child, {PaletteId id = PaletteId.macClassic}) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(id)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PixelDivider', () {
    testWidgets('default height is 2', (tester) async {
      await tester.pumpWidget(_harness(const PixelDivider()));
      final size = tester.getSize(find.byType(PixelDivider));
      expect(size.height, 2);
    });

    testWidgets('honors custom thickness', (tester) async {
      await tester.pumpWidget(_harness(const PixelDivider(thickness: 5)));
      final size = tester.getSize(find.byType(PixelDivider));
      expect(size.height, 5);
    });

    testWidgets('applies the provided padding', (tester) async {
      await tester.pumpWidget(
        _harness(
          const PixelDivider(padding: EdgeInsets.symmetric(vertical: 6)),
        ),
      );
      final size = tester.getSize(find.byType(PixelDivider));
      expect(size.height, 2 + 6 + 6);
    });

    for (final id in [PaletteId.macClassic, PaletteId.gameBoy]) {
      testWidgets('color matches OneBitColors.ink under $id', (tester) async {
        await tester.pumpWidget(_harness(const PixelDivider(), id: id));
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(PixelDivider),
            matching: find.byType(Container),
          ),
        );
        expect(container.color, Palette.of(id).ink);
      });
    }
  });
}

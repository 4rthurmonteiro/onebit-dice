import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

Widget _harness(Widget child, {PaletteId id = PaletteId.macClassic}) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(id)),
    home: Scaffold(body: Center(child: child)),
  );
}

const _matrix = [
  [1, 0],
  [0, 1],
];

void main() {
  group('PixelIcon', () {
    testWidgets('default size is 24x24', (tester) async {
      await tester.pumpWidget(_harness(const PixelIcon(matrix: _matrix)));
      final size = tester.getSize(find.byType(PixelIcon));
      expect(size, const Size(24, 24));
    });

    testWidgets('honors custom size', (tester) async {
      await tester.pumpWidget(
        _harness(const PixelIcon(matrix: _matrix, size: 64)),
      );
      final size = tester.getSize(find.byType(PixelIcon));
      expect(size, const Size(64, 64));
    });

    testWidgets('painter uses ink as `on` color under the active palette', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(const PixelIcon(matrix: _matrix)));
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(PixelIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as PixelIconPainter;
      expect(painter.on, Palette.of(PaletteId.macClassic).ink);
      expect(painter.off, Palette.of(PaletteId.macClassic).paper);
    });

    testWidgets('inverted swaps `on` and `off`', (tester) async {
      await tester.pumpWidget(
        _harness(const PixelIcon(matrix: _matrix, inverted: true)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(PixelIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as PixelIconPainter;
      expect(painter.on, Palette.of(PaletteId.macClassic).paper);
      expect(painter.off, Palette.of(PaletteId.macClassic).ink);
    });

    testWidgets('repaints when palette changes', (tester) async {
      final macPainter = PixelIconPainter(
        matrix: _matrix,
        on: Palette.of(PaletteId.macClassic).ink,
        off: Palette.of(PaletteId.macClassic).paper,
      );
      final gbPainter = PixelIconPainter(
        matrix: _matrix,
        on: Palette.of(PaletteId.gameBoy).ink,
        off: Palette.of(PaletteId.gameBoy).paper,
      );
      expect(macPainter.shouldRepaint(gbPainter), isTrue);
    });

    test('shouldRepaint returns false for the same colors and matrix', () {
      final p = PixelIconPainter(
        matrix: _matrix,
        on: const Color(0xFF000000),
        off: const Color(0xFFFFFFFF),
      );
      expect(p.shouldRepaint(p), isFalse);
    });

    test('paint handles empty matrix without throwing', () {
      final painter = PixelIconPainter(
        matrix: const [],
        on: const Color(0xFF000000),
        off: const Color(0xFFFFFFFF),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(10, 10)),
        returnsNormally,
      );
    });
  });
}

class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

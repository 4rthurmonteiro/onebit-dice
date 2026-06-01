import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/shared/widgets/hatch_painter.dart';

void main() {
  group('HatchPainter', () {
    const ink = Color(0xFF000000);
    const paper = Color(0xFFFFFFFF);

    test('shouldRepaint is true when a color changes', () {
      final a = HatchPainter(ink: ink, paper: paper);
      final b = HatchPainter(ink: const Color(0xFF222222), paper: paper);
      final c = HatchPainter(ink: ink, paper: const Color(0xFFEEEEEE));
      expect(a.shouldRepaint(b), isTrue);
      expect(a.shouldRepaint(c), isTrue);
    });

    test('shouldRepaint is false for identical colors', () {
      final a = HatchPainter(ink: ink, paper: paper);
      final b = HatchPainter(ink: ink, paper: paper);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('paint fills the canvas without throwing', () {
      final painter = HatchPainter(ink: ink, paper: paper);
      expect(
        () => painter.paint(_NoopCanvas(), const Size(40, 40)),
        returnsNormally,
      );
    });

    testWidgets('renders inside a CustomPaint', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CustomPaint(
            painter: HatchPainter(ink: ink, paper: paper),
            size: const Size(100, 100),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

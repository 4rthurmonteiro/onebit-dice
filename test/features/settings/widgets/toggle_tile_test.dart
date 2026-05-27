import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/widgets/toggle_tile.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

CheckboxPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(ToggleTile),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as CheckboxPainter;
}

void main() {
  group('ToggleTile', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(
        _harness(ToggleTile(label: 'Som', value: true, onChanged: (_) {})),
      );

      expect(find.text('Som'), findsOneWidget);
    });

    testWidgets('tapping invokes onChanged with the inverted value', (
      tester,
    ) async {
      final emitted = <bool>[];
      await tester.pumpWidget(
        _harness(
          ToggleTile(label: 'Som', value: false, onChanged: emitted.add),
        ),
      );

      await tester.tap(find.byType(ToggleTile));
      await tester.pump();

      expect(emitted, [true]);
    });

    testWidgets('tapping from true emits false', (tester) async {
      final emitted = <bool>[];
      await tester.pumpWidget(
        _harness(ToggleTile(label: 'Som', value: true, onChanged: emitted.add)),
      );

      await tester.tap(find.byType(ToggleTile));
      await tester.pump();

      expect(emitted, [false]);
    });

    testWidgets('painter reflects checked = false', (tester) async {
      await tester.pumpWidget(
        _harness(ToggleTile(label: 'x', value: false, onChanged: (_) {})),
      );
      expect(_painter(tester).checked, isFalse);
    });

    testWidgets('painter reflects checked = true', (tester) async {
      await tester.pumpWidget(
        _harness(ToggleTile(label: 'x', value: true, onChanged: (_) {})),
      );
      expect(_painter(tester).checked, isTrue);
    });
  });

  group('CheckboxPainter', () {
    test('paint(checked: false) renders without throwing', () {
      final painter = CheckboxPainter(
        checked: false,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(20, 20)),
        returnsNormally,
      );
    });

    test('paint(checked: true) renders without throwing', () {
      final painter = CheckboxPainter(
        checked: true,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(20, 20)),
        returnsNormally,
      );
    });

    test('shouldRepaint returns true when checked changes', () {
      final a = CheckboxPainter(
        checked: false,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      final b = CheckboxPainter(
        checked: true,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false for identical config', () {
      final a = CheckboxPainter(
        checked: true,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      final b = CheckboxPainter(
        checked: true,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      expect(a.shouldRepaint(b), isFalse);
    });
  });
}

class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

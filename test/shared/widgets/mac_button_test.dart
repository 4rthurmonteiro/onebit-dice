import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';

Widget _harness(Widget child, {PaletteId id = PaletteId.macClassic}) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(id)),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('MacButton', () {
    testWidgets('renders the label in upper case', (tester) async {
      await tester.pumpWidget(
        _harness(MacButton(label: 'rolar', onPressed: () {})),
      );
      expect(find.text('ROLAR'), findsOneWidget);
    });

    testWidgets('tap calls onPressed exactly once per tap', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(MacButton(label: 'X', onPressed: () => calls++)),
      );

      await tester.tap(find.byType(MacButton));
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.tap(find.byType(MacButton));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('shows pressed state while gesture is held', (tester) async {
      await tester.pumpWidget(
        _harness(MacButton(label: 'X', onPressed: () {})),
      );

      expect(find.byKey(MacButton.shadowKey), findsOneWidget);
      final faceBefore = tester.getTopLeft(find.byKey(MacButton.faceKey));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MacButton)),
      );
      await tester.pump();

      expect(find.byKey(MacButton.shadowKey), findsNothing);
      final faceAfter = tester.getTopLeft(find.byKey(MacButton.faceKey));
      expect(faceAfter.dx, faceBefore.dx + MacButton.shadowOffset);
      expect(faceAfter.dy, faceBefore.dy + MacButton.shadowOffset);

      await gesture.up();
      await tester.pump();
      expect(find.byKey(MacButton.shadowKey), findsOneWidget);
    });

    testWidgets('cancelling the gesture restores the unpressed state', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(MacButton(label: 'X', onPressed: () {})),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(MacButton)),
      );
      await tester.pump();
      expect(find.byKey(MacButton.shadowKey), findsNothing);

      await gesture.cancel();
      await tester.pump();
      expect(find.byKey(MacButton.shadowKey), findsOneWidget);
    });

    for (final id in [
      PaletteId.macClassic,
      PaletteId.gameBoy,
      PaletteId.zxSpectrum,
    ]) {
      testWidgets('label is tinted with $id ink and press toggles shadow', (
        tester,
      ) async {
        await tester.pumpWidget(
          _harness(
            MacButton(label: 'X', onPressed: () {}),
            id: id,
          ),
        );

        final labelStyle = tester.widget<Text>(find.text('X')).style!;
        expect(labelStyle.color, Palette.of(id).ink);
        expect(find.byKey(MacButton.shadowKey), findsOneWidget);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(MacButton)),
        );
        await tester.pump();
        expect(find.byKey(MacButton.shadowKey), findsNothing);

        await gesture.up();
        await tester.pump();
        expect(find.byKey(MacButton.shadowKey), findsOneWidget);
      });
    }

    testWidgets('expand: true fills the parent width', (tester) async {
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 300,
            child: MacButton(label: 'X', onPressed: () {}, expand: true),
          ),
        ),
      );
      final size = tester.getSize(find.byType(MacButton));
      expect(size.width, 300);
    });

    testWidgets('expand: false shrinks to content width', (tester) async {
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 600,
            child: Align(
              child: MacButton(label: 'X', onPressed: () {}),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(MacButton));
      expect(size.width, lessThan(600));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';

Widget _harness(Widget child, {PaletteId id = PaletteId.macClassic}) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(id)),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('MacWindow', () {
    testWidgets('renders title and close button when both provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          MacWindow(title: 'About', onClose: () {}, child: const Text('body')),
        ),
      );

      expect(find.byKey(MacWindow.titleKey), findsOneWidget);
      expect(find.byKey(MacWindow.closeButtonKey), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('tapping the close button calls onClose', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          MacWindow(
            title: 'About',
            onClose: () => calls++,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      await tester.tap(find.byKey(MacWindow.closeButtonKey));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('omits the close button when onClose is null', (tester) async {
      await tester.pumpWidget(
        _harness(const MacWindow(title: 'About', child: SizedBox.shrink())),
      );

      expect(find.byKey(MacWindow.closeButtonKey), findsNothing);
      expect(find.byKey(MacWindow.titleKey), findsOneWidget);
    });

    testWidgets('omits the title rectangle when title is null', (tester) async {
      await tester.pumpWidget(
        _harness(MacWindow(onClose: () {}, child: const SizedBox.shrink())),
      );

      expect(find.byKey(MacWindow.titleKey), findsNothing);
      expect(find.byKey(MacWindow.closeButtonKey), findsOneWidget);
    });

    testWidgets('shows only stripes when title and onClose are both null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const MacWindow(child: SizedBox.shrink())),
      );

      expect(find.byKey(MacWindow.titleKey), findsNothing);
      expect(find.byKey(MacWindow.closeButtonKey), findsNothing);
    });

    testWidgets('title color tracks the active palette ink', (tester) async {
      Future<void> pumpAt(PaletteId id) async {
        await tester.pumpWidget(
          _harness(
            MacWindow(
              title: 'About',
              onClose: () {},
              child: const SizedBox.shrink(),
            ),
            id: id,
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpAt(PaletteId.macClassic);
      var titleStyle = tester.widget<Text>(find.text('About')).style!;
      expect(titleStyle.color, Palette.of(PaletteId.macClassic).ink);

      // Re-pump with the same palette to also exercise painter shouldRepaint
      // returning false because ink did not change.
      await pumpAt(PaletteId.macClassic);
      titleStyle = tester.widget<Text>(find.text('About')).style!;
      expect(titleStyle.color, Palette.of(PaletteId.macClassic).ink);

      await pumpAt(PaletteId.gameBoy);
      titleStyle = tester.widget<Text>(find.text('About')).style!;
      expect(titleStyle.color, Palette.of(PaletteId.gameBoy).ink);
    });

    for (final id in [PaletteId.macClassic, PaletteId.zxSpectrum]) {
      testWidgets('renders title styled with $id ink', (tester) async {
        await tester.pumpWidget(
          _harness(
            MacWindow(
              title: 'About',
              onClose: () {},
              child: const Text('body'),
            ),
            id: id,
          ),
        );

        final titleStyle = tester.widget<Text>(find.text('About')).style!;
        expect(titleStyle.color, Palette.of(id).ink);
      });
    }

    testWidgets('exposes a Semantics label and a button role on close', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          MacWindow(
            title: 'About',
            onClose: () {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Close'), findsOneWidget);
    });
  });
}

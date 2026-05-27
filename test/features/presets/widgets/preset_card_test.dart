import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/presets/widgets/preset_card.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PresetCard', () {
    testWidgets('renders the label and the notation', (tester) async {
      await tester.pumpWidget(
        _harness(PresetCard(label: 'Ludo', notation: '1D6', onTap: () {})),
      );

      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text('1D6'), findsOneWidget);
    });

    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          PresetCard(label: 'War', notation: '3D6', onTap: () => taps++),
        ),
      );

      await tester.tap(find.byType(PresetCard));
      expect(taps, 1);
    });

    testWidgets('exposes a semantic button label combining text + notation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(PresetCard(label: 'Yahtzee', notation: '5D6', onTap: () {})),
      );

      expect(
        tester.getSemantics(find.byType(PresetCard)),
        matchesSemantics(
          label: 'Yahtzee 5D6',
          isButton: true,
          hasTapAction: true,
        ),
      );
    });
  });
}

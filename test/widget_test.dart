import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/app.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/_dev/design_system_preview.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App renders the design system preview at the Mac Classic '
      'palette by default', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();

    expect(find.byType(DesignSystemPreview), findsOneWidget);
    expect(find.text('1-BIT DICE'), findsOneWidget);

    final context = tester.element(find.byType(DesignSystemPreview));
    expect(context.read<ThemeProvider>().current.id, PaletteId.macClassic);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      Palette.of(PaletteId.macClassic).paper,
    );
  });

  testWidgets('changing palette through the provider rebuilds the theme', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    final provider = tester
        .element(find.byType(DesignSystemPreview))
        .read<ThemeProvider>();
    await provider.setPalette(PaletteId.gameBoy);
    await tester.pumpAndSettle();

    expect(provider.current.id, PaletteId.gameBoy);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Palette.of(PaletteId.gameBoy).paper);
  });
}

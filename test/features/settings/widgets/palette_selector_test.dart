import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/core/theme/palette_preference.dart';
import 'package:onebit_dice/core/theme/theme_provider.dart';
import 'package:onebit_dice/features/settings/widgets/palette_selector.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../support/mock_analytics_service.dart';

class _MockPalettePreference extends Mock implements PalettePreference {}

ThemeProvider _buildProvider() {
  registerFallbackValue(PaletteId.macClassic);
  final preference = _MockPalettePreference();
  when(preference.read).thenReturn(null);
  when(() => preference.write(any())).thenAnswer((_) async {});
  return ThemeProvider(
    analytics: createStubbedAnalytics(),
    preference: preference,
  );
}

Widget _harness(ThemeProvider provider) {
  return ChangeNotifierProvider<ThemeProvider>.value(
    value: provider,
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: const Scaffold(body: PaletteSelector()),
    ),
  );
}

void main() {
  group('PaletteSelector', () {
    testWidgets('renders one swatch per PaletteId', (tester) async {
      await tester.pumpWidget(_harness(_buildProvider()));
      await tester.pumpAndSettle();

      expect(
        find.byType(PaletteSwatch),
        findsNWidgets(PaletteId.values.length),
      );
    });

    testWidgets('marks the active swatch by id', (tester) async {
      await tester.pumpWidget(_harness(_buildProvider()));
      await tester.pumpAndSettle();

      final swatches = tester
          .widgetList<PaletteSwatch>(find.byType(PaletteSwatch))
          .toList();
      expect(swatches.where((s) => s.active).map((s) => s.id), [
        PaletteId.macClassic,
      ]);
    });

    testWidgets('tapping a swatch calls setPalette on the provider', (
      tester,
    ) async {
      final provider = _buildProvider();
      await tester.pumpWidget(_harness(provider));
      await tester.pumpAndSettle();

      // Tap the Game Boy swatch.
      final gameBoySwatchFinder = find.byWidgetPredicate(
        (w) => w is PaletteSwatch && w.id == PaletteId.gameBoy,
      );
      await tester.tap(gameBoySwatchFinder);
      await tester.pumpAndSettle();

      expect(provider.current.id, PaletteId.gameBoy);
    });

    for (final id in PaletteId.values) {
      testWidgets('exposes a swatch for $id', (tester) async {
        await tester.pumpWidget(_harness(_buildProvider()));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate((w) => w is PaletteSwatch && w.id == id),
          findsOneWidget,
        );
      });
    }
  });

  group('PaletteSwatchPainter', () {
    test('shouldRepaint returns true on active toggle', () {
      const ink = Color(0xFF000000);
      const paper = Color(0xFFFFFFFF);
      final a = PaletteSwatchPainter(
        fill: paper,
        border: ink,
        active: false,
        activeInk: ink,
      );
      final b = PaletteSwatchPainter(
        fill: paper,
        border: ink,
        active: true,
        activeInk: ink,
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false for identical config', () {
      const ink = Color(0xFF000000);
      const paper = Color(0xFFFFFFFF);
      final a = PaletteSwatchPainter(
        fill: paper,
        border: ink,
        active: true,
        activeInk: ink,
      );
      final b = PaletteSwatchPainter(
        fill: paper,
        border: ink,
        active: true,
        activeInk: ink,
      );
      expect(a.shouldRepaint(b), isFalse);
    });

    test('paint renders inactive swatch without throwing', () {
      final painter = PaletteSwatchPainter(
        fill: const Color(0xFFFFFFFF),
        border: const Color(0xFF000000),
        active: false,
        activeInk: const Color(0xFF000000),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(48, 48)),
        returnsNormally,
      );
    });

    test('paint renders active swatch without throwing', () {
      final painter = PaletteSwatchPainter(
        fill: const Color(0xFFFFFFFF),
        border: const Color(0xFF000000),
        active: true,
        activeInk: const Color(0xFF000000),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(48, 48)),
        returnsNormally,
      );
    });
  });
}

class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

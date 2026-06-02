import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/i18n/locale_controller.dart';
import 'package:onebit_dice/core/i18n/locale_preference.dart';
import 'package:onebit_dice/core/i18n/supported_locales.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/widgets/language_picker.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../support/mock_analytics_service.dart';

class _MockLocalePreference extends Mock implements LocalePreference {}

LocaleController _buildController() {
  registerFallbackValue(const Locale('en'));
  final preference = _MockLocalePreference();
  when(preference.read).thenReturn(null);
  when(() => preference.write(any())).thenAnswer((_) async {});
  return LocaleController(
    analytics: createStubbedAnalytics(),
    preference: preference,
  );
}

Widget _harness(LocaleController controller) {
  return ChangeNotifierProvider<LocaleController>.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: const Scaffold(body: LanguagePicker()),
    ),
  );
}

Finder _rowFor(String label) =>
    find.byWidgetPredicate((w) => w is LanguageRow && w.label == label);

void main() {
  group('LanguagePicker', () {
    testWidgets('renders Follow system + every supported locale', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_buildController()));
      await tester.pumpAndSettle();

      expect(
        find.byType(LanguageRow),
        findsNWidgets(supportedLocales.length + 1),
      );
    });

    testWidgets('marks Follow system as selected when no override', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_buildController()));
      await tester.pumpAndSettle();

      final rows = tester
          .widgetList<LanguageRow>(find.byType(LanguageRow))
          .toList();
      expect(rows.first.selected, isTrue);
      expect(rows.skip(1).every((r) => !r.selected), isTrue);
    });

    testWidgets('tapping a locale row calls setOverride', (tester) async {
      final controller = _buildController();
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(_rowFor('日本語'));
      await tester.pumpAndSettle();

      expect(controller.override, const Locale('ja'));
    });

    testWidgets('tapping Follow system clears the override', (tester) async {
      final controller = _buildController();
      await controller.setOverride(const Locale('de'));
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(_rowFor('Follow system'));
      await tester.pumpAndSettle();

      expect(controller.override, isNull);
    });

    testWidgets('marks the active override row as selected', (tester) async {
      final controller = _buildController();
      await controller.setOverride(const Locale('de'));
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      final rows = tester
          .widgetList<LanguageRow>(find.byType(LanguageRow))
          .toList();
      expect(rows.where((r) => r.selected).map((r) => r.label), ['Deutsch']);
    });
  });

  group('CheckmarkPainter', () {
    test('shouldRepaint returns true on visible toggle', () {
      const ink = Color(0xFF000000);
      final a = CheckmarkPainter(visible: false, ink: ink);
      final b = CheckmarkPainter(visible: true, ink: ink);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false for identical config', () {
      const ink = Color(0xFF000000);
      final a = CheckmarkPainter(visible: true, ink: ink);
      final b = CheckmarkPainter(visible: true, ink: ink);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('paint(visible: false) is a no-op without throwing', () {
      final painter = CheckmarkPainter(
        visible: false,
        ink: const Color(0xFF000000),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(20, 20)),
        returnsNormally,
      );
    });

    test('paint(visible: true) renders without throwing', () {
      final painter = CheckmarkPainter(
        visible: true,
        ink: const Color(0xFF000000),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(20, 20)),
        returnsNormally,
      );
    });
  });
}

class _NoopCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
}

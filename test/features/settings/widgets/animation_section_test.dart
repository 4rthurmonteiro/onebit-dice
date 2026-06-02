import 'package:flutter/material.dart' hide AnimationStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/storage/app_settings_preference.dart';
import 'package:onebit_dice/core/storage/models/animation_settings.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/animation_settings_controller.dart';
import 'package:onebit_dice/features/settings/widgets/animation_section.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../support/mock_analytics_service.dart';

class _MockAppSettings extends Mock implements AppSettingsPreference {}

AnimationSettingsController _buildController() {
  registerFallbackValue(AnimationStyle.drum);
  registerFallbackValue(AnimationSpeed.medium);
  final preference = _MockAppSettings();
  when(preference.readAnimationStyle).thenReturn(null);
  when(preference.readAnimationSpeed).thenReturn(null);
  when(() => preference.writeAnimationStyle(any())).thenAnswer((_) async {});
  when(() => preference.writeAnimationSpeed(any())).thenAnswer((_) async {});
  return AnimationSettingsController(
    preference: preference,
    analytics: createStubbedAnalytics(),
  );
}

Widget _harness(AnimationSettingsController controller) {
  return ChangeNotifierProvider<AnimationSettingsController>.value(
    value: controller,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: const Scaffold(body: AnimationSection()),
    ),
  );
}

Finder _radioRowFor(String label) {
  return find.byWidgetPredicate((w) => w is RadioRow && w.label == label);
}

void main() {
  group('AnimationSection', () {
    testWidgets('renders three style radios and three speed radios', (
      tester,
    ) async {
      final controller = _buildController();
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();
      expect(find.byType(RadioRow), findsNWidgets(6));
    });

    testWidgets('selects drum + medium by default', (tester) async {
      final controller = _buildController();
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      final rows = tester.widgetList<RadioRow>(find.byType(RadioRow)).toList();
      expect(rows.where((r) => r.selected).map((r) => r.label), [
        'Drum',
        'Medium',
      ]);
    });

    testWidgets('tapping a style row calls setStyle', (tester) async {
      final controller = _buildController();
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(_radioRowFor('Tabletop'));
      await tester.pumpAndSettle();

      expect(controller.style, AnimationStyle.tabletop);
    });

    testWidgets('tapping a speed row calls setSpeed', (tester) async {
      final controller = _buildController();
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      await tester.tap(_radioRowFor('Slow'));
      await tester.pumpAndSettle();

      expect(controller.speed, AnimationSpeed.slow);
    });
  });

  group('RadioPainter', () {
    test('shouldRepaint returns true on selected toggle', () {
      const ink = Color(0xFF000000);
      const paper = Color(0xFFFFFFFF);
      final a = RadioPainter(selected: false, ink: ink, paper: paper);
      final b = RadioPainter(selected: true, ink: ink, paper: paper);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint returns false for identical config', () {
      const ink = Color(0xFF000000);
      const paper = Color(0xFFFFFFFF);
      final a = RadioPainter(selected: true, ink: ink, paper: paper);
      final b = RadioPainter(selected: true, ink: ink, paper: paper);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('paint(selected: false) renders without throwing', () {
      final painter = RadioPainter(
        selected: false,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
      );
      expect(
        () => painter.paint(_NoopCanvas(), const Size(20, 20)),
        returnsNormally,
      );
    });

    test('paint(selected: true) renders without throwing', () {
      final painter = RadioPainter(
        selected: true,
        ink: const Color(0xFF000000),
        paper: const Color(0xFFFFFFFF),
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

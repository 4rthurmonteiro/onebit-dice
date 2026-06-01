import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/presets_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_sheet.dart';
import 'package:onebit_dice/features/dice/widgets/type_selector.dart';
import 'package:onebit_dice/features/presets/widgets/create_preset_sheet.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/mac_button.dart';
import 'package:provider/provider.dart';

import '../../../support/recording_analytics_service.dart';

Widget _harness(
  PresetsRepository repository, {
  Locale locale = const Locale('en'),
  AnalyticsService analytics = const NoOpAnalyticsService(),
}) {
  return Provider<AnalyticsService>.value(
    value: analytics,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () =>
                  CreatePresetSheet.show(context, repository: repository),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpAndOpen(
  WidgetTester tester,
  PresetsRepository repo, {
  Locale locale = const Locale('en'),
  AnalyticsService analytics = const NoOpAnalyticsService(),
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_harness(repo, locale: locale, analytics: analytics));
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  group('CreatePresetSheet', () {
    testWidgets('renders the localized title, field labels, and save action', (
      tester,
    ) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo);

      expect(find.text('New preset'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Die'), findsOneWidget);
      expect(find.text('Count'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
    });

    testWidgets('save button is disabled (no MacButton) when name is empty', (
      tester,
    ) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo);

      expect(find.byType(MacButton), findsNothing);
    });

    testWidgets(
      'typing a name swaps the disabled stub for an enabled MacButton',
      (tester) async {
        final repo = InMemoryPresetsRepository();
        await _pumpAndOpen(tester, repo);

        await tester.enterText(find.byType(TextField), 'My preset');
        await tester.pump();

        expect(find.byType(MacButton), findsOneWidget);
      },
    );

    testWidgets('typing only whitespace leaves the save action disabled', (
      tester,
    ) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(find.byType(MacButton), findsNothing);
    });

    testWidgets(
      'tapping Save adds the preset to the repository and pops the sheet',
      (tester) async {
        final repo = InMemoryPresetsRepository();
        final analytics = RecordingAnalyticsService();
        await _pumpAndOpen(tester, repo, analytics: analytics);

        await tester.enterText(find.byType(TextField), 'Custom 1');
        await tester.pump();
        // The type picker now opens a DiceTypeSheet instead of inline chips.
        await tester.tap(find.byType(TypeSelector));
        await tester.pumpAndSettle();
        expect(find.byType(DiceTypeSheet), findsOneWidget);
        await tester.tap(find.text('D20'));
        await tester.pumpAndSettle();
        // QuantitySelector renders a Text('+') for the increment step.
        await tester.tap(find.text('+'));
        await tester.pump();
        await tester.tap(find.byType(MacButton));
        await tester.pumpAndSettle();

        expect(repo.snapshot(), hasLength(1));
        final saved = repo.snapshot().single;
        expect(saved.name, 'Custom 1');
        expect(saved.diceType, DiceType.d20);
        expect(saved.diceCount, 2);
        expect(find.byType(CreatePresetSheet), findsNothing);
        expect(analytics.eventNames, ['preset_created']);
        expect(analytics.events.single.parameters, {
          'dice_type': 'd20',
          'count': 2,
        });
      },
    );

    testWidgets('trims surrounding whitespace from the saved name', (
      tester,
    ) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo);

      await tester.enterText(find.byType(TextField), '  My preset  ');
      await tester.pump();
      await tester.tap(find.byType(MacButton));
      await tester.pumpAndSettle();

      expect(repo.snapshot().single.name, 'My preset');
    });

    testWidgets('TextField refuses input past 24 characters', (tester) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo);

      final long = 'a' * 30;
      await tester.enterText(find.byType(TextField), long);
      await tester.pump();
      await tester.tap(find.byType(MacButton));
      await tester.pumpAndSettle();

      expect(repo.snapshot().single.name.length, 24);
    });

    testWidgets('renders pt-BR copy under pt-BR locale', (tester) async {
      final repo = InMemoryPresetsRepository();
      await _pumpAndOpen(tester, repo, locale: const Locale('pt', 'BR'));

      expect(find.text('Novo preset'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('SALVAR'), findsOneWidget);
    });
  });
}

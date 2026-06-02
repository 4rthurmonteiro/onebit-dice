import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onebit_dice/core/analytics/analytics_service.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/models/roll_result.dart';
import 'package:onebit_dice/core/storage/history_repository.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/history/history_screen.dart';
import 'package:onebit_dice/features/history/widgets/clear_history_button.dart';
import 'package:onebit_dice/features/history/widgets/history_entry_tile.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../support/mock_analytics_service.dart';
import '../../support/mock_history_repository.dart';

Widget _harness({
  required HistoryRepository repository,
  Locale locale = const Locale('en'),
  MockAnalyticsService? analytics,
}) {
  return MultiProvider(
    providers: [
      Provider<HistoryRepository>.value(value: repository),
      Provider<AnalyticsService>.value(
        value: analytics ?? createStubbedAnalytics(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildThemeData(Palette.of(PaletteId.macClassic)),
      home: const HistoryScreen(),
    ),
  );
}

RollResult _result(int total) => RollResult(
  timestamp: DateTime.utc(2026, 5, 27, 14, 32),
  diceType: DiceType.d6,
  diceCount: 1,
  values: [total],
);

void main() {
  group('HistoryScreen', () {
    testWidgets('renders empty state when the repository is empty', (
      tester,
    ) async {
      final repository = createFakeHistory();
      await tester.pumpWidget(_harness(repository: repository));
      await tester.pumpAndSettle();

      expect(find.byKey(HistoryScreen.emptyKey), findsOneWidget);
      expect(find.text('No rolls yet.'), findsOneWidget);
      expect(find.byType(HistoryEntryTile), findsNothing);
      expect(find.byType(ClearHistoryButton), findsNothing);
    });

    testWidgets('renders entries newest-first plus the clear button', (
      tester,
    ) async {
      final repository = createFakeHistory();
      await repository.append(_result(3));
      await repository.append(_result(11));

      await tester.pumpWidget(_harness(repository: repository));
      await tester.pumpAndSettle();

      expect(find.byKey(HistoryScreen.emptyKey), findsNothing);
      expect(find.byType(HistoryEntryTile), findsNWidgets(2));
      expect(find.byType(ClearHistoryButton), findsOneWidget);

      final tiles = tester
          .widgetList<HistoryEntryTile>(find.byType(HistoryEntryTile))
          .toList();
      expect(tiles.first.entry.values, [11]);
      expect(tiles.last.entry.values, [3]);
    });

    testWidgets('reactively updates when the repository appends a new entry', (
      tester,
    ) async {
      final repository = createFakeHistory();
      await tester.pumpWidget(_harness(repository: repository));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryEntryTile), findsNothing);

      await repository.append(_result(5));
      await tester.pumpAndSettle();

      expect(find.byType(HistoryEntryTile), findsOneWidget);
    });

    testWidgets('confirm dialog flow clears the repository and logs the '
        'history_cleared event', (tester) async {
      final repository = createFakeHistory();
      final analytics = createStubbedAnalytics();
      await repository.append(_result(4));
      await tester.pumpWidget(
        _harness(repository: repository, analytics: analytics),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ClearHistoryButton.confirmKey));
      await tester.pumpAndSettle();

      expect(repository.snapshot(), isEmpty);
      expect(find.byKey(HistoryScreen.emptyKey), findsOneWidget);
      verify(() => analytics.logEvent('history_cleared')).called(1);
    });

    testWidgets('cancelling the clear dialog logs nothing', (tester) async {
      final repository = createFakeHistory();
      final analytics = createStubbedAnalytics();
      await repository.append(_result(4));
      await tester.pumpWidget(
        _harness(repository: repository, analytics: analytics),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ClearHistoryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ClearHistoryButton.cancelKey));
      await tester.pumpAndSettle();

      expect(repository.snapshot(), isNotEmpty);
      verifyNever(
        () => analytics.logEvent(any(), parameters: any(named: 'parameters')),
      );
    });

    testWidgets('uses palette paper for the scaffold background', (
      tester,
    ) async {
      final repository = createFakeHistory();
      await tester.pumpWidget(_harness(repository: repository));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Palette.of(PaletteId.macClassic).paper);
    });

    testWidgets('renders localized empty state in PT-BR', (tester) async {
      final repository = createFakeHistory();
      await tester.pumpWidget(
        _harness(repository: repository, locale: const Locale('pt', 'BR')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma rolagem ainda.'), findsOneWidget);
      expect(find.text('Histórico'), findsOneWidget);
    });
  });
}

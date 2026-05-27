import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/storage/models/roll_entry.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/history/widgets/history_entry_tile.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('HistoryEntryTile', () {
    testWidgets('renders notation, values and total for a well-formed entry', (
      tester,
    ) async {
      final entry = RollEntry(
        timestamp: DateTime(2026, 5, 27, 14, 32),
        diceTypeIndex: DiceType.d6.index,
        diceCount: 3,
        values: [3, 5, 11],
      );

      await tester.pumpWidget(_harness(HistoryEntryTile(entry: entry)));
      await tester.pumpAndSettle();

      expect(find.text('3D6 · [3, 5, 11]'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
      expect(find.byKey(HistoryEntryTile.corruptedKey), findsNothing);
    });

    testWidgets('renders a placeholder when diceTypeIndex is out of range — '
        'a single bad entry must not collapse the list', (tester) async {
      final entry = RollEntry(
        timestamp: DateTime(2026, 5, 27, 14, 32),
        diceTypeIndex: 99,
        diceCount: 1,
        values: [1],
      );

      await tester.pumpWidget(_harness(HistoryEntryTile(entry: entry)));
      await tester.pumpAndSettle();

      expect(find.byKey(HistoryEntryTile.corruptedKey), findsOneWidget);
      expect(find.text('? · [?]'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('enforces a minimum height for the tap target', (tester) async {
      final entry = RollEntry(
        timestamp: DateTime(2026, 5, 27, 14, 32),
        diceTypeIndex: DiceType.d6.index,
        diceCount: 1,
        values: [4],
      );

      await tester.pumpWidget(_harness(HistoryEntryTile(entry: entry)));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(HistoryEntryTile));
      expect(size.height, greaterThanOrEqualTo(HistoryEntryTile.minHeight));
    });
  });
}

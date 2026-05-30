import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_badge.dart';
import 'package:onebit_dice/features/dice/widgets/dice_type_sheet.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';
import 'package:onebit_dice/shared/widgets/hatch_painter.dart';
import 'package:onebit_dice/shared/widgets/mac_window.dart';
import 'package:onebit_dice/shared/widgets/pixel_icon.dart';

Widget _harness({
  required DiceType selected,
  required ValueChanged<DiceType?> onResult,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () async {
              onResult(await DiceTypeSheet.show(context, selected: selected));
            },
            child: const Text('OPEN'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  required DiceType selected,
  required ValueChanged<DiceType?> onResult,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_harness(selected: selected, onResult: onResult));
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

void main() {
  group('DiceTypeSheet', () {
    testWidgets('lists all 7 types in DiceType.values order', (tester) async {
      await _open(tester, selected: DiceType.d6, onResult: (_) {});

      final badges = tester
          .widgetList<DiceTypeBadge>(find.byType(DiceTypeBadge))
          .map((b) => b.type)
          .toList();
      expect(badges, DiceType.values);
    });

    testWidgets('shows the localized title', (tester) async {
      await _open(tester, selected: DiceType.d6, onResult: (_) {});
      expect(find.text('CHOOSE DIE'), findsOneWidget);
    });

    testWidgets('the selected row is inverted and carries a checkmark', (
      tester,
    ) async {
      await _open(tester, selected: DiceType.d8, onResult: (_) {});

      final selectedBadge = tester.widget<DiceTypeBadge>(
        find.byWidgetPredicate(
          (w) => w is DiceTypeBadge && w.type == DiceType.d8,
        ),
      );
      expect(selectedBadge.inverted, isTrue);

      final otherBadge = tester.widget<DiceTypeBadge>(
        find.byWidgetPredicate(
          (w) => w is DiceTypeBadge && w.type == DiceType.d6,
        ),
      );
      expect(otherBadge.inverted, isFalse);

      // 7 row badges + 1 checkmark icon = 8 PixelIcons.
      expect(find.byType(PixelIcon), findsNWidgets(DiceType.values.length + 1));
    });

    testWidgets('tapping a row forwards the type and pops', (tester) async {
      DiceType? result;
      var called = false;
      await _open(
        tester,
        selected: DiceType.d6,
        onResult: (r) {
          result = r;
          called = true;
        },
      );

      await tester.tap(find.text('D12'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, DiceType.d12);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('tapping the already-selected row returns that type', (
      tester,
    ) async {
      DiceType? result;
      await _open(tester, selected: DiceType.d20, onResult: (r) => result = r);

      await tester.tap(find.text('D20'));
      await tester.pumpAndSettle();

      expect(result, DiceType.d20);
    });

    testWidgets('the ✕ closes the sheet with no selection', (tester) async {
      DiceType? result;
      var called = false;
      await _open(
        tester,
        selected: DiceType.d6,
        onResult: (r) {
          result = r;
          called = true;
        },
      );

      await tester.tap(find.byKey(MacWindow.closeButtonKey));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('tapping the hatch barrier dismisses with no selection', (
      tester,
    ) async {
      DiceType? result;
      await _open(tester, selected: DiceType.d6, onResult: (r) => result = r);

      await tester.tap(find.byKey(DiceTypeSheet.barrierKey));
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('dragging the handle down dismisses with no selection', (
      tester,
    ) async {
      DiceType? result;
      var called = false;
      await _open(
        tester,
        selected: DiceType.d6,
        onResult: (r) {
          result = r;
          called = true;
        },
      );

      await tester.drag(
        find.byKey(DiceTypeSheet.dragHandleKey),
        const Offset(0, 120),
      );
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('system back dismisses with no selection', (tester) async {
      DiceType? result;
      await _open(tester, selected: DiceType.d6, onResult: (r) => result = r);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(DiceTypeSheet), findsNothing);
    });

    testWidgets('the barrier paints a 1-bit hatch, not a grey scrim', (
      tester,
    ) async {
      await _open(tester, selected: DiceType.d6, onResult: (_) {});

      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byKey(DiceTypeSheet.barrierKey),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(paint.painter, isA<HatchPainter>());

      final hatch = paint.painter! as HatchPainter;
      final palette = Palette.of(PaletteId.macClassic);
      expect(hatch.ink, palette.ink);
      expect(hatch.paper, palette.paper);
    });
  });
}

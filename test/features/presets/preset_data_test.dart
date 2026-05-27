import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/models/dice_type.dart';
import 'package:onebit_dice/features/presets/preset_data.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

Widget _harness(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
}

void main() {
  group('builtInPresets', () {
    test('exposes the 7 canonical entries in the documented order', () {
      expect(builtInPresets.map((p) => p.id).toList(), [
        'ludo',
        'banco-imobiliario',
        'war',
        'yahtzee',
        'dnd-ataque',
        'magic-vida',
        'percentil',
      ]);
    });

    test('Ludo is 1×D6', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'ludo');
      expect(p.diceType, DiceType.d6);
      expect(p.diceCount, 1);
    });

    test('Banco Imobiliário is 2×D6', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'banco-imobiliario');
      expect(p.diceType, DiceType.d6);
      expect(p.diceCount, 2);
    });

    test('War is 3×D6', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'war');
      expect(p.diceType, DiceType.d6);
      expect(p.diceCount, 3);
    });

    test('Yahtzee is 5×D6', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'yahtzee');
      expect(p.diceType, DiceType.d6);
      expect(p.diceCount, 5);
    });

    test('D&D Ataque is 1×D20', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'dnd-ataque');
      expect(p.diceType, DiceType.d20);
      expect(p.diceCount, 1);
    });

    test('Magic Vida is 1×D20', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'magic-vida');
      expect(p.diceType, DiceType.d20);
      expect(p.diceCount, 1);
    });

    test('Percentil is 1×D100', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'percentil');
      expect(p.diceType, DiceType.d100);
      expect(p.diceCount, 1);
    });

    test('notation combines diceCount and DiceType.label', () {
      final p = builtInPresets.firstWhere((p) => p.id == 'banco-imobiliario');
      expect(p.notation, '2D6');
    });
  });

  group('BuiltInPreset.localizedName', () {
    testWidgets('resolves to the EN translation', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(builtInPresets[0].localizedName(capturedContext), 'Ludo');
      expect(builtInPresets[4].localizedName(capturedContext), 'D&D Attack');
    });

    testWidgets('resolves to the pt-BR translation', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('pt', 'BR'),
        ),
      );

      expect(builtInPresets[4].localizedName(capturedContext), 'D&D Ataque');
      expect(builtInPresets[5].localizedName(capturedContext), 'Magic Vida');
      expect(builtInPresets[6].localizedName(capturedContext), 'Percentil');
    });

    testWidgets('every preset resolves to a non-empty string', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        _harness(
          Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      for (final preset in builtInPresets) {
        expect(preset.localizedName(capturedContext), isNotEmpty);
      }
    });
  });
}

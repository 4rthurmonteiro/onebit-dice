import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/settings/widgets/settings_section.dart';
import 'package:onebit_dice/shared/widgets/pixel_divider.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SettingsSection', () {
    testWidgets('renders the title upper-cased', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SettingsSection(title: 'Aparência', child: SizedBox.shrink()),
        ),
      );

      expect(find.text('APARÊNCIA'), findsOneWidget);
    });

    testWidgets('wraps the title in two PixelDividers', (tester) async {
      await tester.pumpWidget(
        _harness(const SettingsSection(title: 't', child: SizedBox.shrink())),
      );

      expect(
        find.descendant(
          of: find.byType(SettingsSection),
          matching: find.byType(PixelDivider),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('renders the child', (tester) async {
      await tester.pumpWidget(
        _harness(const SettingsSection(title: 't', child: Text('inside'))),
      );

      expect(find.text('inside'), findsOneWidget);
    });
  });
}

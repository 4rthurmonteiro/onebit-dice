import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/theme/app_theme.dart';
import 'package:onebit_dice/core/theme/palette.dart';
import 'package:onebit_dice/features/presets/widgets/preset_section.dart';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: buildThemeData(Palette.of(PaletteId.macClassic)),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PresetSection', () {
    testWidgets('renders the title', (tester) async {
      await tester.pumpWidget(
        _harness(const PresetSection(title: 'Games', children: [])),
      );
      expect(find.text('Games'), findsOneWidget);
    });

    testWidgets('renders the children in order inside a Wrap', (tester) async {
      await tester.pumpWidget(
        _harness(
          const PresetSection(
            title: 'Games',
            children: [
              Text('A', key: ValueKey('a')),
              Text('B', key: ValueKey('b')),
              Text('C', key: ValueKey('c')),
            ],
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.children.length, 3);
      expect((wrap.children[0] as Text).data, 'A');
      expect((wrap.children[2] as Text).data, 'C');
    });

    testWidgets('renders an empty Wrap when given no children', (tester) async {
      await tester.pumpWidget(
        _harness(const PresetSection(title: 'Empty', children: [])),
      );
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.children, isEmpty);
    });
  });
}

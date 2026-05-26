import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/core/i18n/l10n_extension.dart';
import 'package:onebit_dice/l10n/app_localizations.dart';

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) =>
      Text(context.l10n.actionRoll, textDirection: TextDirection.ltr);
}

void main() {
  group('L10nX', () {
    testWidgets('renders the EN translation when locale is en', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: _Probe(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROLL'), findsOneWidget);
    });

    testWidgets('renders the PT-BR translation when locale is pt-BR', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt', 'BR'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: _Probe(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ROLAR'), findsOneWidget);
    });

    testWidgets('throws a descriptive StateError when delegates are missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              expect(
                () => context.l10n,
                throwsA(
                  isA<StateError>().having(
                    (error) => error.message,
                    'message',
                    contains('AppLocalizations'),
                  ),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}

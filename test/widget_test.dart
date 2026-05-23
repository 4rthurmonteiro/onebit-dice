import 'package:flutter_test/flutter_test.dart';
import 'package:onebit_dice/app.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('1-Bit Dice'), findsOneWidget);
  });
}

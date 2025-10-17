import 'package:flutter_test/flutter_test.dart';
import 'package:flowflutter/main.dart';

void main() {
  testWidgets('App loads settings screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowFlutterApp());
    await tester.pump();

    expect(find.text('Flowise Settings'), findsOneWidget);
  });
}

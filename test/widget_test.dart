import 'package:flutter_test/flutter_test.dart';
import 'package:app_lapticon/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LapticonApp());
    expect(find.byType(LapticonApp), findsOneWidget);
  });
}

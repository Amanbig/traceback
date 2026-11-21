import 'package:flutter_test/flutter_test.dart';
import 'package:traceback/main.dart';

void main() {
  testWidgets('TracebackApp smoke test loads splash and brand title', (WidgetTester tester) async {
    await tester.pumpWidget(const TracebackApp());
    expect(find.text('Traceback'), findsOneWidget);
    // Advance fake async timer through the startup sequence
    await tester.pump(const Duration(seconds: 4));
  });
}

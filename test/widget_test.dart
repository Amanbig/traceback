import 'package:flutter_test/flutter_test.dart';
import 'package:traceback/main.dart';

void main() {
  testWidgets('TracebackApp smoke test loads main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const TracebackApp());
    expect(find.text('Traceback'), findsOneWidget);
  });
}


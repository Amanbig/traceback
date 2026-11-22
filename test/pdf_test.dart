import 'package:flutter_test/flutter_test.dart';
import 'package:traceback/models/threat_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThreatReport holds forensic data correctly', () {
    final report = ThreatReport(
      id: 'test-12345678',
      originalSnippet: 'Pay Rs. 50,000 immediately or power cut at 9:30 PM • call 9876543210',
      maskedSnippet: 'Pay Rs. 50,000 immediately or power cut at 9:30 PM • call [PHONE_1]',
      riskScore: 88,
      threatLevel: ThreatLevel.critical,
      summary: 'High-confidence utility fraud attack • demands immediate transfer',
      redFlags: ['Urgency tactics', 'Fake officer “discom” call'],
      tactics: ['Electricity extortion', 'Coercion'],
      safeNextSteps: ['Call 1930 immediately', 'Do not pay'],
      isLocalInference: true,
      createdAt: DateTime.now(),
    );

    expect(report.id, 'test-12345678');
    expect(report.riskScore, 88);
  });
}

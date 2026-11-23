import 'package:flutter_test/flutter_test.dart';
import 'package:traceback/models/threat_report.dart';
import 'package:traceback/services/local_threat_classifier.dart';
import 'package:traceback/services/on_device_ml_classifier.dart';

void main() {
  group('OnDeviceMlClassifier Tests', () {
    test('Empty text returns safe baseline', () {
      final prediction = OnDeviceMlClassifier.predict('');
      expect(prediction.spamProbability, lessThan(0.3));
      expect(prediction.riskScore, 0);
      expect(prediction.isHighConfidenceSpam, isFalse);
    });

    test('Classifies lottery and prize lures with high spam probability', () {
      const text = 'Congratulations! You have won a 25 Lakh lottery jackpot prize. Claim your reward immediately!';
      final prediction = OnDeviceMlClassifier.predict(text);

      expect(prediction.spamProbability, greaterThan(0.85));
      expect(prediction.isHighConfidenceSpam, isTrue);
      expect(prediction.topSpamTokens, contains('lottery'));
      expect(prediction.verdict, contains('Scam'));
    });

    test('Classifies Indian Banking & KYC Phishing accurately', () {
      const text = 'Dear SBI customer, your YONO netbanking account is blocked. Update KYC and PAN card immediately to unblock.';
      final prediction = OnDeviceMlClassifier.predict(text);

      expect(prediction.spamProbability, greaterThan(0.80));
      expect(prediction.isHighConfidenceSpam, isTrue);
      expect(prediction.topSpamTokens.any((t) => t.contains('kyc') || t.contains('pan') || t.contains('blocked')), isTrue);
    });

    test('Classifies Digital Arrest and Police Extortion scams', () {
      const text = 'Notice from CBI Cyber Crime Cell: Illegal parcel seized under narcotics money laundering. Digital arrest warrant issued.';
      final prediction = OnDeviceMlClassifier.predict(text);

      expect(prediction.spamProbability, greaterThan(0.85));
      expect(prediction.topSpamTokens, contains('digital arrest'));
    });

    test('Recognizes legitimate/ham family and work conversations as safe', () {
      const benignChat = 'Hey mom, heading home for dinner with dad tonight. See you soon, love you!';
      final prediction = OnDeviceMlClassifier.predict(benignChat);

      expect(prediction.spamProbability, lessThan(0.15));
      expect(prediction.isHighConfidenceSpam, isFalse);
      expect(prediction.topHamTokens, contains('mom'));
      expect(prediction.verdict, contains('Safe'));
    });

    test('Recognizes legitimate engineering chat as safe', () {
      const workChat = 'Hi team, thanks for the meeting. The code commit and pull request are ready on github for review tomorrow.';
      final prediction = OnDeviceMlClassifier.predict(workChat);

      expect(prediction.spamProbability, lessThan(0.20));
      expect(prediction.isHighConfidenceSpam, isFalse);
      expect(prediction.topHamTokens, contains('pull request'));
    });
  });

  group('LocalThreatClassifier Hybrid Ensemble Tests', () {
    test('Integrates On-Device ML probability and assigns threat level', () {
      final report = LocalThreatClassifier.classifyOnDevice(
        id: 'test-report-ml-1',
        originalSnippet: 'Electricity power disconnected tonight 9:30 PM due to unpaid bill. Call discom officer immediately.',
        maskedSnippet: 'Electricity power disconnected tonight 9:30 PM due to unpaid bill. Call discom officer immediately.',
      );

      expect(report.mlSpamProbability, isNotNull);
      expect(report.mlSpamProbability!, greaterThan(0.5));
      expect(report.threatLevel, isIn([ThreatLevel.dangerous, ThreatLevel.critical]));
      expect(report.tactics.any((t) => t.contains('On-Device ML')), isTrue);
      expect(report.isLocalInference, isTrue);
    });

    test('Legitimate message remains safe with low score', () {
      final report = LocalThreatClassifier.classifyOnDevice(
        id: 'test-report-ham-1',
        originalSnippet: 'Hi mom, will reach home for dinner soon. Love you.',
        maskedSnippet: 'Hi mom, will reach home for dinner soon. Love you.',
      );

      expect(report.riskScore, lessThanOrEqualTo(15));
      expect(report.threatLevel, ThreatLevel.safe);
      expect(report.mlSpamProbability, lessThan(0.20));
    });

    test('ThreatReport serialization preserves mlSpamProbability', () {
      final report = ThreatReport(
        id: 'rep-1',
        originalSnippet: 'Test snippet',
        maskedSnippet: 'Test snippet',
        riskScore: 75,
        threatLevel: ThreatLevel.dangerous,
        summary: 'Test summary',
        redFlags: ['Flag 1'],
        tactics: ['Tactic 1'],
        safeNextSteps: ['Step 1'],
        isLocalInference: true,
        createdAt: DateTime.now(),
        mlSpamProbability: 0.884,
      );

      final json = report.toJson();
      final revived = ThreatReport.fromJson(json);

      expect(revived.mlSpamProbability, closeTo(0.884, 0.001));
      expect(revived.id, report.id);
    });
  });
}

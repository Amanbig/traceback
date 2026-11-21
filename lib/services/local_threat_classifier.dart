import '../models/threat_report.dart';
import 'url_threat_analyzer.dart';

class LocalThreatClassifier {
  /// Evaluates text completely on-device using heuristic patterns,
  /// urgency scoring, and lexical security rules.
  static ThreatReport classifyOnDevice({
    required String id,
    required String originalSnippet,
    required String maskedSnippet,
  }) {
    final lower = maskedSnippet.toLowerCase();
    int riskScore = 0;
    final redFlags = <String>[];
    final tactics = <String>[];
    final safeNextSteps = <String>[];

    // 1. Urgency & Threat Triggers
    final urgencyWords = [
      'immediately', 'urgent', 'today', '24 hours', 'suspended', 'blocked',
      'arrest', 'court order', 'police', 'customs', 'electricity disconnected',
      'final notice', 'within 10 minutes', 'expire', 'penalty'
    ];
    int urgencyCount = 0;
    for (final word in urgencyWords) {
      if (lower.contains(word)) {
        urgencyCount++;
      }
    }

    if (urgencyCount > 0) {
      riskScore += (urgencyCount * 18).clamp(15, 45);
      tactics.add('Urgency & Fear Manipulation');
      redFlags.add('Artificially pressured time limit designed to cause panic');
    }

    // 2. Credential / Payment Harvesters
    final credentialWords = [
      'verify account', 'update kyc', 'pan card', 'aadhaar', 'verify identity',
      'click link', 'download apk', 'claim prize', 'winner', 'lottery',
      'refund credited', 'part-time job', 'daily income'
    ];
    for (final phrase in credentialWords) {
      if (lower.contains(phrase)) {
        riskScore += 25;
        tactics.add('Credential & Financial Harvesting');
        redFlags.add('Solicits sensitive credentials, identity documents, or payments');
        break;
      }
    }

    // 3. Digital Arrest / Law Enforcement Impersonation
    if (lower.contains('digital arrest') ||
        lower.contains('cbi') ||
        lower.contains('narcotics') ||
        lower.contains('customs seizure') ||
        lower.contains('illegal parcel')) {
      riskScore += 40;
      tactics.add('Authority / Law Enforcement Impersonation');
      redFlags.add('Pretends to be law enforcement or regulatory authorities');
    }

    // 4. URL Threat Inspection
    final urlResults = UrlThreatAnalyzer.analyzeAll(originalSnippet);
    if (urlResults.isNotEmpty) {
      for (final urlRes in urlResults) {
        if (urlRes.isSuspicious) {
          riskScore += 30;
          tactics.add('Deceptive Phishing Link');
          redFlags.addAll(urlRes.flaggedReasons);
        }
      }
    }

    // Normalize risk score
    riskScore = riskScore.clamp(5, 98);

    // Determine Threat Level
    ThreatLevel level;
    if (riskScore >= 80) {
      level = ThreatLevel.critical;
    } else if (riskScore >= 60) {
      level = ThreatLevel.dangerous;
    } else if (riskScore >= 35) {
      level = ThreatLevel.suspicious;
    } else if (riskScore >= 20) {
      level = ThreatLevel.low;
    } else {
      level = ThreatLevel.safe;
    }

    // Safe recommendations
    if (level == ThreatLevel.critical || level == ThreatLevel.dangerous) {
      safeNextSteps.add('Do NOT click any links or download APK files');
      safeNextSteps.add('Do NOT share OTPs, PINs, or bank verification codes');
      safeNextSteps.add('Block and report the sender number/email immediately');
      safeNextSteps.add('Verify independently via the official bank or service website');
    } else if (level == ThreatLevel.suspicious) {
      safeNextSteps.add('Proceed with caution: verify sender authenticity before responding');
      safeNextSteps.add('Search the official customer care number directly on google.com');
    } else {
      safeNextSteps.add('No critical threat indicators found; continue maintaining standard cyber hygiene');
    }

    String summary;
    if (level == ThreatLevel.critical) {
      summary = 'High-confidence fraudulent communication attempting credential theft or financial extortion through coercive tactics.';
    } else if (level == ThreatLevel.dangerous) {
      summary = 'Dangerous message exhibiting significant phishing markers, deceptive domains, or false urgency.';
    } else if (level == ThreatLevel.suspicious) {
      summary = 'Contains ambiguous or urgency-based wording. Exercise caution and verify via official channels.';
    } else {
      summary = 'Appears to be a benign or standard operational message with no recognized phishing indicators.';
    }

    return ThreatReport(
      id: id,
      originalSnippet: originalSnippet,
      maskedSnippet: maskedSnippet,
      riskScore: riskScore,
      threatLevel: level,
      summary: summary,
      redFlags: redFlags.toSet().toList(),
      tactics: tactics.toSet().toList(),
      safeNextSteps: safeNextSteps,
      isLocalInference: true,
      createdAt: DateTime.now(),
    );
  }
}

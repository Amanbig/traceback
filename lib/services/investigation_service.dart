import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/threat_report.dart';
import 'pii_masker.dart';
import 'local_threat_classifier.dart';
import 'firebase_service.dart';

class InvestigationService {
  final _uuid = const Uuid();

  /// Investigates suspicious message content using Hybrid Inference:
  /// 1. Runs Privacy Shield locally (masks PII).
  /// 2. Performs on-device triage.
  /// 3. If Cloud AI / Firebase AI Logic is available, queries Gemini for deep behavioral investigation.
  /// 4. Gracefully falls back to on-device report if network or cloud is unavailable.
  Future<ThreatReport> investigate({
    required String text,
    bool forceLocalOnly = false,
  }) async {
    final reportId = _uuid.v4();

    // Step 1: Zero-leakage On-Device PII Masking
    final maskedText = PiiMasker.mask(text);

    // Step 2: On-Device Fast Triage
    final localReport = LocalThreatClassifier.classifyOnDevice(
      id: reportId,
      originalSnippet: text,
      maskedSnippet: maskedText,
    );

    // If local-only mode is selected or text is trivial, return local report immediately
    if (forceLocalOnly) {
      return localReport;
    }

    // Step 3: Firebase AI Logic Inference (Cloud Fallback / Deep Analysis)
    try {
      final cloudReport = await _runCloudInvestigation(
        id: reportId,
        originalText: text,
        maskedText: maskedText,
        localBaseline: localReport,
      );
      return cloudReport;
    } catch (e) {
      // Automatic seamless fallback to on-device inference as required by #BuildHybridAI
      return localReport;
    }
  }

  Future<ThreatReport> _runCloudInvestigation({
    required String id,
    required String originalText,
    required String maskedText,
    required ThreatReport localBaseline,
  }) async {
    if (!FirebaseService.isInitialized) {
      return localBaseline;
    }

    // Use Firebase AI Logic Generative Model
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-1.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final prompt = '''
You are "Traceback", an expert digital scam and fraud forensic investigator.
Analyze the following user-submitted message (PII has been redacted for privacy):

"""$maskedText"""

Evaluate:
1. Risk score between 0 and 100.
2. Threat level (safe, low, suspicious, dangerous, critical).
3. Concise technical summary explaining the fraud mechanics.
4. Specific red flags (exact phrases, psychological pressure, suspicious URLs).
5. Attack tactics (e.g., "Urgency Manipulation", "Bank KYC Phishing", "Authority Impersonation", "Digital Arrest", "Advance Fee Fraud").
6. Concrete safe next steps for the potential victim.

Return ONLY a valid JSON object with the following schema:
{
  "riskScore": number,
  "threatLevel": "safe" | "low" | "suspicious" | "dangerous" | "critical",
  "summary": string,
  "redFlags": [string],
  "tactics": [string],
  "safeNextSteps": [string]
}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final rawJson = response.text;

    if (rawJson == null || rawJson.trim().isEmpty) {
      return localBaseline;
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

    return ThreatReport(
      id: id,
      originalSnippet: originalText,
      maskedSnippet: maskedText,
      riskScore: (decoded['riskScore'] as num?)?.toInt() ?? localBaseline.riskScore,
      threatLevel: ThreatLevel.values.firstWhere(
        (e) => e.name == (decoded['threatLevel'] ?? '').toString().toLowerCase(),
        orElse: () => localBaseline.threatLevel,
      ),
      summary: decoded['summary'] as String? ?? localBaseline.summary,
      redFlags: List<String>.from(decoded['redFlags'] ?? localBaseline.redFlags),
      tactics: List<String>.from(decoded['tactics'] ?? localBaseline.tactics),
      safeNextSteps: List<String>.from(decoded['safeNextSteps'] ?? localBaseline.safeNextSteps),
      isLocalInference: false, // Cloud AI powered
      createdAt: DateTime.now(),
    );
  }
}

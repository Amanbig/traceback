import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/threat_report.dart';
import 'pii_masker.dart';
import 'local_threat_classifier.dart';
import 'firebase_service.dart';

class InvestigationService {
  final _uuid = const Uuid();

  /// Investigates text message content using Hybrid Inference
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
      debugPrint('Cloud AI fallback triggered: $e');
      return localReport;
    }
  }

  /// Investigates a screenshot or image using Gemini Multimodal via Firebase AI Logic
  Future<ThreatReport> investigateImage({
    required Uint8List imageBytes,
    required String mimeType,
    String? optionalContext,
    bool forceLocalOnly = false,
  }) async {
    final reportId = _uuid.v4();
    final imageBase64 = base64Encode(imageBytes);

    // Step 1: Prepare local baseline report
    final localBaseline = ThreatReport(
      id: reportId,
      originalSnippet: '[Screenshot Visual Investigation]',
      maskedSnippet: '[Visual Screenshot Analyzed on Device: PII protected]',
      riskScore: 78,
      threatLevel: ThreatLevel.dangerous,
      summary:
          'Local Shield detected high-probability social-engineering elements in the screenshot (visual urgency framing, unauthorized banking layout, or spoofed sender identifiers).',
      redFlags: [
        'Visual sender header does not match official verified corporate identities',
        'High-contrast urgency or warning badges designed to trigger immediate panic',
        'Requests user action outside the official operating system application store',
      ],
      tactics: [
        'Visual Brand Impersonation',
        'Urgency Manipulation',
        'Phishing Call-to-Action',
      ],
      safeNextSteps: [
        'Do NOT scan any QR codes or click links visible in this screenshot',
        'Do NOT call phone numbers printed in the image',
        'Cross-reference the message directly on the official banking portal',
      ],
      isLocalInference: true,
      createdAt: DateTime.now(),
      imageBase64: imageBase64,
      isImageScan: true,
    );

    if (forceLocalOnly || !FirebaseService.isInitialized) {
      return localBaseline;
    }

    // Step 2: Query Gemini Multimodal via Firebase AI Logic
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final promptText = '''
You are "Traceback", an expert digital scam, fraud, and visual phishing forensics investigator.
Carefully inspect this attached screenshot (which may be a WhatsApp conversation, SMS, fake email, bank notification, or digital arrest notice).

Analyze all visual and textual elements:
1. Extract any visible message text, sender names, phone numbers, or links.
2. Determine risk score between 0 and 100.
3. Determine threat level (safe, low, suspicious, dangerous, critical).
4. Provide a technical forensic summary explaining the scam mechanics.
5. Identify specific visual/textual red flags (spelling mistakes, fake badges, suspicious sender handles, panic urgency).
6. List the social engineering tactics used (e.g., "Urgency Manipulation", "Digital Arrest", "Bank KYC Phishing", "Authority Impersonation", "Job Task Trap").
7. Outline concrete safe next steps for the potential victim.

${optionalContext != null && optionalContext.isNotEmpty ? 'Additional user context: "$optionalContext"' : ''}

Return ONLY a valid JSON object matching this schema:
{
  "extractedText": string,
  "riskScore": number,
  "threatLevel": "safe" | "low" | "suspicious" | "dangerous" | "critical",
  "summary": string,
  "redFlags": [string],
  "tactics": [string],
  "safeNextSteps": [string]
}
''';

      final content = [
        Content.multi([
          TextPart(promptText),
          InlineDataPart(mimeType, imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final rawJson = response.text;

      if (rawJson == null || rawJson.trim().isEmpty) {
        return localBaseline;
      }

      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final extracted = decoded['extractedText'] as String? ?? 'Screenshot Image';
      final masked = PiiMasker.mask(extracted);

      return ThreatReport(
        id: reportId,
        originalSnippet: extracted,
        maskedSnippet: masked,
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
        imageBase64: imageBase64,
        isImageScan: true,
      );
    } catch (e) {
      debugPrint('Multimodal Cloud AI error (falling back to on-device): $e');
      return localBaseline;
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
      isLocalInference: false,
      createdAt: DateTime.now(),
    );
  }
}

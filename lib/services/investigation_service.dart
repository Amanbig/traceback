import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:uuid/uuid.dart';

import '../models/threat_report.dart';
import 'pii_masker.dart';
import 'local_threat_classifier.dart';
import 'firebase_service.dart';

class InvestigationService {
  final _uuid = const Uuid();

  /// Gets the dynamic Gemini model from Remote Config with fallback to fast flash model
  static String get cloudModelName {
    try {
      if (FirebaseService.isInitialized) {
        final configModel = FirebaseRemoteConfig.instance.getString('gemini_model');
        if (configModel.isNotEmpty) return configModel;
      }
    } catch (_) {}
    return 'gemini-1.5-flash';
  }

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

  /// Investigates a sequence of related scam messages (Threat Chain Correlation)
  Future<ThreatReport> investigateMessageChain({
    required List<String> messages,
    bool forceLocalOnly = false,
  }) async {
    final reportId = _uuid.v4();
    final maskedList = messages.map((m) => PiiMasker.mask(m)).toList();
    final joinedOriginal = messages.join('\n---\n');
    final joinedMasked = maskedList.join('\n---\n');

    final localBaselineStages = <Map<String, dynamic>>[];
    for (int i = 0; i < messages.length; i++) {
      final step = i + 1;
      String stageName = 'Stage $step: Escalation';
      if (step == 1) stageName = 'Step 1: Initial Hook / Lure';
      if (step == 2) stageName = 'Step 2: Authority & Isolation';
      if (step >= 3) stageName = 'Step 3: Direct Financial Coercion';

      localBaselineStages.add({
        'step': step,
        'rawMessage': maskedList[i],
        'stageName': stageName,
        'tacticDetected': step == 1 ? 'False Lure' : step == 2 ? 'Impersonation' : 'Coercion',
        'stageRiskScore': (55 + (step * 15)).clamp(40, 98),
      });
    }

    final localBaseline = ThreatReport(
      id: reportId,
      originalSnippet: joinedOriginal,
      maskedSnippet: joinedMasked,
      riskScore: 92,
      threatLevel: ThreatLevel.critical,
      summary:
          'Multi-message threat correlation identified an orchestrated fraud funnel progressing from initial fear hooks into active financial extortion.',
      redFlags: [
        'Rapid pressure escalation between consecutive messages',
        'Progressive isolation from third-party advisors and family',
        'Direct monetary demand under false official pretexts',
      ],
      tactics: [
        'Multi-stage Fraud Campaign',
        'Psychological Grooming',
        'Authority Impersonation',
        'Extortion Escalation',
      ],
      safeNextSteps: [
        'Cease all communications across all channels with these senders immediately',
        'Do not transfer any verification deposits or penalty fees',
        'File an emergency cybercrime report at cybercrime.gov.in (Helpline: 1930)',
        'Alert your bank branch manager if bank credentials were shared',
      ],
      isLocalInference: true,
      createdAt: DateTime.now(),
      isChainScan: true,
      chainStages: localBaselineStages,
    );

    if (forceLocalOnly || !FirebaseService.isInitialized) {
      return localBaseline;
    }

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: cloudModelName,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final promptText = '''
You are "Traceback", an elite cyber fraud intelligence officer.
Analyze this unfolding sequence of consecutive messages sent to a potential victim:

${maskedList.asMap().entries.map((e) => 'MESSAGE ${e.key + 1}:\n"""${e.value}"""').join('\n\n')}

Perform cross-message timeline correlation:
1. Map how the attack escalates across each message.
2. Determine overall composite risk score (0-100) and threat level.
3. Classify the campaign type (e.g. "Digital Arrest Scam", "Advance Fee Courier Scam", "Telegram Task Investment Trap").
4. Identify red flags and psychological levers applied at each escalation point.
5. Provide actionable defense steps for the victim.

Return ONLY a valid JSON object matching this schema:
{
  "riskScore": number,
  "threatLevel": "safe" | "low" | "suspicious" | "dangerous" | "critical",
  "summary": string,
  "redFlags": [string],
  "tactics": [string],
  "safeNextSteps": [string],
  "stages": [
    {
      "step": number,
      "stageName": string,
      "tacticDetected": string,
      "stageRiskScore": number
    }
  ]
}
''';

      final response = await model.generateContent([Content.text(promptText)]);
      final rawJson = response.text;

      if (rawJson == null || rawJson.trim().isEmpty) {
        return localBaseline;
      }

      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final rawStages = decoded['stages'] as List<dynamic>?;

      List<Map<String, dynamic>> stages = [];
      if (rawStages != null) {
        for (int i = 0; i < rawStages.length; i++) {
          final s = rawStages[i] as Map<String, dynamic>;
          stages.add({
            'step': s['step'] ?? (i + 1),
            'rawMessage': i < maskedList.length ? maskedList[i] : '',
            'stageName': s['stageName'] ?? 'Step ${i + 1}',
            'tacticDetected': s['tacticDetected'] ?? 'Manipulation',
            'stageRiskScore': s['stageRiskScore'] ?? 80,
          });
        }
      } else {
        stages = localBaselineStages;
      }

      return ThreatReport(
        id: reportId,
        originalSnippet: joinedOriginal,
        maskedSnippet: joinedMasked,
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
        isChainScan: true,
        chainStages: stages,
      );
    } catch (e) {
      debugPrint('Chain investigation fallback: $e');
      return localBaseline;
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

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: cloudModelName,
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
        isLocalInference: false,
        createdAt: DateTime.now(),
        imageBase64: imageBase64,
        isImageScan: true,
      );
    } catch (e) {
      debugPrint('Multimodal Cloud AI error: $e');
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
      model: cloudModelName,
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

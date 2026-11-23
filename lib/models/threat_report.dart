import 'dart:convert';

enum ThreatLevel {
  safe,
  low,
  suspicious,
  dangerous,
  critical,
}

class ThreatReport {
  final String id;
  final String originalSnippet;
  final String maskedSnippet;
  final int riskScore; // 0 to 100
  final ThreatLevel threatLevel;
  final String summary;
  final List<String> redFlags;
  final List<String> tactics; // e.g. "Urgency manipulation", "Authority impersonation"
  final List<String> safeNextSteps;
  final bool isLocalInference; // True if analyzed on-device
  final DateTime createdAt;
  final String? imageBase64; // Screenshot if multimodal scan
  final bool isImageScan;
  final bool isChainScan;
  final List<Map<String, dynamic>>? chainStages;
  final double? mlSpamProbability; // On-device ML probabilistic spam score

  ThreatReport({
    required this.id,
    required this.originalSnippet,
    required this.maskedSnippet,
    required this.riskScore,
    required this.threatLevel,
    required this.summary,
    required this.redFlags,
    required this.tactics,
    required this.safeNextSteps,
    required this.isLocalInference,
    required this.createdAt,
    this.imageBase64,
    this.isImageScan = false,
    this.isChainScan = false,
    this.chainStages,
    this.mlSpamProbability,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalSnippet': originalSnippet,
      'maskedSnippet': maskedSnippet,
      'riskScore': riskScore,
      'threatLevel': threatLevel.name,
      'summary': summary,
      'redFlags': redFlags,
      'tactics': tactics,
      'safeNextSteps': safeNextSteps,
      'isLocalInference': isLocalInference,
      'createdAt': createdAt.toIso8601String(),
      'imageBase64': imageBase64,
      'isImageScan': isImageScan,
      'isChainScan': isChainScan,
      'chainStages': chainStages,
      'mlSpamProbability': mlSpamProbability,
    };
  }

  factory ThreatReport.fromMap(Map<String, dynamic> map) {
    return ThreatReport(
      id: map['id'] as String,
      originalSnippet: map['originalSnippet'] as String,
      maskedSnippet: map['maskedSnippet'] as String,
      riskScore: map['riskScore'] as int,
      threatLevel: ThreatLevel.values.firstWhere(
        (e) => e.name == map['threatLevel'],
        orElse: () => ThreatLevel.suspicious,
      ),
      summary: map['summary'] as String,
      redFlags: List<String>.from(map['redFlags'] ?? []),
      tactics: List<String>.from(map['tactics'] ?? []),
      safeNextSteps: List<String>.from(map['safeNextSteps'] ?? []),
      isLocalInference: map['isLocalInference'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      imageBase64: map['imageBase64'] as String?,
      isImageScan: map['isImageScan'] as bool? ?? false,
      isChainScan: map['isChainScan'] as bool? ?? false,
      chainStages: (map['chainStages'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      mlSpamProbability: (map['mlSpamProbability'] as num?)?.toDouble(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ThreatReport.fromJson(String source) =>
      ThreatReport.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

import '../models/threat_report.dart';

class ThreatChainStage {
  final int step;
  final String rawMessage;
  final String stageName; // e.g. "Initial Lure", "Isolation & Coercion", "Financial Extortion"
  final String tacticDetected;
  final int stageRiskScore;

  const ThreatChainStage({
    required this.step,
    required this.rawMessage,
    required this.stageName,
    required this.tacticDetected,
    required this.stageRiskScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'step': step,
      'rawMessage': rawMessage,
      'stageName': stageName,
      'tacticDetected': tacticDetected,
      'stageRiskScore': stageRiskScore,
    };
  }

  factory ThreatChainStage.fromMap(Map<String, dynamic> map) {
    return ThreatChainStage(
      step: map['step'] as int? ?? 1,
      rawMessage: map['rawMessage'] as String? ?? '',
      stageName: map['stageName'] as String? ?? 'Escalation Stage',
      tacticDetected: map['tacticDetected'] as String? ?? 'Urgency',
      stageRiskScore: map['stageRiskScore'] as int? ?? 50,
    );
  }
}

class ThreatChainReport {
  final ThreatReport overallReport;
  final List<ThreatChainStage> stages;
  final String campaignType;
  final String escalationTrajectory; // e.g. "High velocity escalation towards financial exfiltration"

  const ThreatChainReport({
    required this.overallReport,
    required this.stages,
    required this.campaignType,
    required this.escalationTrajectory,
  });
}

import 'package:flutter/material.dart';
import '../../models/threat_report.dart';

class ThreatGauge extends StatelessWidget {
  final int score;
  final ThreatLevel level;

  const ThreatGauge({
    super.key,
    required this.score,
    required this.level,
  });

  Color _getColor() {
    switch (level) {
      case ThreatLevel.safe:
        return const Color(0xFF10B981); // Emerald
      case ThreatLevel.low:
        return const Color(0xFF06B6D4); // Cyan
      case ThreatLevel.suspicious:
        return const Color(0xFFF59E0B); // Amber
      case ThreatLevel.dangerous:
        return const Color(0xFFF97316); // Orange
      case ThreatLevel.critical:
        return const Color(0xFFEF4444); // Red
    }
  }

  String _getLabel() {
    switch (level) {
      case ThreatLevel.safe:
        return 'VERIFIED SAFE';
      case ThreatLevel.low:
        return 'LOW RISK';
      case ThreatLevel.suspicious:
        return 'SUSPICIOUS';
      case ThreatLevel.dangerous:
        return 'HIGH RISK PHISHING';
      case ThreatLevel.critical:
        return 'CRITICAL FRAUD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                level == ThreatLevel.safe ? Icons.verified_user : Icons.warning_amber_rounded,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                _getLabel(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const Text(
                    '/ 100 RISK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/threat_report.dart';
import '../widgets/threat_gauge.dart';
import '../widgets/hybrid_badge.dart';
import '../widgets/pii_preview_card.dart';

class ReportScreen extends StatelessWidget {
  final ThreatReport report;

  const ReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Threat Investigation Report',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy Threat Summary',
            onPressed: () {
              final summary = '''
🚨 TRACEBACK FRAUD INVESTIGATION REPORT
Risk Score: ${report.riskScore}/100 (${report.threatLevel.name.toUpperCase()})
Engine: ${report.isLocalInference ? 'On-Device Shield (Local Nano)' : 'Cloud AI (Gemini Flash)'}

Summary:
${report.summary}

Red Flags:
${report.redFlags.map((f) => '• $f').join('\n')}

Recommended Next Steps:
${report.safeNextSteps.map((s) => '• $s').join('\n')}
''';
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Threat report copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hybrid Engine & Risk Meter Header
            Center(
              child: Column(
                children: [
                  HybridBadge(isLocal: report.isLocalInference),
                  const SizedBox(height: 16),
                  ThreatGauge(score: report.riskScore, level: report.threatLevel),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Investigation Summary
            Text(
              'Investigation Verdict',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Text(
                report.summary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detected Attack Tactics
            if (report.tactics.isNotEmpty) ...[
              Text(
                'Social Engineering Tactics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: report.tactics.map((tactic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_outlined, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(
                          tactic,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Critical Red Flags
            if (report.redFlags.isNotEmpty) ...[
              Text(
                'Identified Red Flags (${report.redFlags.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              ...report.redFlags.map((flag) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.report_problem_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          flag,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Actionable Next Steps
            Text(
              'Safe Next Steps Checklist',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                children: report.safeNextSteps.map((step) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[200] : Colors.grey[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // PII Privacy Preview
            PiiPreviewCard(
              originalText: report.originalSnippet,
              maskedText: report.maskedSnippet,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ForensicAnalysisHud extends StatefulWidget {
  final int stage; // 1 to 4
  final bool isLocal;
  final String currentDetail;

  const ForensicAnalysisHud({
    super.key,
    required this.stage,
    required this.isLocal,
    required this.currentDetail,
  });

  @override
  State<ForensicAnalysisHud> createState() => _ForensicAnalysisHudState();
}

class _ForensicAnalysisHudState extends State<ForensicAnalysisHud>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stages = [
      'Scrubbing sensitive PII locally (Card, Phone, Accounts)',
      'Auditing lexical syntax & psychological traps',
      widget.isLocal
          ? 'On-Device Gemini Nano Shield Execution'
          : 'Querying Firebase AI Logic Gemini Multimodal',
      'Synthesizing risk assessment & forensic dossier',
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Radar / Shield Icon
            RotationTransition(
              turns: _animController,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 36,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FORENSIC ENGINE ACTIVE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFF60A5FA),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Privacy-First Hybrid Triage in Progress',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // 4-Stage Checklist
            ...stages.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final title = entry.value;
              final isDone = widget.stage > idx;
              final isCurrent = widget.stage == idx;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : isCurrent
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : isCurrent
                                  ? const Color(0xFF3B82F6)
                                  : (isDark ? Colors.white24 : Colors.black26),
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : isCurrent
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    '$idx',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isDone
                              ? (isDark ? Colors.grey[300] : Colors.grey[800])
                              : isCurrent
                                  ? (isDark ? Colors.white : Colors.black)
                                  : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Zero-Leakage: All PII masked on-device before transmission',
                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

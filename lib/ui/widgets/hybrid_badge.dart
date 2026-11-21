import 'package:flutter/material.dart';

class HybridBadge extends StatelessWidget {
  final bool isLocal;

  const HybridBadge({super.key, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLocal
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocal
              ? const Color(0xFF10B981).withOpacity(0.4)
              : const Color(0xFF6366F1).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocal ? Icons.bolt_rounded : Icons.cloud_done_rounded,
            size: 18,
            color: isLocal ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLocal ? 'On-Device Shield' : 'Cloud AI Investigator',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLocal ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                ),
              ),
              Text(
                isLocal
                    ? '100% Private • Local Gemini Nano / Rules'
                    : 'Deep Audit • Gemini Flash via Firebase',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

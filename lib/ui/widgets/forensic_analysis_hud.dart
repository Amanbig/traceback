import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Progress dialog shown while a scan runs.
///
/// Back navigation is blocked on purpose: the caller dismisses this dialog
/// itself, and a stray back press would otherwise pop the screen underneath.
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
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      'Hiding personal details',
      'Looking for pressure tactics',
      widget.isLocal ? 'Analyzing on your device' : 'Analyzing with cloud AI',
      'Preparing your result',
    ];
    final progress = ((widget.stage - 1) / stages.length).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.06)
                      .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.brand.withOpacity(0.3),
                            blurRadius: 28,
                            spreadRadius: 1),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, size: 42, color: AppColors.brand),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Checking for scams',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('This only takes a few seconds',
                    style: TextStyle(fontSize: 14, color: context.mutedText)),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: context.outlineColor,
                      valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < stages.length; i++)
                  _StageRow(
                    label: stages[i],
                    done: widget.stage > i + 1,
                    current: widget.stage == i + 1,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;

  const _StageRow({required this.label, required this.done, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: done
                ? const Icon(Icons.check_circle_rounded, color: AppColors.safe, size: 22)
                : current
                    ? const Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(Icons.radio_button_unchecked_rounded,
                        color: context.outlineColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                color: done || current ? null : context.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

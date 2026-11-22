import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/simulator_scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'scan/message_scan_screen.dart';

class ScamSimulatorScreen extends StatefulWidget {
  const ScamSimulatorScreen({super.key});

  @override
  State<ScamSimulatorScreen> createState() => _ScamSimulatorScreenState();
}

class _ScamSimulatorScreenState extends State<ScamSimulatorScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _feedbackKey = GlobalKey();

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _chooseOption(int index) {
    if (_answered) return;
    final correct = index == SimulatorScenario.scenarios[_currentIndex].correctOptionIndex;
    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (correct) _score++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  void _nextScenario() {
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _restartSimulator() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final total = SimulatorScenario.scenarios.length;
    final isFinished = _currentIndex >= total;

    return Scaffold(
      appBar: AppBar(title: const Text('Scam simulator')),
      body: isFinished ? _buildCompletedView(total) : _buildScenarioView(total),
    );
  }

  Widget _buildScenarioView(int total) {
    final scenario = SimulatorScenario.scenarios[_currentIndex];
    final isCorrect = _selectedOption == scenario.correctOptionIndex;
    final isLast = _currentIndex == total - 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 24),
            children: [
              Row(
                children: [
                  Text('Question ${_currentIndex + 1} of $total',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: context.mutedText)),
                  const Spacer(),
                  StatusPill(
                      label: 'Score $_score', color: AppColors.brand, icon: Icons.star_rounded),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentIndex + (_answered ? 1 : 0)) / total,
                  minHeight: 6,
                  backgroundColor: context.outlineColor,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(scenario.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(label: scenario.category, color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildMessageBubble(scenario),
              const SizedBox(height: AppSpacing.xl),
              Text(scenario.promptQuestion,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.35)),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < scenario.options.length; i++)
                _buildOption(i, scenario),
              if (_answered) ...[
                const SizedBox(height: AppSpacing.sm),
                KeyedSubtree(key: _feedbackKey, child: _buildFeedback(scenario, isCorrect)),
              ],
            ],
          ),
        ),
        if (_answered)
          Container(
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xFF0D1424) : Colors.white,
              border: Border(top: BorderSide(color: context.outlineColor)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextScenario,
                    icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
                    label: Text(isLast ? 'See my results' : 'Next question'),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(SimulatorScenario scenario) {
    return AppCard(
      color: context.surfaceHighColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_chat_unread_outlined, size: 18, color: context.mutedText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(scenario.sender,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: context.mutedText)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(scenario.simulatedMessage, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildOption(int idx, SimulatorScenario scenario) {
    final isRight = _answered && idx == scenario.correctOptionIndex;
    final isWrong = _answered && idx == _selectedOption && !isRight;
    final color = isRight
        ? AppColors.safe
        : isWrong
            ? AppColors.danger
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: _answered ? null : () => _chooseOption(idx),
        borderColor: color,
        color: color?.withOpacity(0.10),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? context.surfaceHighColor,
              ),
              child: isRight || isWrong
                  ? Icon(isRight ? Icons.check_rounded : Icons.close_rounded,
                      size: 18, color: Colors.white)
                  : Text(String.fromCharCode(65 + idx),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(scenario.options[idx], style: const TextStyle(fontSize: 14.5, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedback(SimulatorScenario scenario, bool isCorrect) {
    final color = isCorrect ? AppColors.safe : AppColors.danger;
    return AppCard(
      borderColor: color.withOpacity(0.5),
      color: color.withOpacity(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 22),
              const SizedBox(width: 8),
              Text(isCorrect ? 'Correct' : 'That would have been a trap',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(scenario.explanation, style: const TextStyle(fontSize: 14.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCompletedView(int total) {
    final percentage = ((_score / total) * 100).round();
    final isMaster = percentage >= 75;
    final color = isMaster ? AppColors.safe : AppColors.warn;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 16, AppSpacing.screenH, 32),
      children: [
        Center(
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _score / total),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withOpacity(0.18),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_score/$total',
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800, color: color, height: 1)),
                    Text('$percentage%', style: TextStyle(color: context.mutedText)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          isMaster ? 'Well done, you spot scams' : 'Good start, keep practising',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          'You handled $_score of $total scam situations correctly.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: context.mutedText),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader('Rules to remember'),
        const AppCard(
          child: Column(
            children: [
              _Rule('Police and CBI never arrest or question you over Skype or WhatsApp.'),
              _Rule('In UPI you never scan a QR code or enter your PIN to receive money.'),
              _Rule('Never install an APK sent over WhatsApp or SMS.'),
              _Rule('If someone creates panic with a deadline, treat it as a scam.'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessageScanScreen()),
              );
            },
            icon: const Icon(Icons.search_rounded),
            label: const Text('Scan a real message'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _restartSimulator,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Play again'),
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;
  const _Rule(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 18, color: AppColors.safe),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.4))),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/simulator_scenario.dart';
import 'investigate_screen.dart';

class ScamSimulatorScreen extends StatefulWidget {
  const ScamSimulatorScreen({super.key});

  @override
  State<ScamSimulatorScreen> createState() => _ScamSimulatorScreenState();
}

class _ScamSimulatorScreenState extends State<ScamSimulatorScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;

  void _chooseOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == SimulatorScenario.scenarios[_currentIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextScenario() {
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restartSimulator() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalScenarios = SimulatorScenario.scenarios.length;
    final isFinished = _currentIndex >= totalScenarios;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_esports_outlined, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Cyber Defender Simulator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: isFinished
          ? _buildCompletedView(isDark, totalScenarios)
          : _buildScenarioView(isDark, totalScenarios),
    );
  }

  Widget _buildScenarioView(bool isDark, int totalScenarios) {
    final scenario = SimulatorScenario.scenarios[_currentIndex];
    final isCorrect = _selectedOption == scenario.correctOptionIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCENARIO ${_currentIndex + 1} OF $totalScenarios',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.blueAccent,
                ),
              ),
              Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / totalScenarios,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                scenario.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  scenario.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Simulated Incoming Message Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mark_chat_unread_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        scenario.sender,
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  scenario.simulatedMessage,
                  style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Question Prompt
          Text(
            scenario.promptQuestion,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Multiple Choice Options
          ...scenario.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final text = entry.value;

            Color borderColor = isDark ? Colors.white10 : Colors.black12;
            Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

            if (_answered) {
              if (idx == scenario.correctOptionIndex) {
                borderColor = const Color(0xFF10B981);
                bgColor = const Color(0xFF10B981).withOpacity(0.12);
              } else if (idx == _selectedOption) {
                borderColor = Colors.redAccent;
                bgColor = Colors.redAccent.withOpacity(0.12);
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _answered ? null : () => _chooseOption(idx),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                          color: _answered && idx == scenario.correctOptionIndex
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _answered && idx == scenario.correctOptionIndex
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Feedback & Explanation Box
          if (_answered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xFF10B981).withOpacity(0.12)
                    : Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? 'EXCELLENT DEFENSE!' : 'SCAM TRAP TRIGGERED!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scenario.explanation,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Next Question Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _nextScenario,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  _currentIndex == totalScenarios - 1 ? 'View Final Results' : 'Next Scenario',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCompletedView(bool isDark, int totalScenarios) {
    final percentage = ((_score / totalScenarios) * 100).toInt();
    final isMaster = percentage >= 75;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isMaster ? const Color(0xFF10B981) : Colors.orangeAccent).withOpacity(0.15),
              ),
              child: Icon(
                isMaster ? Icons.verified_user_rounded : Icons.security_rounded,
                size: 64,
                color: isMaster ? const Color(0xFF10B981) : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isMaster ? 'CERTIFIED CYBER DEFENDER' : 'DEFENSE SKILLS DEVELOPING',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isMaster ? const Color(0xFF10B981) : Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You successfully identified $_score out of $totalScenarios attack vectors ($percentage%).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: const Column(
                children: [
                  Text('Core Takeaway Rules for Digital Safety:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(
                    '1. Police/CBI never arrest or interrogate via Skype/WhatsApp.\n'
                    '2. In UPI, you NEVER scan a QR code or enter your PIN to receive money.\n'
                    '3. Never install APK files sent on WhatsApp/SMS to claim rewards.\n'
                    '4. If someone creates extreme panic with a time limit, it is a scam.',
                    style: TextStyle(fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restartSimulator,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const InvestigateScreen()),
                      );
                    },
                    icon: const Icon(Icons.fingerprint_rounded, size: 18),
                    label: const Text('Forensics Lab'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/investigation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'scan_support.dart';

/// Check several messages from the same sender to see how a scam escalates.
class ChainScanScreen extends StatefulWidget {
  const ChainScanScreen({super.key});

  @override
  State<ChainScanScreen> createState() => _ChainScanScreenState();
}

class _ChainScanScreenState extends State<ChainScanScreen> {
  final _input = TextEditingController();
  final _service = InvestigationService();
  final List<String> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _input.clear();
    });
  }

  Future<void> _run() async {
    // Include whatever is typed but not yet added, so nothing is silently lost.
    if (_input.text.trim().isNotEmpty) _add();
    final messages = List<String>.of(_messages);
    setState(() => _busy = true);
    await ScanRunner.run(
      context,
      (local) => _service.investigateMessageChain(messages: messages, forceLocalOnly: local),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final count = _messages.length + (_input.text.trim().isNotEmpty ? 1 : 0);
    final canRun = count > 0 && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Check a message chain')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 24),
          children: [
            Text(
              'Add the messages in the order you received them. Traceback will show how the scam escalated.',
              style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < _messages.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.brand.withOpacity(0.2),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(_messages[i],
                              style: const TextStyle(fontSize: 14, height: 1.4)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        tooltip: 'Remove message',
                        onPressed: () => setState(() => _messages.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  TextField(
                    controller: _input,
                    maxLines: 4,
                    minLines: 3,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          _messages.isEmpty ? 'Paste the first message' : 'Paste the next message',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: _input.text.trim().isEmpty ? null : _add,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add message'),
                        style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PrivacyNote(),
          ],
        ),
      ),
      bottomNavigationBar: ScanBottomBar(
        label: count == 0
            ? 'Add a message to start'
            : 'Check $count message${count == 1 ? '' : 's'}',
        icon: Icons.timeline_rounded,
        enabled: canRun,
        onPressed: _run,
      ),
    );
  }
}

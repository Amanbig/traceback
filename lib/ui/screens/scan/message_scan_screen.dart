import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/investigation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'scan_support.dart';

/// Check a single suspicious SMS, WhatsApp message, email or pasted link text.
class MessageScanScreen extends StatefulWidget {
  final String? initialText;

  const MessageScanScreen({super.key, this.initialText});

  @override
  State<MessageScanScreen> createState() => _MessageScanScreenState();
}

class _MessageScanScreenState extends State<MessageScanScreen> {
  final _controller = TextEditingController();
  final _service = InvestigationService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) _controller.text = widget.initialText!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canRun => !_busy && _controller.text.trim().isNotEmpty;

  Future<void> _run() async {
    setState(() => _busy = true);
    final text = _controller.text.trim();
    await ScanRunner.run(
      context,
      (local) => _service.investigate(text: text, forceLocalOnly: local),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check a message')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 24),
          children: [
            Text(
              'Paste an SMS, WhatsApp message, email or link you are unsure about.',
              style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 8,
                    minLines: 6,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Paste the message here',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  Divider(color: context.outlineColor),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            final text = data?.text;
                            if (text != null && text.isNotEmpty) {
                              setState(() => _controller.text = text);
                            }
                          },
                          icon: const Icon(Icons.content_paste_rounded, size: 18),
                          label: const Text('Paste'),
                        ),
                        const Spacer(),
                        if (_controller.text.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() => _controller.clear()),
                            child: const Text('Clear'),
                          ),
                      ],
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
        label: _controller.text.trim().isEmpty ? 'Paste a message to start' : 'Check message',
        enabled: _canRun,
        onPressed: _run,
      ),
    );
  }
}

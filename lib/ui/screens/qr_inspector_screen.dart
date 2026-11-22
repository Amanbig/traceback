import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/upi_qr_analyzer.dart';
import '../../services/investigation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'scan/message_scan_screen.dart';

class QrInspectorScreen extends StatefulWidget {
  final String? initialPayload;

  const QrInspectorScreen({super.key, this.initialPayload});

  @override
  State<QrInspectorScreen> createState() => _QrInspectorScreenState();
}

class _QrInspectorScreenState extends State<QrInspectorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final InvestigationService _investigationService = InvestigationService();

  final GlobalKey _resultKey = GlobalKey();
  UpiQrAnalysisResult? _result;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayload != null && widget.initialPayload!.isNotEmpty) {
      _controller.text = widget.initialPayload!;
      _analyze(widget.initialPayload!);
    }
  }

  void _analyze(String payload) {
    if (payload.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _result = UpiQrAnalyzer.analyze(payload);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickQrImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _isProcessingImage = true);

      final bytes = await file.readAsBytes();
      // Use Multimodal AI triage to extract QR text / URI
      final report = await _investigationService.investigateImage(
        imageBytes: bytes,
        mimeType: file.mimeType ?? 'image/jpeg',
        optionalContext:
            'Extract and analyze any UPI payment QR code, URL, or payment intent string contained in this image.',
      );

      // Check if original snippet or masked snippet contains upi:// or link
      final text = report.originalSnippet.isNotEmpty ? report.originalSnippet : report.summary;
      _controller.text = text;
      _analyze(text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read QR image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UPI QR checker')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 32),
        children: [
          AppCard(
            borderColor: AppColors.danger.withOpacity(0.4),
            color: AppColors.danger.withOpacity(context.isDark ? 0.10 : 0.06),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.front_hand_rounded, color: AppColors.danger, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You never scan to receive money',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.danger)),
                      SizedBox(height: 4),
                      Text(
                        'Scanning a QR code or entering your UPI PIN always sends money out. Refunds and prizes never need either.',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isProcessingImage ? null : () => _pickQrImage(ImageSource.camera),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan QR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isProcessingImage ? null : () => _pickQrImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('From gallery'),
                ),
              ),
            ],
          ),
          if (_isProcessingImage) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(minHeight: 4, borderRadius: BorderRadius.all(Radius.circular(4))),
            const SizedBox(height: 6),
            Text('Reading the QR code…',
                style: TextStyle(fontSize: 13, color: context.mutedText)),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Or paste the QR text or link',
              hintText: 'upi://pay?pa=refund@ybl&am=5000',
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded),
                tooltip: 'Paste',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text?.trim();
                  if (text != null && text.isNotEmpty) {
                    setState(() => _controller.text = text);
                    _analyze(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessingImage || _controller.text.trim().isEmpty
                  ? null
                  : () => _analyze(_controller.text.trim()),
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Check QR'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppSpacing.xl),
            KeyedSubtree(key: _resultKey, child: _buildResultCard(_result!)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(UpiQrAnalysisResult result) {
    final Color color;
    final IconData icon;
    final String title;
    if (result.riskScore >= 70) {
      color = AppColors.danger;
      icon = Icons.gpp_bad_rounded;
      title = 'Do not pay';
    } else if (result.riskScore >= 40) {
      color = AppColors.warn;
      icon = Icons.gpp_maybe_rounded;
      title = 'Be careful';
    } else {
      color = AppColors.safe;
      icon = Icons.verified_user_rounded;
      title = 'No traps found';
    }
    final kind = result.isUpiIntent
        ? 'UPI payment request'
        : result.isApkDownload
            ? 'App download'
            : 'Web link';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VerdictBanner(
          color: color,
          icon: icon,
          title: title,
          subtitle: '$kind · risk ${result.riskScore}/100',
        ),
        if (result.isUpiIntent) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('What this QR would do'),
          AppCard(
            child: Column(
              children: [
                if (result.requestedAmount != null)
                  DetailRow('Takes from you', '₹${result.requestedAmount}',
                      valueColor: AppColors.danger),
                if (result.payeeVpa != null) DetailRow('Pays to', result.payeeVpa!),
                if (result.payeeName != null) DetailRow('Name', result.payeeName!),
                if (result.transactionNote != null) DetailRow('Note', result.transactionNote!),
                DetailRow('Currency', result.currency ?? 'INR'),
              ],
            ),
          ),
        ],
        if (result.redFlags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Why it was flagged'),
          for (final flag in result.redFlags)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report_problem_rounded, color: AppColors.warn, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(flag, style: const TextStyle(fontSize: 14.5, height: 1.4))),
                  ],
                ),
              ),
            ),
        ],
        if (result.safetyAdvisories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('What to do'),
          AppCard(
            borderColor: AppColors.safe.withOpacity(0.4),
            child: Column(
              children: [
                for (var i = 0; i < result.safetyAdvisories.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.safe, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(result.safetyAdvisories[i],
                              style: const TextStyle(fontSize: 14.5, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageScanScreen(initialText: result.rawPayload),
                ),
              );
            },
            icon: const Icon(Icons.manage_search_rounded, size: 20),
            label: const Text('Run a full scan and save the report'),
          ),
        ),
      ],
    );
  }
}

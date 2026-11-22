import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/upi_qr_analyzer.dart';
import '../../services/investigation_service.dart';
import 'investigate_screen.dart';

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
    setState(() {
      _result = UpiQrAnalyzer.analyze(payload);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('UPI & QR Exploit Inspector',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Education Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.redAccent, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE "SCAN-TO-RECEIVE" FRAUD RULE',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'In UPI architecture, scanning a QR code or entering your UPI PIN ALWAYS debits money from your account. You NEVER scan a QR code to receive money, refunds, or lottery prizes.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Paste UPI string (e.g. upi://pay?pa=refund@ybl&am=5000&tn=Refund) or external QR URL...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              setState(() => _controller.text = data.text!);
                              _analyze(data.text!);
                            }
                          },
                          icon: const Icon(Icons.paste_rounded, size: 16),
                          label: const Text('Paste Payload', style: TextStyle(fontSize: 12)),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _isProcessingImage ? null : () => _pickQrImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                          label: const Text('Upload QR', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton.icon(
                          onPressed: _isProcessingImage ? null : () => _pickQrImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Snap QR', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Analyze Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isProcessingImage
                    ? null
                    : () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) _analyze(text);
                      },
                icon: _isProcessingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.biotech_outlined, size: 20),
                label: Text(
                  _isProcessingImage ? 'Extracting QR via Multimodal AI...' : 'Inspect QR Security',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results Section
            if (_result != null) ...[
              _buildResultCard(_result!, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(UpiQrAnalysisResult result, bool isDark) {
    final isCritical = result.riskScore >= 70;
    final riskColor = isCritical
        ? Colors.redAccent
        : result.riskScore >= 40
            ? Colors.orangeAccent
            : const Color(0xFF10B981);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Threat Header Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: riskColor.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(
                isCritical ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                color: riskColor,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.riskSeverity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risk Score: ${result.riskScore}/100 • Protocol: ${result.isUpiIntent ? "UPI Payment Intent" : result.isApkDownload ? "Malware APK" : "Web URL"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Decoded Payment Parameters (If UPI)
        if (result.isUpiIntent) ...[
          const Text('Decoded Transaction Parameters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                if (result.requestedAmount != null)
                  _buildParamRow(
                    'Debit Request Amount:',
                    '₹${result.requestedAmount}',
                    isHighlight: true,
                    highlightColor: Colors.redAccent,
                  ),
                if (result.payeeVpa != null)
                  _buildParamRow('Recipient VPA (pa):', result.payeeVpa!),
                if (result.payeeName != null)
                  _buildParamRow('Payee Name (pn):', result.payeeName!),
                if (result.transactionNote != null)
                  _buildParamRow('Transaction Note (tn):', result.transactionNote!),
                _buildParamRow('Currency (cu):', result.currency ?? 'INR'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Red Flags
        if (result.redFlags.isNotEmpty) ...[
          const Text('Identified Exploits & Traps',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...result.redFlags.map(
            (flag) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      flag,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: isDark ? Colors.grey[200] : const Color(0xFF9A3412),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Safety Advisories
        const Text('Mandatory Protection Steps',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Column(
            children: result.safetyAdvisories.map((step) {
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
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Send to full workbench CTA
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvestigateScreen(initialText: result.rawPayload),
                ),
              );
            },
            icon: const Icon(Icons.fingerprint_rounded, size: 18),
            label: const Text('Execute Full Forensic Audit & Generate Dossier'),
          ),
        ),
      ],
    );
  }

  Widget _buildParamRow(String label, String value,
      {bool isHighlight = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? highlightColor : null,
            ),
          ),
        ],
      ),
    );
  }
}

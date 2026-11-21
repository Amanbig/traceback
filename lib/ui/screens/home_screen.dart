import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/investigation_service.dart';
import '../../services/history_service.dart';
import 'report_screen.dart';
import 'url_inspector_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final InvestigationService _investigationService = InvestigationService();
  final ImagePicker _picker = ImagePicker();

  int _selectedInputMode = 0; // 0: Single Text/Link, 1: Screenshot, 2: Threat Chain
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  String? _selectedImageName;

  // Threat Chain state
  final List<String> _chainMessages = [];
  final TextEditingController _chainInputController = TextEditingController();

  bool _preferOnDevice = true;
  bool _isAnalyzing = false;
  String _analysisStatus = '';

  void setInputText(String text) {
    setState(() {
      _selectedInputMode = 0;
      _controller.text = text;
    });
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = file.mimeType ?? 'image/jpeg';
          _selectedImageName = file.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick screenshot: $e')),
      );
    }
  }

  void _loadDemoScreenshot() {
    const demoBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    setState(() {
      _selectedImageBytes = base64Decode(demoBase64);
      _selectedImageMime = 'image/png';
      _selectedImageName = 'whatsapp_scam_chat.png';
      _controller.text =
          'User notes: This WhatsApp message came from an unknown UK number claiming my Aadhaar card is blocked.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded sample screenshot scenario for investigation!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadDemoChain() {
    setState(() {
      _chainMessages.clear();
      _chainMessages.addAll([
        'FedEx Notice: Parcel #FX-9201 addressed to you containing 5 illegal passports and fake credit cards detained at Mumbai Airport Customs. Contact customs clearance immediately.',
        'Cyber Crime Officer Sharma: An arrest warrant has been prepared under your Aadhaar. Connect to official Skype video link immediately for digital arrest inquiry.',
        'Urgent Notice: To avoid immediate physical dispatch of police team to your house, deposit ₹85,000 RBI verification security bond. Refundable in 2 hours.',
      ]);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Loaded 3-step Digital Arrest escalation thread!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addMessageToChain() {
    final text = _chainInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chainMessages.add(text);
      _chainInputController.clear();
    });
  }

  Future<void> _runInvestigation() async {
    if (_selectedInputMode == 2) {
      // Threat Chain Investigation
      if (_chainMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least 1 message to the threat chain.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _analysisStatus = '1. Correlating timeline and masking PII across messages...';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      setState(() {
        _analysisStatus = _preferOnDevice
            ? '2. Running On-Device Gemini Nano timeline analysis...'
            : '2. Running Cloud AI Threat Chain Correlation via Firebase...';
      });

      try {
        final report = await _investigationService.investigateMessageChain(
          messages: _chainMessages,
          forceLocalOnly: _preferOnDevice,
        );

        await HistoryService.saveReport(report);

        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = '';
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(report: report),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investigation error: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    if (_selectedInputMode == 1) {
      // Screenshot Investigation
      if (_selectedImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or upload a screenshot to investigate.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _analysisStatus = '1. Preprocessing image and masking sensitive visual regions...';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      setState(() {
        _analysisStatus = _preferOnDevice
            ? '2. Running On-Device Gemini Nano visual triage...'
            : '2. Querying Firebase AI Logic Gemini Multimodal...';
      });

      try {
        final report = await _investigationService.investigateImage(
          imageBytes: _selectedImageBytes!,
          mimeType: _selectedImageMime ?? 'image/jpeg',
          optionalContext: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
          forceLocalOnly: _preferOnDevice,
        );

        await HistoryService.saveReport(report);

        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = '';
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(report: report),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _analysisStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investigation error: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // Text Investigation
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste a suspicious message to investigate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisStatus = '1. Scrubbing sensitive PII locally on device...';
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _analysisStatus = _preferOnDevice
          ? '2. Running On-Device Gemini Nano Shield & Lexical Audit...'
          : '2. Querying Firebase AI Logic Cloud Investigator...';
    });

    try {
      final report = await _investigationService.investigate(
        text: text,
        forceLocalOnly: _preferOnDevice,
      );

      await HistoryService.saveReport(report);

      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '';
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportScreen(report: report),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Investigation error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chainInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security, color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Traceback',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Past Investigations',
            onPressed: () => widget.onNavigateTab?.call(2),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3-Way Mode Selector: Text vs Screenshot vs Threat Chain
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildModeTab(0, Icons.text_fields_rounded, 'Single Msg', isDark),
                  _buildModeTab(1, Icons.camera_alt_outlined, 'Screenshot', isDark),
                  _buildModeTab(2, Icons.timeline_rounded, 'Threat Chain', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hybrid Inference Setting Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(
                    _preferOnDevice ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                    color: _preferOnDevice ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preferOnDevice
                              ? 'On-Device Shield (Gemini Nano)'
                              : 'Cloud AI (Gemini Flash Correlation)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          _preferOnDevice
                              ? 'Zero-leakage local triage • 100% Private'
                              : 'Deep forensic reasoning via Firebase AI Logic',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _preferOnDevice,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _preferOnDevice = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mode 2: Multi-Message Threat Chain UI
            if (_selectedInputMode == 2) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Multi-Message Escalation Thread',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: _loadDemoChain,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Load Demo Chain', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Existing Chain Messages
              if (_chainMessages.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.timeline_rounded, color: Colors.blueAccent, size: 36),
                      const SizedBox(height: 10),
                      const Text(
                        'No messages added to thread yet',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add sequential messages from an escalating scam (e.g. initial SMS ➔ fake phone call notice ➔ payment request)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._chainMessages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final msg = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            msg,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[200] : Colors.grey[800],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () => setState(() => _chainMessages.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),

              // Add Message Input Box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _chainInputController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter next message in the incident...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: _addMessageToChain,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Step', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedInputMode == 1) ...[
              // Mode 1: Screenshot Uploader UI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedImageBytes != null
                        ? Colors.blueAccent
                        : (isDark ? Colors.white10 : Colors.black12),
                    width: _selectedImageBytes != null ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    if (_selectedImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedImageName ?? 'screenshot.png',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _selectedImageBytes = null;
                              _selectedImageName = null;
                            }),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                            label: const Text('Remove',
                                style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ] else ...[
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: Colors.blueAccent.withOpacity(0.8)),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload a Scam Screenshot',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'WhatsApp conversation, SMS thread, bank alert, or fake email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _pickScreenshot,
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: const Text('Browse Files'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _loadDemoScreenshot,
                            icon: const Icon(Icons.science_outlined, size: 18),
                            label: const Text('Load Demo Screenshot'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional notes (e.g. "Received via WhatsApp from +44 number")...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                ),
              ),
            ] else ...[
              // Mode 0: Single Text / Link Input UI
              Text(
                'Suspicious Message or Link',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
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
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Paste an SMS, WhatsApp message, email body, or suspicious URL here...',
                        hintStyle: TextStyle(
                          fontSize: 13,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data?.text != null && data!.text!.isNotEmpty) {
                                setState(() => _controller.text = data.text!);
                              }
                            },
                            icon: const Icon(Icons.paste_rounded, size: 16),
                            label: const Text('Paste', style: TextStyle(fontSize: 12)),
                          ),
                          if (_controller.text.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() => _controller.clear()),
                              child: const Text('Clear',
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Investigate Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isAnalyzing ? null : _runInvestigation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        _selectedInputMode == 2
                            ? Icons.timeline_rounded
                            : _selectedInputMode == 1
                                ? Icons.document_scanner
                                : Icons.manage_search_rounded,
                        size: 22,
                      ),
                label: Text(
                  _isAnalyzing
                      ? _analysisStatus
                      : (_selectedInputMode == 2
                          ? 'Correlate Threat Chain (${_chainMessages.length} msgs)'
                          : _selectedInputMode == 1
                              ? 'Investigate Screenshot'
                              : 'Investigate Threat'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // URL Inspector Quick Banner
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UrlInspectorScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.travel_explore_rounded, size: 20, color: Colors.blueAccent),
              label: const Text('Open URL & Phishing Inspector',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(height: 24),

            // Quick Test Scenarios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Test Scenarios',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(1),
                  child: const Text('View All Radar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSampleTile(
              title: 'Bank KYC Account Suspension',
              category: 'Phishing Link',
              text:
                  'Dear Customer, Your SBI netbanking account has been suspended today due to missing PAN card verification. Click here to verify and restore access immediately: http://sbi-kyc-update.live/portal',
              icon: Icons.account_balance,
              color: Colors.redAccent,
            ),
            _buildSampleTile(
              title: 'Electricity Disconnection Tonight',
              category: 'Urgency Trap',
              text:
                  'Dear Consumer, Your electricity will be disconnected tonight at 9:30 PM because your previous month bill was not updated. Please immediately contact our power officer at 98123-45678.',
              icon: Icons.bolt,
              color: Colors.orangeAccent,
            ),
            _buildSampleTile(
              title: 'Digital Arrest by Police / Customs',
              category: 'Authority Extortion',
              text:
                  'Illegal narcotics parcel detected in your name at Mumbai Airport customs. Arrest warrant issued by Crime Branch. Join Skype session immediately for digital arrest inquiry.',
              icon: Icons.gavel,
              color: Colors.deepPurpleAccent,
            ),
            _buildSampleTile(
              title: 'Legitimate Bank Transaction (Control)',
              category: 'Benign Alert',
              text:
                  'Dear Customer, INR 450.00 debited from A/C XX8912 at Grocery Store on 21-Nov-2026. Available balance: INR 14,230.50. If not done by you, SMS BLOCK to 567676.',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedInputMode == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedInputMode = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.blueAccent : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSampleTile({
    required String title,
    required String category,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedInputMode = 0;
            _controller.text = text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded scenario: $title'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          category,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      ),
    );
  }
}

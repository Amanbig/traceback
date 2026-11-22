import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/investigation_service.dart';
import '../../services/history_service.dart';
import '../../services/firebase_service.dart';
import '../../models/threat_report.dart';
import '../widgets/forensic_analysis_hud.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class InvestigateScreen extends StatefulWidget {
  final int initialMode; // 0: Single Text, 1: Screenshot, 2: Threat Chain
  final String? initialText;

  const InvestigateScreen({
    super.key,
    this.initialMode = 0,
    this.initialText,
  });

  @override
  State<InvestigateScreen> createState() => _InvestigateScreenState();
}

class _InvestigateScreenState extends State<InvestigateScreen> {
  final TextEditingController _controller = TextEditingController();
  final InvestigationService _investigationService = InvestigationService();
  final ImagePicker _picker = ImagePicker();

  late int _selectedInputMode;
  Uint8List? _selectedImageBytes;
  String? _selectedImageMime;
  String? _selectedImageName;

  final List<String> _chainMessages = [];
  final TextEditingController _chainInputController = TextEditingController();

  bool _preferOnDevice = true;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _selectedInputMode = widget.initialMode;
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _preferOnDevice = prefs.getBool('setting_prefer_on_device') ?? true;
    });
  }

  Future<void> _pickFromGallery() async {
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
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _captureWithCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageMime = file.mimeType ?? 'image/jpeg';
          _selectedImageName = file.name.isNotEmpty ? file.name : 'camera_capture.jpg';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera capture failed: $e')),
      );
    }
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
    if (_selectedInputMode == 2 && _chainMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 message to the threat chain.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedInputMode == 1 && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture a screenshot to investigate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedInputMode == 0 && _controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or paste a suspicious message to investigate.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    final stageNotifier = ValueNotifier<int>(1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: stageNotifier,
        builder: (ctx, stage, _) => ForensicAnalysisHud(
          stage: stage,
          isLocal: _preferOnDevice,
          currentDetail: '',
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 350));
      stageNotifier.value = 2; // Tokenizing & syntax audit

      await Future.delayed(const Duration(milliseconds: 300));
      stageNotifier.value = 3; // Hybrid AI inference

      final ThreatReport report;
      if (_selectedInputMode == 2) {
        report = await _investigationService.investigateMessageChain(
          messages: _chainMessages,
          forceLocalOnly: _preferOnDevice,
        );
      } else if (_selectedInputMode == 1) {
        report = await _investigationService.investigateImage(
          imageBytes: _selectedImageBytes!,
          mimeType: _selectedImageMime ?? 'image/jpeg',
          optionalContext: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
          forceLocalOnly: _preferOnDevice,
        );
      } else {
        report = await _investigationService.investigate(
          text: _controller.text.trim(),
          forceLocalOnly: _preferOnDevice,
        );
      }

      stageNotifier.value = 4; // Synthesizing report
      await HistoryService.saveReport(report);
      await FirebaseService.syncInvestigationToCloud(report);
      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss HUD

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReportScreen(report: report)),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss HUD
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Investigation error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
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
        title: const Text('Investigation Workbench',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Engine Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    preferOnDevice: _preferOnDevice,
                    onPreferOnDeviceChanged: (val) => setState(() => _preferOnDevice = val),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildModeTab(0, Icons.text_fields_rounded, 'Message / Link', isDark),
                  _buildModeTab(1, Icons.camera_alt_outlined, 'Screenshot', isDark),
                  _buildModeTab(2, Icons.timeline_rounded, 'Threat Chain', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode 2: Multi-Message Threat Chain UI
            if (_selectedInputMode == 2) ...[
              const Text(
                'Incident Timeline Messages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Add consecutive messages to correlate the escalating fraud campaign.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              if (_chainMessages.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                        'No messages added to this incident thread',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the initial contact message below and tap "Add Step".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
                          height: 200,
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
                          size: 52, color: Colors.blueAccent.withOpacity(0.8)),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Fraud Evidence Image',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text('Gallery / Files'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: _captureWithCamera,
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Take Photo'),
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
                  hintText: 'Optional context (e.g. "Received via WhatsApp from +44 number")...',
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
              const Text(
                'Suspicious Message Text or Link',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Paste the suspicious SMS, WhatsApp message, email body, or URL here...',
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
                            label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 12)),
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

            const SizedBox(height: 24),

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
                icon: Icon(
                  _selectedInputMode == 2
                      ? Icons.timeline_rounded
                      : _selectedInputMode == 1
                          ? Icons.document_scanner
                          : Icons.manage_search_rounded,
                  size: 22,
                ),
                label: Text(
                  _selectedInputMode == 2
                      ? 'Correlate Threat Chain (${_chainMessages.length} msgs)'
                      : _selectedInputMode == 1
                          ? 'Investigate Screenshot Evidence'
                          : 'Execute Forensic Audit',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
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
}

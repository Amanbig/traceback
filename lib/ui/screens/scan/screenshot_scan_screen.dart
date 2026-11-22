import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/investigation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'scan_support.dart';

/// Check a screenshot or photo of a chat, SMS, bank alert or email.
class ScreenshotScanScreen extends StatefulWidget {
  const ScreenshotScanScreen({super.key});

  @override
  State<ScreenshotScanScreen> createState() => _ScreenshotScanScreenState();
}

class _ScreenshotScanScreenState extends State<ScreenshotScanScreen> {
  final _context = TextEditingController();
  final _service = InvestigationService();
  final _picker = ImagePicker();

  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  String? _name;
  bool _busy = false;

  @override
  void dispose() {
    _context.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _mime = file.mimeType ?? 'image/jpeg';
        _name = file.name.isNotEmpty ? file.name : 'photo.jpg';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(source == ImageSource.camera
              ? 'Could not open the camera. Check the app has camera permission.'
              : 'Could not open that image.'),
        ),
      );
    }
  }

  Future<void> _run() async {
    final bytes = _bytes;
    if (bytes == null) return;
    setState(() => _busy = true);
    final note = _context.text.trim();
    await ScanRunner.run(
      context,
      (local) => _service.investigateImage(
        imageBytes: bytes,
        mimeType: _mime,
        optionalContext: note.isEmpty ? null : note,
        forceLocalOnly: local,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _bytes != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Check a screenshot')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 24),
          children: [
            AppCard(
              borderColor: hasImage ? AppColors.brand : null,
              child: hasImage ? _buildPreview() : _buildPicker(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _context,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Context (optional)',
                hintText: 'e.g. Received on WhatsApp from an unknown number',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const PrivacyNote(),
          ],
        ),
      ),
      bottomNavigationBar: ScanBottomBar(
        label: hasImage ? 'Check screenshot' : 'Add a screenshot to start',
        enabled: hasImage && !_busy,
        onPressed: _run,
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_bytes!, height: 260, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(_name ?? 'screenshot',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _bytes = null;
                _name = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPicker() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_photo_alternate_outlined, size: 34, color: AppColors.brand),
        ),
        const SizedBox(height: 14),
        const Text('Add a screenshot',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'A chat, SMS, bank alert or email you are unsure about',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: context.mutedText),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

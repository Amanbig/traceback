import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../qr_inspector_screen.dart';
import '../settings_screen.dart';
import '../url_inspector_screen.dart';
import 'chain_scan_screen.dart';
import 'message_scan_screen.dart';
import 'scan_support.dart';
import 'screenshot_scan_screen.dart';

/// The Scan tab: pick what you want to check.
class ScanHubScreen extends StatelessWidget {
  const ScanHubScreen({super.key});

  void _open(BuildContext context, Widget page) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openSettings(BuildContext context) async {
    final local = await ScanRunner.preferOnDevice();
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(preferOnDevice: local, onPreferOnDeviceChanged: (_) {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => _openSettings(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 24),
        children: [
          const Text('What do you want to check?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Pick the kind of thing you received.',
              style: TextStyle(fontSize: 14.5, color: context.mutedText)),
          const SizedBox(height: AppSpacing.lg),
          _Option(
            icon: Icons.chat_bubble_outline_rounded,
            color: const Color(0xFF60A5FA),
            title: 'Message',
            subtitle: 'SMS, WhatsApp or email text',
            onTap: () => _open(context, const MessageScanScreen()),
          ),
          _Option(
            icon: Icons.image_outlined,
            color: const Color(0xFFC084FC),
            title: 'Screenshot',
            subtitle: 'A photo or screenshot of a chat or alert',
            onTap: () => _open(context, const ScreenshotScanScreen()),
          ),
          _Option(
            icon: Icons.link_rounded,
            color: const Color(0xFF22D3EE),
            title: 'Link',
            subtitle: 'Check a website address before opening it',
            onTap: () => _open(context, const UrlInspectorScreen()),
          ),
          _Option(
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFFFBBF24),
            title: 'UPI QR code',
            subtitle: 'Find payment traps before you scan to pay',
            onTap: () => _open(context, const QrInspectorScreen()),
          ),
          _Option(
            icon: Icons.timeline_rounded,
            color: const Color(0xFF818CF8),
            title: 'Message chain',
            subtitle: 'Several messages from the same sender',
            onTap: () => _open(context, const ChainScanScreen()),
          ),
          const SizedBox(height: AppSpacing.sm),
          const PrivacyNote(),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13.5, color: context.mutedText)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.mutedText),
          ],
        ),
      ),
    );
  }
}

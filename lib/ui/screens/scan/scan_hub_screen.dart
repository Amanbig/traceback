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
class ScanHubScreen extends StatefulWidget {
  const ScanHubScreen({super.key});

  @override
  State<ScanHubScreen> createState() => _ScanHubScreenState();
}

class _ScanHubScreenState extends State<ScanHubScreen> with WidgetsBindingObserver {
  String? _clipboardText;
  bool _dismissedClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim();
      if (text != null && text.length >= 12 && text != _clipboardText) {
        if (mounted) {
          setState(() {
            _clipboardText = text;
            _dismissedClipboard = false;
          });
        }
      }
    } catch (_) {}
  }

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

  Widget _buildEvaluatorDeck(BuildContext context) {
    final demos = [
      (
        label: '🚨 Digital Arrest',
        color: AppColors.danger,
        text:
            'MUMBAI POLICE & CBI NOTICE: Case #CR-9102 registered under your Aadhaar. A parcel containing 5 fake passports and narcotic contraband was seized at customs. Connect to official Skype video immediately for digital arrest inquiry or warrant will execute.',
      ),
      (
        label: '💸 Reverse UPI PIN',
        color: AppColors.brand,
        text:
            'Congratulations! You received Rs 4,999 cashback reward on PhonePe. Click here and enter your UPI PIN to claim money directly into your bank account: phonepe-rewards-claim.xyz',
      ),
      (
        label: '⚡ Electricity Panic',
        color: AppColors.warn,
        text:
            'Dear Consumer, Your electricity power will be disconnected tonight at 9:30 PM from the power office because your previous month bill was not updated. Please immediately contact our electricity officer at 98123-XXXXX. Thank you.',
      ),
      (
        label: '📲 AnyDesk RAT APK',
        color: const Color(0xFFEF4444),
        text:
            'SBI NetBanking alert: Your YONO account is suspended. Download and install our official QuickSupport APK update from http://sbi-yono-support.top/apk to verify KYC immediately.',
      ),
      (
        label: '💬 Benign Chat (Ham)',
        color: AppColors.safe,
        text:
            'Hey mom, heading home for dinner with dad tonight. See you soon, love you!',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 18, color: AppColors.brand),
              const SizedBox(width: 6),
              const Text(
                'Quick Evaluator Demo Deck',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '1-TAP TEST',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Test on-device ML triage and zero-leakage PII scrubbing:',
            style: TextStyle(fontSize: 11.5, color: context.mutedText),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: demos.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    backgroundColor: d.color.withOpacity(0.08),
                    side: BorderSide(color: d.color.withOpacity(0.3)),
                    label: Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: d.color,
                      ),
                    ),
                    onPressed: () {
                      _open(context, MessageScanScreen(initialText: d.text));
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
          // 1. Smart Clipboard Auto-Detect Banner
          if (_clipboardText != null && !_dismissedClipboard) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brand.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.content_paste_rounded, color: AppColors.brand, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Copied text detected',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          _clipboardText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: context.mutedText),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      _open(context, MessageScanScreen(initialText: _clipboardText));
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(60, 36),
                    ),
                    child: const Text('Analyze',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => setState(() => _dismissedClipboard = true),
                  ),
                ],
              ),
            ),
          ],

          const Text('What do you want to check?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Pick the kind of thing you received.',
              style: TextStyle(fontSize: 14.5, color: context.mutedText)),
          const SizedBox(height: AppSpacing.md),

          // 2. Evaluator & Judge Quick Test Deck
          _buildEvaluatorDeck(context),
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
            icon: Icons.alt_route_rounded,
            color: const Color(0xFF34D399),
            title: 'Threat chain',
            subtitle: 'Several messages that escalate over time',
            onTap: () => _open(context, const ChainScanScreen()),
          ),
          _Option(
            icon: Icons.link_rounded,
            color: const Color(0xFF38BDF8),
            title: 'Link or domain',
            subtitle: 'Inspect a suspicious web address for typosquatting',
            onTap: () => _open(context, const UrlInspectorScreen()),
          ),
          _Option(
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFFFBBF24),
            title: 'QR or UPI code',
            subtitle: 'Check for "scan to receive" and hidden debits',
            onTap: () => _open(context, const QrInspectorScreen()),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Offline Capable Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.safe.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.safe),
                SizedBox(width: 8),
                Text(
                  '100% Offline Capable • On-Device Gemini Nano Shield',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.safe),
                ),
              ],
            ),
          ),
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

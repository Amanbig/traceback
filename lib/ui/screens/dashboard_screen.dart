import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';
import '../../services/history_service.dart';
import '../../models/threat_report.dart';
import '../../models/scam_radar_item.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/common.dart';
import 'scan/chain_scan_screen.dart';
import 'scan/message_scan_screen.dart';
import 'scan/screenshot_scan_screen.dart';
import 'url_inspector_screen.dart';
import 'qr_inspector_screen.dart';
import 'emergency_toolkit_screen.dart';
import 'scam_simulator_screen.dart';
import 'settings_screen.dart';
import 'report_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _preferOnDevice = true;
  List<ThreatReport> _history = [];
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final history = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _preferOnDevice = prefs.getBool('setting_prefer_on_device') ?? true;
        _history = history;
        _isLoadingMetrics = false;
      });
    }
  }

  void _push(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadDashboardData());
  }

  void _showAuth() {
    showDialog(context: context, builder: (_) => const AuthDialog())
        .then((_) => _loadDashboardData());
  }

  void _openSettings() {
    _push(SettingsScreen(
      preferOnDevice: _preferOnDevice,
      onPreferOnDeviceChanged: (val) => setState(() => _preferOnDevice = val),
    ));
  }


  bool _isHigh(ThreatReport h) =>
      h.threatLevel == ThreatLevel.dangerous ||
      h.threatLevel == ThreatLevel.critical ||
      h.riskScore >= 70;

  @override
  Widget build(BuildContext context) {
    final totalScans = _history.length;
    final highThreats = _history.where(_isHigh).length;
    final safeCount = _history.where((h) => h.riskScore < 40).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screenH,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDeep],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Traceback',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ],
        ),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseService.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data ?? FirebaseService.currentUser;
              final signedIn = user != null && !user.isAnonymous;
              return IconButton(
                onPressed: _showAuth,
                tooltip: signedIn ? 'Account' : 'Sign in',
                icon: signedIn
                    ? CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.safe.withOpacity(0.2),
                        child: Text(
                          (user.email?.isNotEmpty ?? false) ? user.email![0].toUpperCase() : 'D',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.safe),
                        ),
                      )
                    : const Icon(Icons.account_circle_outlined),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, 32),
          children: [
            _buildHero(),
            const SizedBox(height: AppSpacing.sm),
            _buildOfflinePill(),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickScan(),
            const SizedBox(height: AppSpacing.xl),
            _buildStats(totalScans, highThreats, safeCount),
            const SizedBox(height: AppSpacing.xl),
            _buildEmergencyStrip(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('More tools'),
            _buildTools(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('Scam alert'),
            _buildAdvisory(),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              'Recent scans',
              actionLabel: _history.isNotEmpty ? 'View all' : null,
              onAction: () => widget.onNavigateTab?.call(3),
            ),
            _buildRecent(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflinePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.safe.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.safe.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.offline_bolt_rounded, size: 16, color: AppColors.safe),
          const SizedBox(width: 8),
          Text(
            _preferOnDevice
                ? '⚡ 100% Offline Shield Active (Gemini Nano Local)'
                : '☁️ Hybrid Cloud AI Active (Firebase Gemini Flash)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.safe),
          ),
        ],
      ),
    );
  }

  // ---- Hero: protection status + primary scan action -----------------------

  Widget _buildHero() {
    final latest = _history.isNotEmpty ? _history.first : null;
    final atRisk = latest != null && _isHigh(latest);
    final color = atRisk ? AppColors.danger : AppColors.safe;
    final title = atRisk ? 'Threat found recently' : "You're protected";
    final subtitle = atRisk
        ? 'Your last scan flagged a ${latest.threatLevel.label.toLowerCase()} message. Review it.'
        : (latest == null
            ? 'Scan any message, link or screenshot before you act on it.'
            : 'No high-risk threats in your latest scan.');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.22), context.surfaceColor],
        ),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Semantics(
            label: title,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.16),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 32, spreadRadius: 2),
                ],
              ),
              child: Icon(
                atRisk ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
                size: 50,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1);
                } else {
                  _push(const MessageScanScreen());
                }
              },
              icon: const Icon(Icons.search_rounded),
              label: const Text('Scan now'),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openSettings,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _preferOnDevice ? Icons.phone_android_rounded : Icons.cloud_outlined,
                    size: 15,
                    color: context.mutedText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _preferOnDevice
                        ? 'Private mode: scans stay on this device'
                        : 'Cloud AI mode: deeper analysis',
                    style: TextStyle(fontSize: 13, color: context.mutedText),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16, color: context.mutedText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Quick scan row -------------------------------------------------------

  Widget _buildQuickScan() {
    final items = [
      (Icons.chat_bubble_outline_rounded, 'Message', const Color(0xFF60A5FA),
          () => _push(const MessageScanScreen())),
      (Icons.image_outlined, 'Screenshot', const Color(0xFFC084FC),
          () => _push(const ScreenshotScanScreen())),
      (Icons.link_rounded, 'Link', const Color(0xFF22D3EE),
          () => _push(const UrlInspectorScreen())),
      (Icons.qr_code_scanner_rounded, 'UPI QR', const Color(0xFFFBBF24),
          () => _push(const QrInspectorScreen())),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickAction(
              icon: items[i].$1,
              label: items[i].$2,
              color: items[i].$3,
              onTap: items[i].$4,
            ),
          ),
        ],
      ],
    );
  }

  // ---- Stats ----------------------------------------------------------------

  Widget _buildStats(int total, int threats, int safe) {
    String v(int n) => _isLoadingMetrics ? '–' : '$n';
    return Row(
      children: [
        Expanded(child: _StatTile(value: v(total), label: 'Scans', color: AppColors.brand)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatTile(value: v(threats), label: 'Threats', color: AppColors.danger)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatTile(value: v(safe), label: 'Safe', color: AppColors.safe)),
      ],
    );
  }

  // ---- Emergency ------------------------------------------------------------

  Widget _buildEmergencyStrip() {
    return AppCard(
      onTap: () => _push(const EmergencyToolkitScreen()),
      borderColor: AppColors.danger.withOpacity(0.4),
      color: AppColors.danger.withOpacity(context.isDark ? 0.10 : 0.06),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sos_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Already been scammed?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                SizedBox(height: 2),
                Text('Get emergency steps and the 1930 helpline',
                    style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  // ---- Tools ----------------------------------------------------------------

  Widget _buildTools() {
    return Column(
      children: [
        _ToolRow(
          icon: Icons.timeline_rounded,
          color: const Color(0xFF818CF8),
          title: 'Threat chain',
          subtitle: 'Link several messages to spot an escalating scam',
          onTap: () => _push(const ChainScanScreen()),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ToolRow(
          icon: Icons.sports_esports_outlined,
          color: const Color(0xFF2DD4BF),
          title: 'Scam simulator',
          subtitle: 'Practice spotting scams in a safe space',
          onTap: () => _push(const ScamSimulatorScreen()),
        ),
      ],
    );
  }

  // ---- Advisory -------------------------------------------------------------

  Widget _buildAdvisory() {
    final topScam = ScamRadarItem.trendingScams.first;
    return AppCard(
      onTap: () => widget.onNavigateTab?.call(2),
      borderColor: AppColors.warn.withOpacity(0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warn, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Trending now',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warn)),
                    const Spacer(),
                    StatusPill(label: topScam.severity, color: AppColors.danger),
                  ],
                ),
                const SizedBox(height: 6),
                Text(topScam.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  topScam.modusOperandi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, height: 1.35, color: context.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Recent ---------------------------------------------------------------

  Widget _buildRecent() {
    if (_history.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: EmptyState(
            icon: Icons.manage_search_rounded,
            title: 'No scans yet',
            message: 'Paste a suspicious message or link and get a verdict in seconds.',
            actionLabel: 'Run first scan',
            onAction: () => _push(const MessageScanScreen()),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final item in _history.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _push(ReportScreen(report: item)),
              child: Row(
                children: [
                  RiskBadge(score: item.riskScore),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.maskedSnippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.threatLevel.label} · ${relativeTime(item.createdAt)}',
                          style: TextStyle(fontSize: 13, color: context.mutedText),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: context.mutedText),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: context.mutedText)),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: context.mutedText)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.mutedText),
        ],
      ),
    );
  }
}

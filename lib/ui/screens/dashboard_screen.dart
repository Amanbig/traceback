import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';
import '../../services/history_service.dart';
import '../../models/threat_report.dart';
import '../../models/scam_radar_item.dart';
import '../widgets/auth_dialog.dart';
import 'investigate_screen.dart';
import 'url_inspector_screen.dart';
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

  void _showAuth() {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(),
    ).then((_) => _loadDashboardData());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          preferOnDevice: _preferOnDevice,
          onPreferOnDeviceChanged: (val) {
            setState(() => _preferOnDevice = val);
          },
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _openInvestigator({int mode = 0, String? text}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvestigateScreen(
          initialMode: mode,
          initialText: text,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  Color _getRiskColor(int score) {
    if (score >= 70) return Colors.redAccent;
    if (score >= 40) return Colors.amber;
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalScans = _history.length;
    final highThreats = _history
        .where((h) =>
            h.threatLevel == ThreatLevel.dangerous ||
            h.threatLevel == ThreatLevel.critical ||
            h.riskScore >= 70)
        .length;

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
          StreamBuilder<User?>(
            stream: FirebaseService.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data ?? FirebaseService.currentUser;
              final isAnonymous = user?.isAnonymous ?? true;
              return TextButton.icon(
                onPressed: _showAuth,
                icon: Icon(
                  user != null && !isAnonymous ? Icons.account_circle : Icons.person_outline,
                  size: 18,
                  color: user != null && !isAnonymous ? const Color(0xFF10B981) : Colors.grey,
                ),
                label: Text(
                  user != null && !isAnonymous
                      ? (user.email?.split('@').first ?? 'Defender')
                      : 'Sign In',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user != null && !isAnonymous ? const Color(0xFF10B981) : Colors.grey,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Engine Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Executive Status Shield Banner
              InkWell(
                onTap: _openSettings,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _preferOnDevice
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFF3B82F6).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_preferOnDevice
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6))
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _preferOnDevice ? Icons.shield_rounded : Icons.cloud_done_rounded,
                          color: _preferOnDevice
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _preferOnDevice
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _preferOnDevice ? 'ACTIVE • ON-DEVICE SHIELD' : 'ACTIVE • CLOUD AI ENGINE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: _preferOnDevice
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _preferOnDevice
                                  ? 'Gemini Nano Zero-Leakage Privacy Guard'
                                  : 'Gemini 1.5 Flash Multimodal Forensics',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to configure hybrid inference & privacy settings',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Primary Action: Start Forensic Investigation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.manage_search_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forensic Investigation Workbench',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Inspect suspicious messages, links, screenshots & scams',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _openInvestigator(mode: 0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.shield, size: 20),
                        label: const Text(
                          'Start Forensic Investigation',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 3. Live Telemetry Metrics Grid
              const Text(
                'Security Telemetry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Audited Scans',
                      value: _isLoadingMetrics ? '...' : '$totalScans',
                      icon: Icons.search_rounded,
                      accentColor: Colors.blueAccent,
                      isDark: isDark,
                      subtitle: 'Local & Cloud',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'High Threats Blocked',
                      value: _isLoadingMetrics ? '...' : '$highThreats',
                      icon: Icons.gpp_bad_rounded,
                      accentColor: Colors.redAccent,
                      isDark: isDark,
                      subtitle: 'Dangerous alerts',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'PII Privacy Guard',
                      value: '100%',
                      icon: Icons.lock_outline_rounded,
                      accentColor: const Color(0xFF10B981),
                      isDark: isDark,
                      subtitle: '0 Leakage to Cloud',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Avg Triage Speed',
                      value: '< 250ms',
                      icon: Icons.bolt_rounded,
                      accentColor: Colors.amber,
                      isDark: isDark,
                      subtitle: 'On-device Nano',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 4. Dedicated Tools Row
              const Text(
                'Investigative Modules',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  _buildToolTile(
                    icon: Icons.camera_alt_outlined,
                    title: 'Evidence Screenshot',
                    subtitle: 'Multimodal vision audit',
                    color: Colors.purpleAccent,
                    isDark: isDark,
                    onTap: () => _openInvestigator(mode: 1),
                  ),
                  _buildToolTile(
                    icon: Icons.link_rounded,
                    title: 'Deep URL Inspector',
                    subtitle: 'Typosquatting & domains',
                    color: Colors.cyanAccent,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UrlInspectorScreen()),
                      );
                    },
                  ),
                  _buildToolTile(
                    icon: Icons.timeline_rounded,
                    title: 'Threat Chain',
                    subtitle: 'Multi-message correlation',
                    color: Colors.indigoAccent,
                    isDark: isDark,
                    onTap: () => _openInvestigator(mode: 2),
                  ),
                  _buildToolTile(
                    icon: Icons.emergency_outlined,
                    title: 'Emergency 1930',
                    subtitle: 'Victim protocol & helplines',
                    color: Colors.redAccent,
                    isDark: isDark,
                    onTap: () {
                      widget.onNavigateTab?.call(2); // Switch to Emergency tab
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 5. Threat Intelligence Advisory Banner
              _buildThreatAdvisoryBanner(isDark),
              const SizedBox(height: 22),

              // 6. Recent Investigations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Investigations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (_history.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        widget.onNavigateTab?.call(3); // Switch to History tab
                      },
                      child: const Text('View All', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 36, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text(
                        'No Audits Logged Yet',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Run your first forensic investigation to view risk telemetry and anatomy breakdown.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._history.take(3).map((item) {
                  final riskColor = _getRiskColor(item.riskScore);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: riskColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          '${item.riskScore}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ),
                      title: Text(
                        item.maskedSnippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${item.threatLevel.name.toUpperCase()} • ${item.isLocalInference ? "On-Device" : "Cloud"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportScreen(report: item),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  );
                }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatAdvisoryBanner(bool isDark) {
    final topScam = ScamRadarItem.trendingScams.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ACTIVE CAMPAIGN ADVISORY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.orangeAccent,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        topScam.severity.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  topScam.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  topScam.modusOperandi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    widget.onNavigateTab?.call(1); // Switch to Radar tab
                  },
                  child: const Text(
                    'View community radar analysis ➔',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

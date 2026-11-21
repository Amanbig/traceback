import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';
import '../widgets/auth_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final bool preferOnDevice;
  final ValueChanged<bool> onPreferOnDeviceChanged;

  const SettingsScreen({
    super.key,
    required this.preferOnDevice,
    required this.onPreferOnDeviceChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _preferOnDevice;
  bool _maskPii = true;
  bool _autoCloudSync = true;
  double _riskThreshold = 75;

  @override
  void initState() {
    super.initState();
    _preferOnDevice = widget.preferOnDevice;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maskPii = prefs.getBool('setting_mask_pii') ?? true;
      _autoCloudSync = prefs.getBool('setting_auto_cloud_sync') ?? true;
      _riskThreshold = prefs.getDouble('setting_risk_threshold') ?? 75;
    });
  }

  Future<void> _saveBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveDouble(String key, double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, val);
  }

  void _showAuth() {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engine Settings & Preferences',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section 1: Hybrid AI Inference Core
          _buildSectionHeader('HYBRID AI INFERENCE CORE'),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _preferOnDevice
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : const Color(0xFF6366F1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _preferOnDevice ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                      color: _preferOnDevice ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                    ),
                  ),
                  title: Text(
                    _preferOnDevice ? 'On-Device Shield (Gemini Nano)' : 'Cloud AI (Gemini Flash)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    _preferOnDevice
                        ? '100% private offline local execution. Never sends message content to servers.'
                        : 'High-reasoning cloud forensic investigation via Firebase AI Logic.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  value: _preferOnDevice,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setState(() => _preferOnDevice = val);
                    widget.onPreferOnDeviceChanged(val);
                    _saveBool('setting_prefer_on_device', val);
                  },
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline, color: Color(0xFF10B981)),
                  title: const Text('Zero-Leakage Privacy Guard',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    'Automatically scrub accounts, phone numbers, and OTPs on-device prior to external calls.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  value: _maskPii,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    setState(() => _maskPii = val);
                    _saveBool('setting_mask_pii', val);
                  },
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_sync_outlined, color: Colors.blueAccent),
                  title: const Text('Auto-Sync to Private Cloud',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    'Securely sync your investigation records to your personal Firestore collection.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  value: _autoCloudSync,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {
                    setState(() => _autoCloudSync = val);
                    _saveBool('setting_auto_cloud_sync', val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Threat Detection Sensitivity
          _buildSectionHeader('FORENSIC THRESHOLDS (REMOTE CONFIG)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Critical Threat Trigger Threshold',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${_riskThreshold.toInt()} / 100',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
                Slider(
                  value: _riskThreshold,
                  min: 50,
                  max: 95,
                  divisions: 9,
                  label: '${_riskThreshold.toInt()}',
                  activeColor: Colors.redAccent,
                  onChanged: (val) {
                    setState(() => _riskThreshold = val);
                    _saveDouble('setting_risk_threshold', val);
                  },
                ),
                Text(
                  'Messages scoring at or above this threshold will immediately trigger the critical emergency checklist.',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: User Account & Authentication
          _buildSectionHeader('ACCOUNT & IDENTITY'),
          StreamBuilder<User?>(
            stream: FirebaseService.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data ?? FirebaseService.currentUser;
              final isAnonymous = user?.isAnonymous ?? true;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              user != null && !isAnonymous ? const Color(0xFF10B981) : Colors.blueGrey,
                          child: Icon(
                            user != null && !isAnonymous ? Icons.shield : Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user != null && !isAnonymous
                                    ? (user.email ?? 'Verified Defender')
                                    : 'Guest Session (Anonymous)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                user != null && !isAnonymous
                                    ? 'UID: ${user.uid.substring(0, 8)}... (Cloud Sync Active)'
                                    : 'Sign in with email to sync investigations across devices',
                                style: TextStyle(
                                    fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: user != null && !isAnonymous
                            ? () async {
                                await FirebaseService.signOut();
                                setState(() {});
                              }
                            : _showAuth,
                        icon: Icon(user != null && !isAnonymous ? Icons.logout : Icons.login, size: 16),
                        label: Text(user != null && !isAnonymous ? 'Sign Out' : 'Sign In / Register',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 4: Engine Diagnostics & Info
          _buildSectionHeader('ABOUT TRACEBACK ENGINE'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Engine Version', 'v1.3.0 • Hybrid Intelligence Core'),
                const Divider(height: 20),
                _buildInfoRow('AI SDK', 'Firebase AI Logic (firebase_ai 3.11)'),
                const Divider(height: 20),
                _buildInfoRow('App Attestation', 'Firebase App Check (Debug Token Active)'),
                const Divider(height: 20),
                _buildInfoRow('License', 'Apache License 2.0 (Open Source)'),
                const Divider(height: 20),
                _buildInfoRow('Repository', 'github.com/Amanbig/traceback'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ],
    );
  }
}

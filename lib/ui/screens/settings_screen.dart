import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_dialog.dart';
import '../widgets/common.dart';

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
    if (!mounted) return;
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
    showDialog(context: context, builder: (_) => const AuthDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 32),
        children: [
          _group('Protection', [
            _SwitchRow(
              icon: _preferOnDevice ? Icons.phone_android_rounded : Icons.hub_outlined,
              color: _preferOnDevice ? AppColors.safe : AppColors.brand,
              title: 'Strict On-Device Only',
              subtitle: _preferOnDevice
                  ? 'Active: 100% on-device (Gemini Nano offline shield). Zero network calls.'
                  : 'Hybrid AI (Recommended): Local PII scrub + Google Gemini via Firebase AI Logic (with instant offline fallback).',
              value: _preferOnDevice,
              onChanged: (val) {
                setState(() => _preferOnDevice = val);
                widget.onPreferOnDeviceChanged(val);
                _saveBool('setting_prefer_on_device', val);
              },
            ),
            _SwitchRow(
              icon: Icons.visibility_off_outlined,
              color: AppColors.safe,
              title: 'Hide personal details',
              subtitle: 'Mask phone numbers, account numbers and OTPs before any scan.',
              value: _maskPii,
              onChanged: (val) {
                setState(() => _maskPii = val);
                _saveBool('setting_mask_pii', val);
              },
            ),
            _SwitchRow(
              icon: Icons.cloud_sync_outlined,
              color: AppColors.brand,
              title: 'Back up my scans',
              subtitle: 'Save your scan history to your private cloud space.',
              value: _autoCloudSync,
              onChanged: (val) {
                setState(() => _autoCloudSync = val);
                _saveBool('setting_auto_cloud_sync', val);
              },
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _group('Alert sensitivity', [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Show emergency steps at',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      StatusPill(label: '${_riskThreshold.toInt()} / 100', color: AppColors.danger),
                    ],
                  ),
                  Slider(
                    value: _riskThreshold,
                    min: 50,
                    max: 95,
                    divisions: 9,
                    label: '${_riskThreshold.toInt()}',
                    onChanged: (val) {
                      setState(() => _riskThreshold = val);
                      _saveDouble('setting_risk_threshold', val);
                    },
                  ),
                  Text(
                    'Scans scoring at or above this number show the emergency checklist. Lower means more cautious.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedText),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _group('Appearance', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Choose between cyber dark, crisp light, or system synchronization.',
                      style: TextStyle(fontSize: 13, color: context.mutedText)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                          label: Text('Dark'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_rounded, size: 16),
                          label: Text('System'),
                        ),
                      ],
                      selected: {ThemeController.mode.value},
                      onSelectionChanged: (selected) {
                        setState(() {
                          ThemeController.setTheme(selected.first);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
          _group('Account', [_buildAccount()]),
          const SizedBox(height: AppSpacing.xl),
          _group('About', [
            const _InfoRow('Version', '1.3.0'),
            const _InfoRow('License', 'Apache 2.0'),
            const _InfoRow('Source', 'github.com/Amanbig/traceback'),
          ]),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: context.mutedText),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.outlineColor),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(indent: 16, endIndent: 16, color: context.outlineColor),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccount() {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseService.currentUser;
        final signedIn = user != null && !user.isAnonymous;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        (signedIn ? AppColors.safe : AppColors.brand).withOpacity(0.18),
                    child: Icon(
                      signedIn ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                      color: signedIn ? AppColors.safe : AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedIn ? (user.email ?? 'Signed in') : 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          signedIn
                              ? 'Your scans are backed up'
                              : 'Sign in to keep your scans across devices',
                          style: TextStyle(fontSize: 13, color: context.mutedText),
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
                  onPressed: signedIn
                      ? () async {
                          await FirebaseService.signOut();
                          if (mounted) setState(() {});
                        }
                      : _showAuth,
                  icon: Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded, size: 18),
                  label: Text(signedIn ? 'Sign out' : 'Sign in or register'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle,
            style: TextStyle(fontSize: 13, height: 1.35, color: context.mutedText)),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 14, color: context.mutedText)),
          ),
        ],
      ),
    );
  }
}

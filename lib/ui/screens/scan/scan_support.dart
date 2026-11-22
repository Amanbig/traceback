import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/threat_report.dart';
import '../../../services/firebase_service.dart';
import '../../../services/history_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/forensic_analysis_hud.dart';
import '../report_screen.dart';

/// Runs a scan with the progress pop-up, saves it, and opens the report.
///
/// All scan pages use this so the flow (and its error handling) lives in one place.
class ScanRunner {
  ScanRunner._();

  static Future<bool> preferOnDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('setting_prefer_on_device') ?? false;
  }

  /// [analyze] receives `true` when private (on-device) mode is on.
  /// Returns true if a report was produced and opened.
  static Future<bool> run(
    BuildContext context,
    Future<ThreatReport> Function(bool forceLocalOnly) analyze,
  ) async {
    // Capture before any await so we never touch a stale context.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    final local = await preferOnDevice();
    final stage = ValueNotifier<int>(1);

    if (!context.mounted) return false;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: stage,
        builder: (_, s, __) => ForensicAnalysisHud(stage: s, isLocal: local, currentDetail: ''),
      ),
    );

    ThreatReport? report;
    Object? error;
    try {
      await Future.delayed(const Duration(milliseconds: 350));
      stage.value = 2;
      await Future.delayed(const Duration(milliseconds: 300));
      stage.value = 3;
      report = await analyze(local);
      stage.value = 4;
      await HistoryService.saveReport(report);
      await FirebaseService.syncInvestigationToCloud(report);
      await Future.delayed(const Duration(milliseconds: 250));
    } catch (e) {
      error = e;
    }

    navigator.pop(); // Always dismiss the progress pop-up, even if the page is gone.
    stage.dispose();

    if (error != null || report == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('The scan could not finish. Check your connection and try again.'),
          backgroundColor: AppColors.danger,
          action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
        ),
      );
      return false;
    }

    final done = report;
    navigator.push(MaterialPageRoute(builder: (_) => ReportScreen(report: done)));
    return true;
  }
}

/// Sticky bottom bar holding a page's single main action.
class ScanBottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;

  const ScanBottomBar({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.icon = Icons.shield_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF0D1424) : Colors.white,
        border: Border(top: BorderSide(color: context.outlineColor)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: Icon(icon, size: 20),
              label: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-line note showing where the scan will run.
class PrivacyNote extends StatefulWidget {
  const PrivacyNote({super.key});

  @override
  State<PrivacyNote> createState() => _PrivacyNoteState();
}

class _PrivacyNoteState extends State<PrivacyNote> {
  bool _local = true;

  @override
  void initState() {
    super.initState();
    ScanRunner.preferOnDevice().then((v) {
      if (mounted) setState(() => _local = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: context.mutedText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _local
                ? 'Private mode is on. Analysis runs on this device and personal details are masked.'
                : 'Cloud AI is on. Personal details are masked before anything leaves your device.',
            style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedText),
          ),
        ),
      ],
    );
  }
}

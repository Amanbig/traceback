import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/threat_report.dart';
import '../../models/scam_radar_item.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_dossier_service.dart';
import '../../services/vernacular_translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/hybrid_badge.dart';
import '../widgets/pii_preview_card.dart';

class ReportScreen extends StatefulWidget {
  final ThreatReport report;

  const ReportScreen({super.key, required this.report});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedLanguage = 'en'; // 'en' or 'hi'

  ThreatReport get report => widget.report;

  void _showFlagDetails(BuildContext context, String flag) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Anatomy of this Attack Marker',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Text(
                  flag,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The Psychological Trap:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Scammers exploit cognitive panic and artificial time scarcity to bypass your critical thinking. By threatening imminent loss (account suspension, legal arrest, electricity disconnection), they compel impulsive action before you can verify.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'What happens if a victim complies:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Entering credentials transfers full control of netbanking/UPI sessions or installs SMS-forwarding malware. Once submitted, fund exfiltration takes under 90 seconds.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color get _levelColor {
    switch (report.threatLevel) {
      case ThreatLevel.safe:
        return AppColors.safe;
      case ThreatLevel.low:
        return const Color(0xFF06B6D4);
      case ThreatLevel.suspicious:
        return AppColors.warn;
      case ThreatLevel.dangerous:
        return const Color(0xFFF97316);
      case ThreatLevel.critical:
        return AppColors.danger;
    }
  }

  String get _headline {
    switch (report.threatLevel) {
      case ThreatLevel.safe:
        return 'Looks safe';
      case ThreatLevel.low:
        return 'Low risk';
      case ThreatLevel.suspicious:
        return 'Be careful';
      case ThreatLevel.dangerous:
        return 'Likely a scam';
      case ThreatLevel.critical:
        return 'Scam detected';
    }
  }

  IconData get _levelIcon {
    if (report.riskScore >= 70) return Icons.gpp_bad_rounded;
    if (report.riskScore >= 40) return Icons.gpp_maybe_rounded;
    return Icons.verified_user_rounded;
  }

  void _copySummary(BuildContext context) {
    final summary = '''
TRACEBACK FRAUD INVESTIGATION REPORT
Risk Score: ${report.riskScore}/100 (${report.threatLevel.name.toUpperCase()})
Engine: ${report.isLocalInference ? 'On-Device Shield (Local Nano)' : 'Cloud AI (Gemini Flash)'}
Type: ${report.isChainScan ? 'Multi-Message Threat Chain' : report.isImageScan ? 'Screenshot Scan' : 'Message Scan'}

Summary:
${report.summary}

Red Flags:
${report.redFlags.map((f) => '• $f').join('\n')}

Recommended Next Steps:
${report.safeNextSteps.map((s) => '• $s').join('\n')}
''';
    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      );

  Widget _buildHero() {
    final color = _levelColor;
    final hi = _selectedLanguage == 'hi';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.24), context.surfaceColor],
        ),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: report.riskScore.clamp(0, 100) / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color.withOpacity(0.18),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${report.riskScore}',
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w800, color: color, height: 1)),
                    Text('/ 100', style: TextStyle(fontSize: 12, color: context.mutedText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_levelIcon, color: color, size: 26),
              const SizedBox(width: 8),
              Text(_headline,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hi
                ? VernacularTranslationService.getHindiSummary(
                    report.summary, report.threatLevel.name, report.riskScore)
                : report.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 14),
          HybridBadge(isLocal: report.isLocalInference),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 'en', label: Text('English')),
          ButtonSegment(value: 'hi', label: Text('हिंदी / Hinglish')),
        ],
        selected: {_selectedLanguage},
        onSelectionChanged: (s) => setState(() => _selectedLanguage = s.first),
      ),
    );
  }

  Widget _buildNextSteps() {
    final steps = _selectedLanguage == 'hi'
        ? VernacularTranslationService.getHindiNextSteps()
        : report.safeNextSteps;
    return AppCard(
      borderColor: AppColors.safe.withOpacity(0.4),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.safe.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.safe)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(steps[i], style: const TextStyle(fontSize: 14.5, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChain() {
    final stages = report.chainStages!;
    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              borderColor: i == stages.length - 1 ? AppColors.danger.withOpacity(0.5) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            i == stages.length - 1 ? AppColors.danger : AppColors.brand,
                        child: Text('${stages[i]['step']}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(stages[i]['stageName'] ?? 'Escalation step',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      StatusPill(
                        label: '${stages[i]['tacticDetected'] ?? 'Pressure'}',
                        color: i == stages.length - 1 ? AppColors.danger : AppColors.warn,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(stages[i]['rawMessage'] ?? '',
                      style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedEvidence() {
    final text = report.maskedSnippet;
    final triggers = [
      'arrest', 'warrant', 'cbi', 'police', 'customs', 'narcotics',
      'disconnect', 'tonight', 'immediately', 'urgent', 'urgency',
      'qr', 'upi', 'pin', 'apk', 'transfer', 'deposit', 'bond',
      'blocked', 'suspended', 'compromised', 'seized', 'passports',
      'drugs', 'refund', 'cashback', 'kyc', 'power office'
    ];

    final pattern = RegExp('(${triggers.join('|')})', caseSensitive: false);
    final spans = <TextSpan>[];

    int lastIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            fontFamily: 'monospace',
            color: context.isDark ? Colors.grey[300] : Colors.grey[800],
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: AppColors.danger,
          backgroundColor: Color(0x33EF4444),
          decoration: TextDecoration.underline,
          decorationColor: AppColors.danger,
        ),
      ));
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontFamily: 'monospace',
          color: context.isDark ? Colors.grey[300] : Colors.grey[800],
        ),
      ));
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              const Text('Deceptive Triggers in Evidence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('AUTO-TAGGED',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.danger)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(text: TextSpan(children: spans)),
          const SizedBox(height: 10),
          Text(
            'Highlighted words represent psychological coercion or urgency vectors flagged by the model.',
            style: TextStyle(fontSize: 11, color: context.mutedText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy summary',
            onPressed: () => _copySummary(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 8, AppSpacing.screenH, 32),
        children: [
          _buildHero(),
          const SizedBox(height: AppSpacing.md),
          _buildLanguageToggle(),
          const SizedBox(height: AppSpacing.xl),

          if (report.safeNextSteps.isNotEmpty) ...[
            _title(_selectedLanguage == 'hi' ? 'अब क्या करें' : 'What to do now'),
            _buildNextSteps(),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (report.redFlags.isNotEmpty) ...[
            _title('Warning signs (${report.redFlags.length})'),
            for (final flag in report.redFlags)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => _showFlagDetails(context, flag),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.report_problem_rounded, color: AppColors.warn, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(flag, style: const TextStyle(fontSize: 14.5, height: 1.4)),
                      ),
                      Icon(Icons.info_outline_rounded, size: 18, color: context.mutedText),
                    ],
                  ),
                ),
              ),
            Text('Tap a warning sign to learn why it matters.',
                style: TextStyle(fontSize: 13, color: context.mutedText)),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (report.tactics.isNotEmpty) ...[
            _title('Manipulation tactics'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in report.tactics)
                  StatusPill(label: t, color: AppColors.danger, icon: Icons.psychology_outlined),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (report.isChainScan &&
              report.chainStages != null &&
              report.chainStages!.isNotEmpty) ...[
            _title('How the scam escalated (${report.chainStages!.length} steps)'),
            _buildChain(),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (report.isImageScan && report.imageBase64 != null) ...[
            _title('Screenshot checked'),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                base64Decode(report.imageBase64!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          _title('Analyzed Evidence Transcript'),
          _buildHighlightedEvidence(),
          const SizedBox(height: AppSpacing.xl),

          PiiPreviewCard(
            originalText: report.originalSnippet,
            maskedText: report.maskedSnippet,
          ),
          if (report.riskScore >= 40) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sharing to the Radar removes names, numbers and account details first.',
              style: TextStyle(fontSize: 13, color: context.mutedText),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF0D1424) : Colors.white,
          border: Border(top: BorderSide(color: context.outlineColor)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: () => PdfDossierService.exportReportDossier(report),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: const Text('Export PDF'),
                  ),
                ),
                if (report.riskScore >= 40) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _reportToRadar(context),
                      icon: const Icon(Icons.campaign_outlined, size: 20),
                      label: const Text('Warn others'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reportToRadar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_alert_rounded, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text('Contribute to Radar',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share this anonymized scam pattern with the community to alert other citizens.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All personal data (names, accounts, numbers) has already been scrubbed on-device.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Sanitized Pattern Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.maskedSnippet,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final item = ScamRadarItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: report.tactics.isNotEmpty
                                ? report.tactics.first
                                : 'Reported Scam Pattern',
                            category: report.tactics.isNotEmpty
                                ? report.tactics.first
                                : 'Cyber Fraud',
                            sampleText: report.maskedSnippet,
                            severity: report.riskScore >= 75 ? 'Critical' : 'High',
                            targetAudience: 'General Citizens',
                            modusOperandi: report.summary,
                            warningSigns: report.redFlags,
                            safetyTip: report.safeNextSteps.isNotEmpty
                                ? report.safeNextSteps.first
                                : 'Do not reply or click any links in this message.',
                          );
                          await FirebaseService.submitCommunityScam(item);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Thank you! Scam pattern contributed to Community Radar.'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(isSubmitting ? 'Contributing...' : 'Submit to Radar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

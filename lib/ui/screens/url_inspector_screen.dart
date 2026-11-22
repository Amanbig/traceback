import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/url_threat_analyzer.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class UrlInspectorScreen extends StatefulWidget {
  final String? initialUrl;

  const UrlInspectorScreen({super.key, this.initialUrl});

  @override
  State<UrlInspectorScreen> createState() => _UrlInspectorScreenState();
}

class _UrlInspectorScreenState extends State<UrlInspectorScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _resultKey = GlobalKey();
  UrlThreatResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlController.text = widget.initialUrl!;
      _analyzeUrl(widget.initialUrl!);
    }
  }

  void _analyzeUrl(String url) {
    if (url.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _result = UrlThreatAnalyzer.analyze(url.trim()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link checker')),
      body: ListView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 32),
        children: [
          Text(
            'Paste a link to check for fake bank sites, look-alike domains and malware downloads. Nothing is opened.',
            style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            onSubmitted: _analyzeUrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. sbi-kyc-update.live',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded),
                tooltip: 'Paste',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  final text = data?.text?.trim();
                  if (text != null && text.isNotEmpty) {
                    setState(() => _urlController.text = text);
                    _analyzeUrl(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _urlController.text.trim().isEmpty
                  ? null
                  : () => _analyzeUrl(_urlController.text),
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Check link'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_result != null) ...[
            KeyedSubtree(key: _resultKey, child: _buildResult(_result!)),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionHeader('Try an example'),
          _sample(
            title: 'Fake bank KYC page',
            url: 'http://sbi-kyc-update.live/portal',
            desc: 'Not secure, imitates a bank, cheap .live domain',
            color: AppColors.danger,
          ),
          _sample(
            title: 'Look-alike PayPal login',
            url: 'http://paypa1-security.top/verify-login',
            desc: 'Number "1" used in place of letter "l"',
            color: const Color(0xFFF97316),
          ),
          _sample(
            title: 'Malware app download',
            url: 'http://185.220.101.5/challan.apk',
            desc: 'Raw IP address and an APK that can steal SMS',
            color: const Color(0xFFC084FC),
          ),
          _sample(
            title: 'Genuine site (for comparison)',
            url: 'https://www.apple.com',
            desc: 'Secure connection, well-known domain',
            color: AppColors.safe,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(UrlThreatResult res) {
    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;
    if (res.riskVerdict.startsWith('Critical')) {
      color = AppColors.danger;
      icon = Icons.gpp_bad_rounded;
      title = 'Dangerous link';
      subtitle = 'Do not open it or enter any details.';
    } else if (res.riskVerdict.startsWith('Suspicious')) {
      color = AppColors.warn;
      icon = Icons.gpp_maybe_rounded;
      title = 'Suspicious link';
      subtitle = 'Be careful. Verify the sender before you tap.';
    } else {
      color = AppColors.safe;
      icon = Icons.verified_user_rounded;
      title = 'No problems found';
      subtitle = 'This still does not guarantee a link is safe.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VerdictBanner(color: color, icon: icon, title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              DetailRow('Address', res.url),
              DetailRow('Connection', res.isSsl ? 'Secure (HTTPS)' : 'Not secure (HTTP)',
                  valueColor: res.isSsl ? AppColors.safe : AppColors.danger),
              DetailRow('Website', res.host,
                  valueColor:
                      res.hasBrandSquatting || res.isIpAddress ? AppColors.danger : null),
              if (res.tld.isNotEmpty)
                DetailRow('Ending', res.tld,
                    valueColor: res.hasSuspiciousDomain ? AppColors.warn : null),
              if (res.path.length > 1)
                DetailRow('Page', res.path,
                    valueColor: res.path.endsWith('.apk') ? AppColors.danger : null),
            ],
          ),
        ),
        if (res.flaggedReasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Why it was flagged'),
          for (final r in res.flaggedReasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report_problem_rounded, color: AppColors.warn, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 14.5, height: 1.4))),
                  ],
                ),
              ),
            ),
        ],
        if (res.officialAlternativeUrl != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            borderColor: AppColors.safe.withOpacity(0.45),
            color: AppColors.safe.withOpacity(0.08),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.safe),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Real ${res.impersonatedBrand ?? 'site'} address',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(res.officialAlternativeUrl!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.safe,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy address',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: res.officialAlternativeUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Official address copied')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sample({
    required String title,
    required String url,
    required String desc,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () {
          setState(() => _urlController.text = url);
          _analyzeUrl(url);
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.link_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 13, color: context.mutedText)),
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

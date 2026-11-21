import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/url_threat_analyzer.dart';

class UrlInspectorScreen extends StatefulWidget {
  final String? initialUrl;

  const UrlInspectorScreen({super.key, this.initialUrl});

  @override
  State<UrlInspectorScreen> createState() => _UrlInspectorScreenState();
}

class _UrlInspectorScreenState extends State<UrlInspectorScreen> {
  final TextEditingController _urlController = TextEditingController();
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
    setState(() {
      _result = UrlThreatAnalyzer.analyze(url);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('URL & Phishing Inspector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            Text(
              'Inspect suspicious links and QR destinations for typosquatting, deceptive subdomains, disposable TLDs, and malware downloads.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 16),

            // Input Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter or paste link (e.g. sbi-kyc-update.live)...',
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              setState(() => _urlController.text = data.text!);
                              _analyzeUrl(data.text!);
                            }
                          },
                          icon: const Icon(Icons.paste_rounded, size: 16),
                          label: const Text('Paste Link', style: TextStyle(fontSize: 12)),
                        ),
                        FilledButton.icon(
                          onPressed: () => _analyzeUrl(_urlController.text),
                          icon: const Icon(Icons.travel_explore_rounded, size: 16),
                          label: const Text('Analyze', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Analysis Result Card
            if (_result != null) ...[
              _buildResultCard(context, _result!, isDark),
              const SizedBox(height: 24),
            ],

            // Preset Test Links
            const Text(
              'Preset Phishing Link Scenarios',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            _buildSampleLinkTile(
              title: 'Bank KYC Subdomain Impersonation',
              url: 'http://sbi-kyc-update.live/portal',
              desc: 'Insecure HTTP • Spoofed Brand • Disposable .live TLD',
              color: Colors.redAccent,
            ),
            _buildSampleLinkTile(
              title: 'PayPal Typosquatting Attack',
              url: 'http://paypa1-security.top/verify-login',
              desc: 'Substituted numeral "1" for letter "l" • Credential Action',
              color: Colors.orangeAccent,
            ),
            _buildSampleLinkTile(
              title: 'Direct IP Host & Malware APK',
              url: 'http://185.220.101.5/challan.apk',
              desc: 'Direct IP Host • SMS-Stealing Android APK Installer',
              color: Colors.purpleAccent,
            ),
            _buildSampleLinkTile(
              title: 'Legitimate Official Domain (Control)',
              url: 'https://www.apple.com',
              desc: 'Encrypted HTTPS • Registered Corporate Domain',
              color: Colors.green,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, UrlThreatResult res, bool isDark) {
    Color verdictColor = Colors.green;
    IconData verdictIcon = Icons.verified_user_rounded;

    if (res.riskVerdict == 'Critical Phishing Link') {
      verdictColor = Colors.redAccent;
      verdictIcon = Icons.dangerous_rounded;
    } else if (res.riskVerdict == 'Suspicious Domain') {
      verdictColor = Colors.orangeAccent;
      verdictIcon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: verdictColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(verdictIcon, color: verdictColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.riskVerdict.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: verdictColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      res.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Domain Anatomy Breakdown
          const Text(
            'URL Lexical Anatomy:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAnatomyPill(
                'Protocol: ${res.protocol}://',
                res.isSsl ? Colors.green : Colors.redAccent,
              ),
              _buildAnatomyPill(
                'Host: ${res.host}',
                res.hasBrandSquatting || res.isIpAddress ? Colors.redAccent : Colors.blueAccent,
              ),
              if (res.tld.isNotEmpty)
                _buildAnatomyPill(
                  'TLD: ${res.tld}',
                  res.hasSuspiciousDomain ? Colors.orangeAccent : Colors.grey,
                ),
              if (res.path.length > 1)
                _buildAnatomyPill(
                  'Path: ${res.path}',
                  res.path.endsWith('.apk') ? Colors.redAccent : Colors.teal,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Flagged Security Findings
          if (res.flaggedReasons.isNotEmpty) ...[
            const Text(
              'Security Red Flags:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...res.flaggedReasons.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.redAccent, size: 18),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Legitimate Official Alternative
          if (res.officialAlternativeUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Official Alternative for ${res.impersonatedBrand ?? "Brand"}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          res.officialAlternativeUrl!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: res.officialAlternativeUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied verified official URL to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnatomyPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildSampleLinkTile({
    required String title,
    required String url,
    required String desc,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        onTap: () {
          setState(() => _urlController.text = url);
          _analyzeUrl(url);
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.link, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          desc,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12),
      ),
    );
  }
}

class UrlThreatResult {
  final String url;
  final String protocol;
  final String host;
  final String tld;
  final String path;
  final bool isSsl;
  final bool hasSuspiciousDomain;
  final bool isIpAddress;
  final bool hasBrandSquatting;
  final String? impersonatedBrand;
  final String? officialAlternativeUrl;
  final String riskVerdict; // Safe, Suspicious, Critical Phishing
  final List<String> flaggedReasons;

  UrlThreatResult({
    required this.url,
    required this.protocol,
    required this.host,
    required this.tld,
    required this.path,
    required this.isSsl,
    required this.hasSuspiciousDomain,
    required this.isIpAddress,
    required this.hasBrandSquatting,
    this.impersonatedBrand,
    this.officialAlternativeUrl,
    required this.riskVerdict,
    required this.flaggedReasons,
  });

  bool get isSuspicious => flaggedReasons.isNotEmpty;
}

class UrlThreatAnalyzer {
  static final RegExp _urlRegex = RegExp(
    r'https?://[^\s<>"]+|www\.[^\s<>"]+',
    caseSensitive: false,
  );

  static final List<String> _suspiciousTlds = [
    '.top', '.xyz', '.click', '.live', '.loan', '.work',
    '.icu', '.buzz', '.rest', '.link', '.bar', '.quest',
    '.support', '.vip', '.cfd', '.sbs', '.cc',
  ];

  static final Map<String, String> _brandOfficialUrls = {
    'paypal': 'https://www.paypal.com',
    'apple': 'https://www.apple.com',
    'netflix': 'https://www.netflix.com',
    'amazon': 'https://www.amazon.com',
    'google': 'https://www.google.com',
    'chase': 'https://www.chase.com',
    'wellsfargo': 'https://www.wellsfargo.com',
    'sbi': 'https://onlinesbi.sbi',
    'hdfc': 'https://www.hdfcbank.com',
    'icici': 'https://www.icicibank.com',
    'axis': 'https://www.axisbank.com',
    'paytm': 'https://paytm.com',
    'fedex': 'https://www.fedex.com',
    'dhl': 'https://www.dhl.com',
    'binance': 'https://www.binance.com',
  };

  static final List<String> _phishingKeywords = [
    'verify', 'verification', 'kyc', 'suspend', 'suspended',
    'blocked', 'restore', 'unblock', 'security-update', 'login-confirm',
    'claim', 'reward', 'refund', 'refund-portal', 'ebill', 'challan',
  ];

  static List<UrlThreatResult> analyzeAll(String text) {
    final matches = _urlRegex.allMatches(text);
    final results = <UrlThreatResult>[];

    for (final match in matches) {
      final rawUrl = match.group(0)!;
      results.add(analyze(rawUrl));
    }

    return results;
  }

  static UrlThreatResult analyze(String rawUrl) {
    final reasons = <String>[];
    String formattedUrl = rawUrl.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    Uri? uri;
    try {
      uri = Uri.parse(formattedUrl);
    } catch (_) {
      reasons.add('Malformed URL syntax');
      return UrlThreatResult(
        url: rawUrl,
        protocol: 'unknown',
        host: 'invalid',
        tld: 'none',
        path: '',
        isSsl: false,
        hasSuspiciousDomain: true,
        isIpAddress: false,
        hasBrandSquatting: false,
        riskVerdict: 'Critical Phishing',
        flaggedReasons: reasons,
      );
    }

    final protocol = uri.scheme;
    final host = uri.host.toLowerCase();
    final path = uri.path;
    final isSsl = protocol == 'https';

    bool isIp = false;
    bool hasSuspiciousTld = false;
    bool hasBrandSquatting = false;
    String detectedTld = '';
    String? matchedBrand;
    String? officialUrl;

    if (!isSsl) {
      reasons.add('Insecure unencrypted connection (HTTP instead of HTTPS)');
    }

    // 1. IP address host
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(host)) {
      isIp = true;
      reasons.add('Direct numeric IP address ($host) bypasses legitimate domain reputation checks');
    }

    // 2. Punycode check
    if (host.startsWith('xn--') || host.contains('.xn--')) {
      reasons.add('Punycode / Homograph domain detected (uses lookalike foreign characters to spoof trusted domains)');
    }

    // 3. Suspicious TLD check
    for (final tld in _suspiciousTlds) {
      if (host.endsWith(tld)) {
        hasSuspiciousTld = true;
        detectedTld = tld;
        reasons.add('Disposable high-risk top-level domain ($tld) frequently purchased anonymously for fraud campaigns');
        break;
      }
    }

    // 4. Brand squatting & typosquatting check
    for (final entry in _brandOfficialUrls.entries) {
      final brand = entry.key;
      if (host.contains(brand)) {
        final isLegit = host == '$brand.com' ||
            host == 'www.$brand.com' ||
            host == '$brand.in' ||
            host == 'www.$brand.in' ||
            host == '$brand.co.in' ||
            host == 'www.$brand.co.in' ||
            host == 'onlinesbi.sbi';

        if (!isLegit) {
          hasBrandSquatting = true;
          matchedBrand = brand.toUpperCase();
          officialUrl = entry.value;
          reasons.add('Brand Impersonation: Domain unauthorizedly contains "$brand" inside deceptive host "$host"');
        }
      }
    }

    // 5. Phishing keywords in path or query
    final pathAndQuery = (uri.path + uri.query).toLowerCase();
    for (final keyword in _phishingKeywords) {
      if (pathAndQuery.contains(keyword)) {
        reasons.add('Suspicious URL action: Solicits sensitive user action ("$keyword")');
        break;
      }
    }

    // 6. APK download check
    if (path.endsWith('.apk')) {
      reasons.add('Direct Android Package (.apk) installer link — high probability SMS-stealing malware');
    }

    String verdict;
    if (isIp || hasBrandSquatting || path.endsWith('.apk') || reasons.length >= 3) {
      verdict = 'Critical Phishing Link';
    } else if (hasSuspiciousTld || reasons.isNotEmpty) {
      verdict = 'Suspicious Domain';
    } else {
      verdict = 'Legitimate / Standard URL';
    }

    return UrlThreatResult(
      url: rawUrl,
      protocol: protocol,
      host: host,
      tld: detectedTld.isNotEmpty ? detectedTld : (host.contains('.') ? '.${host.split('.').last}' : ''),
      path: path.isNotEmpty ? path : '/',
      isSsl: isSsl,
      hasSuspiciousDomain: hasSuspiciousTld,
      isIpAddress: isIp,
      hasBrandSquatting: hasBrandSquatting,
      impersonatedBrand: matchedBrand,
      officialAlternativeUrl: officialUrl,
      riskVerdict: verdict,
      flaggedReasons: reasons,
    );
  }
}

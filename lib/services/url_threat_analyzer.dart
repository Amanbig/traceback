class UrlThreatResult {
  final String url;
  final bool hasSuspiciousDomain;
  final bool isIpAddress;
  final bool hasBrandSquatting;
  final List<String> flaggedReasons;

  UrlThreatResult({
    required this.url,
    required this.hasSuspiciousDomain,
    required this.isIpAddress,
    required this.hasBrandSquatting,
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

  static final List<String> _targetedBrands = [
    'paypal', 'apple', 'netflix', 'amazon', 'google', 'chase',
    'wellsfargo', 'bankofamerica', 'sbi', 'hdfc', 'icici', 'axis',
    'paytm', 'fedex', 'dhl', 'usps', 'ups', 'microsoft', 'binance',
    'metamask', 'coinbase',
  ];

  static final List<String> _phishingKeywords = [
    'verify', 'verification', 'kyc', 'suspend', 'suspended',
    'blocked', 'restore', 'unblock', 'security-update', 'login-confirm',
    'claim', 'reward', 'refund', 'refund-portal', 'ebill',
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
    String formattedUrl = rawUrl;
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    Uri? uri;
    try {
      uri = Uri.parse(formattedUrl);
    } catch (_) {
      reasons.add('Malformed URL structure');
      return UrlThreatResult(
        url: rawUrl,
        hasSuspiciousDomain: true,
        isIpAddress: false,
        hasBrandSquatting: false,
        flaggedReasons: reasons,
      );
    }

    final host = uri.host.toLowerCase();
    bool isIp = false;
    bool hasSuspiciousTld = false;
    bool hasBrandSquatting = false;

    // 1. IP address host detection
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (ipRegex.hasMatch(host)) {
      isIp = true;
      reasons.add('Direct IP address used instead of legitimate registered domain');
    }

    // 2. Punycode check
    if (host.startsWith('xn--') || host.contains('.xn--')) {
      reasons.add('Punycode / Homograph domain detected (possible spoofed characters)');
    }

    // 3. Suspicious TLD check
    for (final tld in _suspiciousTlds) {
      if (host.endsWith(tld)) {
        hasSuspiciousTld = true;
        reasons.add('High-risk top-level domain ($tld) commonly associated with disposable phishing campaigns');
        break;
      }
    }

    // 4. Brand squatting / typosquatting check
    for (final brand in _targetedBrands) {
      if (host.contains(brand)) {
        // Check if the domain is legitimately that brand
        final isOfficial = host == '$brand.com' ||
            host == 'www.$brand.com' ||
            host == '$brand.in' ||
            host == 'www.$brand.in' ||
            host == '$brand.co.in' ||
            host == 'www.$brand.co.in';

        if (!isOfficial) {
          hasBrandSquatting = true;
          reasons.add('Domain impersonates trusted service "$brand" ($host)');
        }
      }
    }

    // 5. Sensitive action keywords in path or query
    final pathAndQuery = (uri.path + uri.query).toLowerCase();
    for (final keyword in _phishingKeywords) {
      if (pathAndQuery.contains(keyword)) {
        reasons.add('URL path invokes sensitive credential action ("$keyword")');
        break;
      }
    }

    return UrlThreatResult(
      url: rawUrl,
      hasSuspiciousDomain: hasSuspiciousTld,
      isIpAddress: isIp,
      hasBrandSquatting: hasBrandSquatting,
      flaggedReasons: reasons,
    );
  }
}

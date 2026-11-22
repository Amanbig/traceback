class UpiQrAnalysisResult {
  final String rawPayload;
  final bool isUpiIntent;
  final bool isWebUrl;
  final bool isApkDownload;
  final String? payeeVpa;
  final String? payeeName;
  final String? requestedAmount;
  final String? transactionNote;
  final String? currency;
  final int riskScore; // 0 to 100
  final String riskSeverity; // Safe, Suspicious, Critical Trap
  final List<String> redFlags;
  final List<String> safetyAdvisories;

  const UpiQrAnalysisResult({
    required this.rawPayload,
    required this.isUpiIntent,
    required this.isWebUrl,
    required this.isApkDownload,
    this.payeeVpa,
    this.payeeName,
    this.requestedAmount,
    this.transactionNote,
    this.currency,
    required this.riskScore,
    required this.riskSeverity,
    required this.redFlags,
    required this.safetyAdvisories,
  });
}

class UpiQrAnalyzer {
  static UpiQrAnalysisResult analyze(String input) {
    final trimmed = input.trim();
    final redFlags = <String>[];
    final safetyAdvisories = <String>[];
    int score = 0;

    final lower = trimmed.toLowerCase();
    final isUpi = lower.startsWith('upi://');
    final isWeb = lower.startsWith('http://') || lower.startsWith('https://');
    final isApk = lower.endsWith('.apk') || lower.contains('.apk?') || lower.contains('/apk/');

    String? vpa;
    String? name;
    String? amount;
    String? note;
    String? currency;

    if (isUpi) {
      try {
        final uri = Uri.parse(trimmed);
        final params = uri.queryParameters;
        vpa = params['pa'];
        name = params['pn'];
        amount = params['am'];
        note = params['tn'];
        currency = params['cu'] ?? 'INR';

        // 1. Fundamental UPI Trap Check: Scanning QR only debits!
        score += 35;
        redFlags.add(
            'UPI DEBIT INTENT: Scanning this QR code will SEND/DEBIT money from your bank account, NEVER credit or receive.');

        // 2. Amount Analysis
        if (amount != null && double.tryParse(amount) != null) {
          final amtVal = double.parse(amount);
          if (amtVal > 0) {
            score += 25;
            redFlags.add(
                'EXPLICIT DEBIT AMOUNT: This QR will immediately request ₹$amount from your account upon PIN entry.');
          }
        }

        // 3. Deceptive Transaction Notes
        if (note != null) {
          final noteLower = note.toLowerCase();
          final deceptiveKeywords = [
            'refund',
            'cashback',
            'receive',
            'credit',
            'prize',
            'reward',
            'claim',
            'bonus',
            'olx',
            'lottery',
            'kyc'
          ];
          for (final kw in deceptiveKeywords) {
            if (noteLower.contains(kw)) {
              score += 30;
              redFlags.add(
                  'DECEPTIVE TRANSACTION NOTE: The note "$note" mimics a refund or reward to trick you into entering your UPI PIN.');
              break;
            }
          }
        }

        // 4. Payee Name & VPA Analysis
        if (vpa != null) {
          final vpaLower = vpa.toLowerCase();
          final authorityKeywords = ['police', 'customs', 'income.tax', 'rbi', 'govt', 'official', 'refund', 'helpdesk'];
          for (final kw in authorityKeywords) {
            if (vpaLower.contains(kw) &&
                (vpaLower.contains('@ok') || vpaLower.contains('@ybl') || vpaLower.contains('@paytm') || vpaLower.contains('@ibl'))) {
              score += 25;
              redFlags.add(
                  'IMPERSONATION VPA: The address "$vpa" uses official-sounding words on a free personal payment handle.');
              break;
            }
          }
        }

        safetyAdvisories.add(
            'GOLDEN RULE: Receiving money on UPI NEVER requires scanning a QR code or entering your UPI PIN.');
        safetyAdvisories.add(
            'If someone told you to scan this to "receive payment" for OLX, rental deposit, or customer refund, it is 100% a scam.');
        safetyAdvisories.add('Do not scan this QR in GPay, PhonePe, Paytm, or BHIM.');
      } catch (e) {
        score += 20;
        redFlags.add('Malformed or obfuscated UPI payment string.');
      }
    } else if (isApk) {
      score = 95;
      redFlags.add('CRITICAL MALWARE VECTOR: This QR payload links directly to an Android APK download.');
      redFlags.add('Installing this package can install SMS-stealing trojans, screen recorders, or remote access RATs.');
      safetyAdvisories.add('Do NOT download or install the referenced application.');
      safetyAdvisories.add('Real banking applications are only installed via Google Play Store, never via direct QR links.');
    } else if (isWeb) {
      score += 20;
      redFlags.add('QR code resolves to an external web address rather than an authenticated application.');
      if (lower.startsWith('http://')) {
        score += 25;
        redFlags.add('INSECURE HTTP: The link does not use TLS encryption.');
      }
      safetyAdvisories.add('Verify the destination domain carefully before entering credentials.');
    } else {
      score += 15;
      redFlags.add('Unrecognized or custom scheme QR payload.');
    }

    final cappedScore = score.clamp(0, 100);
    final severity = cappedScore >= 75
        ? 'CRITICAL TRAP'
        : cappedScore >= 40
            ? 'SUSPICIOUS'
            : 'SAFE';

    return UpiQrAnalysisResult(
      rawPayload: trimmed,
      isUpiIntent: isUpi,
      isWebUrl: isWeb,
      isApkDownload: isApk,
      payeeVpa: vpa,
      payeeName: name,
      requestedAmount: amount,
      transactionNote: note,
      currency: currency,
      riskScore: cappedScore,
      riskSeverity: severity,
      redFlags: redFlags,
      safetyAdvisories: safetyAdvisories,
    );
  }
}

import '../models/threat_report.dart';
import 'url_threat_analyzer.dart';

class LocalThreatClassifier {
  /// Evaluates text completely on-device using comprehensive heuristic patterns,
  /// urgency scoring, multi-vector fraud taxonomy, and lexical security rules.
  static ThreatReport classifyOnDevice({
    required String id,
    required String originalSnippet,
    required String maskedSnippet,
  }) {
    final lower = maskedSnippet.toLowerCase();
    int riskScore = 0;
    final redFlags = <String>[];
    final tactics = <String>[];
    final safeNextSteps = <String>[];
    final primaryVectors = <String>[];

    // 1. Remote Access Trojans (RAT) & Dangerous APK Sideloading
    final apkTriggers = [
      'download apk', 'install apk', '.apk', 'download app', 'sideload',
      'anydesk', 'rustdesk', 'teamviewer', 'quicksupport', 'screen share',
      'allow unknown sources', 'install update package', 'update application'
    ];
    for (final trigger in apkTriggers) {
      if (lower.contains(trigger)) {
        riskScore += 45;
        tactics.add('Remote Access Trojan / Malware Sideloading');
        redFlags.add('Instructs victim to install an unverified APK or screen-sharing application ($trigger)');
        primaryVectors.add('Remote Access Trojan / Malicious APK Sideloading');
        safeNextSteps.add('NEVER install or open .apk files received over SMS or WhatsApp');
        safeNextSteps.add('If already installed, immediately disconnect Wi-Fi/Mobile Data and uninstall the app in Android Safe Mode');
        break;
      }
    }

    // 2. Digital Arrest & Law Enforcement Impersonation
    final legalTriggers = [
      'digital arrest', 'cbi', 'narcotics', 'ncb', 'customs seizure',
      'illegal parcel', 'money laundering', 'delhi police', 'mumbai police',
      'cyber crime cell', 'supreme court', 'arrest warrant', 'skype statement',
      'video call verification', 'trai disconnection', 'sim blocked within 2 hours'
    ];
    int legalCount = 0;
    for (final phrase in legalTriggers) {
      if (lower.contains(phrase)) {
        legalCount++;
      }
    }
    if (legalCount > 0) {
      riskScore += (35 + legalCount * 12).clamp(35, 60);
      tactics.add('Authority / Law Enforcement Impersonation');
      tactics.add('Coercive Psychological Intimidation');
      redFlags.add('Falsely claims official law enforcement authority or legal seizure');
      redFlags.add('Uses "Digital Arrest" or video call interrogation to isolate victim');
      primaryVectors.add('Digital Arrest / Law Enforcement Impersonation');
      safeNextSteps.add('Indian police, CBI, or courts NEVER conduct "Digital Arrests" or demand money over Skype/WhatsApp');
      safeNextSteps.add('Disconnect immediately; real police issue written summons under Section 41A CrPC');
    }

    // 3. Reverse UPI & Cashback QR Scam (Enter PIN to receive)
    final upiTriggers = [
      'enter pin to receive', 'enter upi pin', 'claim cashback', 'lottery winner',
      'gpay scratch card', 'phonepe reward', 'paytm cashback', 'approve request on phonepe',
      'scan qr to get money', 'refund credited'
    ];
    for (final trigger in upiTriggers) {
      if (lower.contains(trigger)) {
        riskScore += 40;
        tactics.add('Reverse Payment / Deceptive UPI Collect Request');
        redFlags.add('Deceptively implies entering a UPI PIN will receive or credit money ($trigger)');
        primaryVectors.add('UPI Reverse PIN / Collect Request Exploit');
        safeNextSteps.add('CRITICAL RULE: You NEVER need to enter your UPI PIN to RECEIVE money');
        safeNextSteps.add('Decline any pending collect requests on PhonePe, GPay, or Paytm');
        break;
      }
    }

    // 4. Electricity & Utility Bill Disconnection Scam
    if (lower.contains('electricity disconnected') ||
        lower.contains('power will be disconnected') ||
        lower.contains('electricity bill unpaid') ||
        (lower.contains('electricity') && (lower.contains('officer') || lower.contains('call')))) {
      riskScore += 40;
      tactics.add('Utility Disconnection Extortion');
      redFlags.add('Threatens immediate night-time utility cut-off to force panic payment');
      primaryVectors.add('Utility Bill Disconnection Panic Scam');
      safeNextSteps.add('Power discoms never send WhatsApp/SMS from personal mobile numbers demanding urgent payment');
      safeNextSteps.add('Verify your bill status exclusively on the official state electricity portal or consumer app');
    }

    // 5. Fake Traffic Challan Trap
    if (lower.contains('traffic challan') ||
        lower.contains('echallan') ||
        lower.contains('parivahan notice') ||
        lower.contains('vehicle fine pending')) {
      riskScore += 35;
      tactics.add('Traffic E-Challan Spoofing');
      redFlags.add('Uses fake traffic violation notices to distribute phishing portals or spyware');
      primaryVectors.add('Fake E-Challan Phishing');
      safeNextSteps.add('Pay or verify challans ONLY through the official Parivahan portal (echallan.parivahan.gov.in)');
    }

    // 6. Work From Home / Task Rating / YouTube Like Trap
    final jobTriggers = [
      'like youtube videos', 'telegram task', 'part-time job', 'earn 3000',
      'earn 5000 daily', 'hotel review rating', 'prepaid task', 'crypto investment group',
      'vip task', 'daily withdrawal income'
    ];
    for (final trigger in jobTriggers) {
      if (lower.contains(trigger)) {
        riskScore += 35;
        tactics.add('Part-Time Job / Task Investment Ponzi');
        redFlags.add('Promises unrealistic daily earnings for trivial online tasks ($trigger)');
        primaryVectors.add('Task Scam / Fake Investment Funnel');
        safeNextSteps.add('Legitimate companies never pay via Telegram for liking YouTube videos or Google Maps reviews');
        safeNextSteps.add('Do not transfer "deposit" or "prepaid task unlock" fees under any circumstances');
        break;
      }
    }

    // 7. Bank KYC & Account Expiry Threats
    final credentialWords = [
      'verify account', 'update kyc', 'pan card expired', 'aadhaar link', 'verify identity',
      'sbi yono blocked', 'hdfc netbanking locked', 'reward points expire', 'debit card blocked'
    ];
    for (final phrase in credentialWords) {
      if (lower.contains(phrase)) {
        riskScore += 30;
        tactics.add('Credential & Banking Harvesting');
        redFlags.add('Solicits sensitive credentials, PAN/Aadhaar details, or banking authentication ($phrase)');
        primaryVectors.add('Banking KYC / Account Suspension Phishing');
        safeNextSteps.add('Banks NEVER send SMS links to update KYC or unblock YONO/NetBanking');
        safeNextSteps.add('Visit your bank branch directly or use the official mobile banking app');
        break;
      }
    }

    // 8. Artificial Urgency & Panic Triggers
    final urgencyWords = [
      'immediately', 'urgent', 'today', '24 hours', 'suspended', 'blocked',
      'final notice', 'within 10 minutes', 'within 30 minutes', 'penalty'
    ];
    int urgencyCount = 0;
    for (final word in urgencyWords) {
      if (lower.contains(word)) {
        urgencyCount++;
      }
    }
    if (urgencyCount > 0) {
      riskScore += (urgencyCount * 12).clamp(12, 36);
      tactics.add('Urgency & Fear Manipulation');
      redFlags.add('Artificially pressured time limits designed to induce panic and bypass critical thinking');
    }

    // 9. URL Threat Inspection (Typosquatting & Suspicious TLDs)
    final urlResults = UrlThreatAnalyzer.analyzeAll(originalSnippet);
    if (urlResults.isNotEmpty) {
      for (final urlRes in urlResults) {
        if (urlRes.isSuspicious) {
          riskScore += 35;
          tactics.add('Deceptive Phishing Link');
          redFlags.addAll(urlRes.flaggedReasons);
          primaryVectors.add('Deceptive / Typosquatted Domain (${urlRes.host})');
        }
      }
    }

    // Normalize risk score
    riskScore = riskScore.clamp(5, 98);

    // Determine Threat Level
    ThreatLevel level;
    if (riskScore >= 75) {
      level = ThreatLevel.critical;
    } else if (riskScore >= 55) {
      level = ThreatLevel.dangerous;
    } else if (riskScore >= 35) {
      level = ThreatLevel.suspicious;
    } else if (riskScore >= 20) {
      level = ThreatLevel.low;
    } else {
      level = ThreatLevel.safe;
    }

    // Default safe steps
    if (level == ThreatLevel.critical || level == ThreatLevel.dangerous) {
      safeNextSteps.add('Do NOT click any links, scan QR codes, or download files');
      safeNextSteps.add('Do NOT share OTPs, PINs, passwords, or card CVVs');
      safeNextSteps.add('Block and report the sender number immediately');
      safeNextSteps.add('If money was lost in the last 2 hours, call national helpline 1930 immediately');
    } else if (level == ThreatLevel.suspicious) {
      safeNextSteps.add('Proceed with caution: verify sender authenticity before responding');
      safeNextSteps.add('Search the official customer care number directly on official portals');
    } else {
      safeNextSteps.add('No active fraud vectors detected. Continue practicing standard cyber hygiene');
    }

    // Context-tailored forensic summary
    String summary;
    if (primaryVectors.isNotEmpty) {
      final vectorsList = primaryVectors.toSet().join(' & ');
      if (level == ThreatLevel.critical) {
        summary = 'High-confidence cyber fraud attack detected on-device ($vectorsList). Employs aggressive social engineering designed to cause financial loss or credential compromise.';
      } else {
        summary = 'Potential social engineering attack flagged on-device ($vectorsList). Uses deceptive pretexts to provoke an immediate response.';
      }
    } else if (level == ThreatLevel.critical) {
      summary = 'High-confidence fraudulent communication attempting credential theft or financial extortion through coercive tactics.';
    } else if (level == ThreatLevel.dangerous) {
      summary = 'Dangerous message exhibiting significant phishing markers, deceptive links, or false urgency.';
    } else if (level == ThreatLevel.suspicious) {
      summary = 'Contains ambiguous or urgency-based wording. Exercise caution and verify via official channels.';
    } else {
      summary = 'Appears to be a benign or standard operational message with no recognized phishing indicators.';
    }

    return ThreatReport(
      id: id,
      originalSnippet: originalSnippet,
      maskedSnippet: maskedSnippet,
      riskScore: riskScore,
      threatLevel: level,
      summary: summary,
      redFlags: redFlags.toSet().toList(),
      tactics: tactics.toSet().toList(),
      safeNextSteps: safeNextSteps.toSet().toList(),
      isLocalInference: true,
      createdAt: DateTime.now(),
    );
  }
}

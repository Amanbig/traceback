class ScamRadarItem {
  final String id;
  final String title;
  final String category;
  final String sampleText;
  final String severity; // High, Critical, Medium
  final String targetAudience;
  final String modusOperandi;
  final List<String> warningSigns;
  final String safetyTip;

  const ScamRadarItem({
    required this.id,
    required this.title,
    required this.category,
    required this.sampleText,
    required this.severity,
    required this.targetAudience,
    required this.modusOperandi,
    required this.warningSigns,
    required this.safetyTip,
  });

  static const List<ScamRadarItem> trendingScams = [
    ScamRadarItem(
      id: 'scam-01',
      title: 'Digital Arrest & Illegal Parcel Scam',
      category: 'Authority Impersonation',
      severity: 'Critical',
      sampleText:
          'Your Aadhaar details were used to send a parcel to Cambodia containing illegal passports and drugs. Case #CR-9102 registered by Narcotics Bureau. Join Skype call immediately for verification or police will be dispatched to your residence.',
      targetAudience: 'Professionals, Senior Citizens, General Public',
      modusOperandi:
          'Scammers pose as courier agents (FedEx/DHL) and transfer calls to fake police/CBI officers in counterfeit uniforms. They isolate the victim on continuous video calls ("digital arrest") and coerce them into transferring funds to "secret government verification accounts".',
      warningSigns: [
        'Demands for video calls on Skype or WhatsApp in police uniform',
        'Coercion to stay isolated and not contact family',
        'Directing funds to "safe RBI verification" accounts',
      ],
      safetyTip:
          'Real law enforcement agencies NEVER conduct arrests over Skype/video call or demand fund transfers. Hang up immediately and dial cyber helpline 1930.',
    ),
    ScamRadarItem(
      id: 'scam-02',
      title: 'Electricity Bill Disconnection Panic',
      category: 'Urgency & Utility',
      severity: 'High',
      sampleText:
          'Dear Consumer, Your electricity power will be disconnected tonight at 9:30 PM from the power office because your previous month bill was not updated. Please immediately contact our electricity officer at 98123-XXXXX. Thank you.',
      targetAudience: 'Homeowners, Tenants, Small Businesses',
      modusOperandi:
          'Sent via bulk SMS late in the afternoon or evening. Scammers instruct the caller to download a remote-access app (AnyDesk, QuickSupport) or pay a nominal ₹10 fee via an unsecured phishing link to drain their account.',
      warningSigns: [
        'Personal 10-digit mobile number provided for customer care',
        'Imminent cutoff deadline within a few hours',
        'Instructions to install screen-sharing apps',
      ],
      safetyTip:
          'Check your bill status only on the official state electricity utility website or app. Never install screen-sharing applications on request.',
    ),
    ScamRadarItem(
      id: 'scam-03',
      title: 'Bank KYC & Account Block Phishing',
      category: 'Financial Phishing',
      severity: 'Critical',
      sampleText:
          'Dear Customer, Your State Bank / HDFC netbanking account has been suspended today due to missing PAN card verification. Click here to verify and restore access immediately: http://sbi-kyc-update.live/portal',
      targetAudience: 'Bank Account Holders',
      modusOperandi:
          'Directs users to a visually indistinguishable clone of the banking portal. Once the victim enters their username, password, and OTP, the attackers instantly execute high-value fund transfers.',
      warningSigns: [
        'Suspicious URL domain (e.g. .live, .top, .xyz instead of official .com/.co.in)',
        'Threatens immediate account suspension',
        'Asks for full login credentials and OTP on an external form',
      ],
      safetyTip:
          'Banks never send links via SMS to update KYC or PAN. Always log in directly through the official bank app or official verified URL.',
    ),
    ScamRadarItem(
      id: 'scam-04',
      title: 'Part-Time Task & YouTube Video Like Fraud',
      category: 'Investment & Job Fraud',
      severity: 'High',
      sampleText:
          'Earn ₹3,000 to ₹8,000 daily from home! Work just 30 minutes liking YouTube videos and rating Google Maps places. No experience required. Daily instant payout to UPI. Contact recruiter on Telegram @GlobalHRTasks.',
      targetAudience: 'Students, Job Seekers, Homemakers',
      modusOperandi:
          'Victims receive small genuine payouts (₹150 - ₹500) for initial easy tasks to build trust. Then they are invited to "VIP prepaid investment tasks" requiring ₹10,000 to ₹50,000 deposits, which are then frozen and stolen.',
      warningSigns: [
        'Unrealistic daily income for minimal effort',
        'Recruiter operates exclusively over Telegram/WhatsApp',
        'Requirement to pay money upfront to unlock earnings',
      ],
      safetyTip:
          'Legitimate companies never ask employees to pay money to receive work or complete tasks.',
    ),
    ScamRadarItem(
      id: 'scam-05',
      title: 'Fake Traffic E-Challan APK Scam',
      category: 'Mobile Malware',
      severity: 'Critical',
      sampleText:
          'Notice: You have 1 pending traffic violation recorded on camera at City Center. Pay ₹500 fine to avoid vehicle impoundment. Download official Challan App: http://traffic-police-portal.xyz/challan.apk',
      targetAudience: 'Vehicle Owners',
      modusOperandi:
          'The link tricks users into downloading and installing an Android APK file. The APK contains SMS-stealing spyware that reads incoming OTPs and bank credentials in the background.',
      warningSigns: [
        'Direct download of an .apk file from a random website',
        'Missing vehicle registration number or violation photograph',
        'Urgent threat of vehicle impoundment',
      ],
      safetyTip:
          'Never install APK files received via SMS or messaging apps. Pay challans exclusively on the official government transport portal (echallan.parivahan.gov.in).',
    ),
  ];
}

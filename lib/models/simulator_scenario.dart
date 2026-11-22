class SimulatorScenario {
  final String id;
  final String title;
  final String category;
  final String sender;
  final String simulatedMessage;
  final String promptQuestion;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String attackVector;

  const SimulatorScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.sender,
    required this.simulatedMessage,
    required this.promptQuestion,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.attackVector,
  });

  static const List<SimulatorScenario> scenarios = [
    SimulatorScenario(
      id: 'sim-1',
      title: 'Digital Arrest Threat',
      category: 'Authority Impersonation',
      sender: '+91 98765-XXXXX (Posing as CBI/Cyber Crime)',
      simulatedMessage:
          'COURT NOTICE: A parcel sent to Cambodia with 5 illegal fake passports under your Aadhaar has been seized at Mumbai Airport. Warrant #CBI-9921 has been issued. Connect immediately to Skype link for interrogation and transfer ₹85,000 security deposit to avoid immediate arrest.',
      promptQuestion:
          'You receive this urgent notice on WhatsApp. What is the correct assessment and action?',
      options: [
        'Join the Skype call immediately to prove your innocence and pay the refundable deposit.',
        'It is a Digital Arrest scam! Real police or CBI never conduct arrests on video call or demand money transfers. Block and report to 1930.',
        'Forward the message to your family group to ask for the ₹85,000 deposit.',
      ],
      correctOptionIndex: 1,
      explanation:
          'Law enforcement agencies (Police, CBI, ED, Customs) NEVER arrest anyone via Skype, Zoom, or WhatsApp video calls, nor do they ever request "security verification deposits". This is pure psychological intimidation.',
      attackVector: 'Coercive Authority Impersonation & Panic Isolation',
    ),
    SimulatorScenario(
      id: 'sim-2',
      title: 'Tonight Power Disconnection',
      category: 'Urgency & Utility Panic',
      sender: '+91 88234-XXXXX (Unknown Mobile Number)',
      simulatedMessage:
          'Dear Consumer, Your electricity power will be disconnected tonight at 9:30 PM from the power office because your previous month bill was not updated. Please immediately contact our electricity officer at 98123-XXXXX. Thank you.',
      promptQuestion: 'You receive this SMS at 8:00 PM. What is the critical red flag?',
      options: [
        'The message is sent from a personal 10-digit mobile number rather than an official utility sender ID, inducing artificial time scarcity.',
        'The electricity department always sends disconnection notices 1 hour before cutting power.',
        'You should immediately call the 10-digit number and download the APK file they send.',
      ],
      correctOptionIndex: 0,
      explanation:
          'Official power distribution companies (DISCOMs) always send alerts from registered 6-character Alpha Header IDs (e.g. BSES-DL, TPDDL), never from personal 10-digit mobile numbers. Scammers use evening deadlines so you cannot reach official offices.',
      attackVector: 'Artificial Time Scarcity & Utility Panic',
    ),
    SimulatorScenario(
      id: 'sim-3',
      title: 'OLX "Scan to Receive Payment"',
      category: 'UPI Debit Trap',
      sender: 'OLX Buyer via WhatsApp',
      simulatedMessage:
          'I am buying your sofa on OLX. I have created a QR code for your ₹6,500 payment. Just open Google Pay / PhonePe, scan this QR code, and enter your UPI PIN to receive the money in your bank account.',
      promptQuestion:
          'A buyer sends you a QR code and tells you to scan it in Google Pay to receive your money. What will happen if you do?',
      options: [
        '₹6,500 will be credited into your account.',
        'Google Pay will ask you to verify your identity before releasing funds.',
        '₹6,500 will be instantly DEBITED from your bank account! In UPI architecture, scanning a QR or entering a PIN is ONLY for paying money, NEVER for receiving.',
      ],
      correctOptionIndex: 2,
      explanation:
          'GOLDEN RULE OF UPI: You NEVER scan a QR code or enter your UPI PIN to receive money. Scanning a QR code always sends money from your account. The moment you enter your PIN, the funds are debited.',
      attackVector: 'Reverse Transaction Trap & UPI Exploitation',
    ),
    SimulatorScenario(
      id: 'sim-4',
      title: 'Bank Reward Points APK',
      category: 'Mobile Malware Trojan',
      sender: 'SMS from unknown sender',
      simulatedMessage:
          'Dear Customer, your 9,850 SBI Reward points worth ₹9,850 are expiring today. Download and install SBI_Rewards.apk from http://sbi-bonus-claim.site to redeem cash directly to your bank account.',
      promptQuestion:
          'You receive a link prompting you to download an APK file to claim reward points. What is this?',
      options: [
        'A legitimate reward redemption app from your bank.',
        'An SMS-forwarding Trojan! Installing untrusted APKs grants hackers access to read your 2FA OTPs and steal your money.',
        'A temporary security certificate that protects your phone.',
      ],
      correctOptionIndex: 1,
      explanation:
          'Banks never distribute apps via third-party websites or direct APK downloads. These malicious APKs request SMS and Accessibility permissions to intercept 2FA OTPs in the background, exfiltrating bank funds in minutes.',
      attackVector: 'SMS-Stealing Malware Trojan & Credential Harvesting',
    ),
  ];
}

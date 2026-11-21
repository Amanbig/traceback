class EmergencyContact {
  final String entityName;
  final String category; // Bank, National Helpline, Telecom
  final String primaryContact;
  final String? alternativeContact;
  final String? website;
  final String advice;

  const EmergencyContact({
    required this.entityName,
    required this.category,
    required this.primaryContact,
    this.alternativeContact,
    this.website,
    required this.advice,
  });

  static const List<EmergencyContact> verifiedDirectory = [
    EmergencyContact(
      entityName: 'National Cybercrime Reporting Portal',
      category: 'National Helpline',
      primaryContact: '1930',
      alternativeContact: '112',
      website: 'https://cybercrime.gov.in',
      advice: 'Dial 1930 within the "Golden Hour" (<2 hours) of unauthorized transactions to freeze money trails in intermediary accounts.',
    ),
    EmergencyContact(
      entityName: 'Chakshu (DoT Fraud Communications)',
      category: 'Telecom',
      primaryContact: 'Sanchar Saathi Portal',
      website: 'https://sancharsaathi.gov.in',
      advice: 'Report suspicious SMS senders, fake WhatsApp numbers, and mobile disconnection threats directly to the Department of Telecommunications.',
    ),
    EmergencyContact(
      entityName: 'State Bank of India (SBI)',
      category: 'Bank',
      primaryContact: '1800-1234',
      alternativeContact: '1800-2100',
      website: 'https://onlinesbi.sbi',
      advice: 'To freeze netbanking instantly, SMS "BLOCK <last 4 digits of card>" to 567676 from registered mobile.',
    ),
    EmergencyContact(
      entityName: 'HDFC Bank',
      category: 'Bank',
      primaryContact: '1800-202-6161',
      alternativeContact: '1800-1600',
      website: 'https://www.hdfcbank.com',
      advice: 'Report unauthorized card/UPI debits immediately via official HDFC NetBanking or PhoneBanking portal.',
    ),
    EmergencyContact(
      entityName: 'ICICI Bank',
      category: 'Bank',
      primaryContact: '1800-1080',
      website: 'https://www.icicibank.com',
      advice: 'Use iMobile app -> Services -> Card Services -> Block Card for instant self-service account lock.',
    ),
    EmergencyContact(
      entityName: 'Axis Bank',
      category: 'Bank',
      primaryContact: '1860-419-5555',
      alternativeContact: '1860-500-5555',
      website: 'https://www.axisbank.com',
      advice: 'SMS "BLOCK <last 4 digits of account>" to 5676782 to lock your customer ID immediately.',
    ),
    EmergencyContact(
      entityName: 'PayPal Security & Fraud',
      category: 'Payment Platform',
      primaryContact: '1800-419-9838',
      website: 'https://www.paypal.com/security',
      advice: 'Open the Resolution Center within PayPal to dispute unauthorized payments or spoofed merchant invoices.',
    ),
  ];
}

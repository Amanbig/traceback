class VernacularTranslationService {
  /// Generates a colloquial Hindi / Hinglish explanation for an investigation report
  static String getHindiSummary(String englishSummary, String threatLevel, int riskScore) {
    if (englishSummary.toLowerCase().contains('arrest') ||
        englishSummary.toLowerCase().contains('passport') ||
        englishSummary.toLowerCase().contains('customs') ||
        englishSummary.toLowerCase().contains('cbi')) {
      return 'चेतावनी: यह एक "डिजिटल अरेस्ट" (Digital Arrest) और नकली पुलिस/कस्टम्स फ्रॉड का प्रयास है। कोई भी सरकारी जांच एजेंसी या पुलिस कभी भी स्काइप या व्हाट्सएप वीडियो कॉल पर पूछताछ या अरेस्ट नहीं करती है। न ही वे "सिक्योरिटी डिपॉजिट" मांगते हैं।';
    }

    if (englishSummary.toLowerCase().contains('electricity') ||
        englishSummary.toLowerCase().contains('power') ||
        englishSummary.toLowerCase().contains('bill')) {
      return 'चेतावनी: यह नकली "बिजली बिल डिस्कनेक्शन" का फर्जीवाड़ा है। जालसाज आपको डराकर किसी अनजान नंबर पर कॉल करने या कोई APK/AnyDesk ऐप डाउनलोड करवाने की कोशिश कर रहे हैं। बिजली विभाग रात में ऐसे व्यक्तिगत नंबर से मैसेज नहीं भेजता।';
    }

    if (englishSummary.toLowerCase().contains('upi') ||
        englishSummary.toLowerCase().contains('qr') ||
        englishSummary.toLowerCase().contains('refund') ||
        englishSummary.toLowerCase().contains('cashback')) {
      return 'चेतावनी: यह "स्कैन टू रिसीव" (Scan to Receive) यूपीआई फ्रॉड है। याद रखें: किसी से पैसे प्राप्त करने या रिफंड लेने के लिए कभी भी क्यूआर कोड स्कैन करने या यूपीआई पिन (PIN) दर्ज करने की आवश्यकता नहीं होती। पिन डालने से आपके खाते से पैसे कट जाएंगे।';
    }

    if (englishSummary.toLowerCase().contains('kyc') ||
        englishSummary.toLowerCase().contains('bank') ||
        englishSummary.toLowerCase().contains('pan')) {
      return 'चेतावनी: यह बैंक केवाईसी (KYC) सस्पेंशन के नाम पर आपकी निजी जानकारी चुराने का फिशिंग हमला है। बैंक कभी भी एसएमएस या व्हाट्सएप लिंक के जरिए आधार, पैन या ओटीपी अपडेट करने को नहीं कहते।';
    }

    return 'सावधानी: ट्रेसबैक एआई ने इस संदेश को $riskScore% जोखिम के साथ संदिग्ध पाया है। संदेश में दिए गए किसी भी लिंक पर क्लिक न करें और न ही कोई ऐप डाउनलोड करें।';
  }

  static List<String> getHindiRedFlags(List<String> flags) {
    final hindiFlags = <String>[];
    for (final f in flags) {
      final lower = f.toLowerCase();
      if (lower.contains('urgency') || lower.contains('time') || lower.contains('panic')) {
        hindiFlags.add('अनावश्यक हड़बड़ी और डर पैदा करना (तुरंत कार्रवाई न करने पर नुकसान की धमकी)');
      } else if (lower.contains('authority') || lower.contains('police') || lower.contains('officer')) {
        hindiFlags.add('सरकारी अधिकारी या पुलिस होने का फर्जी दिखावा');
      } else if (lower.contains('apk') || lower.contains('malware') || lower.contains('download')) {
        hindiFlags.add('अनजान ऐप (APK) डाउनलोड करने का दबाव ताकि फोन हैक किया जा सके');
      } else if (lower.contains('link') || lower.contains('url') || lower.contains('domain')) {
        hindiFlags.add('फर्जी या संदेहास्पद वेब लिंक जो असली वेबसाइट जैसी दिखती है');
      } else if (lower.contains('money') || lower.contains('deposit') || lower.contains('fee')) {
        hindiFlags.add('सत्यापन या रिफंड के नाम पर पैसे ट्रांसफर करने की मांग');
      } else {
        hindiFlags.add('संदेहास्पद संकेत: $f');
      }
    }
    if (hindiFlags.isEmpty) {
      hindiFlags.add('अज्ञात स्रोत से प्राप्त संदेहास्पद संदेश');
    }
    return hindiFlags;
  }

  static List<String> getHindiNextSteps() {
    return [
      'तत्काल 1930 डायल करें (राष्ट्रीय साइबर अपराध हेल्पलाइन) या cybercrime.gov.in पर शिकायत दर्ज करें।',
      'अपने बैंक के हेल्पलाइन नंबर पर कॉल करके संबंधित यूपीआई/कार्ड या नेटबैंकिंग को अस्थायी रूप से ब्लॉक करवाएं।',
      'संदेश भेजने वाले को तुरंत ब्लॉक करें और किसी भी लिंक या फॉर्म में कोई विवरण न भरें।',
      'अपने परिवार और दोस्तों को इस तरह के फ्रॉड पैटर्न के बारे में सचेत करें।',
    ];
  }
}

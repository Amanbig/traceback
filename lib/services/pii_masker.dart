class PiiMasker {
  /// Redacts sensitive personally identifiable information (PII)
  /// locally on the device prior to any processing.
  static String mask(String input) {
    if (input.trim().isEmpty) return input;

    String text = input;

    // 1. Mask Email Addresses
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    text = text.replaceAll(emailRegex, '[EMAIL_REDACTED]');

    // 2. Mask Credit / Debit Card Numbers (13 to 19 digits, possibly hyphenated or spaced)
    final cardRegex = RegExp(
      r'\b(?:\d{4}[ -]?){3}\d{1,4}\b',
    );
    text = text.replaceAll(cardRegex, '[CARD_REDACTED]');

    // 3. Mask Phone Numbers (formats like +91 9876543210, +1 (555) 234-5678, 10-digit numbers)
    final phoneRegex = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}\b',
    );
    text = text.replaceAll(phoneRegex, '[PHONE_REDACTED]');

    // 4. Mask OTP / Verification codes (e.g. "code is 492013", "OTP: 9182")
    final otpRegex = RegExp(
      r'\b(?:otp|code|pin|verification)\s*(?:is|:)?\s*([0-9]{4,8})\b',
      caseSensitive: false,
    );
    text = text.replaceAllMapped(otpRegex, (match) {
      return match.group(0)!.replaceFirst(match.group(1)!, '[OTP_REDACTED]');
    });

    // 5. Mask Bank Account numbers (alphanumeric or numbers >= 9 digits)
    final bankAccRegex = RegExp(
      r'\b(?:a/c|account|acct)\s*(?:no\.?|num|number)?\s*[:#-]?\s*([0-9A-Z]{8,18})\b',
      caseSensitive: false,
    );
    text = text.replaceAllMapped(bankAccRegex, (match) {
      return match.group(0)!.replaceFirst(match.group(1)!, '[ACCOUNT_REDACTED]');
    });

    return text;
  }
}

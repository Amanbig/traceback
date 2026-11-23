# Traceback 🛡️
### AI Digital Scam & Fraud Forensics Engine (Bharat Cyber Shield)

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Live Web App](https://img.shields.io/badge/Live%20Demo-gem--app--2adf0.web.app-brightgreen?logo=firebase)](https://gem-app-2adf0.web.app)
[![Release: v1.3.0](https://img.shields.io/badge/Release-v1.3.0-orange?logo=github)](https://github.com/Amanbig/traceback/releases/tag/v1.3.0)
[![Flutter](https://img.shields.io/badge/Flutter-v3.24.5-02569B?logo=flutter)](https://flutter.dev)
[![Firebase AI Logic](https://img.shields.io/badge/AI-Firebase%20AI%20Logic-FFCA28?logo=firebase)](https://firebase.google.com/docs/ai-logic)
[![Hackathon](https://img.shields.io/badge/%23BuildHybridAI-Submission-4285F4?logo=google)](https://github.com/Amanbig/traceback)

> **Traceback** is an open-source, zero-leakage hybrid AI forensic investigator built for the **#BuildHybridAI** Hackathon. It decompiles social-engineering attack patterns—exposing Digital Arrest coercion, UPI reverse-charge traps, Remote Access Trojan (RAT) APKs, electricity disconnection panic, and typosquatted domains across SMS, WhatsApp, screenshots, threat message sequences, and suspicious URLs.

---

## 🌟 The Problem & Value Proposition

India and global digital ecosystems face an unprecedented surge in sophisticated social-engineering cyber fraud. In India alone, over **₹1,750 Crore** was siphoned through digital fraud schemes in recent quarters:
- **Digital Arrest Scams:** Fraudsters impersonating CBI, Cyber Crime, or Customs on Skype video calls demanding "security deposits".
- **Reverse UPI PIN Traps:** Fake "cashback" or "refund" collect requests deceiving victims into entering their secret UPI PIN to "receive" funds.
- **Utility Disconnection Panic:** Alarming SMS threats claiming electricity will be disconnected at 9:30 PM unless a private phone number is called.
- **Remote Access Trojans (RATs):** Tricking users into sideloading malicious `.apk` packages (AnyDesk, QuickSupport, RustDesk).

Traditional spam filters act as opaque black boxes: they label messages as "spam" or "ham" without explaining *why*. Fear and urgency bypass critical thinking, causing victims to comply anyway.

**Traceback transforms users from vulnerable targets into informed forensic defenders:**
1. **Explainable AI Forensics:** Highlights exact manipulative phrases and explains the cognitive levers applied (Fear, Isolation, Authority Impersonation, False Urgency).
2. **Zero-Leakage Privacy Guard:** Automatically scrubs phone numbers, Aadhaar, PAN, UPI IDs, bank accounts, and OTPs on-device before any external cloud inference occurs.
3. **Pure-Dart On-Device ML Classifier (<1ms):** Pre-calibrated Log-Odds Naive Bayes & N-Gram model running 100% locally with zero external C++ binary dependencies across Web, Android, and iOS.
4. **8 Indian Vernacular Languages:** Generates localized emergency recovery playbooks in English, Hindi (हिंदी), Tamil (தமிழ்), Telugu (తెలుగు), Bengali (বাংলা), Marathi (मराठी), Gujarati (ગુજરાતી), and Kannada (ಕನ್ನಡ).
5. **Tamper-Proof PDF Forensic Evidence Dossier:** Generates an official incident dossier with SHA-256 chain of custody checksum and statutory 1930 / FIR bank dispute annexure.

---

## ⚡ Hybrid AI Architecture

Traceback implements Google's Hybrid AI paradigm using the **Firebase AI Logic SDK** (`firebase_ai`), combining zero-latency on-device statistical machine learning with cloud multimodal intelligence:

```
+-----------------------------------------------------------------------------------+
|                                  USER INPUT                                       |
|  (Suspicious SMS / WhatsApp / Screenshots / Threat Chain / QR Code / URLs)        |
+-----------------------------------------------------------------------------------+
                                          │
                                          ▼
+-----------------------------------------------------------------------------------+
|                     ON-DEVICE ZERO-LEAKAGE PRIVACY LAYER                          |
|                                                                                   |
|  1. Local PII Masker: Scrubs [CARD], [PHONE], [ACCOUNT], [AADHAAR], [PAN], [UPI]   |
|  2. Pure-Dart ML Model: Log-odds Naive Bayes + N-Gram Spam Classifier (<1ms)     |
|  3. Deterministic Heuristics: RAT APKs, Digital Arrest, Reverse UPI, Utility Cut  |
|  4. Lexical URL Security: Homoglyphs, punycode, entropy, suspicious TLDs          |
+-----------------------------------------------------------------------------------+
                                          │
                        Is Offline or "Prefer On-Device" ON?
                                       /     \
                            YES       /       \      NO (Default Hybrid)
                                     /         \
                                    ▼           ▼
+---------------------------------------+   +---------------------------------------+
|     LOCAL SHIELD INFERENCE ENGINE     |   |   CLOUD AI (FIREBASE AI LOGIC SDK)    |
| • 100% offline (Airplane mode ready)  |   | • Dynamic Gemini Flash / Pro routing  |
| • Sub-millisecond execution latency   |   | • Deep cross-message threat chain     |
| • Zero telemetry / zero data egress   |   | • Psychological lever decompilation   |
| • Probabilistic ML + Heuristic Fusion |   | • Auto-fallback to local if offline   |
+---------------------------------------+   +---------------------------------------+
                                    \           /
                                     \         /
                                      ▼       ▼
+-----------------------------------------------------------------------------------+
|                          INTERACTIVE FORENSIC DOSSIER                             |
|  • Threat Risk Gauge (0-100 Score) & Color-Coded Threat Tier                      |
|  • On-Device ML Probability Indicator (e.g. 96% Statistical Scam Confidence)     |
|  • Manipulative Phrases Tagged in Evidence Transcript                             |
|  • 8-Language Vernacular Translation & Emergency Action Steps                     |
|  • 1-Tap WhatsApp Family Advisory Sharing                                         |
|  • Tamper-Proof SHA-256 PDF Incident Dossier (for Police / Bank Dispute)          |
+-----------------------------------------------------------------------------------+
```

---

## 🔒 Firebase Ecosystem Integration

| Product | Architecture & Role in Traceback |
| :--- | :--- |
| **Firebase AI Logic (`firebase_ai`)** | Powers Gemini 1.5 Flash / Pro model invocation with structured JSON schema outputs and automatic on-device fallback. |
| **Firebase Hosting** | Continuous deployment of production Flutter Web releases at [gem-app-2adf0.web.app](https://gem-app-2adf0.web.app). |
| **Firebase Remote Config** | Dynamically updates Gemini model parameters and threat classification weights over-the-air without app updates. |
| **Firebase App Check** | Attests authentic app instances, preventing automated scraping and abuse of AI backend endpoints. |
| **Firebase Firestore** | Catalogs community threat intelligence reports and trending scams on the live Scam Radar. |
| **Firebase Auth** | Provides anonymous and authenticated session management for persistent cross-device threat tracking. |

---

## 📱 Key Capabilities

### 1. Multi-Vector Forensic Scanners
- **Message Scan:** Analyzes SMS, WhatsApp messages, emails, and social media DMs.
- **Multimodal Screenshot Scan:** Gemini Vision decompiles spoofed bank layouts, fake notice logos, and urgency badges.
- **Threat Chain Investigator:** Correlates multiple consecutive messages to expose how scammers escalate from initial lure to financial extortion.
- **QR / UPI Threat Inspector:** Validates UPI deep-links (`upi://pay`) to detect "enter PIN to receive" deception and deceptive `pa=` handles.
- **URL Inspector:** Detects typosquatting, homoglyph character spoofing, and high-risk top-level domains.

### 2. Evaluator Quick-Demo Deck
Built specifically for hackathon evaluators to test all forensic capabilities in **1 tap without typing**:
- 🚨 **Digital Arrest & CBI Notice** (Authority intimidation)
- 💸 **UPI Reverse PIN Cashback Trap** (Collect request exploit)
- ⚡ **Electricity Midnight Disconnect Panic** (Utility cut-off panic)
- 📲 **AnyDesk Remote APK Sideload** (Malware installation)
- 💬 **Legitimate Family Chat** (Zero false-positive pure-Dart ML test)

### 3. Bharat Cyber Shield & Statutory Compliance
- **Emergency Action Playbooks:** Step-by-step guidance to freeze accounts, block UPI IDs, and dial **1930** (National Cyber Crime Reporting Helpline).
- **Tamper-Proof PDF Dossier:** Printable legal evidence dossier featuring a SHA-256 custody hash for submitting to Cyber Cells and bank ombudsmen.
- **1-Tap WhatsApp Warning:** Allows users to immediately share clean, localized fraud warnings to family WhatsApp groups.

---

## 📦 Downloads & Releases

Pre-compiled production release artifacts are available under [GitHub Releases (v1.3.0)](https://github.com/Amanbig/traceback/releases/tag/v1.3.0):

- **Android APK:** `traceback-v1.3.0-android.apk` (56.54 MB)
- **Android App Bundle:** `traceback-v1.3.0-android.aab` (27.40 MB)
- **iOS Archive:** `traceback-v1.3.0-ios.zip` (16.55 MB)
- **Web Bundle:** `traceback-v1.3.0-web.zip` (7.67 MB)
- **Live Progressive Web App:** [https://gem-app-2adf0.web.app](https://gem-app-2adf0.web.app)

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.24.5`)
- Google Chrome or Android device / emulator

### Local Setup

```bash
# 1. Clone the repository
git clone https://github.com/Amanbig/traceback.git
cd traceback

# 2. Install dependencies
flutter pub get

# 3. Run in Chrome (Web)
flutter run -d chrome

# 4. Run on Android device
flutter run -d android
```

### Static Analysis & Verification

```bash
# Verify static analysis (0 warnings / 0 errors)
flutter analyze

# Run unit and widget test suite
flutter test
```

---

## 📄 License

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE) for details.

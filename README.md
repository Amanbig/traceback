# Traceback 🛡️
### AI Digital Scam and Fraud Investigator

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Built for #BuildHybridAI](https://img.shields.io/badge/Hackathon-%23BuildHybridAI-orange)](https://devpost.com)
[![Firebase AI Logic](https://img.shields.io/badge/AI-Firebase%20AI%20Logic-FFCA28?logo=firebase)](https://firebase.google.com/docs/ai-logic)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20Web-blue)](#getting-started)

> **Traceback** is an explanatory, privacy-first fraud investigation shield. Instead of binary spam filtering, Traceback unmasks how social engineering attacks work—decoding urgency manipulation, credential harvesting traps, spoofed domains, and panic triggers across SMS, WhatsApp, emails, and suspicious links.

---

## 🌟 The Problem & Value Proposition

Traditional spam filters operate as opaque black boxes: they label messages as "spam" or "not spam" without explaining *why*. When a user receives an alarming message—such as a bank suspension warning, a digital arrest threat, or an electricity disconnection ultimatum—fear and cognitive overload often lead them to click malicious links anyway.

**Traceback transforms users from potential victims into informed defenders:**
1. **Explainable AI Forensics:** Highlights exact manipulative phrases and explains the psychology behind the attack (Fear, Authority Impersonation, False Scarcity).
2. **Zero-Leakage Privacy Guard:** Automatically redacts phone numbers, bank accounts, emails, and OTPs on-device before any external cloud inference occurs.
3. **Actionable Defense Checklist:** Delivers immediate, safe guidance (e.g., official verification channels, national cybercrime helplines) rather than just a warning flag.
4. **Community Scam Radar:** Catalogs trending real-world scam campaigns to build proactive collective immunity.

---

## ⚡ Hybrid Inference Architecture (#BuildHybridAI)

Traceback is built using the **Firebase AI Logic SDK** (`firebase_ai`), implementing a dual-engine hybrid pipeline that intelligently balances privacy, latency, and investigative depth.

```
+-------------------------------------------------------------------------+
|                              USER INPUT                                 |
|         (Suspicious SMS / WhatsApp / Email / QR Code / URL)             |
+-------------------------------------------------------------------------+
                                     │
                                     ▼
+-------------------------------------------------------------------------+
|                  ON-DEVICE PRIVACY & TRIAGE LAYER                       |
|                                                                         |
|  1. Local PII Redaction: Masks [CARD], [PHONE], [ACCOUNT], [OTP]        |
|  2. Lexical URL Security: Punycode, suspicious TLDs, IP hosts           |
|  3. Fast Heuristic Engine: Urgency scoring & panic pattern detection    |
+-------------------------------------------------------------------------+
                                     │
                    Is Device Offline or Local Mode Preferred?
                                  /     \
                       YES       /       \      NO (Deep Audit)
                                /         \
                               ▼           ▼
+-----------------------------------+   +---------------------------------+
|   LOCAL INFERENCE (GEMINI NANO)   |   |   CLOUD INFERENCE (GEMINI FLASH)|
| • Zero-latency offline triage     |   | • Multi-turn forensic analysis  |
| • Full privacy (data stays local) |   | • Social engineering breakdown  |
| • Rapid preliminary threat score  |   | • Threat intel cross-referencing|
+-----------------------------------+   +---------------------------------+
                                \         /
                                 \       /
                                  ▼     ▼
+-------------------------------------------------------------------------+
|                       INTERACTIVE THREAT REPORT                         |
|  • Threat Risk Gauge (0-100 Score)                                      |
|  • Identified Red Flags & Manipulative Phrases                          |
|  • Social Engineering Tactics Taxonomy                                  |
|  • Safe Next Steps Checklist & Official Helplines                       |
|  • On-Device Encrypted History Persistence                              |
+-------------------------------------------------------------------------+
```

### Why Hybrid Inference Matters for Fraud Detection
- **On-Device (Local Gemini Nano):** Protects sensitive user data (bank details, personal names, OTPs) by keeping it strictly on the device. Provides instant offline protection when travelers have no cellular data.
- **Cloud Fallback (Gemini Flash via Firebase AI Logic):** When devices lack local NPU/Nano hardware, Firebase AI Logic provides automatic fallback to cloud inference for deep psychological and contextual investigation.

---

## 🔒 Firebase Products Integration

| Product | Role in Traceback |
| :--- | :--- |
| **Firebase AI Logic (`firebase_ai`)** | Powers both on-device model routing and Gemini Flash cloud inference with JSON schema outputs. |
| **Firebase App Check** | Attests legitimate app instances, securing client-side AI endpoints against API abuse. |
| **Firebase Firestore** | Stores community threat intelligence reports and trending scam patterns on the Scam Radar. |
| **Firebase Auth** | Allows users to securely sync their investigation history across personal devices. |
| **Firebase Remote Config** | Dynamically updates fraud heuristic weights and high-risk domain registries without requiring app store updates. |

---

## 📱 Core Features

### 1. Hybrid Threat Investigation
- Paste any text or enter a URL.
- One-tap switch between **On-Device Shield (Gemini Nano)** and **Cloud AI (Gemini Flash)**.
- Step-by-step forensic status indicators during analysis.

### 2. Forensic Threat Report
- **Threat Gauge:** Dynamic circular risk meter (0–100) with color-coded severity:
  - `0 - 20`: Verified Safe
  - `21 - 40`: Low Risk
  - `41 - 65`: Suspicious
  - `66 - 80`: High Risk Phishing
  - `81 - 100`: Critical Fraud
- **Social Engineering Taxonomy:** Flags tactics like *Authority Impersonation*, *Urgency & Fear Manipulation*, and *Credential Harvesting*.
- **Interactive Red Flags:** Point-by-point annotations detailing why specific phrases or domain structures are malicious.
- **Actionable Defense Checklist:** Immediate steps for victims (blocking numbers, contacting official bank portals, dialing 1930).

### 3. Community Scam Radar
- Searchable directory of trending real-world scam campaigns:
  - *Digital Arrest & Narcotics Parcel Scam*
  - *Electricity Bill Disconnection Panic*
  - *Bank KYC Account Suspension Phishing*
  - *Part-Time Task & YouTube Video Like Fraud*
  - *Fake Traffic E-Challan APK Malware*
- Direct "Test This Scenario" button to run live simulations in the investigator.

### 4. Investigation History
- Offline-first encrypted storage of past reports using `SharedPreferences`.
- Fast search and review of historical threat reports.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.5 or newer)
- Modern web browser (Chrome recommended for Gemini Nano Prompt API) or Android device

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/traceback.git
   cd traceback
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on Web:**
   ```bash
   flutter run -d chrome
   ```

4. **Build Production Web Release:**
   ```bash
   flutter build web --release
   ```

5. **Run on Android (requires connected device/emulator):**
   ```bash
   flutter run -d android
   ```

---

## 🧪 Testing & Code Quality

Traceback maintains clean code health:

```bash
# Run static analysis
flutter analyze

# Run unit and widget tests
flutter test
```

---

## 📄 License

Licensed under the **Apache License, Version 2.0**. See the [LICENSE](LICENSE) file for details.

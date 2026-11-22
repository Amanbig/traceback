# Contributing to Traceback

Thank you for your interest in contributing to **Traceback**! We welcome contributions from developers, security researchers, and cyber advocates worldwide.

## Code of Conduct
By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Core Architectural Invariants (Must Follow)
1. **Zero-Leakage Guarantee**: Under NO circumstances should unmasked Personally Identifiable Information (bank accounts, card numbers, Aadhaar, PAN, phone numbers, OTPs) be transmitted to any network endpoint or cloud service. Always process user content through `PiiMasker.mask()` first.
2. **Offline-First Resilience**: Any feature added to the threat engine must provide a deterministic on-device fallback so users in airplane mode or with poor network connectivity can still protect themselves.
3. **Statutory Integrity**: Emergency helplines (1930, 112, Sanchar Saathi Chakshu) must remain authoritative and vetted. Never scrape general search results for bank/police numbers due to SEO-poisoning fraud vectors.

## Development Workflow
1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-username>/traceback.git
   cd traceback
   ```
3. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
4. Verify tests and analyzer:
   ```bash
   flutter analyze
   flutter test
   ```
5. Create a topic branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```
6. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/):
   ```bash
   git commit -m "feat(ai): add new scam pattern detection"
   ```
7. Push to your fork and submit a Pull Request.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/emergency_contact.dart';
import '../../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class EmergencyToolkitScreen extends StatefulWidget {
  const EmergencyToolkitScreen({super.key});

  @override
  State<EmergencyToolkitScreen> createState() => _EmergencyToolkitScreenState();
}

class _EmergencyToolkitScreenState extends State<EmergencyToolkitScreen> {
  String _searchQuery = '';

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _toast('$what copied');
  }

  Future<void> _call(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final ok = digits.isNotEmpty &&
        await launchUrl(Uri(scheme: 'tel', path: digits)).catchError((_) => false);
    if (!ok) {
      // No dialer available (e.g. web or a tablet). Fall back to copying.
      await _copy(number, 'Number');
    }
  }

  Future<void> _openSite(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
        .catchError((_) => false);
    if (!ok && mounted) _toast('Could not open $url');
  }

  bool _isDialable(String s) => RegExp(r'^[0-9][0-9\-\s]{2,}$').hasMatch(s);

  void _showDisputeLetterGenerator() {
    final bank = TextEditingController();
    final account = TextEditingController();
    final amount = TextEditingController();
    final txId = TextEditingController();
    final date = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bank dispute letter',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                'Fill in what you know. We write a formal complaint you can paste into an email to your bank.',
                style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bank,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Bank name', hintText: 'e.g. State Bank of India'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: account,
                decoration: const InputDecoration(
                    labelText: 'Account or card number', hintText: 'Last 4 digits are enough'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Amount (INR)', hintText: '45,000'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: date,
                      decoration: const InputDecoration(
                          labelText: 'Date', hintText: 'DD-MMM-YYYY'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txId,
                decoration: const InputDecoration(
                    labelText: 'UTR or reference ID', hintText: 'From the debit SMS'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    String v(TextEditingController c, String fallback) =>
                        c.text.trim().isEmpty ? fallback : c.text.trim();
                    final letter = '''
To,
The Branch Manager & Cyber Fraud Cell,
${v(bank, '[Bank name]')}

Subject: Urgent Notification & Chargeback Request for Unauthorized Fraudulent Transaction

Dear Sir/Madam,

I am writing to formally report an unauthorized fraudulent transaction executed on my account:
• Account / Card Number: ${v(account, '[Account number]')}
• Disputed Amount: INR ${v(amount, '[Amount]')}
• Transaction Date: ${v(date, '[Date]')}
• Transaction Reference / UTR: ${v(txId, '[Reference ID]')}

This transaction was executed without my informed consent as a consequence of a deceptive digital phishing/social engineering scam. In accordance with RBI Circular DBR.No.Leg.BC.78/09.07.005/2017-18 ("Customer Protection – Limiting Liability of Customers in Unauthorized Electronic Banking Transactions"), I have reported this incident within the stipulated zero-liability window.

I request you to:
1. Immediately freeze any further debits on this payment instrument.
2. Liaise with the beneficiary bank nodal officer to recall and freeze the funds.
3. Initiate the formal chargeback dispute process.

I have also reported this matter to the National Cybercrime Reporting Portal (Helpline 1930).

Sincerely,
[Your Name]
[Registered Mobile Number]
''';
                    Clipboard.setData(ClipboardData(text: letter));
                    Navigator.pop(ctx);
                    _toast('Letter copied. Paste it into an email to your bank.');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy letter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelplineHero() {
    const red = AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [red.withOpacity(0.28), context.surfaceColor],
        ),
        border: Border.all(color: red.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: red, size: 20),
              SizedBox(width: 8),
              Text('Lost money in the last 2 hours?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: red)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Call 1930 now',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text(
            'Reporting quickly can freeze the money before scammers withdraw it.',
            style: TextStyle(fontSize: 14.5, height: 1.4, color: context.mutedText),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _call('1930'),
              style: FilledButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 56),
              ),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call 1930'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSite('https://cybercrime.gov.in'),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Report online at cybercrime.gov.in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    const steps = [
      'Call 1930 and note the complaint number.',
      'Call your bank and ask them to block the card, UPI or net banking.',
      'Do not send any more money, even to "recover" the loss.',
      'Keep screenshots, messages and transaction IDs as evidence.',
    ];
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brand)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(steps[i], style: const TextStyle(fontSize: 14.5, height: 1.4)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact item) {
    final dialable = _isDialable(item.primaryContact);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.entityName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                ),
                const SizedBox(width: 8),
                StatusPill(label: item.category, color: AppColors.brand),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone_in_talk_outlined, size: 18, color: AppColors.safe),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(item.primaryContact,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.safe)),
                ),
                if (item.alternativeContact != null) ...[
                  const SizedBox(width: 8),
                  Text('or ${item.alternativeContact}',
                      style: TextStyle(fontSize: 13.5, color: context.mutedText)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(item.advice,
                style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (dialable)
                  FilledButton.tonalIcon(
                    onPressed: () => _call(item.primaryContact),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                    style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _copy(item.primaryContact, 'Number'),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
                ),
                if (item.website != null)
                  OutlinedButton.icon(
                    onPressed: () => _openSite(item.website!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Website'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency help')),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: FirebaseService.streamEmergencyContacts(),
        initialData: EmergencyContact.verifiedDirectory,
        builder: (context, snapshot) {
          final contacts = snapshot.data ?? EmergencyContact.verifiedDirectory;
          final q = _searchQuery.toLowerCase().trim();
          final filtered = contacts.where((c) {
            return c.entityName.toLowerCase().contains(q) ||
                c.category.toLowerCase().contains(q) ||
                c.primaryContact.toLowerCase().contains(q);
          }).toList();

          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 32),
            children: [
              _buildHelplineHero(),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader('What to do right now'),
              _buildChecklist(),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showDisputeLetterGenerator,
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Write a bank dispute letter'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(child: SectionHeader('Verified contacts')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safe.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.safe.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 13, color: AppColors.safe),
                        SizedBox(width: 5),
                        Text(
                          'RBI & DoT Verified',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.safe,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Only use these verified numbers. Never call numbers from SMS, spoofed emails, or search engine ads.',
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: context.mutedText),
                ),
              ),
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search bank, helpline or portal',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No contacts found',
                    message: 'Try the name of your bank, or search "helpline".',
                  ),
                )
              else
                for (final item in filtered) _buildContactCard(item),
            ],
          );
        },
      ),
    );
  }
}

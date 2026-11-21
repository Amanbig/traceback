import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/emergency_contact.dart';

class EmergencyToolkitScreen extends StatefulWidget {
  const EmergencyToolkitScreen({super.key});

  @override
  State<EmergencyToolkitScreen> createState() => _EmergencyToolkitScreenState();
}

class _EmergencyToolkitScreenState extends State<EmergencyToolkitScreen> {
  String _searchQuery = '';

  void _showDisputeLetterGenerator(BuildContext context) {
    final bankController = TextEditingController(text: 'State Bank of India');
    final accountController = TextEditingController(text: 'XXXX-XXXX-8910');
    final amountController = TextEditingController(text: '45,000');
    final txIdController = TextEditingController(text: 'UPI/20261121/9821038192');
    final dateController = TextEditingController(text: '21-Nov-2026');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Official Bank Dispute Letter Generator',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bankController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(labelText: 'Account / Card Number'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Disputed Amount (INR)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Transaction Date'),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: txIdController,
                decoration: const InputDecoration(labelText: 'Transaction UTR / Reference ID'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final letter = '''
To,
The Branch Manager & Cyber Fraud Cell,
${bankController.text}

Subject: Urgent Notification & Chargeback Request for Unauthorized Fraudulent Transaction

Dear Sir/Madam,

I am writing to formally report an unauthorized fraudulent transaction executed on my account:
• Account / Card Number: ${accountController.text}
• Disputed Amount: INR ${amountController.text}
• Transaction Date: ${dateController.text}
• Transaction Reference / UTR: ${txIdController.text}

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dispute complaint letter copied to clipboard! Ready to email your bank.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Generate & Copy Dispute Letter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = EmergencyContact.verifiedDirectory.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.entityName.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q) ||
          c.primaryContact.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.emergency_outlined, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Victim Emergency Toolkit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Golden Hour Emergency Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Golden Hour Cyber Response',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you lost money within the last 2 hours, reporting immediately to 1930 freezes money before scammers can cash out at ATMs or crypto exchanges.',
                    style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '1930'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Helpline 1930 copied!')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[900],
                        ),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Dial 1930', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showDisputeLetterGenerator(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('Bank Dispute Letter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Directory Header & Search Box
            const Text(
              'Verified Official Contacts Directory',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Never call numbers sent in SMS or found on unofficial websites.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search bank, helpline, or portal...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Directory List
            ...filtered.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.entityName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_in_talk_outlined, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          item.primaryContact,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        if (item.alternativeContact != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '/ ${item.alternativeContact}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Copy Number',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.primaryContact));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied ${item.primaryContact} to clipboard'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.advice,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

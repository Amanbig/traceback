import 'package:flutter/material.dart';
import '../../models/scam_radar_item.dart';
import '../../services/firebase_service.dart';
import 'scam_simulator_screen.dart';

class ScamRadarScreen extends StatefulWidget {
  final Function(String)? onSelectSample;

  const ScamRadarScreen({super.key, this.onSelectSample});

  @override
  State<ScamRadarScreen> createState() => _ScamRadarScreenState();
}

class _ScamRadarScreenState extends State<ScamRadarScreen> {
  String _selectedCategory = 'All';

  void _showReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'Financial Phishing';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report a New Scam Pattern'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Scam Title (e.g., Fake Courier Customs)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Financial Phishing', child: Text('Financial Phishing')),
                    DropdownMenuItem(value: 'Authority Impersonation', child: Text('Authority Impersonation')),
                    DropdownMenuItem(value: 'Urgency & Utility', child: Text('Urgency & Utility')),
                    DropdownMenuItem(value: 'Mobile Malware', child: Text('Mobile Malware')),
                    DropdownMenuItem(value: 'Investment & Job Fraud', child: Text('Investment & Job Fraud')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Intercepted Message Text',
                    hintText: 'Paste the exact text of the scam message...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final msg = messageController.text.trim();
                if (title.isEmpty || msg.isEmpty) return;

                final newItem = ScamRadarItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  category: category,
                  sampleText: msg,
                  severity: 'High',
                  targetAudience: 'Community Alert',
                  modusOperandi: 'Reported directly by community member.',
                  warningSigns: ['Community reported threat', 'Verify sender independently'],
                  safetyTip: 'Do not click links or share verification codes.',
                );

                await FirebaseService.submitCommunityScam(newItem);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Scam pattern submitted to Community Radar!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      'All',
      'Authority Impersonation',
      'Financial Phishing',
      'Urgency & Utility',
      'Mobile Malware',
      'Investment & Job Fraud'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Community Scam Radar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined),
            tooltip: 'Cyber Defender Simulator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScamSimulatorScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(context),
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report Scam'),
      ),
      body: StreamBuilder<List<ScamRadarItem>>(
        stream: FirebaseService.streamCommunityScams(),
        builder: (context, snapshot) {
          final allScams = snapshot.data ?? ScamRadarItem.trendingScams;
          final filtered = _selectedCategory == 'All'
              ? allScams
              : allScams.where((s) => s.category == _selectedCategory).toList();

          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                        selectedColor: Colors.blueAccent.withOpacity(0.2),
                        checkmarkColor: Colors.blueAccent,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final scam = filtered[index];
                    return _buildScamCard(context, scam, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScamCard(BuildContext context, ScamRadarItem scam, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_outlined, color: Colors.redAccent),
        ),
        title: Text(
          scam.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Text(
              scam.category,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                scam.severity.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Intercepted Sample Message:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Text(
                    scam.sampleText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Modus Operandi:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  scam.modusOperandi,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Warning Signs:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                ...scam.warningSigns.map((sign) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 18, color: Colors.orangeAccent),
                          Expanded(
                            child: Text(
                              sign,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                if (widget.onSelectSample != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.onSelectSample!(scam.sampleText);
                      },
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('Investigate This Pattern'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/scam_radar_item.dart';
import '../../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'scam_simulator_screen.dart';

class ScamRadarScreen extends StatefulWidget {
  final Function(String)? onSelectSample;

  const ScamRadarScreen({super.key, this.onSelectSample});

  @override
  State<ScamRadarScreen> createState() => _ScamRadarScreenState();
}

class _ScamRadarScreenState extends State<ScamRadarScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String category = 'Financial Phishing';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report a scam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (e.g. Fake courier customs fee)',
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
                    labelText: 'Scam message',
                    hintText: 'Paste the message you received',
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
                if (title.isEmpty || msg.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add a title and the message text first.')),
                  );
                  return;
                }

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
                      content: Text('Thanks. Your report was added to the Radar.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  static const _categories = [
    'All',
    'Authority Impersonation',
    'Financial Phishing',
    'Urgency & Utility',
    'Mobile Malware',
    'Investment & Job Fraud'
  ];

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return const Color(0xFFF97316);
      default:
        return AppColors.warn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scam Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined),
            tooltip: 'Scam simulator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScamSimulatorScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportDialog(context),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Report a scam'),
      ),
      body: StreamBuilder<List<ScamRadarItem>>(
        stream: FirebaseService.streamCommunityScams(),
        builder: (context, snapshot) {
          final allScams = snapshot.data ?? ScamRadarItem.trendingScams;
          final query = _searchController.text.toLowerCase().trim();
          final filtered = allScams.where((s) {
            final matchesCat = _selectedCategory == 'All' || s.category == _selectedCategory;
            final matchesQuery = query.isEmpty ||
                s.title.toLowerCase().contains(query) ||
                s.sampleText.toLowerCase().contains(query) ||
                s.modusOperandi.toLowerCase().contains(query);
            return matchesCat && matchesQuery;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 4, AppSpacing.screenH, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search scams, e.g. courier, electricity',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Clear',
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenH, vertical: 10),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return ChoiceChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching scams',
                        message: 'Try a different word or pick another category.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH, 4, AppSpacing.screenH, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildScamCard(context, filtered[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _buildScamCard(BuildContext context, ScamRadarItem scam) {
    final sev = _severityColor(scam.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.outlineColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  StatusPill(label: scam.severity, color: sev),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(scam.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: context.mutedText)),
                  ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scam.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16, height: 1.25)),
                const SizedBox(height: 4),
                Text(scam.modusOperandi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, height: 1.35, color: context.mutedText)),
              ],
            ),
            children: [
              _sectionLabel('Example message'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surfaceHighColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(scam.sampleText,
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
              ),
              if (scam.warningSigns.isNotEmpty) ...[
                _sectionLabel('Warning signs'),
                for (final sign in scam.warningSigns)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.warn),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(sign, style: const TextStyle(fontSize: 14, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
              ],
              if (scam.safetyTip.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded,
                          size: 18, color: AppColors.safe),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(scam.safetyTip,
                            style: const TextStyle(fontSize: 14, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.onSelectSample != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onSelectSample!(scam.sampleText),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Scan a similar message'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

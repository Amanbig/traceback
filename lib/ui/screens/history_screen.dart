import 'package:flutter/material.dart';
import '../../models/threat_report.dart';
import '../../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'report_screen.dart';

enum _Filter { all, threats, suspicious, safe }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ThreatReport> _history = [];
  bool _loading = true;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistory();
    if (!mounted) return;
    setState(() {
      _history = list;
      _loading = false;
    });
  }

  List<ThreatReport> get _visible {
    switch (_filter) {
      case _Filter.all:
        return _history;
      case _Filter.threats:
        return _history.where((r) => r.riskScore >= 70).toList();
      case _Filter.suspicious:
        return _history.where((r) => r.riskScore >= 40 && r.riskScore < 70).toList();
      case _Filter.safe:
        return _history.where((r) => r.riskScore < 40).toList();
    }
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all scans?'),
        content: const Text('This permanently deletes all reports stored on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(90, 44),
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HistoryService.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _delete(ThreatReport report) async {
    // Remove from the UI first (Dismissible requires it), delete in storage,
    // and let the user undo by re-saving the report.
    setState(() => _history.removeWhere((r) => r.id == report.id));
    await HistoryService.deleteReport(report.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Scan deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await HistoryService.saveReport(report);
            _loadHistory();
          },
        ),
      ));
  }

  String _filterLabel(_Filter f) {
    final n = switch (f) {
      _Filter.all => _history.length,
      _Filter.threats => _history.where((r) => r.riskScore >= 70).length,
      _Filter.suspicious => _history.where((r) => r.riskScore >= 40 && r.riskScore < 70).length,
      _Filter.safe => _history.where((r) => r.riskScore < 40).length,
    };
    final name = switch (f) {
      _Filter.all => 'All',
      _Filter.threats => 'Threats',
      _Filter.suspicious => 'Suspicious',
      _Filter.safe => 'Safe',
    };
    return '$name · $n';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No scans yet',
                  message: 'Your scan results will show up here so you can review them later.',
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH, vertical: 6),
                        itemCount: _Filter.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final f = _Filter.values[i];
                          return ChoiceChip(
                            label: Text(_filterLabel(f)),
                            selected: _filter == f,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = f),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? const EmptyState(
                              icon: Icons.filter_list_off_rounded,
                              title: 'Nothing here',
                              message: 'No scans match this filter.',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.screenH, 8, AppSpacing.screenH, 24),
                                itemCount: visible.length,
                                itemBuilder: (context, index) =>
                                    _buildItem(context, visible[index]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildItem(BuildContext context, ThreatReport report) {
    final color = AppColors.forScore(report.riskScore);
    final kind = report.isChainScan
        ? 'Chain'
        : report.isImageScan
            ? 'Screenshot'
            : 'Message';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Dismissible(
        key: ValueKey(report.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _delete(report),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        ),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReportScreen(report: report)),
            );
            _loadHistory();
          },
          child: Row(
            children: [
              RiskBadge(score: report.riskScore),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.maskedSnippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(label: report.threatLevel.label, color: color),
                        Text(
                          '$kind · ${report.isLocalInference ? 'On-device' : 'Cloud'} · ${relativeTime(report.createdAt)}',
                          style: TextStyle(fontSize: 12.5, color: context.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

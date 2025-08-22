import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/logs_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogsListScreen extends ConsumerWidget {
  const LogsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsListProvider);
    final range = ref.watch(logsDateRangeProvider);
    final module = ref.watch(logsModuleProvider);
    final niveau = ref.watch(logsLevelProvider);
    final userId = ref.watch(logsUserIdProvider);

    final page = ref.watch(logsPageProvider);
    final pageSize = ref.watch(logsPageSizeProvider);
    final usersRef = ref.watch(logsUsersRefProvider);
    Future<void> _persist(int page, int size) async {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt('logs_page', page);
      await sp.setInt('logs_size', size);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs (audit)'),
        actions: [
          IconButton(
            tooltip: 'Exporter CSV (presse-papiers)',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final csv = await ref.read(logsExportProvider.future);
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copié dans le presse-papiers')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: range,
                    );
                    if (picked != null) ref.read(logsDateRangeProvider.notifier).state = picked;
                  },
                  child: Text(_fmtRange(range)),
                ),
                DropdownButton<String?>(
                  value: module,
                  hint: const Text('Module'),
                  items: [const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...logsModules.map((m) => DropdownMenuItem(value: m, child: Text(m))),],
                  onChanged: (v) => ref.read(logsModuleProvider.notifier).state = v,
                ),
                DropdownButton<String?>(
                  value: niveau,
                  hint: const Text('Niveau'),
                  items: [const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...logsLevels.map((m) => DropdownMenuItem(value: m, child: Text(m))),],
                  onChanged: (v) => ref.read(logsLevelProvider.notifier).state = v,
                ),
                usersRef.when(
                  data: (items) => DropdownButton<String?>(
                    value: userId,
                    hint: const Text('Utilisateur'),
                    items: [const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...items.map((e) => DropdownMenuItem(value: e['id'], child: Text(e['label'] ?? ''))),],
                    onChanged: (v) => ref.read(logsUserIdProvider.notifier).state = v,
                  ),
                  loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => const Text('Erreur users'),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Action contient'),
                    onChanged: (v) => ref.read(logsActionContainsProvider.notifier).state = v.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Page taille:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: pageSize,
                  items: const [
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                  onChanged: (v) async {
                    final val = v ?? 50;
                    ref.read(logsPageSizeProvider.notifier).state = val;
                    await _persist(ref.read(logsPageProvider), val);
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Précédent',
                  onPressed: page > 0
                      ? () async {
                          final newPage = page - 1;
                          ref.read(logsPageProvider.notifier).state = newPage;
                          await _persist(newPage, ref.read(logsPageSizeProvider));
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${page + 1}'),
                IconButton(
                  tooltip: 'Suivant',
                  onPressed: () async {
                    final newPage = page + 1;
                    ref.read(logsPageProvider.notifier).state = newPage;
                    await _persist(newPage, ref.read(logsPageSizeProvider));
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: logs.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('Aucun log'));
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Module')),
                        DataColumn(label: Text('Action')),
                        DataColumn(label: Text('Niveau')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Details')),
                      ],
                      rows: [
                        for (final r in items)
                          DataRow(
                            onSelectChanged: (_) => _showLogDetails(context, r),
                            cells: [
                              DataCell(Text(_fmtIso(r.createdAt))),
                              DataCell(Text(r.module)),
                              DataCell(Text(r.action)),
                              DataCell(Text(r.niveau)),
                              DataCell(Text(r.userId ?? '')),
                              DataCell(Text(_shorten(r.details?.toString() ?? '', 80))),
                            ],
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtIso(DateTime d) => d.toIso8601String().replaceFirst('T', ' ').split('.').first;
  String _fmtRange(DateTimeRange? r) => r == null ? 'Période' : '${r.start.year}-${r.start.month.toString().padLeft(2, '0')}-${r.start.day.toString().padLeft(2, '0')} → ${r.end.year}-${r.end.month.toString().padLeft(2, '0')}-${r.end.day.toString().padLeft(2, '0')}';
  String _shorten(String s, int max) => s.length <= max ? s : '${s.substring(0, max)}…';

  void _showLogDetails(BuildContext context, LogEntryView r) {
    final pretty = _prettyJson(r.details);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r.module} • ${r.action}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(pretty),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pretty));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Copier'),
          ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  String _prettyJson(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) return '{}';
    try {
      // Simple pretty for nested maps/lists
      return m.toString().replaceAll(', ', ',\n').replaceAll('{', '{\n').replaceAll('}', '\n}');
    } catch (_) {
      return m.toString();
    }
  }
}


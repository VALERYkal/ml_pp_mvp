import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../providers/logs_providers.dart';
import '../services/logs_service.dart';
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
    final search = ref.watch(logsSearchTextProvider);

    final page = ref.watch(logsPageProvider);
    final pageSize = ref.watch(logsPageSizeProvider);
    final usersRef = ref.watch(logsUsersProvider);
    final modulesRef = ref.watch(logsModulesProvider);
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
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(logsListProvider),
          ),
          IconButton(
            tooltip: 'Exporter CSV (presse-papiers)',
            icon: const Icon(Icons.download),
            onPressed: () async {
              final service = ref.read(logsServiceProvider);
              final r = ref.read(logsDateRangeProvider);
              final module = ref.read(logsModuleProvider);
              final niveau = ref.read(logsLevelProvider);
              final userId = ref.read(logsUserIdProvider);
              final search = ref.read(logsSearchTextProvider);

              final start = r?.start ?? DateTime.now().subtract(const Duration(days: 7));
              final end = r?.end ?? DateTime.now().add(const Duration(days: 1));

              final csv = await service.exportCsv(
                startUtc: DateTime(start.year, start.month, start.day),
                endUtc: DateTime(end.year, end.month, end.day).add(const Duration(days: 1)),
                module: module,
                level: niveau,
                userId: userId,
                search: search,
              );
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('CSV copié dans le presse-papiers')));
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
                modulesRef.when(
                  data: (modules) => DropdownButton<String?>(
                    value: module,
                    hint: const Text('Module'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...modules.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (v) => ref.read(logsModuleProvider.notifier).state = v,
                  ),
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => const Text('Erreur'),
                ),
                DropdownButton<String?>(
                  value: niveau,
                  hint: const Text('Niveau'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous')),
                    ...logsLevels.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                  ],
                  onChanged: (v) => ref.read(logsLevelProvider.notifier).state = v,
                ),
                usersRef.when(
                  data: (users) => DropdownButton<String?>(
                    value: userId,
                    hint: const Text('Utilisateur'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...users.map(
                        (u) => DropdownMenuItem(value: u['id'], child: Text(u['label'] ?? '')),
                      ),
                    ],
                    onChanged: (v) => ref.read(logsUserIdProvider.notifier).state = v,
                  ),
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (e, _) => const Text('Erreur'),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => ref.read(logsSearchTextProvider.notifier).state = v.isEmpty
                        ? null
                        : v.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Page ${page + 1} • ${pageSize} éléments'),
                const Spacer(),
                Row(
                  children: [
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
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: logs.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('Aucun log'));

                  // Récupérer les maps de lookup pour les libellés
                  final citMap = ref
                      .watch(citerneLookupProvider)
                      .maybeWhen(data: (m) => m, orElse: () => <String, String>{});
                  final prodMap = ref
                      .watch(produitLookupProvider)
                      .maybeWhen(data: (m) => m, orElse: () => <String, String>{});
                  final usersMap = ref
                      .watch(usersLookupProvider)
                      .maybeWhen(data: (m) => m, orElse: () => const <String, String>{});

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Module')),
                        DataColumn(label: Text('Action')),
                        DataColumn(label: Text('Niveau')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Citerne')),
                        DataColumn(label: Text('Produit')),
                        DataColumn(label: Text('Vol (L)')),
                        DataColumn(label: Text('15°C (L)')),
                        DataColumn(label: Text('Date op.')),
                        DataColumn(label: Text('Details')), // compact brut (optionnel)
                      ],
                      rows: items.map((e) {
                        String fmtDt(DateTime? d) =>
                            d == null ? '-' : d.toLocal().toString().split('.').first;
                        String fmtD(DateTime? d) => d == null
                            ? '-'
                            : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                        // Résolution des IDs en libellés lisibles
                        final citerneLabel = e.citerneId == null
                            ? '-'
                            : (citMap[e.citerneId!] ?? e.citerneId!.substring(0, 8));
                        final produitLabel = e.produitId == null
                            ? '-'
                            : (prodMap[e.produitId!] ?? e.produitId!.substring(0, 8));

                        return DataRow(
                          onSelectChanged: (_) => _showLogDetails(context, e),
                          cells: [
                            DataCell(Text(fmtDt(e.createdAt))),
                            DataCell(Text(e.module)),
                            DataCell(Text(e.action)),
                            DataCell(Text(e.niveau)),
                            DataCell(
                              Text(
                                e.userId == null
                                    ? '-'
                                    : (usersMap[e.userId!] ?? e.userId!.substring(0, 8)),
                              ),
                            ),
                            DataCell(Text(citerneLabel)),
                            DataCell(Text(produitLabel)),
                            DataCell(Text(e.volAmb == null ? '-' : e.volAmb!.toStringAsFixed(1))),
                            DataCell(Text(e.vol15c == null ? '-' : e.vol15c!.toStringAsFixed(1))),
                            DataCell(Text(fmtD(e.dateOp))),
                            // détail compact (facilite le debug si une clé manque)
                            DataCell(
                              Text(
                                e.rawDetails == null ? '' : e.rawDetails.toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
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
  String _fmtRange(DateTimeRange? r) => r == null
      ? 'Période'
      : '${r.start.year}-${r.start.month.toString().padLeft(2, '0')}-${r.start.day.toString().padLeft(2, '0')} → ${r.end.year}-${r.end.month.toString().padLeft(2, '0')}-${r.end.day.toString().padLeft(2, '0')}';
  String _shorten(String s, int max) => s.length <= max ? s : '${s.substring(0, max)}…';

  // Formatters pour le popup
  String _fmtYmd(DateTime? d) => d == null
      ? '-'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtNum(double? v) => v == null ? '-' : v.toStringAsFixed(1);

  void _showLogDetails(BuildContext context, LogEntryView e) {
    // Récupérer les maps de lookup pour les libellés via ProviderScope
    final container = ProviderScope.containerOf(context);
    final usersMap = container
        .read(usersLookupProvider)
        .maybeWhen(data: (m) => m, orElse: () => const <String, String>{});
    final citMap = container
        .read(citerneLookupProvider)
        .maybeWhen(data: (m) => m, orElse: () => <String, String>{});
    final prodMap = container
        .read(produitLookupProvider)
        .maybeWhen(data: (m) => m, orElse: () => <String, String>{});

    showDialog(
      context: context,
      builder: (ctx) {
        final userName = e.userId == null
            ? '-'
            : (usersMap[e.userId!] ?? e.userId!.substring(0, 8));
        final citerneName = e.citerneId == null
            ? '-'
            : (citMap[e.citerneId!] ?? e.citerneId!.substring(0, 8));
        final produitName = e.produitId == null
            ? '-'
            : (prodMap[e.produitId!] ?? e.produitId!.substring(0, 8));
        final prettyJson = e.rawDetails == null
            ? ''
            : const JsonEncoder.withIndent('  ').convert(e.rawDetails);

        return AlertDialog(
          title: Text('${e.module} • ${e.action}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line('Date log', e.createdAt.toLocal().toString().split('.').first),
                _line('Utilisateur', userName),
                const SizedBox(height: 8),
                if (e.citerneId != null || e.produitId != null) ...[
                  _line('Citerne', citerneName),
                  _line('Produit', produitName),
                ],
                if (e.volAmb != null || e.vol15c != null || e.dateOp != null) ...[
                  _line('Volume (L)', _fmtNum(e.volAmb)),
                  _line('15°C (L)', _fmtNum(e.vol15c)),
                  _line('Date opération', _fmtYmd(e.dateOp)),
                ],
                const SizedBox(height: 12),
                Text('Détails (JSON)', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      prettyJson.isEmpty ? '{}' : prettyJson,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
        );
      },
    );
  }

  // petit widget helper
  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../providers/logs_providers.dart';
import '../providers/logs_refs_provider.dart';
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

              final start =
                  r?.start ?? DateTime.now().subtract(const Duration(days: 7));
              final end = r?.end ?? DateTime.now().add(const Duration(days: 1));

              final csv = await service.exportCsv(
                startUtc: DateTime(start.year, start.month, start.day),
                endUtc: DateTime(
                  end.year,
                  end.month,
                  end.day,
                ).add(const Duration(days: 1)),
                module: module,
                level: niveau,
                userId: userId,
                search: search,
              );
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV copié dans le presse-papiers'),
                  ),
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
                    if (picked != null) {
                      ref.read(logsDateRangeProvider.notifier).state = picked;
                    }
                  },
                  child: Text(_fmtRange(range)),
                ),
                modulesRef.when(
                  data: (modules) => DropdownButton<String?>(
                    value: module,
                    hint: const Text('Module'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...modules.map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      ),
                    ],
                    onChanged: (v) =>
                        ref.read(logsModuleProvider.notifier).state = v,
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
                    ...logsLevels.map(
                      (l) => DropdownMenuItem(value: l, child: Text(l)),
                    ),
                  ],
                  onChanged: (v) =>
                      ref.read(logsLevelProvider.notifier).state = v,
                ),
                usersRef.when(
                  data: (users) => DropdownButton<String?>(
                    value: userId,
                    hint: const Text('Utilisateur'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...users.map(
                        (u) => DropdownMenuItem(
                          value: u['id'],
                          child: Text(u['label'] ?? ''),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        ref.read(logsUserIdProvider.notifier).state = v,
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
                    onChanged: (v) =>
                        ref.read(logsSearchTextProvider.notifier).state =
                            v.isEmpty ? null : v.trim(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Page ${page + 1} • $pageSize éléments'),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Précédent',
                      onPressed: page > 0
                          ? () async {
                              final newPage = page - 1;
                              ref.read(logsPageProvider.notifier).state =
                                  newPage;
                              await _persist(
                                newPage,
                                ref.read(logsPageSizeProvider),
                              );
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
                  if (items.isEmpty) {
                    return const Center(child: Text('Aucun log'));
                  }

                  // Extraire les IDs uniques pour cette page
                  final refsRequest = LogsRefsRequest.fromLogEntryViews(items);
                  
                  // Résoudre les références en batch
                  final refsAsync = ref.watch(logsRefsProvider(refsRequest));
                  
                  final usersMap = ref
                      .watch(usersLookupProvider)
                      .maybeWhen(
                        data: (m) => m,
                        orElse: () => const <String, String>{},
                      );

                  // Obtenir les références résolues (avec fallback)
                  final refs = refsAsync.maybeWhen(
                    data: (r) => r,
                    orElse: () => const LogsRefs(
                      produitsLabelById: {},
                      citernesLabelById: {},
                    ),
                  );

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date/Heure')),
                        DataColumn(label: Text('Niveau')),
                        DataColumn(label: Text('Module')),
                        DataColumn(label: Text('Action')),
                        DataColumn(label: Text('Résumé')),
                      ],
                      rows: items.map((e) {
                        String fmtDt(DateTime d) {
                          final local = d.toLocal();
                          return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
                        }

                        // Couleur du niveau
                        Color levelColor(String niveau) {
                          switch (niveau.toUpperCase()) {
                            case 'CRITICAL':
                              return Colors.red;
                            case 'WARNING':
                              return Colors.orange;
                            case 'INFO':
                            default:
                              return Colors.blue;
                          }
                        }

                        return DataRow(
                          onSelectChanged: (_) => _showLogDetails(context, e, refs),
                          cells: [
                            DataCell(Text(fmtDt(e.createdAtLocal))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor(e.niveau).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: levelColor(e.niveau),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  e.levelLabel,
                                  style: TextStyle(
                                    color: levelColor(e.niveau),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(e.moduleLabel)),
                            DataCell(Text(e.actionLabel)),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 300),
                                child: Text(
                                  e.buildHumanSummary(refs: refs),
                                  overflow: TextOverflow.ellipsis,
                                ),
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

  String _fmtIso(DateTime d) =>
      d.toIso8601String().replaceFirst('T', ' ').split('.').first;
  String _fmtRange(DateTimeRange? r) => r == null
      ? 'Période'
      : '${r.start.year}-${r.start.month.toString().padLeft(2, '0')}-${r.start.day.toString().padLeft(2, '0')} → ${r.end.year}-${r.end.month.toString().padLeft(2, '0')}-${r.end.day.toString().padLeft(2, '0')}';
  String _shorten(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  // Formatters pour le popup
  String _fmtYmd(DateTime? d) => d == null
      ? '-'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _fmtNum(double? v) => v == null ? '-' : v.toStringAsFixed(1);

  void _showLogDetails(BuildContext context, LogEntryView e, LogsRefs refs) async {
    // Récupérer les maps de lookup pour les libellés via ProviderScope
    final container = ProviderScope.containerOf(context);
    final usersMap = container
        .read(usersLookupProvider)
        .maybeWhen(data: (m) => m, orElse: () => const <String, String>{});

    // Couleur du niveau
    Color levelColor(String niveau) {
      switch (niveau.toUpperCase()) {
        case 'CRITICAL':
          return Colors.red;
        case 'WARNING':
          return Colors.orange;
        case 'INFO':
        default:
          return Colors.blue;
      }
    }

    final userName = e.userId == null
        ? '-'
        : (usersMap[e.userId!] ?? e.userId!.substring(0, 8));
    
    final detailsMap = e.detailsMap;
    final prettyJson = detailsMap == null
        ? '{}'
        : const JsonEncoder.withIndent('  ').convert(detailsMap);
    
    final chips = e.buildChips(refs: refs);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${e.moduleLabel} • ${e.actionLabel}'),
              const SizedBox(height: 4),
              Text(
                '${e.createdAtLocal.year}-${e.createdAtLocal.month.toString().padLeft(2, '0')}-${e.createdAtLocal.day.toString().padLeft(2, '0')} ${e.createdAtLocal.hour.toString().padLeft(2, '0')}:${e.createdAtLocal.minute.toString().padLeft(2, '0')}:${e.createdAtLocal.second.toString().padLeft(2, '0')}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Niveau + Utilisateur
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor(e.niveau).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: levelColor(e.niveau),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          e.levelLabel,
                          style: TextStyle(
                            color: levelColor(e.niveau),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Utilisateur: $userName',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Résumé
                  Text(
                    'Résumé',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e.buildHumanSummary(refs: refs)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Champs clés (chips)
                  if (chips.isNotEmpty) ...[
                    Text(
                      'Champs clés',
                      style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips.map((chip) {
                        return Chip(
                          label: Text('${chip.label}: ${chip.value}'),
                          avatar: const Icon(Icons.label, size: 16),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // JSON complet
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'JSON complet',
                        style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: prettyJson));
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('JSON copié dans le presse-papiers'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copier'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(ctx).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: SelectableText(
                          prettyJson,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // ID cible (si présent)
                  if (e.cibleId != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID cible',
                          style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: e.cibleId!));
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('ID copié dans le presse-papiers'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: Text(e.cibleId!.substring(0, 8)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fermer'),
            ),
          ],
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
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  String _prettyJson(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) {
      return '{}';
    }
    try {
      // Simple pretty for nested maps/lists
      return m
          .toString()
          .replaceAll(', ', ',\n')
          .replaceAll('{', '{\n')
          .replaceAll('}', '\n}');
    } catch (_) {
      return m.toString();
    }
  }
}

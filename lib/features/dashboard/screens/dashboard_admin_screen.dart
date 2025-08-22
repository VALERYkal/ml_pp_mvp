import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_card.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/placeholders.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/admin_kpi_provider.dart';
import 'package:ml_pp_mvp/features/logs/providers/logs_provider.dart' as logs;
import 'package:ml_pp_mvp/features/logs/services/logs_service.dart' as logs_service;

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(adminKpiProvider);
    final kpiHeader = kpis.when(
      loading: () => const ShimmerRow(),
      error: (e, _) => ErrorTile('Impossible de charger les KPIs', onRetry: () => ref.invalidate(adminKpiProvider)),
      data: (d) => Wrap(
        spacing: 16, runSpacing: 16,
        children: [
          KpiCard(title: 'Erreurs (24h)', value: d.erreurs24h, warning: d.erreurs24h > 0),
          KpiCard(title: 'Réceptions (jour)', value: d.receptionsJour),
          KpiCard(title: 'Sorties (jour)', value: d.sortiesJour),
          KpiCard(title: 'Citernes sous seuil', value: d.citernesSousSeuil, warning: d.citernesSousSeuil > 0),
          KpiCard(title: 'Produits actifs', value: d.produitsActifs),
        ],
      ),
    );

    final filter = ref.watch(logs.logsFilterProvider).copyWith(module: null);
    final logsAsync = ref.watch(logs.logsProvider(filter));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminKpiProvider);
        ref.invalidate(logs.logsProvider(filter));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          kpiHeader,
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(logs_service.logsServiceProvider).exportCsv(filter);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export CSV lancé')));
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter logs CSV'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: context.go('/receptions');
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Voir Réceptions'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: context.go('/sorties');
                    },
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Voir Sorties'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: context.go('/stocks');
                    },
                    icon: const Icon(Icons.storage),
                    label: const Text('Voir Stocks & Citernes'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Erreurs récentes', style: Theme.of(context).textTheme.titleMedium),
                logsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur chargement logs: $e'),
                  data: (items) {
                    final errors = items.where((it) => it.niveau == 'ERROR' || it.niveau == 'CRITICAL').toList();
                    if (errors.isEmpty) return const Text('Aucune erreur récente');
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: errors.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final it = errors[i];
                        return ListTile(
                          leading: Icon(it.niveau == 'CRITICAL' ? Icons.error : Icons.warning_amber),
                          title: Text('${it.module} • ${it.action}'),
                          subtitle: Text(it.createdAtFmt),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: showDialog avec détails JSON
                          },
                        );
                      },
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

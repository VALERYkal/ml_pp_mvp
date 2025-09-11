import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/shared/ui/section_title.dart';
import 'package:ml_pp_mvp/shared/ui/async_view.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/admin_trends_provider.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/activites_recentes_provider.dart';
import 'package:ml_pp_mvp/features/dashboard/admin/widgets/area_chart.dart';
import 'package:ml_pp_mvp/features/dashboard/admin/widgets/citernes_table.dart';
import 'package:ml_pp_mvp/features/kpi/providers/camions_a_suivre_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/receptions_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/stocks_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/sorties_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/balance_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/kpi/widgets/kpi_summary_card.dart';
import 'package:ml_pp_mvp/features/kpi/widgets/kpi_split_card.dart';
import 'package:ml_pp_mvp/shared/utils/format.dart';
import 'package:ml_pp_mvp/shared/utils/formatters.dart';

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trends = ref.watch(adminTrends7dProvider);
    final activity = ref.watch(activitesRecentesProvider);
    // KPI Camions enrichi avec volumes
    ref.watch(coursRealtimeInvalidatorProvider); // invalidation realtime
    final coursParam = ref.watch(coursDefaultParamProvider);
    final coursState = ref.watch(coursKpiProvider(coursParam));
    
    final p = ref.watch(receptionsTodayParamProvider); // ✅ param stable (record)
    final recState = ref.watch(receptionsKpiProvider(p)); // ✅ family sur record
    
    // KPI 3 : Stocks totaux
    ref.watch(stocksRealtimeInvalidatorProvider); // invalidation realtime
    final sp = ref.watch(stocksDefaultParamProvider);
    final stocksState = ref.watch(stocksTotalsProvider(sp));
    
    // KPI 4 : Sorties du jour
    ref.watch(sortiesRealtimeInvalidatorProvider); // invalidation realtime
    final sortiesP = ref.watch(sortiesTodayParamProvider);
    final sortiesState = ref.watch(sortiesKpiProvider(sortiesP));
    
    // KPI 5 : Balance du jour
    final balanceState = ref.watch(balanceTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord — Admin'),
        actions: [
          IconButton(onPressed: () {/* TODO: filtres globaux */}, icon: const Icon(Icons.filter_alt_outlined)),
          IconButton(onPressed: () {/* TODO: export */}, icon: const Icon(Icons.download_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPIs
          LayoutBuilder(builder: (context, c) {
            final isWide = c.maxWidth > 900;
            final grid = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: isWide ? 6 : 2, mainAxisExtent: 110, crossAxisSpacing: 12, mainAxisSpacing: 12);
            
            return Column(
              children: [
                // KPI Camions enrichi avec volumes
                coursState.when(
                  data: (d) => KpiSplitCard(
                    title: 'Camions à suivre',
                    icon: Icons.local_shipping_outlined,
                    leftLabel: 'En route',
                    leftValue: '${d.enRoute}',
                    leftSubLabel: 'Volume prévu',
                    leftSubValue: fmtLiters(d.enRouteLitres),
                    rightLabel: 'En attente de déchargement',
                    rightValue: '${d.attente}',
                    rightSubLabel: 'Volume prévu',
                    rightSubValue: fmtLiters(d.attenteLitres),
                    onTap: () => context.go('/cours'),
                  ),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => SizedBox(height: 120, child: Center(child: Text('KPI Cours indisponible'))),
                ),
                const SizedBox(height: 12),
                // KPI Réceptions (jour)
                recState.when(
                  data: (d) => KpiSummaryCard(
                    title: 'Réceptions (jour)',
                    totalValue: '${d.nbCamions}',
                    details: [
                      KpiLabelValue('Vol. ambiant', fmtLiters(d.volAmbiant)),
                      KpiLabelValue('Vol. 15°C', fmtLiters(d.vol15c)),
                    ],
                    icon: Icons.move_to_inbox_outlined,
                    tint: d.nbCamions == 0 ? null : Colors.teal,
                    onTap: () => context.go('/receptions'),
                  ),
                  loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                  error: (e, st) => SizedBox(
                    height: 110,
                    child: Center(
                      child: Text(
                        'Réceptions indisponibles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // KPI 3 : Stocks totaux
                stocksState.when(
                  data: (s) => KpiSplitCard(
                    title: 'Stock total (actuel)',
                    icon: Icons.inventory_2_outlined,
                    leftLabel: 'Vol. ambiant',
                    leftValue: fmtLiters(s.totalAmbiant),
                    rightLabel: 'Vol. 15 °C',
                    rightValue: fmtLiters(s.total15c),
                    // Option : afficher la date de MAJ si disponible
                    leftSubLabel: s.lastDay != null ? 'MAJ' : null,
                    leftSubValue: s.lastDay != null ? fmtShortDate(s.lastDay!) : null,
                    onTap: () => context.go('/stocks'),
                  ),
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => const SizedBox(height: 120, child: Center(child: Text('Stocks indisponibles'))),
                ),
                const SizedBox(height: 12),
                // KPI 4 : Sorties du jour
                sortiesState.when(
                  data: (s) => KpiSummaryCard(
                    title: 'Sorties (jour)',
                    totalValue: '${s.nbCamions}',
                    details: [
                      KpiLabelValue('Vol. ambiant', fmtLiters(s.volAmbiant)),
                      KpiLabelValue('Vol. 15 °C', fmtLiters(s.vol15c)),
                    ],
                    icon: Icons.outbox_outlined,
                    onTap: () => context.go('/sorties'),
                  ),
                  loading: () => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 110, child: Center(child: Text('Sorties indisponibles'))),
                ),
                const SizedBox(height: 12),
                // KPI 5 : Balance du jour
                balanceState.when(
                  data: (b) {
                    Color tint(num v) => v > 0 ? Colors.teal : (v < 0 ? Colors.red : Colors.grey);
                    return KpiSplitCard(
                      title: 'Balance du jour',
                      icon: Icons.swap_vert,
                      leftLabel: 'Δ Vol. ambiant',
                      leftValue: fmtLitersSigned(b.deltaAmbiant),
                      rightLabel: 'Δ Vol. 15 °C',
                      rightValue: fmtLitersSigned(b.delta15c),
                      leftAccent: tint(b.deltaAmbiant),
                      rightAccent: tint(b.delta15c),
                      onTap: () => context.go('/stocks'),
                    );
                  },
                  loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(height: 120, child: Center(child: Text('Balance indisponible'))),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Tendances
          const SectionTitle(title: 'Tendances 7 jours'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0,6))],
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
            ),
            height: 320, // Augmenté pour accommoder la légende
            child: AsyncView(
              state: trends,
              builder: (pts) => AreaChart(points: pts),
            ),
          ),

          const SizedBox(height: 24),
          // A surveiller
          const SectionTitle(title: 'À surveiller — Citernes sous seuil'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0,6))],
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
            ),
            child: const CiternesSousSeuilTable(),
          ),

          const SizedBox(height: 24),
          // Activité récente
          SectionTitle(
            title: 'Activité récente (24h)',
            trailing: TextButton.icon(
              onPressed: () async {
                // TODO: appeler logsService.exportCsv(...) et sauvegarder
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Exporter CSV'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0,6))],
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.2)),
            ),
            child: AsyncView(
              state: activity,
              builder: (rows) => ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final m = rows[i];
                  final level = m.niveau.toUpperCase();
                  final icon = level == 'CRITICAL' ? Icons.warning_amber_outlined
                               : level == 'WARNING' ? Icons.report_gmailerrorred_outlined
                               : Icons.info_outline;
                  return ListTile(
                    leading: Icon(icon),
                    title: Text('${m.action} • ${m.module}'),
                    subtitle: Text('${m.createdAtFmt} — user:${m.userId ?? 'N/A'}\n${m.details?.toString() ?? ''}'),
                    isThreeLine: true,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { /* TODO: ouvrir menu d'actions rapides */ },
        label: const Text('Actions rapides'),
        icon: const Icon(Icons.flash_on_outlined),
      ),
    );
  }
}


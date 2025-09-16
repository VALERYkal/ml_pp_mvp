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

// Nouveaux composants modernes
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_header.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_kpi_card.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_grid.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_tiles.dart';

class DashboardAdminScreen extends ConsumerWidget {
  const DashboardAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trends = ref.watch(adminTrends7dProvider);
    final activity = ref.watch(activitesRecentesProvider);
    
    // --- Realtime invalidators (no UI)
    ref.watch(coursRealtimeInvalidatorProvider);
    ref.watch(stocksRealtimeInvalidatorProvider);
    ref.watch(sortiesRealtimeInvalidatorProvider);

    // --- KPI 1: Camions (en route / attente + volumes)
    final coursParam  = ref.watch(coursDefaultParamProvider);
    final coursState  = ref.watch(coursKpiProvider(coursParam));

    final kpiCamions = coursState.when(
      data: (d) => ModernKpiCard(
        title: 'Camions à suivre',
        primaryValue: '${d.enRoute + d.attente}',
        primaryLabel: 'Camions total',
        secondaryValue: fmtLiters(d.enRouteLitres + d.attenteLitres),
        secondaryLabel: 'Volume total prévu',
        icon: Icons.local_shipping_outlined,
        accentColor: Colors.blue,
        metrics: [
          KpiMetric(label: 'En route', value: '${d.enRoute}'),
          KpiMetric(label: 'En attente', value: '${d.attente}'),
          KpiMetric(label: 'Vol. en route', value: fmtLiters(d.enRouteLitres)),
          KpiMetric(label: 'Vol. en attente', value: fmtLiters(d.attenteLitres)),
        ],
        onTap: () => context.go('/cours'),
      ),
      loading: () => _buildLoadingCard('Camions à suivre', Icons.local_shipping_outlined),
      error: (_, __) => _buildErrorCard('Camions à suivre', Icons.local_shipping_outlined),
    );

    // --- KPI 2: Réceptions (jour)
    final recParam   = ref.watch(receptionsTodayParamProvider);
    final recState   = ref.watch(receptionsKpiProvider(recParam));

    final kpiReceptions = recState.when(
      data: (d) => ModernKpiCard(
        title: 'Réceptions du jour',
        primaryValue: '${d.nbCamions}',
        primaryLabel: 'Camions reçus',
        secondaryValue: fmtLiters(d.volAmbiant),
        secondaryLabel: 'Volume ambiant',
        icon: Icons.move_to_inbox_outlined,
        accentColor: Colors.green,
        metrics: [
          KpiMetric(label: 'Volume 15°C', value: fmtLiters(d.vol15c)),
        ],
        onTap: () => context.go('/receptions'),
      ),
      loading: () => _buildLoadingCard('Réceptions', Icons.move_to_inbox_outlined),
      error:  (_, __) => _buildErrorCard('Réceptions', Icons.move_to_inbox_outlined),
    );

    // --- KPI 3: Stock total (actuel)
    final stkParam   = ref.watch(stocksDefaultParamProvider);
    final stkState   = ref.watch(stocksTotalsProvider(stkParam));

    final kpiStocks = stkState.when(
      data: (s) => ModernKpiCard(
        title: 'Stock total',
        primaryValue: fmtLiters(s.totalAmbiant),
        primaryLabel: 'Volume ambiant',
        secondaryValue: fmtLiters(s.total15c),
        secondaryLabel: 'Volume 15°C',
        icon: Icons.inventory_2_outlined,
        accentColor: Colors.orange,
        metrics: s.lastDay != null ? [
          KpiMetric(label: 'Dernière MAJ', value: fmtShortDate(s.lastDay!)),
        ] : null,
        onTap: () => context.go('/stocks'),
      ),
      loading: () => _buildLoadingCard('Stocks', Icons.inventory_2_outlined),
      error:  (_, __) => _buildErrorCard('Stocks', Icons.inventory_2_outlined),
    );

    // --- KPI 4: Sorties (jour)
    final sorParam   = ref.watch(sortiesTodayParamProvider);
    final sorState   = ref.watch(sortiesKpiProvider(sorParam));

    final kpiSorties = sorState.when(
      data: (d) => ModernKpiCard(
        title: 'Sorties du jour',
        primaryValue: '${d.nbCamions}',
        primaryLabel: 'Camions sortis',
        secondaryValue: fmtLiters(d.volAmbiant),
        secondaryLabel: 'Volume ambiant',
        icon: Icons.outbox_outlined,
        accentColor: Colors.red,
        metrics: [
          KpiMetric(label: 'Volume 15°C', value: fmtLiters(d.vol15c)),
        ],
        onTap: () => context.go('/sorties'),
      ),
      loading: () => _buildLoadingCard('Sorties', Icons.outbox_outlined),
      error:  (_, __) => _buildErrorCard('Sorties', Icons.outbox_outlined),
    );

    // --- KPI 5: Balance (jour) = Réceptions - Sorties (ambiant & 15°C)
    final balanceState = ref.watch(balanceTodayProvider);
    final kpiBalance = balanceState.when(
      data: (b) {
        final isPositive = b.deltaAmbiant > 0;
        final accentColor = isPositive ? Colors.teal : Colors.red;
        
        return ModernKpiCard(
          title: 'Balance du jour',
          primaryValue: fmtLitersSigned(b.deltaAmbiant),
          primaryLabel: 'Δ Volume ambiant',
          secondaryValue: fmtLitersSigned(b.delta15c),
          secondaryLabel: 'Δ Volume 15°C',
          icon: Icons.compare_arrows_outlined,
          accentColor: accentColor,
          trend: KpiTrend(value: b.deltaAmbiant > 0 ? 5.2 : -3.1),
          onTap: () => context.go('/stocks'),
        );
      },
      loading: () => _buildLoadingCard('Balance', Icons.compare_arrows_outlined),
      error:  (_, __) => _buildErrorCard('Balance', Icons.compare_arrows_outlined),
    );

    // --- Mise en page moderne
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec salutation
              const DashboardHeader(),
              
              // Section principale - KPIs essentiels
              DashboardSection(
                title: 'Vue d\'ensemble',
                subtitle: 'Indicateurs clés de performance en temps réel',
                child: DashboardGrid(
                  children: [kpiCamions, kpiStocks, kpiBalance],
                ),
              ),
              
              // Section cours de route détaillée
              DashboardSection(
                title: 'Cours de route',
                subtitle: 'Suivi détaillé des camions par statut',
                child: const CdrKpiTiles(),
              ),
              
              // Section activités du jour
              DashboardSection(
                title: 'Activités du jour',
                subtitle: 'Réceptions et sorties',
                child: DashboardGrid(
                  children: [kpiReceptions, kpiSorties],
                ),
              ),

              // Section tendances (spécifique admin)
              DashboardSection(
                title: 'Tendances 7 jours',
                subtitle: 'Évolution des volumes et activités',
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: AsyncView(
                    state: trends,
                    builder: (pts) => AreaChart(points: pts),
                  ),
                ),
              ),

              // Section surveillance (spécifique admin)
              DashboardSection(
                title: 'À surveiller',
                subtitle: 'Citernes sous seuil critique',
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: const CiternesSousSeuilTable(),
                ),
              ),

              // Section activité récente (spécifique admin)
              DashboardSection(
                title: 'Activité récente (24h)',
                subtitle: 'Logs et événements système',
                action: TextButton.icon(
                  onPressed: () async {
                    // TODO: appeler logsService.exportCsv(...) et sauvegarder
                  },
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Exporter CSV'),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: AsyncView(
                    state: activity,
                    builder: (rows) => ListView.separated(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
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
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { /* TODO: ouvrir menu d'actions rapides */ },
        label: const Text('Actions rapides'),
        icon: const Icon(Icons.flash_on_outlined),
      ),
    );
  }

  /// Widget de chargement moderne
  Widget _buildLoadingCard(String title, IconData icon) {
    return ModernKpiCard(
      title: title,
      primaryValue: '...',
      icon: icon,
      accentColor: Colors.grey,
    );
  }

  /// Widget d'erreur moderne
  Widget _buildErrorCard(String title, IconData icon) {
    return ModernKpiCard(
      title: title,
      primaryValue: 'Erreur',
      primaryLabel: 'Données indisponibles',
      icon: icon,
      accentColor: Colors.red,
    );
  }
}


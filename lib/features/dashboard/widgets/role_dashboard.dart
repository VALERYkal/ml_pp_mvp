import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/shared/ui/kpi_card.dart';
import 'package:ml_pp_mvp/shared/formatters.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_grid.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_header.dart';
import 'package:ml_pp_mvp/shared/dev/hot_reload_hooks.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/stocks/widgets/stocks_kpi_cards.dart';
import 'trucks_to_follow_card.dart';

class RoleDashboard extends ConsumerWidget {
  const RoleDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(kpiProviderProvider);

    final dashboardContent = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec salutation
              const DashboardHeader(),
              
              // Section principale - KPIs unifiés
              DashboardSection(
                title: 'Vue d\'ensemble',
                subtitle: 'Indicateurs clés de performance en temps réel',
                accentColor: KpiColorPalette.primary,
                child: kpis.when(
                       loading: () => const Center(
                         key: Key('role_dashboard_loading_state'),
                         child: CircularProgressIndicator(),
                       ),
                       error: (e, st) => Center(
                         key: const Key('role_dashboard_error_state'),
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Icon(
                               Icons.error_outline,
                               size: 48,
                               color: Theme.of(context).colorScheme.error,
                             ),
                             const SizedBox(height: 16),
                             Text(
                               'Erreur de chargement des KPIs',
                               style: Theme.of(context).textTheme.titleMedium,
                             ),
                             const SizedBox(height: 8),
                             Text(
                               'Veuillez réessayer plus tard',
                               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                 color: Theme.of(context).colorScheme.onSurfaceVariant,
                               ),
                             ),
                           ],
                         ),
                       ),
                       data: (KpiSnapshot data) {
                         // Obtenir le depotId depuis le profil pour le breakdown par propriétaire
                         final profil = ref.watch(profilProvider).valueOrNull;
                         final depotId = profil?.depotId;
                         
                         return DashboardGrid(
                           children: [
                             // 1. Camions à suivre (priorité logistique)
                             TrucksToFollowCard(
                               data: data.trucksToFollow,
                               onTap: () => context.go('/camions'),
                             ),
                             // 2. Réceptions du jour
                             Builder(
                               builder: (context) {
                                 return KpiCard(
                                   cardKey: const Key('kpi_receptions_today_card'),
                                   icon: Icons.move_to_inbox_outlined,
                                   title: 'Réceptions du jour',
                                   tintColor: const Color(0xFF4CAF50),
                                   primaryValue: fmtL(data.receptionsToday.volume15c),
                                   primaryLabel: 'Volume 15°C',
                                   subLeftLabel: 'Nombre de camions',
                                   subLeftValue: fmtCount(data.receptionsToday.count),
                                   subRightLabel: 'Volume ambiant',
                                   subRightValue: fmtL(data.receptionsToday.volumeAmbient),
                                   onTap: () => context.go('/receptions'),
                                 );
                               },
                             ),
                             // 3. Sorties du jour
                             Builder(
                               builder: (context) {
                                 return KpiCard(
                                   cardKey: const Key('kpi_sorties_today_card'),
                                   icon: Icons.outbox_outlined,
                                   title: 'Sorties du jour',
                                   tintColor: const Color(0xFFF44336),
                                   primaryValue: fmtL(data.sortiesToday.volume15c),
                                   primaryLabel: 'Volume 15°C',
                                   subLeftLabel: 'Nombre de camions',
                                   subLeftValue: fmtCount(data.sortiesToday.count),
                                   subRightLabel: 'Volume ambiant',
                                   subRightValue: fmtL(data.sortiesToday.volumeAmbient),
                                   onTap: () => context.go('/sorties'),
                                 );
                               },
                             ),
                             // 4. Stock total
                             Builder(
                               builder: (context) {
                                 final usagePct = data.stocks.capacityTotal <= 0 ? 0 : (data.stocks.totalAmbient / data.stocks.capacityTotal * 100);
                                 return KpiCard(
                                   cardKey: const Key('kpi_stock_total_card'),
                                   icon: Icons.inventory_2_outlined,
                                   title: 'Stock total',
                                   tintColor: const Color(0xFFFF9800),
                                   primaryValue: fmtL(data.stocks.total15c),
                                   primaryLabel: 'Volume 15°C',
                                   subLeftLabel: 'Volume ambiant',
                                   subLeftValue: fmtL(data.stocks.totalAmbient, fixed: 1),
                                   subRightLabel: '${usagePct.toStringAsFixed(0)}% utilisation',
                                   subRightValue: 'Capacité ${fmtL(data.stocks.capacityTotal, fixed: 0)}',
                                   onTap: () => context.go('/stocks'),
                                 );
                               },
                             ),
                             // 4.5. Stock par propriétaire (si depotId disponible)
                             if (depotId != null && depotId.isNotEmpty)
                               OwnerStockBreakdownCard(
                                 depotId: depotId,
                                 onTap: () => context.go('/stocks'),
                               ),
                             // 5. Balance du jour
                             Builder(
                               builder: (context) {
                                 return KpiCard(
                                   cardKey: const Key('kpi_balance_today_card'),
                                   icon: Icons.compare_arrows_outlined,
                                   title: 'Balance du jour',
                                   tintColor: data.balanceToday.delta15c >= 0 ? const Color(0xFF009688) : const Color(0xFFF44336),
                                   primaryValue: fmtDelta(data.balanceToday.delta15c),
                                   primaryLabel: 'Δ Volume 15°C',
                                   subLeftLabel: 'Réceptions 15°C',
                                   subLeftValue: fmtL(data.balanceToday.receptions15c),
                                   subRightLabel: 'Sorties 15°C',
                                   subRightValue: fmtL(data.balanceToday.sorties15c),
                                   onTap: () => context.go('/stocks'),
                                 );
                               },
                             ),
                             // 6. Tendance 7 jours
                             Builder(
                               builder: (context) {
                                 final sumIn = data.trend7d.fold<double>(0, (s, p) => s + p.receptions15c);
                                 final sumOut = data.trend7d.fold<double>(0, (s, p) => s + p.sorties15c);
                                 final net = sumIn - sumOut;
                                 return KpiCard(
                                   cardKey: const Key('kpi_tendance_7d_card'),
                                   icon: Icons.trending_up_rounded,
                                   title: 'Tendance 7 jours',
                                   tintColor: const Color(0xFF7C4DFF),
                                   primaryValue: fmtL(net),
                                   primaryLabel: 'Somme nette 15°C (7j)',
                                   subLeftLabel: 'Somme réceptions (15°C)',
                                   subLeftValue: fmtL(sumIn),
                                   subRightLabel: 'Somme sorties (15°C)',
                                   subRightValue: fmtL(sumOut),
                                   onTap: () => context.go('/analytics/trends'),
                                 );
                               },
                             ),
                           ],
                         );
                       },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Envelopper avec le hook d'invalidation Hot Reload en mode debug
    if (kDebugMode) {
      return HotReloadInvalidator(
        child: dashboardContent,
        providersToInvalidate: [
          profilProvider,
          kpiProviderProvider,
        ],
      );
    }
    return dashboardContent;
  }

}

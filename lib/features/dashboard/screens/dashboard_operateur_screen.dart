// 📌 Module : Dashboard Feature - Operateur Screen
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Écran de dashboard pour l'opérateur

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/receptions_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/stocks_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/sorties_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/balance_kpi_provider.dart';
import 'package:ml_pp_mvp/shared/utils/formatters.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_tiles.dart';

// Nouveaux composants modernes
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_header.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_kpi_card.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_grid.dart';

class DashboardOperateurScreen extends ConsumerWidget {
  const DashboardOperateurScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // Section accès rapide (spécifique opérateur)
              DashboardSection(
                title: 'Accès rapide',
                subtitle: 'Fonctionnalités opérationnelles',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        context,
                        'Nouveau cours',
                        Icons.add_circle_outline,
                        Colors.blue,
                        () => context.go('/cours/new'),
                      ),
                      _buildQuickAction(
                        context,
                        'Réception',
                        Icons.inventory_2_outlined,
                        Colors.green,
                        () => context.go('/receptions/new'),
                      ),
                      _buildQuickAction(
                        context,
                        'Sortie',
                        Icons.outbox_outlined,
                        Colors.red,
                        () => context.go('/sorties/new'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

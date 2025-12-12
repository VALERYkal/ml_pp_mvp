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
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/citernes_sous_seuil_provider.dart';
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                          onTap: () => context.go('/cours'),
                        ),
                        // 2. Réceptions du jour
                        Builder(
                          builder: (context) {
                            return KpiCard(
                              cardKey: const Key('kpi_receptions_today_card'),
                              icon: Icons.move_to_inbox_outlined,
                              title: 'Réceptions du jour',
                              tintColor: const Color(0xFF4CAF50),
                              primaryValue: fmtL(
                                data.receptionsToday.volume15c,
                              ),
                              primaryLabel: 'Volume 15°C',
                              subLeftLabel: 'Nombre de camions',
                              subLeftValue: fmtCount(
                                data.receptionsToday.count,
                              ),
                              subRightLabel: 'Volume ambiant',
                              subRightValue: fmtL(
                                data.receptionsToday.volumeAmbient,
                              ),
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
                              subRightValue: fmtL(
                                data.sortiesToday.volumeAmbient,
                              ),
                              onTap: () => context.go('/sorties'),
                            );
                          },
                        ),
                        // 4. Stock total
                        Builder(
                          builder: (context) {
                            final depotId = ref
                                .watch(profilProvider)
                                .valueOrNull
                                ?.depotId;

                            // Récupérer la capacité totale du dépôt (toutes les citernes actives)
                            final depotCapacityAsync = depotId != null
                                ? ref.watch(depotTotalCapacityProvider(depotId))
                                : null;

                            // Utiliser la capacité du dépôt si disponible, sinon fallback sur l'ancienne
                            final capacityTotal =
                                depotCapacityAsync?.valueOrNull ??
                                data.stocks.capacityTotal;

                            final usagePct = capacityTotal <= 0
                                ? 0
                                : (data.stocks.totalAmbient /
                                      capacityTotal *
                                      100);

                            final stocksByOwnerAsync = ref.watch(
                              kpiStockByOwnerProvider,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Carte existante (inchangée sauf capacité)
                                KpiCard(
                                  cardKey: const Key('kpi_stock_total_card'),
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Stock total',
                                  tintColor: const Color(0xFFFF9800),
                                  primaryValue: fmtL(
                                    data.stocks.total15c,
                                  ), // Inchangé
                                  primaryLabel: 'Volume 15°C',
                                  subLeftLabel: 'Volume ambiant',
                                  subLeftValue: fmtL(
                                    data.stocks.totalAmbient,
                                    fixed: 1,
                                  ), // Inchangé
                                  subRightLabel:
                                      '${usagePct.toStringAsFixed(0)}% utilisation',
                                  subRightValue:
                                      'Capacité ${fmtL(capacityTotal, fixed: 0)}', // Utilise la nouvelle capacité
                                  onTap: () => context.go('/stocks'),
                                ),
                                // Nouvelle section : Détail par propriétaire
                                stocksByOwnerAsync.when(
                                  data: (ownerList) {
                                    // Filtrer par depotId si disponible
                                    final filteredList = depotId != null
                                        ? ownerList
                                              .where(
                                                (item) =>
                                                    item.depotId == depotId,
                                              )
                                              .toList()
                                        : ownerList;

                                    // Agréger les valeurs par propriétaire
                                    double mon15c = 0.0;
                                    double monAmb = 0.0;
                                    double part15c = 0.0;
                                    double partAmb = 0.0;

                                    for (final item in filteredList) {
                                      if (item.proprietaireType.toUpperCase() ==
                                          'MONALUXE') {
                                        mon15c += item.stock15cTotal;
                                        monAmb += item.stockAmbiantTotal;
                                      } else if (item.proprietaireType
                                              .toUpperCase() ==
                                          'PARTENAIRE') {
                                        part15c += item.stock15cTotal;
                                        partAmb += item.stockAmbiantTotal;
                                      }
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 16),
                                        Text(
                                          'Détail par propriétaire',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Layout responsive : Row sur grand écran, Column sur mobile
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isWide =
                                                constraints.maxWidth > 400;
                                            if (isWide) {
                                              // Desktop : côte à côte
                                              return Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child:
                                                        _buildOwnerDetailColumn(
                                                          context,
                                                          'MONALUXE',
                                                          mon15c,
                                                          monAmb,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child:
                                                        _buildOwnerDetailColumn(
                                                          context,
                                                          'PARTENAIRE',
                                                          part15c,
                                                          partAmb,
                                                        ),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              // Mobile : empilé
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  _buildOwnerDetailColumn(
                                                    context,
                                                    'MONALUXE',
                                                    mon15c,
                                                    monAmb,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildOwnerDetailColumn(
                                                    context,
                                                    'PARTENAIRE',
                                                    part15c,
                                                    partAmb,
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
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
                              tintColor: data.balanceToday.delta15c >= 0
                                  ? const Color(0xFF009688)
                                  : const Color(0xFFF44336),
                              primaryValue: fmtDelta(
                                data.balanceToday.delta15c,
                              ),
                              primaryLabel: 'Δ Volume 15°C',
                              subLeftLabel: 'Réceptions 15°C',
                              subLeftValue: fmtL(
                                data.balanceToday.receptions15c,
                              ),
                              subRightLabel: 'Sorties 15°C',
                              subRightValue: fmtL(data.balanceToday.sorties15c),
                              onTap: () => context.go('/stocks'),
                            );
                          },
                        ),
                        // 6. Alertes Citernes
                        Builder(
                          builder: (context) {
                            final alertesAsync = ref.watch(citernesSousSeuilProvider);
                            return alertesAsync.when(
                              loading: () => KpiCard(
                                cardKey: const Key('kpi_alertes_citernes_card'),
                                icon: Icons.warning_amber_rounded,
                                title: 'Alertes Citernes',
                                tintColor: const Color(0xFFEF4444),
                                primaryValue: '...',
                                primaryLabel: 'Chargement...',
                                subLeftLabel: 'Citernes',
                                subLeftValue: '...',
                                subRightLabel: 'État',
                                subRightValue: '...',
                                onTap: () => context.go('/citernes'),
                              ),
                              error: (_, __) => KpiCard(
                                cardKey: const Key('kpi_alertes_citernes_card'),
                                icon: Icons.warning_amber_rounded,
                                title: 'Alertes Citernes',
                                tintColor: const Color(0xFFEF4444),
                                primaryValue: '—',
                                primaryLabel: 'Erreur de chargement',
                                subLeftLabel: 'Citernes',
                                subLeftValue: '—',
                                subRightLabel: 'État',
                                subRightValue: '—',
                                onTap: () => context.go('/citernes'),
                              ),
                              data: (alertes) {
                                final count = alertes.length;
                                final criticalCount = alertes.where((a) {
                                  final ratio = a.seuil > 0 ? (a.stock / a.seuil) : 0.0;
                                  return ratio < 0.2;
                                }).length;
                                
                                // Top 2 citernes les plus critiques pour l'affichage
                                final topAlertes = alertes.take(2).toList();
                                final topNames = topAlertes.isEmpty 
                                    ? 'Aucune'
                                    : topAlertes.map((a) => a.nom).join(', ');
                                
                                return KpiCard(
                                  cardKey: const Key('kpi_alertes_citernes_card'),
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Alertes Citernes',
                                  tintColor: count > 0 
                                      ? (criticalCount > 0 
                                          ? const Color(0xFFEF4444) 
                                          : const Color(0xFFF59E0B))
                                      : const Color(0xFF10B981),
                                  primaryValue: count > 0 ? '$count' : '0',
                                  primaryLabel: count > 0 
                                      ? '${count > 1 ? 'citernes' : 'citerne'} sous seuil'
                                      : 'Toutes les citernes sont OK',
                                  subLeftLabel: 'Citernes critiques',
                                  subLeftValue: criticalCount > 0 ? '$criticalCount' : '0',
                                  subRightLabel: count > 0 ? 'Exemples' : 'État',
                                  subRightValue: count > 0 
                                      ? (topNames.length > 15 
                                          ? '${topNames.substring(0, 15)}...' 
                                          : topNames)
                                      : 'Normal',
                                  onTap: () => context.go('/citernes'),
                                );
                              },
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
        providersToInvalidate: [profilProvider, kpiProviderProvider],
      );
    }
    return dashboardContent;
  }

  /// Construit une colonne d'affichage pour un propriétaire (MONALUXE ou PARTENAIRE)
  Widget _buildOwnerDetailColumn(
    BuildContext context,
    String ownerName,
    double volume15c,
    double volumeAmbient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ownerName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vol @15°C : ${fmtL(volume15c)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          'Vol ambiant : ${fmtL(volumeAmbient)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

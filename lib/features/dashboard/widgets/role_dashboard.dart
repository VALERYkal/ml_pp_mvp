import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_refresh_signal_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/shared/ui/kpi_card.dart';
import 'package:ml_pp_mvp/shared/formatters.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_grid.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/dashboard_header.dart';
import 'package:ml_pp_mvp/shared/dev/hot_reload_hooks.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/stocks/widgets/stocks_kpi_cards.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/citernes_sous_seuil_provider.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/widgets/stock_corrige_badge.dart'
    show StockCorrectedBadge;
import 'trucks_to_follow_card.dart';

class RoleDashboard extends ConsumerStatefulWidget {
  const RoleDashboard({super.key});

  @override
  ConsumerState<RoleDashboard> createState() => _RoleDashboardState();
}

class _RoleDashboardState extends ConsumerState<RoleDashboard> {
  String? _previousLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? false;
    final currentLocation = GoRouterState.of(context).uri.toString();

    // Détecter si on vient de revenir sur le dashboard
    final isDashboardRoute = currentLocation.startsWith('/dashboard/');

    if (isCurrent && isDashboardRoute) {
      // Si on était sur une autre route et qu'on revient sur dashboard
      if (_previousLocation != null &&
          !_previousLocation!.startsWith('/dashboard/') &&
          _previousLocation != currentLocation) {
        ref.invalidate(kpiProviderProvider);
        debugPrint(
          '🔄 Dashboard: route became active -> invalidate kpiProviderProvider',
        );
      }
      _previousLocation = currentLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kpis = ref.watch(kpiProviderProvider);

    // Écouter le signal de refresh KPI et invalider le provider quand il change
    ref.listen<int>(kpiRefreshSignalProvider, (prev, next) {
      if (prev == next) return;
      debugPrint(
        '🔄 KPI Refresh Signal received ($prev -> $next) -> invalidate(kpiProviderProvider)',
      );
      ref.invalidate(kpiProviderProvider);
    });

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
                        // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                        Builder(
                          builder: (context) {
                            return KpiCard(
                              cardKey: const Key('kpi_receptions_today_card'),
                              icon: Icons.move_to_inbox_outlined,
                              title: 'Réceptions du jour',
                              tintColor: const Color(0xFF4CAF50),
                              primaryValue: fmtL(
                                data.receptionsToday.volumeAmbient,
                              ), // Volume ambiant = source de vérité opérationnelle
                              primaryLabel: 'Volume ambiant',
                              subLeftLabel: 'Nombre de camions',
                              subLeftValue: fmtCount(
                                data.receptionsToday.count,
                              ),
                              subRightLabel: '≈ Volume 15°C',
                              subRightValue: fmtL(
                                data.receptionsToday.volume15c,
                              ), // Valeur dérivée, analytique
                              onTap: () => context.go('/receptions'),
                            );
                          },
                        ),
                        // 3. Sorties du jour
                        // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                        Builder(
                          builder: (context) {
                            return KpiCard(
                              cardKey: const Key('kpi_sorties_today_card'),
                              icon: Icons.outbox_outlined,
                              title: 'Sorties du jour',
                              tintColor: const Color(0xFFF44336),
                              primaryValue: fmtL(
                                data.sortiesToday.volumeAmbient,
                              ), // Volume ambiant = source de vérité opérationnelle
                              primaryLabel: 'Volume ambiant',
                              subLeftLabel: 'Nombre de camions',
                              subLeftValue: fmtCount(data.sortiesToday.count),
                              subRightLabel: '≈ Volume 15°C',
                              subRightValue: fmtL(
                                data.sortiesToday.volume15c,
                              ), // Valeur dérivée, analytique
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

                            // PHASE 3: Source unifiée = depotStocksSnapshotProvider pour TOUS les KPIs stock
                            // Utilise la même date normalisée pour stock total ET breakdown par propriétaire
                            // Normaliser la date une seule fois de manière stable pour éviter rebuild loops
                            final today = DateTime.now();
                            final normalizedToday = DateTime(
                              today.year,
                              today.month,
                              today.day,
                            );

                            // Watch pour réactivité/invalidations (valeur non utilisée directement)
                            if (depotId != null) {
                              ref.watch(
                                depotStocksSnapshotProvider(
                                  DepotStocksSnapshotParams(
                                    depotId: depotId,
                                    dateJour:
                                        normalizedToday, // Date normalisée stable
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                                // Le stock à 15°C est une valeur dérivée, analytique, non décisionnelle
                                // Référentiel : docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md
                                // Source de vérité : v_stock_actuel via depotGlobalStockFromSnapshotProvider (agrégation Dart)
                                Builder(
                                  builder: (context) {
                                    final snapAsync = depotId != null
                                        ? ref.watch(
                                            depotGlobalStockFromSnapshotProvider(
                                              depotId,
                                            ),
                                          )
                                        : null;

                                    return snapAsync?.when(
                                          data: (s) {
                                            final displayAmbient = s.amb;
                                            final display15c = s.v15;

                                            return KpiCard(
                                              cardKey: const Key(
                                                'kpi_stock_total_card',
                                              ),
                                              icon: Icons.inventory_2_outlined,
                                              title: 'Stock total',
                                              tintColor: const Color(
                                                0xFFFF9800,
                                              ),
                                              primaryValue: fmtL(
                                                displayAmbient,
                                              ), // Stock ambiant = source de vérité opérationnelle
                                              primaryLabel: 'Volume ambiant',
                                              subLeftLabel: '≈ Volume 15°C',
                                              subLeftValue: fmtL(
                                                display15c,
                                              ), // Valeur dérivée, analytique
                                              subRightLabel:
                                                  '${usagePct.toStringAsFixed(0)}% utilisation',
                                              subRightValue:
                                                  'Capacité ${fmtL(capacityTotal, fixed: 0)}', // Utilise la nouvelle capacité
                                              onTap: () =>
                                                  context.go('/stocks'),
                                              // B4.4-B : Badge "Corrigé" pour KPI stock dashboard
                                              titleTrailing: depotId != null && depotId.isNotEmpty
                                                  ? StockCorrectedBadge(depotId: depotId)
                                                  : null,
                                            );
                                          },
                                          loading: () => KpiCard(
                                            cardKey: const Key(
                                              'kpi_stock_total_card',
                                            ),
                                            icon: Icons.inventory_2_outlined,
                                            title: 'Stock total',
                                            tintColor: const Color(0xFFFF9800),
                                            primaryValue: fmtL(0.0),
                                            primaryLabel: 'Volume ambiant',
                                            subLeftLabel: '≈ Volume 15°C',
                                            subLeftValue: fmtL(0.0),
                                            subRightLabel: '...',
                                            subRightValue: 'Chargement...',
                                            onTap: () => context.go('/stocks'),
                                          ),
                                          error: (e, st) => KpiCard(
                                            cardKey: const Key(
                                              'kpi_stock_total_card',
                                            ),
                                            icon: Icons.inventory_2_outlined,
                                            title: 'Stock total',
                                            tintColor: const Color(0xFFFF9800),
                                            primaryValue: fmtL(0.0),
                                            primaryLabel: 'Volume ambiant',
                                            subLeftLabel: '≈ Volume 15°C',
                                            subLeftValue: fmtL(0.0),
                                            subRightLabel: 'Erreur',
                                            subRightValue: 'Recharger',
                                            onTap: () => context.go('/stocks'),
                                          ),
                                        ) ??
                                        KpiCard(
                                          cardKey: const Key(
                                            'kpi_stock_total_card',
                                          ),
                                          icon: Icons.inventory_2_outlined,
                                          title: 'Stock total',
                                          tintColor: const Color(0xFFFF9800),
                                          primaryValue: fmtL(
                                            data.stocks.totalAmbient,
                                          ),
                                          primaryLabel: 'Volume ambiant',
                                          subLeftLabel: '≈ Volume 15°C',
                                          subLeftValue: fmtL(
                                            data.stocks.total15c,
                                          ),
                                          subRightLabel:
                                              '${usagePct.toStringAsFixed(0)}% utilisation',
                                          subRightValue:
                                              'Capacité ${fmtL(capacityTotal, fixed: 0)}',
                                          onTap: () => context.go('/stocks'),
                                        );
                                  },
                                ),
                                // Détail par propriétaire depuis v_stock_actuel (agrégation Dart par proprietaire_type)
                                Builder(
                                  builder: (context) {
                                    final ownersAsync = depotId != null
                                        ? ref.watch(
                                            depotOwnerStockFromSnapshotProvider(
                                              depotId,
                                            ),
                                          )
                                        : null;

                                    return ownersAsync?.when(
                                          data: (owners) {
                                            // Trouver MONALUXE et PARTENAIRE (ou utiliser 0.0 si absent)
                                            final monaluxe = owners.firstWhere(
                                              (o) =>
                                                  o.proprietaireType
                                                      .toUpperCase() ==
                                                  'MONALUXE',
                                              orElse: () => DepotOwnerStockKpi(
                                                depotId: depotId ?? '',
                                                depotNom: '',
                                                proprietaireType: 'MONALUXE',
                                                produitId: '',
                                                produitNom: '',
                                                stockAmbiantTotal: 0.0,
                                                stock15cTotal: 0.0,
                                              ),
                                            );

                                            final partenaire = owners
                                                .firstWhere(
                                                  (o) =>
                                                      o.proprietaireType
                                                          .toUpperCase() ==
                                                      'PARTENAIRE',
                                                  orElse: () =>
                                                      DepotOwnerStockKpi(
                                                        depotId: depotId ?? '',
                                                        depotNom: '',
                                                        proprietaireType:
                                                            'PARTENAIRE',
                                                        produitId: '',
                                                        produitNom: '',
                                                        stockAmbiantTotal: 0.0,
                                                        stock15cTotal: 0.0,
                                                      ),
                                                );

                                            final monAmb =
                                                monaluxe.stockAmbiantTotal;
                                            final mon15c =
                                                monaluxe.stock15cTotal;
                                            final partAmb =
                                                partenaire.stockAmbiantTotal;
                                            final part15c =
                                                partenaire.stock15cTotal;

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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                // Layout responsive : Row sur grand écran, Column sur mobile
                                                LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final isWide =
                                                        constraints.maxWidth >
                                                        400;
                                                    if (isWide) {
                                                      // Desktop : côte à côte
                                                      return Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildOwnerDetailColumn(
                                                                  context,
                                                                  'MONALUXE',
                                                                  monAmb,
                                                                  mon15c,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                _buildOwnerDetailColumn(
                                                                  context,
                                                                  'PARTENAIRE',
                                                                  partAmb,
                                                                  part15c,
                                                                ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      // Mobile : empilé
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          _buildOwnerDetailColumn(
                                                            context,
                                                            'MONALUXE',
                                                            monAmb,
                                                            mon15c,
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildOwnerDetailColumn(
                                                            context,
                                                            'PARTENAIRE',
                                                            partAmb,
                                                            part15c,
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (error, stack) {
                                            // Fallback : afficher 0.0 plutôt que de masquer complètement
                                            if (kDebugMode) {
                                              debugPrint(
                                                '⚠️ Dashboard Stock par propriétaire: Erreur $error',
                                              );
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final isWide =
                                                        constraints.maxWidth >
                                                        400;
                                                    if (isWide) {
                                                      return Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildOwnerDetailColumn(
                                                                  context,
                                                                  'MONALUXE',
                                                                  0.0,
                                                                  0.0,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),
                                                          Expanded(
                                                            child:
                                                                _buildOwnerDetailColumn(
                                                                  context,
                                                                  'PARTENAIRE',
                                                                  0.0,
                                                                  0.0,
                                                                ),
                                                          ),
                                                        ],
                                                      );
                                                    } else {
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          _buildOwnerDetailColumn(
                                                            context,
                                                            'MONALUXE',
                                                            0.0,
                                                            0.0,
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          _buildOwnerDetailColumn(
                                                            context,
                                                            'PARTENAIRE',
                                                            0.0,
                                                            0.0,
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        ) ??
                                        const SizedBox.shrink();
                                  },
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
                        // RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle
                        Builder(
                          builder: (context) {
                            // Calcul du delta ambiant (réceptions - sorties)
                            final deltaAmbient = data.balanceToday.deltaAmbient;
                            final delta15c = data.balanceToday.delta15c;
                            return KpiCard(
                              cardKey: const Key('kpi_balance_today_card'),
                              icon: Icons.compare_arrows_outlined,
                              title: 'Balance du jour',
                              tintColor: deltaAmbient >= 0
                                  ? const Color(0xFF009688)
                                  : const Color(0xFFF44336),
                              primaryValue: fmtDelta(
                                deltaAmbient,
                              ), // Δ ambiant = source de vérité opérationnelle
                              primaryLabel: 'Δ Volume ambiant',
                              subLeftLabel: '≈ Δ Volume 15°C',
                              subLeftValue: fmtDelta(
                                delta15c,
                              ), // Valeur dérivée, analytique
                              subRightLabel: 'Capacité',
                              subRightValue: fmtL(
                                data.stocks.capacityTotal,
                                fixed: 0,
                              ),
                              onTap: () => context.go('/stocks'),
                            );
                          },
                        ),
                        // 6. Alertes Citernes
                        Builder(
                          builder: (context) {
                            final alertesAsync = ref.watch(
                              citernesSousSeuilProvider,
                            );
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
                                  final ratio = a.seuil > 0
                                      ? (a.stock / a.seuil)
                                      : 0.0;
                                  return ratio < 0.2;
                                }).length;

                                // Top 2 citernes les plus critiques pour l'affichage
                                final topAlertes = alertes.take(2).toList();
                                final topNames = topAlertes.isEmpty
                                    ? 'Aucune'
                                    : topAlertes.map((a) => a.nom).join(', ');

                                return KpiCard(
                                  cardKey: const Key(
                                    'kpi_alertes_citernes_card',
                                  ),
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
                                  subLeftValue: criticalCount > 0
                                      ? '$criticalCount'
                                      : '0',
                                  subRightLabel: count > 0
                                      ? 'Exemples'
                                      : 'État',
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
        providersToInvalidate: [profilProvider, kpiProviderProvider],
        child: dashboardContent,
      );
    }
    return dashboardContent;
  }

  /// Construit une colonne d'affichage pour un propriétaire (MONALUXE ou PARTENAIRE)
  /// RÈGLE MÉTIER : Stock ambiant = source de vérité opérationnelle (affiché en premier)
  Widget _buildOwnerDetailColumn(
    BuildContext context,
    String ownerName,
    double volumeAmbient,
    double volume15c,
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
          'Vol ambiant : ${fmtL(volumeAmbient)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          '≈ Vol @15°C : ${fmtL(volume15c)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

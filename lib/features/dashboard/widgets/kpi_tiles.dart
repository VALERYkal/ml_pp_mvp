import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cdr_etat.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cdr_kpi_provider.dart';
import 'package:ml_pp_mvp/shared/formatters.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_providers.dart';

/// Carte KPI réutilisable
class KpiCard extends StatelessWidget {
  final String title;
  final num? value;
  final bool warning;
  final IconData? icon;
  
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.warning = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final defaultIcon = warning ? Icons.warning_amber : Icons.trending_up;
    
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon ?? defaultIcon,
                color: warning 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      v.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: warning 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder shimmer pour le chargement
class ShimmerRow extends StatelessWidget {
  final int count;
  
  const ShimmerRow({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (int i = 0; i < count; i++)
          SizedBox(
            width: 260,
            child: Card(
              elevation: 2,
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget d'erreur avec bouton de retry
class ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  
  const ErrorTile(this.message, {super.key, required this.retry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(message),
        trailing: TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ),
    );
  }
}

/// Grille de cartes KPI avec gestion d'états
class KpiTiles extends ConsumerWidget {
  const KpiTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Remplacer par le vrai provider de KPIs
    // final kpis = ref.watch(kpiProvider);
    
    // Pour l'instant, on simule des données
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          KpiCard(
            title: 'Réceptions (jour)',
            value: 12,
            icon: Icons.call_received,
          ),
          KpiCard(
            title: 'Sorties (jour)',
            value: 8,
            icon: Icons.call_made,
          ),
          KpiCard(
            title: 'Citernes sous seuil',
            value: 3,
            warning: true,
            icon: Icons.warning_amber,
          ),
          KpiCard(
            title: 'Stock total (L)',
            value: 45000,
            icon: Icons.inventory_2,
          ),
        ],
      ),
    );
  }
}

/// Version avec gestion d'états AsyncValue
class KpiTilesWithStates extends ConsumerWidget {
  const KpiTilesWithStates({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Remplacer par le vrai provider de KPIs
    // final kpis = ref.watch(kpiProvider);
    
    // Simulation d'un état de chargement
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // TODO: Remplacer par kpis.when(...)
          const ShimmerRow(count: 4),
          const SizedBox(height: 16),
          // TODO: Ajouter la gestion d'erreur avec retry
        ],
      ),
    );
  }
}

/// Widget KPI pour les cours de route par catégorie métier - Version moderne
class CdrKpiTiles extends ConsumerWidget {
  const CdrKpiTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(cdrKpiCountsByCategorieProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: kpisAsync.when(
        loading: () => _buildLoadingState(context),
        error: (error, stack) => _buildErrorState(context, ref, error),
        data: (kpis) => _buildDataState(context, kpis),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => _buildShimmerCard(context)),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 8),
            Text(
              'Erreur lors du chargement',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(cdrKpiCountsByCategorieProvider),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataState(BuildContext context, Map<String, int> kpis) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _buildModernKpiCard(
            context,
            'En route',
            '${kpis['enRoute'] ?? 0}',
            Icons.local_shipping_outlined,
            Colors.blue,
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildModernKpiCard(
            context,
            'En attente',
            '${kpis['enAttente'] ?? 0}',
            Icons.hourglass_empty_outlined,
            Colors.orange,
          )),
          const SizedBox(width: 16),
          Expanded(child: _buildModernKpiCard(
            context,
            'Terminés',
            '${kpis['termines'] ?? 0}',
            Icons.check_circle_outline,
            Colors.green,
          )),
        ],
      ),
    );
  }

  Widget _buildModernKpiCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget KPI détaillé pour les cours de route par statut
class CdrKpiTilesDetail extends ConsumerWidget {
  const CdrKpiTilesDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(cdrKpiCountsByStatutProvider);
    
    return kpisAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerRow(count: 5),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorTile(
          'Erreur lors du chargement des KPIs CDR détaillés: $error',
          retry: () => ref.invalidate(cdrKpiCountsByStatutProvider),
        ),
      ),
      data: (kpis) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            KpiCard(
              title: 'Chargement',
              value: kpis['CHARGEMENT'] ?? 0,
              icon: Icons.upload,
            ),
            KpiCard(
              title: 'Transit',
              value: kpis['TRANSIT'] ?? 0,
              icon: Icons.local_shipping,
            ),
            KpiCard(
              title: 'Frontière',
              value: kpis['FRONTIERE'] ?? 0,
              icon: Icons.border_clear,
            ),
            KpiCard(
              title: 'Arrivé',
              value: kpis['ARRIVE'] ?? 0,
              icon: Icons.location_on,
            ),
            KpiCard(
              title: 'Déchargé',
              value: kpis['DECHARGE'] ?? 0,
              icon: Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }
}

// Stock total — 15°C en primary, ambiant en secondaire, % d'utilisation
class StockTotalTile extends ConsumerWidget {
  const StockTotalTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total15c = ref.watch(kpiStocksProvider.select((s) => s.total15c ?? 0.0));
    final totalAmb = ref.watch(kpiStocksProvider.select((s) => s.totalAmbient ?? 0.0));
    final capacity = ref.watch(kpiStocksProvider.select((s) => s.capacityTotal ?? 0.0));
    final usagePct = capacity <= 0 ? 0 : (totalAmb / capacity * 100);
    return KpiCard(
      title: 'Stock total',
      value: total15c,
      icon: Icons.inventory_2_outlined,
    );
  }
}

// Tendance 7 jours — net (réceptions - sorties) en primary
class Trend7dTile extends ConsumerWidget {
  const Trend7dTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sumIn = ref.watch(kpiTrend7dProvider.select((t) => t.sumReceptions15c7d ?? 0.0));
    final sumOut = ref.watch(kpiTrend7dProvider.select((t) => t.sumSorties15c7d ?? 0.0));
    final net = sumIn - sumOut;
    return KpiCard(
      title: 'Tendance 7 jours',
      value: net,
      icon: Icons.trending_up_rounded,
    );
  }
}

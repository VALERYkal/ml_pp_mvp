import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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


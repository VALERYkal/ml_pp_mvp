// 📌 Module : Cours de Route - Widgets
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Widgets de statistiques pour les cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/services/statistics_service.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

/// Widget principal des statistiques
class CoursStatisticsWidget extends ConsumerWidget {
  const CoursStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pour l'instant, on utilise des données mockées
    // Dans une vraie implémentation, on utiliserait un provider
    final cours = <CoursDeRoute>[]; // ref.watch(cachedFilteredCoursProvider);
    final statistics = CoursStatisticsService.calculateStatistics(cours);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Statistiques des Cours de Route',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showDetailedStatistics(context, statistics),
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Voir les statistiques détaillées',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistiques principales
            _StatisticsGrid(statistics: statistics),

            const SizedBox(height: 16),

            // Graphique des statuts
            _StatusChart(statistics: statistics),
          ],
        ),
      ),
    );
  }

  void _showDetailedStatistics(BuildContext context, CoursStatistics statistics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques Détaillées'),
        content: SizedBox(
          width: double.maxFinite,
          height: 600,
          child: _DetailedStatisticsView(statistics: statistics),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

/// Grille des statistiques principales
class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.statistics});

  final CoursStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _StatisticCard(
          title: 'Total',
          value: statistics.totalCours.toString(),
          icon: Icons.list,
          color: Colors.blue,
        ),
        _StatisticCard(
          title: 'Volume Total',
          value: fmtVolume(statistics.totalVolume),
          icon: Icons.local_shipping,
          color: Colors.green,
        ),
        _StatisticCard(
          title: 'Volume Moyen',
          value: fmtVolume(statistics.volumeMoyen),
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
        _StatisticCard(
          title: 'Taux Completion',
          value: '${statistics.tauxCompletion.toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: Colors.purple,
        ),
      ],
    );
  }
}

/// Carte de statistique
class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Graphique des statuts
class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.statistics});

  final CoursStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final statusData = statistics.coursParStatut.entries.where((entry) => entry.value > 0).toList();

    if (statusData.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition par Statut',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...statusData.map(
          (entry) =>
              _StatusBar(statut: entry.key, count: entry.value, total: statistics.totalCours),
        ),
      ],
    );
  }
}

/// Barre de statut
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.statut, required this.count, required this.total});

  final StatutCours statut;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    final color = _getStatusColor(statut);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(statut.label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatutCours statut) {
    switch (statut) {
      case StatutCours.chargement:
        return Colors.blue;
      case StatutCours.transit:
        return Colors.orange;
      case StatutCours.frontiere:
        return Colors.amber;
      case StatutCours.arrive:
        return Colors.green;
      case StatutCours.decharge:
        return Colors.grey;
    }
  }
}

/// Vue détaillée des statistiques
class _DetailedStatisticsView extends StatelessWidget {
  const _DetailedStatisticsView({required this.statistics});

  final CoursStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top fournisseurs
          _TopList(
            title: 'Top Fournisseurs',
            data: statistics.topFournisseurs,
            icon: Icons.business,
          ),

          const SizedBox(height: 16),

          // Top produits
          _TopList(title: 'Top Produits', data: statistics.topProduits, icon: Icons.inventory),

          const SizedBox(height: 16),

          // Top transporteurs
          _TopList(
            title: 'Top Transporteurs',
            data: statistics.topTransporteurs,
            icon: Icons.local_shipping,
          ),

          const SizedBox(height: 16),

          // Top chauffeurs
          _TopList(title: 'Top Chauffeurs', data: statistics.topChauffeurs, icon: Icons.person),

          const SizedBox(height: 16),

          // Top dépôts
          _TopList(title: 'Top Dépôts', data: statistics.topDepots, icon: Icons.warehouse),
        ],
      ),
    );
  }
}

/// Liste des tops
class _TopList extends StatelessWidget {
  const _TopList({required this.title, required this.data, required this.icon});

  final String title;
  final List<MapEntry<String, int>> data;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...data.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: Text(entry.key, style: Theme.of(context).textTheme.bodySmall),
                ),
                const Spacer(),
                Text(
                  entry.value.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

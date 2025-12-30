// 📌 Module : Cours de Route - Widgets
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Indicateurs de performance pour les cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_pagination_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_cache_provider.dart';

/// Indicateur de performance compact
class PerformanceIndicator extends ConsumerWidget {
  const PerformanceIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginationInfo = ref.watch(paginationInfoProvider);
    final cache = ref.watch(coursCacheProvider);
    final performanceStats = ref.watch(performanceStatsProvider);

    final totalItems = paginationInfo['totalItems'] as int;
    final currentPage = paginationInfo['currentPage'] as int;
    final totalPages = paginationInfo['totalPages'] as int;
    final pageSize = paginationInfo['pageSize'] as int;

    final cacheHits = performanceStats['cacheHits'] as int;
    final totalRequests = performanceStats['totalRequests'] as int;

    final cacheHitRate = totalRequests > 0
        ? (cacheHits / totalRequests * 100).round()
        : 0;
    final isCacheValid = cache?.isValid ?? false;
    final lastRefresh = performanceStats['lastRefresh'] as DateTime;
    final timeSinceRefresh = DateTime.now().difference(lastRefresh);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Indicateur de cache
          Icon(
            isCacheValid ? Icons.cached : Icons.cached_outlined,
            size: 16,
            color: isCacheValid
                ? Colors.green
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),

          // Statistiques de cache
          Text(
            'Cache: ${cacheHitRate}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),

          // Informations de pagination
          Text(
            '$totalItems cours • Page $currentPage/$totalPages',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),

          // Temps depuis le dernier rafraîchissement
          Text(
            _formatTimeSince(timeSinceRefresh),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'À l\'instant';
    } else if (duration.inMinutes < 60) {
      return 'Il y a ${duration.inMinutes}min';
    } else if (duration.inHours < 24) {
      return 'Il y a ${duration.inHours}h';
    } else {
      return 'Il y a ${duration.inDays}j';
    }
  }
}

/// Indicateur de performance détaillé (pour debug)
class DetailedPerformanceIndicator extends ConsumerWidget {
  const DetailedPerformanceIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginationInfo = ref.watch(paginationInfoProvider);
    final cache = ref.watch(coursCacheProvider);
    final performanceStats = ref.watch(performanceStatsProvider);

    final totalItems = paginationInfo['totalItems'] as int;
    final currentPage = paginationInfo['currentPage'] as int;
    final totalPages = paginationInfo['totalPages'] as int;
    final pageSize = paginationInfo['pageSize'] as int;
    final startItem = paginationInfo['startItem'] as int;
    final endItem = paginationInfo['endItem'] as int;

    final cacheHits = performanceStats['cacheHits'] as int;
    final totalRequests = performanceStats['totalRequests'] as int;

    final cacheHitRate = totalRequests > 0
        ? (cacheHits / totalRequests * 100).round()
        : 0;
    final isCacheValid = cache?.isValid ?? false;
    final lastRefresh = performanceStats['lastRefresh'] as DateTime;
    final timeSinceRefresh = DateTime.now().difference(lastRefresh);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicateurs de Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Cache
            _PerformanceRow(
              label: 'Cache',
              value: isCacheValid ? 'Valide' : 'Expiré',
              icon: isCacheValid ? Icons.cached : Icons.cached_outlined,
              color: isCacheValid ? Colors.green : Colors.orange,
            ),

            _PerformanceRow(
              label: 'Taux de cache',
              value: '$cacheHitRate% ($cacheHits/$totalRequests)',
              icon: Icons.analytics_outlined,
            ),

            _PerformanceRow(
              label: 'Dernier rafraîchissement',
              value: _formatTimeSince(timeSinceRefresh),
              icon: Icons.refresh,
            ),

            const Divider(),

            // Pagination
            _PerformanceRow(
              label: 'Total d\'éléments',
              value: '$totalItems',
              icon: Icons.list,
            ),

            _PerformanceRow(
              label: 'Page actuelle',
              value: '$currentPage / $totalPages',
              icon: Icons.pages,
            ),

            _PerformanceRow(
              label: 'Taille de page',
              value: '$pageSize',
              icon: Icons.view_list,
            ),

            _PerformanceRow(
              label: 'Éléments affichés',
              value: '$startItem - $endItem',
              icon: Icons.visibility,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeSince(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'À l\'instant';
    } else if (duration.inMinutes < 60) {
      return 'Il y a ${duration.inMinutes}min';
    } else if (duration.inHours < 24) {
      return 'Il y a ${duration.inHours}h';
    } else {
      return 'Il y a ${duration.inDays}j';
    }
  }
}

/// Ligne d'indicateur de performance
class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton pour afficher/masquer les indicateurs de performance
class PerformanceToggleButton extends ConsumerWidget {
  const PerformanceToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Indicateurs de performance',
      icon: const Icon(Icons.analytics_outlined),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Indicateurs de Performance'),
            content: const DetailedPerformanceIndicator(),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}

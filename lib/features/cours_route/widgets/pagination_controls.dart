// 📌 Module : Cours de Route - Widgets
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Contrôles de pagination pour les cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_pagination_provider.dart';

/// Contrôles de pagination pour la vue desktop
class PaginationControls extends ConsumerWidget {
  const PaginationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginationInfo = ref.watch(paginationInfoProvider);

    final currentPage = paginationInfo['currentPage'] as int;
    final totalPages = paginationInfo['totalPages'] as int;
    final totalItems = paginationInfo['totalItems'] as int;
    final startItem = paginationInfo['startItem'] as int;
    final endItem = paginationInfo['endItem'] as int;
    final hasMore = paginationInfo['hasMore'] as bool;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Informations de pagination
          Text(
            'Affichage de $startItem à $endItem sur $totalItems cours',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),

          // Contrôles de navigation
          Row(
            children: [
              // Page précédente
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(ref, currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Page précédente',
              ),

              // Numéro de page actuel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Page suivante
              IconButton(
                onPressed: hasMore ? () => _goToPage(ref, currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Page suivante',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(WidgetRef ref, int page) {
    ref.read(coursPaginationProvider.notifier).state = ref
        .read(coursPaginationProvider)
        .copyWith(currentPage: page);
  }
}

/// Contrôles de pagination compacts pour la vue mobile
class CompactPaginationControls extends ConsumerWidget {
  const CompactPaginationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paginationInfo = ref.watch(paginationInfoProvider);

    final currentPage = paginationInfo['currentPage'] as int;
    final totalPages = paginationInfo['totalPages'] as int;
    final totalItems = paginationInfo['totalItems'] as int;
    final hasMore = paginationInfo['hasMore'] as bool;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Informations compactes
          Text(
            '$totalItems cours',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),

          // Contrôles compacts
          Row(
            children: [
              // Page précédente
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(ref, currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              ),

              // Numéro de page
              Text(
                '$currentPage/$totalPages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),

              // Page suivante
              IconButton(
                onPressed: hasMore ? () => _goToPage(ref, currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(WidgetRef ref, int page) {
    ref.read(coursPaginationProvider.notifier).state = ref
        .read(coursPaginationProvider)
        .copyWith(currentPage: page);
  }
}

/// Sélecteur de taille de page
class PageSizeSelector extends ConsumerWidget {
  const PageSizeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagination = ref.watch(coursPaginationProvider);

    const pageSizes = [10, 20, 50, 100];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Par page:', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: pagination.pageSize,
          items: pageSizes
              .map((size) => DropdownMenuItem(value: size, child: Text('$size')))
              .toList(),
          onChanged: (size) {
            if (size != null) {
              ref.read(coursPaginationProvider.notifier).state = pagination.copyWith(
                pageSize: size,
                currentPage: 1,
              );
            }
          },
          isDense: true,
        ),
      ],
    );
  }
}

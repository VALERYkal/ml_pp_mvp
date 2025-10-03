// 📌 Module : Cours de Route - Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Provider pour le cache et les optimisations des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_sort_provider.dart';

/// Cache pour les cours de route avec TTL (Time To Live)
class CoursCache {
  final List<CoursDeRoute> cours;
  final DateTime lastUpdated;
  final Duration ttl;

  const CoursCache({
    required this.cours,
    required this.lastUpdated,
    this.ttl = const Duration(minutes: 5),
  });

  bool get isExpired => DateTime.now().difference(lastUpdated) > ttl;
  bool get isValid => !isExpired && cours.isNotEmpty;

  CoursCache copyWith({
    List<CoursDeRoute>? cours,
    DateTime? lastUpdated,
    Duration? ttl,
  }) {
    return CoursCache(
      cours: cours ?? this.cours,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ttl: ttl ?? this.ttl,
    );
  }
}

/// Provider pour le cache des cours de route
final coursCacheProvider = StateProvider<CoursCache?>((ref) => null);

/// Provider pour mettre à jour le cache des cours de route
/// Ce provider gère la mise à jour du cache de manière appropriée
final coursCacheUpdaterProvider = Provider<void>((ref) {
  final coursAsync = ref.watch(coursDeRouteListProvider);

  coursAsync.whenOrNull(
    data: (cours) {
      // Mettre à jour le cache de manière asynchrone
      Future.microtask(() {
        final currentCache = ref.read(coursCacheProvider);
        if (currentCache == null ||
            !currentCache.isValid ||
            currentCache.cours.length != cours.length) {
          ref.read(coursCacheProvider.notifier).state = CoursCache(
            cours: cours,
            lastUpdated: DateTime.now(),
          );
        }
      });
    },
  );
});

/// Provider pour les cours avec cache
final cachedCoursProvider = Provider<List<CoursDeRoute>>((ref) {
  final cache = ref.watch(coursCacheProvider);
  final coursAsync = ref.watch(coursDeRouteListProvider);

  return coursAsync.when(
    data: (cours) {
      // Retourner directement les données sans modifier le cache ici
      // Le cache sera mis à jour par un autre mécanisme
      return cours;
    },
    loading: () {
      // Retourner le cache si disponible et valide
      if (cache != null && cache.isValid) {
        return cache.cours;
      }
      return <CoursDeRoute>[];
    },
    error: (_, __) {
      // Retourner le cache en cas d'erreur
      if (cache != null && cache.isValid) {
        return cache.cours;
      }
      return <CoursDeRoute>[];
    },
  );
});

/// Provider pour les statistiques de performance
final performanceStatsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'cacheHits': 0,
    'cacheMisses': 0,
    'lastRefresh': DateTime.now(),
    'totalRequests': 0,
  };
});

/// Provider pour le débouncing des recherches
final debouncedSearchProvider = StateProvider<String>((ref) => '');

/// Provider pour les cours filtrés avec cache
final cachedFilteredCoursProvider = Provider<List<CoursDeRoute>>((ref) {
  final cours = ref.watch(cachedCoursProvider);
  final filters = ref.watch(coursFiltersProvider);
  final sortConfig = ref.watch(coursSortProvider);

  // Appliquer les filtres et le tri
  final filtered = _applyFilters(cours, filters);
  return sortCours(filtered, sortConfig);
});

/// Applique les filtres à une liste de cours de route (version simplifiée)
List<CoursDeRoute> _applyFilters(
  List<CoursDeRoute> cours,
  CoursFilters filters,
) {
  return cours.where((c) {
    // Filtre par fournisseur
    final okFournisseur = (filters.fournisseurId == null)
        ? true
        : c.fournisseurId == filters.fournisseurId;

    // Filtre par volume (0-100 000 L)
    bool okVolume = true;
    if (c.volume != null) {
      if (c.volume! < filters.volumeMin) {
        okVolume = false;
      }
      if (c.volume! > filters.volumeMax) {
        okVolume = false;
      }
    }

    return okFournisseur && okVolume;
  }).toList();
}

/// Fonction de tri des cours (copié depuis cours_sort_provider.dart)
List<CoursDeRoute> sortCours(List<CoursDeRoute> cours, CoursSortConfig config) {
  final sorted = List<CoursDeRoute>.from(cours);

  sorted.sort((a, b) {
    int comparison = 0;

    switch (config.column) {
      case CoursSortColumn.fournisseur:
        comparison = (a.fournisseurId ?? '').compareTo(b.fournisseurId ?? '');
        break;
      case CoursSortColumn.produit:
        final aProd = (a.produitCode ?? a.produitNom ?? '').trim();
        final bProd = (b.produitCode ?? b.produitNom ?? '').trim();
        comparison = aProd.compareTo(bProd);
        break;
      case CoursSortColumn.plaques:
        final aPlaque = (a.plaqueCamion ?? '').trim();
        final bPlaque = (b.plaqueCamion ?? '').trim();
        comparison = aPlaque.compareTo(bPlaque);
        break;
      case CoursSortColumn.chauffeur:
        comparison = (a.chauffeur ?? '').compareTo(b.chauffeur ?? '');
        break;
      case CoursSortColumn.transporteur:
        comparison = (a.transporteur ?? '').compareTo(b.transporteur ?? '');
        break;
      case CoursSortColumn.volume:
        final aVolume = a.volume ?? 0.0;
        final bVolume = b.volume ?? 0.0;
        comparison = aVolume.compareTo(bVolume);
        break;
      case CoursSortColumn.depot:
        comparison = (a.depotDestinationId).compareTo(b.depotDestinationId);
        break;
      case CoursSortColumn.date:
        final aDate = a.dateChargement ?? DateTime(1970);
        final bDate = b.dateChargement ?? DateTime(1970);
        comparison = aDate.compareTo(bDate);
        break;
      case CoursSortColumn.statut:
        comparison = a.statut.index.compareTo(b.statut.index);
        break;
    }

    return config.direction == SortDirection.ascending
        ? comparison
        : -comparison;
  });

  return sorted;
}

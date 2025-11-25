// ?? Module : Cours de Route - Providers Filters
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-01-27
// ?? Description : Providers pour le filtrage des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_sort_provider.dart';

/// Modèle pour les filtres de cours de route
///
/// Contient les critères de filtrage simplifiés :
/// - Fournisseur : Filtre par fournisseur spécifique
/// - Volume : Filtre par plage de volume (0-100 000 L)
class CoursFilters {
  /// ID du fournisseur à filtrer (null pour tous les fournisseurs)
  final String? fournisseurId;

  /// Volume minimum (par défaut 0)
  final double volumeMin;

  /// Volume maximum (par défaut 100 000)
  final double volumeMax;

  const CoursFilters({
    this.fournisseurId,
    this.volumeMin = 0,
    this.volumeMax = 100000,
  });

  /// Crée une copie avec des modifications
  CoursFilters copyWith({
    String? fournisseurId,
    double? volumeMin,
    double? volumeMax,
  }) {
    return CoursFilters(
      fournisseurId: fournisseurId ?? this.fournisseurId,
      volumeMin: volumeMin ?? this.volumeMin,
      volumeMax: volumeMax ?? this.volumeMax,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoursFilters &&
        other.fournisseurId == fournisseurId &&
        other.volumeMin == volumeMin &&
        other.volumeMax == volumeMax;
  }

  @override
  int get hashCode =>
      fournisseurId.hashCode ^ volumeMin.hashCode ^ volumeMax.hashCode;

  @override
  String toString() {
    return 'CoursFilters(fournisseurId: $fournisseurId, volumeMin: $volumeMin, volumeMax: $volumeMax)';
  }
}

/// Provider pour l'état des filtres
///
/// Gère l'état des filtres appliqués à la liste des cours de route.
/// Utilisé par les widgets de filtrage pour mettre à jour les critères.
final coursFiltersProvider = StateProvider<CoursFilters>((ref) {
  return const CoursFilters();
});

/// Provider pour la liste filtrée et triée des cours de route
///
/// Combine la liste brute des cours avec les filtres actuels et le tri
/// pour fournir une liste filtrée et triée réactive.
///
/// Utilisé par les widgets d'affichage pour obtenir la liste filtrée et triée.
final filteredCoursProvider = Provider<List<CoursDeRoute>>((ref) {
  // Récupérer la liste brute des cours
  final coursAsync = ref.watch(coursDeRouteListProvider);
  final cours = coursAsync.value ?? const <CoursDeRoute>[];

  // Récupérer les filtres actuels
  final filters = ref.watch(coursFiltersProvider);

  // Récupérer la configuration de tri
  final sortConfig = ref.watch(coursSortProvider);

  // Appliquer les filtres puis le tri
  final filtered = _applyFilters(cours, filters);
  return sortCours(filtered, sortConfig);
});

/// Applique les filtres à une liste de cours de route
///
/// [cours] : Liste brute des cours
/// [filters] : Filtres à appliquer
///
/// Retourne la liste filtrée selon les critères (fournisseur et volume uniquement)
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


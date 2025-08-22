// 📌 Module : Cours de Route - Providers Filters
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Providers pour le filtrage des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';

/// Modèle pour les filtres de cours de route
/// 
/// Contient tous les critères de filtrage possibles :
/// - Statut : Filtre par statut spécifique
/// - Produit : Filtre par produit spécifique
/// - Recherche : Recherche textuelle dans plaque/chauffeur
class CoursFilters {
  /// Statut à filtrer ('Tous' pour tous les statuts)
  final String statut;
  
  /// ID du produit à filtrer (null pour tous les produits)
  final String? produitId;
  
  /// Requête de recherche textuelle
  final String query;
  
  const CoursFilters({
    this.statut = 'Tous',
    this.produitId,
    this.query = '',
  });

  /// Crée une copie avec des modifications
  CoursFilters copyWith({
    String? statut,
    String? produitId,
    String? query,
  }) {
    return CoursFilters(
      statut: statut ?? this.statut,
      produitId: produitId ?? this.produitId,
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoursFilters &&
        other.statut == statut &&
        other.produitId == produitId &&
        other.query == query;
  }

  @override
  int get hashCode => statut.hashCode ^ produitId.hashCode ^ query.hashCode;

  @override
  String toString() {
    return 'CoursFilters(statut: $statut, produitId: $produitId, query: $query)';
  }
}

/// Provider pour l'état des filtres
/// 
/// Gère l'état des filtres appliqués à la liste des cours de route.
/// Utilisé par les widgets de filtrage pour mettre à jour les critères.
final coursFiltersProvider = StateProvider<CoursFilters>((ref) {
  return const CoursFilters();
});

/// Provider pour la liste filtrée des cours de route
/// 
/// Combine la liste brute des cours avec les filtres actuels
/// pour fournir une liste filtrée réactive.
/// 
/// Utilisé par les widgets d'affichage pour obtenir la liste filtrée.
final filteredCoursProvider = Provider<List<CoursDeRoute>>((ref) {
  // Récupérer la liste brute des cours
  final coursAsync = ref.watch(coursDeRouteListProvider);
  final cours = coursAsync.value ?? const <CoursDeRoute>[];
  
  // Récupérer les filtres actuels
  final filters = ref.watch(coursFiltersProvider);
  
  // Appliquer les filtres
  return _applyFilters(cours, filters);
});

/// Applique les filtres à une liste de cours de route
/// 
/// [cours] : Liste brute des cours
/// [filters] : Filtres à appliquer
/// 
/// Retourne la liste filtrée selon les critères
List<CoursDeRoute> _applyFilters(List<CoursDeRoute> cours, CoursFilters filters) {
  final q = filters.query.trim().toLowerCase();
  
  return cours.where((c) {
    // Filtre par statut (utilise les noms enum normalisés: chargement/transit/frontiere/arrive/decharge)
    final okStatut = (filters.statut == 'Tous') ? true : c.statut.name == filters.statut;
    
    // Filtre par produit
    final okProd = (filters.produitId == null) ? true : c.produitId == filters.produitId;
    
    // Filtre par recherche textuelle
    final okQuery = q.isEmpty ||
        (c.plaqueCamion?.toLowerCase().contains(q) ?? false) ||
        (c.chauffeur?.toLowerCase().contains(q) ?? false);
    
    return okStatut && okProd && okQuery;
  }).toList();
}

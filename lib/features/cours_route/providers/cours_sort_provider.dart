// 📌 Module : Cours de Route - Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Provider pour le tri des cours de route

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Énumération des colonnes triables
enum CoursSortColumn {
  fournisseur,
  produit,
  plaques,
  chauffeur,
  transporteur,
  volume,
  depot,
  date,
  statut,
}

/// Direction du tri
enum SortDirection { ascending, descending }

/// Configuration de tri
class CoursSortConfig {
  final CoursSortColumn column;
  final SortDirection direction;

  const CoursSortConfig({required this.column, required this.direction});

  CoursSortConfig copyWith({
    CoursSortColumn? column,
    SortDirection? direction,
  }) {
    return CoursSortConfig(
      column: column ?? this.column,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoursSortConfig &&
        other.column == column &&
        other.direction == direction;
  }

  @override
  int get hashCode => column.hashCode ^ direction.hashCode;

  @override
  String toString() =>
      'CoursSortConfig(column: $column, direction: $direction)';
}

/// Provider pour la configuration de tri
final coursSortProvider = StateProvider<CoursSortConfig>((ref) {
  return const CoursSortConfig(
    column: CoursSortColumn.date,
    direction: SortDirection.descending,
  );
});

/// Fonction de tri des cours
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

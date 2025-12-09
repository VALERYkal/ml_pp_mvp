import '../../../data/repositories/stocks_kpi_repository.dart';

/// Snapshot complet des stocks d'un dépôt pour une date donnée.
///
/// Ce DTO agrège toutes les données de stock nécessaires pour afficher
/// une vue complète du dépôt à un instant donné :
/// - Totaux globaux (tous produits, tous propriétaires)
/// - Breakdown par propriétaire (MONALUXE / PARTENAIRE)
/// - Détail par citerne (tous propriétaires confondus)
class DepotStocksSnapshot {
  /// Date du snapshot (date_jour utilisée pour la requête).
  final DateTime dateJour;

  /// Indique si ce snapshot provient d'un fallback vers une date antérieure
  /// (quand la date demandée n'a pas de données disponibles).
  final bool isFallback;

  /// Totaux globaux pour le dépôt (tous produits confondus).
  final DepotGlobalStockKpi totals;

  /// Breakdown par propriétaire (MONALUXE / PARTENAIRE / etc.).
  final List<DepotOwnerStockKpi> owners;

  /// Snapshots par citerne (tous propriétaires confondus).
  final List<CiterneGlobalStockSnapshot> citerneRows;

  const DepotStocksSnapshot({
    required this.dateJour,
    required this.isFallback,
    required this.totals,
    required this.owners,
    required this.citerneRows,
  });
}


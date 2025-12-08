// 📌 StocksKpiService
// Rôle : encapsuler le StocksKpiRepository et offrir des use-cases
// de haut niveau pour le Dashboard (chargement des KPIs de stock).

import '../../../data/repositories/stocks_kpi_repository.dart';

/// Agrégat complet des KPIs de stock pour un contexte donné (optionnellement un dépôt).
class StocksDashboardKpis {
  final List<DepotGlobalStockKpi> globalByDepotProduct;
  final List<DepotOwnerStockKpi> byOwner;
  final List<CiterneOwnerStockSnapshot> citerneByOwner;
  final List<CiterneGlobalStockSnapshot> citerneGlobal;

  const StocksDashboardKpis({
    required this.globalByDepotProduct,
    required this.byOwner,
    required this.citerneByOwner,
    required this.citerneGlobal,
  });
}

class StocksKpiService {
  final StocksKpiRepository _repo;

  StocksKpiService(this._repo);

  /// Charge tous les KPIs nécessaires au Dashboard Stocks pour un dépôt donné.
  ///
  /// - [depotId] facultatif : si fourni, toutes les requêtes sont filtrées sur ce dépôt.
  /// - [produitId] facultatif : permet de limiter à un produit.
  ///
  /// Remarque : on ne met pas ici de logique métier "forte" (tout est en lecture seule),
  /// l'objectif est surtout d'offrir un point d'entrée unique et testable.
  Future<StocksDashboardKpis> loadDashboardKpis({
    String? depotId,
    String? produitId,
  }) async {
    // 1. KPI global par dépôt & produit
    final global = await _repo.fetchDepotProductTotals(
      depotId: depotId,
      produitId: produitId,
    );

    // 2. KPI par propriétaire (MONALUXE / PARTENAIRE)
    final byOwner = await _repo.fetchDepotOwnerTotals(
      depotId: depotId,
      produitId: produitId,
    );

    // 3. Snapshots détaillés par citerne + propriétaire
    final citerneOwner = await _repo.fetchCiterneOwnerSnapshots(
      depotId: depotId,
      produitId: produitId,
    );

    // 4. Snapshots globaux par citerne (tous propriétaires confondus)
    final citerneGlobal = await _repo.fetchCiterneGlobalSnapshots(
      depotId: depotId,
      produitId: produitId,
    );

    return StocksDashboardKpis(
      globalByDepotProduct: global,
      byOwner: byOwner,
      citerneByOwner: citerneOwner,
      citerneGlobal: citerneGlobal,
    );
  }

  /// Méthode utilitaire si tu veux uniquement les KPIs pour un dépôt donné,
  /// sans te soucier du produit.
  Future<StocksDashboardKpis> loadDashboardKpisForDepot(String depotId) {
    return loadDashboardKpis(depotId: depotId);
  }
}


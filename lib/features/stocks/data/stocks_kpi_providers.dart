import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../data/repositories/stocks_kpi_repository.dart';
import '../../../data/repositories/repositories.dart';
import 'stocks_kpi_service.dart';

/// Provider du repository KPI de stock
final stocksKpiRepositoryProvider = riverpod.Provider<StocksKpiRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StocksKpiRepository(client);
});

/// Provider du service KPI de stock
///
/// Permet d'orchestrer des use-cases de haut niveau (Dashboard)
/// tout en gardant le repository testable et injecté.
final stocksKpiServiceProvider = riverpod.Provider<StocksKpiService>((ref) {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return StocksKpiService(repo);
});

/// KPI global par dépôt & produit (toutes propriétés confondues)
/// 
/// Source SQL : v_kpi_stock_global
/// 
/// Retourne tous les dépôts et produits, ou peut être filtré via les paramètres
/// du repository si nécessaire.
final kpiGlobalStockProvider =
    riverpod.FutureProvider<List<DepotGlobalStockKpi>>((ref) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return repo.fetchDepotProductTotals();
});

/// KPI de stock par propriétaire (MONALUXE / PARTENAIRE) et par dépôt
/// 
/// Source SQL : v_kpi_stock_owner
/// 
/// Utilisé pour le breakdown Monaluxe vs Partenaire.
final kpiStockByOwnerProvider =
    riverpod.FutureProvider<List<DepotOwnerStockKpi>>((ref) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return repo.fetchDepotOwnerTotals();
});

/// Snapshot par citerne et propriétaire (détail Monaluxe vs Partenaire)
/// 
/// Source SQL : v_stocks_citerne_owner
/// 
/// Permet d'alimenter les cartes "TANK1 Monaluxe / Partenaire", etc.
final kpiStocksByCiterneOwnerProvider =
    riverpod.FutureProvider<List<CiterneOwnerStockSnapshot>>((ref) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return repo.fetchCiterneOwnerSnapshots();
});

/// Snapshot global par citerne (tous propriétaires confondus)
/// 
/// Source SQL : v_stocks_citerne_global
/// 
/// Retourne le volume total par citerne, sans distinction de propriétaire.
final kpiStocksByCiterneGlobalProvider =
    riverpod.FutureProvider<List<CiterneGlobalStockSnapshot>>((ref) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return repo.fetchCiterneGlobalSnapshots();
});

/// KPI global filtré par dépôt (si tu veux filtrer côté app)
/// 
/// Provider family pour obtenir le KPI d'un dépôt spécifique.
final kpiGlobalStockByDepotProvider =
    riverpod.FutureProvider.family<DepotGlobalStockKpi?, String>((ref, depotId) async {
  final list = await ref.watch(kpiGlobalStockProvider.future);
  try {
    return list.firstWhere(
      (item) => item.depotId == depotId,
    );
  } catch (e) {
    return null;
  }
});

/// Snapshots par citerne pour un dépôt donné (détail propriétaires)
/// 
/// Provider family pour filtrer les snapshots par citerne et propriétaire
/// pour un dépôt spécifique.
/// 
/// Utilise directement le repository avec le paramètre depotId pour filtrer
/// côté SQL plutôt que côté Dart.
final kpiCiterneOwnerByDepotProvider = riverpod.FutureProvider.family<
    List<CiterneOwnerStockSnapshot>, String>((ref, depotId) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);
  return repo.fetchCiterneOwnerSnapshots(depotId: depotId);
});

/// Agrégat complet des KPIs de stock pour le Dashboard.
///
/// Usage typique dans l'UI :
///   - si [depotId] est null → vue globale multi-dépôts
///   - si [depotId] est fourni → vue focalisée sur un dépôt
///
/// Exemple :
///   final kpisAsync = ref.watch(stocksDashboardKpisProvider(depotId));
final stocksDashboardKpisProvider = riverpod.FutureProvider.family<
    StocksDashboardKpis, String?>((ref, depotId) async {
  final service = ref.watch(stocksKpiServiceProvider);
  return service.loadDashboardKpis(
    depotId: depotId,
    // produitId laissé à null pour l'instant (filtrage futur possible)
  );
});


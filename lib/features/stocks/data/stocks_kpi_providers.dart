import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../data/repositories/stocks_kpi_repository.dart';
import '../../../data/repositories/repositories.dart';
import 'stocks_kpi_service.dart';
import '../domain/depot_stocks_snapshot.dart';

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

/// Paramètres pour le provider depotStocksSnapshotProvider.
class DepotStocksSnapshotParams {
  final String depotId;
  final DateTime? dateJour;

  const DepotStocksSnapshotParams({
    required this.depotId,
    this.dateJour,
  });
}

/// Snapshot complet des stocks d'un dépôt pour une date donnée.
///
/// Ce provider agrège toutes les données de stock nécessaires pour afficher
/// une vue complète du dépôt à un instant donné :
/// - Totaux globaux (tous produits, tous propriétaires)
/// - Breakdown par propriétaire (MONALUXE / PARTENAIRE)
/// - Détail par citerne (tous propriétaires confondus)
///
/// Usage :
///   final snapshotAsync = ref.watch(
///     depotStocksSnapshotProvider(
///       DepotStocksSnapshotParams(
///         depotId: 'depot-1',
///         dateJour: DateTime(2025, 12, 8), // optionnel, défaut = aujourd'hui
///       ),
///     ),
///   );
final depotStocksSnapshotProvider = riverpod.FutureProvider.autoDispose
    .family<DepotStocksSnapshot, DepotStocksSnapshotParams>((ref, params) async {
  final repo = ref.watch(stocksKpiRepositoryProvider);

  final DateTime dateJour = params.dateJour ?? DateTime.now();

  // 1) Global totals per depot (we expect at most one row for this depot at this date)
  final globalList = await repo.fetchDepotProductTotals(
    depotId: params.depotId,
    dateJour: dateJour,
  );
  final totals = globalList.isNotEmpty
      ? globalList.first
      : DepotGlobalStockKpi(
          depotId: params.depotId,
          depotNom: '',
          produitId: '',
          produitNom: '',
          stockAmbiantTotal: 0.0,
          stock15cTotal: 0.0,
        );

  // 2) Breakdown by owner
  final owners = await repo.fetchDepotOwnerTotals(
    depotId: params.depotId,
    dateJour: dateJour,
  );

  // 3) Citerne-level snapshots (all owners combined at this stage)
  final citerneRows = await repo.fetchCiterneGlobalSnapshots(
    depotId: params.depotId,
    dateJour: dateJour,
  );

  // For now, we do not implement fallback logic to previous dates.
  // That will be handled in a later Phase.
  const bool isFallback = false;

  return DepotStocksSnapshot(
    dateJour: dateJour,
    isFallback: isFallback,
    totals: totals,
    owners: owners,
    citerneRows: citerneRows,
  );
});


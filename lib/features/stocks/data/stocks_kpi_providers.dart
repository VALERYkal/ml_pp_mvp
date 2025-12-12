import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../data/repositories/stocks_kpi_repository.dart';
import '../../../data/repositories/repositories.dart';
import 'stocks_kpi_service.dart';
import '../domain/depot_stocks_snapshot.dart';

/// Provider du repository KPI de stock
final stocksKpiRepositoryProvider = riverpod.Provider<StocksKpiRepository>((
  ref,
) {
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
    riverpod.FutureProvider.family<DepotGlobalStockKpi?, String>((
      ref,
      depotId,
    ) async {
      final list = await ref.watch(kpiGlobalStockProvider.future);
      try {
        return list.firstWhere((item) => item.depotId == depotId);
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
final kpiCiterneOwnerByDepotProvider =
    riverpod.FutureProvider.family<List<CiterneOwnerStockSnapshot>, String>((
      ref,
      depotId,
    ) async {
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
final stocksDashboardKpisProvider =
    riverpod.FutureProvider.family<StocksDashboardKpis, String?>((
      ref,
      depotId,
    ) async {
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

  const DepotStocksSnapshotParams({required this.depotId, this.dateJour});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepotStocksSnapshotParams &&
        other.depotId == depotId &&
        other.dateJour == dateJour;
  }

  @override
  int get hashCode => Object.hash(depotId, dateJour);

  @override
  String toString() =>
      'DepotStocksSnapshotParams(depotId: $depotId, dateJour: $dateJour)';
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

/// Fonction helper pour créer un snapshot de fallback
DepotStocksSnapshot _fallbackSnapshot(
  DateTime dateJour,
  DepotStocksSnapshotParams params,
) {
  return DepotStocksSnapshot(
    dateJour: dateJour,
    isFallback: true,
    totals: DepotGlobalStockKpi(
      depotId: params.depotId,
      depotNom: '',
      produitId: '',
      produitNom: '',
      stockAmbiantTotal: 0.0,
      stock15cTotal: 0.0,
    ),
    owners: const [],
    citerneRows: const [],
  );
}

final depotStocksSnapshotProvider = riverpod.FutureProvider.autoDispose
    .family<DepotStocksSnapshot, DepotStocksSnapshotParams>((
      ref,
      params,
    ) async {
      // Normaliser la date à minuit pour rester cohérent avec stocks_journaliers.date_jour (DATE)
      final rawDate = params.dateJour ?? DateTime.now();
      final dateJour = DateTime(rawDate.year, rawDate.month, rawDate.day);

      // Log pour vérifier si les params changent constamment
      debugPrint(
        '🔄 depotStocksSnapshotProvider: Début - depotId=${params.depotId}, dateJour=$dateJour',
      );

      StocksKpiRepository repo;

      // Try/catch pour la création du repository
      try {
        repo = ref.watch(stocksKpiRepositoryProvider);
      } catch (e, stack) {
        debugPrint('❌ depotStocksSnapshotProvider ERROR(creation repo): $e');
        debugPrint('Stack: $stack');
        debugPrint(
          '⚠️ depotStocksSnapshotProvider: Retour snapshot fallback (repo)',
        );
        return _fallbackSnapshot(dateJour, params);
      }

      // Try/catch pour les appels Supabase
      try {
        // 1) Global totals per depot
        debugPrint(
          '🔄 depotStocksSnapshotProvider: Appel fetchDepotProductTotals...',
        );
        final globalList = await repo.fetchDepotProductTotals(
          depotId: params.depotId,
          dateJour: dateJour,
        );
        debugPrint(
          '🔄 depotStocksSnapshotProvider: fetchDepotProductTotals OK (${globalList.length} items)',
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
        // IMPORTANT : pas de filtre dateJour pour aligner avec le dashboard
        // Le dashboard utilise kpiStockByOwnerProvider qui appelle fetchDepotOwnerTotals sans date
        debugPrint(
          '🔄 depotStocksSnapshotProvider: Appel fetchDepotOwnerTotals (sans filtre date)...',
        );
        final owners = await repo.fetchDepotOwnerTotals(
          depotId: params.depotId,
          // Pas de dateJour ici pour aligner avec le dashboard
        );
        debugPrint(
          '🔄 depotStocksSnapshotProvider: fetchDepotOwnerTotals OK (${owners.length} items)',
        );

        // 3) Citerne-level snapshots
        // IMPORTANT : pas de filtre dateJour pour aligner avec le dashboard
        // La vue v_stocks_citerne_global expose date_dernier_mouvement, pas date_jour
        // Donc le filtre date ne fonctionne pas et retourne des données partielles
        debugPrint(
          '🔄 depotStocksSnapshotProvider: Appel fetchCiterneGlobalSnapshots (sans filtre date)...',
        );
        final citerneRowsRaw = await repo.fetchCiterneGlobalSnapshots(
          depotId: params.depotId,
          // Pas de dateJour ici pour aligner avec le dashboard
        );
        debugPrint(
          '🔄 depotStocksSnapshotProvider: fetchCiterneGlobalSnapshots OK (${citerneRowsRaw.length} items)',
        );
        // Log détaillé pour diagnostic
        for (final row in citerneRowsRaw) {
          debugPrint(
            '  📊 Citerne: ${row.citerneNom} (${row.citerneId}) | '
            'Stock ambiant: ${row.stockAmbiantTotal} L | '
            'Stock 15°C: ${row.stock15cTotal} L',
          );
        }

        // Agréger les snapshots par (citerneId, produitId) pour sommer tous les propriétaires
        // La vue peut retourner plusieurs lignes pour la même citerne (une par propriétaire)
        final byCiterneProduct = <String, CiterneGlobalStockSnapshot>{};

        for (final row in citerneRowsRaw) {
          final key = '${row.citerneId}::${row.produitId}';
          final existing = byCiterneProduct[key];

          if (existing == null) {
            // Première ligne pour cette citerne+produit -> on stocke tel quel
            byCiterneProduct[key] = row;
          } else {
            // On crée un snapshot agrégé en additionnant les volumes
            byCiterneProduct[key] = CiterneGlobalStockSnapshot(
              citerneId: existing.citerneId,
              citerneNom: existing.citerneNom,
              produitId: existing.produitId,
              produitNom: existing.produitNom,
              dateJour: existing.dateJour,
              stockAmbiantTotal:
                  existing.stockAmbiantTotal + row.stockAmbiantTotal,
              stock15cTotal: existing.stock15cTotal + row.stock15cTotal,
              capaciteTotale: existing.capaciteTotale,
              capaciteSecurite: existing.capaciteSecurite,
            );
          }
        }

        final citerneRows = byCiterneProduct.values.toList();
        debugPrint(
          '🔄 depotStocksSnapshotProvider: Agrégation citernes OK (${citerneRows.length} items après agrégation)',
        );

        const bool isFallback = false;

        debugPrint(
          '✅ depotStocksSnapshotProvider: Succès - retour snapshot normal',
        );
        return DepotStocksSnapshot(
          dateJour: dateJour,
          isFallback: isFallback,
          totals: totals,
          owners: owners,
          citerneRows: citerneRows,
        );
      } catch (e, stack) {
        debugPrint('❌ depotStocksSnapshotProvider ERROR(fetch): $e');
        debugPrint('Stack: $stack');
        debugPrint(
          '⚠️ depotStocksSnapshotProvider: Retour snapshot fallback (fetch)',
        );
        return _fallbackSnapshot(dateJour, params);
      }
    });

/// Provider pour récupérer la capacité totale d'un dépôt
///
/// Retourne la somme des capacités de toutes les citernes actives du dépôt.
/// Utilisé pour calculer le % d'utilisation correct dans la carte Stock total.
final depotTotalCapacityProvider =
    riverpod.FutureProvider.family<double, String>((ref, depotId) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      return repo.fetchDepotTotalCapacity(depotId: depotId);
    });

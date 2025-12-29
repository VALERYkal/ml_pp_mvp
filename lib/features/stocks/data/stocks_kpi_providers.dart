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

/// KPI global filtré par dépôt
///
/// Provider family pour obtenir le KPI d'un dépôt spécifique.
/// Filtre côté SQL via repository pour éviter de charger tous les dépôts.
final kpiGlobalStockByDepotProvider =
    riverpod.FutureProvider.family<DepotGlobalStockKpi?, String>((
      ref,
      depotId,
    ) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      final list = await repo.fetchDepotProductTotals(depotId: depotId);
      // Si plusieurs produits pour ce dépôt, on prend le premier (ou on pourrait les sommer si nécessaire)
      return list.isNotEmpty ? list.first : null;
    });

/// Calcule les totaux de stock d'un dépôt depuis v_stock_actuel_snapshot.
///
/// Ce provider agrège les données de toutes les citernes d'un dépôt
/// depuis la vue snapshot qui représente l'état actuel.
///
/// Retourne un record avec :
/// - amb : total stock ambiant
/// - v15 : total stock @15°C
/// - nbTanks : nombre de citernes distinctes avec stock
final depotGlobalStockFromSnapshotProvider =
    riverpod.FutureProvider.autoDispose.family<({double amb, double v15, int nbTanks}), String>((
      ref,
      depotId,
    ) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      final rows = await repo.fetchCiterneStocksFromSnapshot(depotId: depotId);

      double amb = 0.0;
      double v15 = 0.0;
      final tanks = <String>{};

      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        tanks.add(m['citerne_id']?.toString() ?? '');
        amb += (m['stock_ambiant_total'] as num?)?.toDouble()
            ?? (m['stock_ambiant'] as num?)?.toDouble()
            ?? 0.0;
        v15 += (m['stock_15c_total'] as num?)?.toDouble()
            ?? (m['stock_15c'] as num?)?.toDouble()
            ?? 0.0;
      }

      return (amb: amb, v15: v15, nbTanks: tanks.where((e) => e.isNotEmpty).length);
    });

/// Calcule les stocks par propriétaire d'un dépôt depuis v_stock_actuel_owner_snapshot.
///
/// Retourne une liste de DepotOwnerStockKpi, une par propriétaire (MONALUXE, PARTENAIRE).
/// Si un propriétaire n'a pas de stock, il est inclus avec des valeurs à 0.0.
final depotOwnerStockFromSnapshotProvider = 
    riverpod.FutureProvider.family<List<DepotOwnerStockKpi>, String>((
      ref,
      depotId,
    ) async {
      final repo = ref.watch(stocksKpiRepositoryProvider);
      
      try {
        final rows = await repo.fetchDepotOwnerStocksFromSnapshot(depotId: depotId);

        if (kDebugMode) {
          debugPrint(
            '🔍 depotOwnerStockFromSnapshotProvider: Reçu ${rows.length} lignes depuis la vue'
          );
        }

        // Helper safe pour conversion numérique
        double safeDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

        // Normaliser et filtrer les rows valides
        final validOwners = <DepotOwnerStockKpi>[];
        String? depotNom;

        for (final row in rows) {
          // Normaliser proprietaire_type
          final propTypeRaw = row['proprietaire_type'];
          if (propTypeRaw == null || (propTypeRaw is String && propTypeRaw.trim().isEmpty)) {
            if (kDebugMode) {
              debugPrint(
                '⚠️ depotOwnerStockFromSnapshotProvider: Ignoré une row avec proprietaire_type absent/null'
              );
            }
            continue; // Ignorer les rows sans proprietaire_type
          }

          final proprietaireType = (propTypeRaw as String).toUpperCase().trim();
          
          // Stocker le depotNom depuis la première ligne valide
          depotNom ??= (row['depot_nom'] as String?) ?? '';

          // Créer le DepotOwnerStockKpi avec conversion safe
          final owner = DepotOwnerStockKpi(
            depotId: (row['depot_id'] as String?) ?? depotId,
            depotNom: depotNom,
            proprietaireType: proprietaireType,
            produitId: (row['produit_id'] as String?) ?? '',
            produitNom: (row['produit_nom'] as String?) ?? '',
            // Utiliser stock_ambiant_total et stock_15c_total (cohérence avec autres vues)
            stockAmbiantTotal: safeDouble(row['stock_ambiant_total'] ?? row['stock_ambiant']),
            stock15cTotal: safeDouble(row['stock_15c_total'] ?? row['stock_15c']),
          );

          validOwners.add(owner);
        }

        // S'assurer que MONALUXE et PARTENAIRE existent (avec 0.0 si absents)
        final hasMonaluxe = validOwners.any((o) => o.proprietaireType == 'MONALUXE');
        final hasPartenaire = validOwners.any((o) => o.proprietaireType == 'PARTENAIRE');

        final result = <DepotOwnerStockKpi>[];

        // Ajouter MONALUXE en premier
        if (hasMonaluxe) {
          result.add(validOwners.firstWhere((o) => o.proprietaireType == 'MONALUXE'));
        } else {
          result.add(DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: depotNom ?? '',
            proprietaireType: 'MONALUXE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ));
        }

        // Ajouter PARTENAIRE en second
        if (hasPartenaire) {
          result.add(validOwners.firstWhere((o) => o.proprietaireType == 'PARTENAIRE'));
        } else {
          result.add(DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: depotNom ?? '',
            proprietaireType: 'PARTENAIRE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ));
        }

        if (kDebugMode) {
          debugPrint(
            '🔍 depotOwnerStockFromSnapshotProvider: Retourne MONALUXE=${result[0].stockAmbiantTotal}L, '
            'PARTENAIRE=${result[1].stockAmbiantTotal}L'
          );
        }

        return result;
      } catch (e, stack) {
        debugPrint('❌ depotOwnerStockFromSnapshotProvider: Erreur $e');
        debugPrint('Stack: $stack');
        // Fallback : retourner 2 entrées à 0.0 plutôt que de faire planter l'UI
        return [
          DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: '',
            proprietaireType: 'MONALUXE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ),
          DepotOwnerStockKpi(
            depotId: depotId,
            depotNom: '',
            proprietaireType: 'PARTENAIRE',
            produitId: '',
            produitNom: '',
            stockAmbiantTotal: 0.0,
            stock15cTotal: 0.0,
          ),
        ];
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
  /// En debug/test : si `false`, une assertion échouera si un fallback est utilisé.
  /// En release : toujours autorisé pour éviter les crashes.
  /// Par défaut : `true` en release, `false` en debug (pour forcer la détection des problèmes).
  final bool allowFallbackInDebug;

  const DepotStocksSnapshotParams({
    required this.depotId,
    this.dateJour,
    this.allowFallbackInDebug = kDebugMode ? false : true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepotStocksSnapshotParams &&
        other.depotId == depotId &&
        other.dateJour == dateJour &&
        other.allowFallbackInDebug == allowFallbackInDebug;
  }

  @override
  int get hashCode => Object.hash(depotId, dateJour, allowFallbackInDebug);

  @override
  String toString() =>
      'DepotStocksSnapshotParams(depotId: $depotId, dateJour: $dateJour, allowFallbackInDebug: $allowFallbackInDebug)';
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
/// 
/// En debug : si `allowFallbackInDebug == false`, une assertion échoue pour forcer
/// la détection des problèmes (repository manquant, erreurs Supabase, etc.).
DepotStocksSnapshot _fallbackSnapshot(
  DateTime dateJour,
  DepotStocksSnapshotParams params,
) {
  // Policy explicite : en debug, fallback doit être explicitement autorisé
  if (kDebugMode && !params.allowFallbackInDebug) {
    assert(
      false,
      '❌ depotStocksSnapshotProvider: Fallback utilisé mais allowFallbackInDebug=false. '
      'Cela indique un problème (repository manquant, erreur Supabase, etc.). '
      'Pour autoriser le fallback en test, passez allowFallbackInDebug: true dans DepotStocksSnapshotParams.',
    );
  }

  if (kDebugMode) {
    debugPrint(
      '⚠️ depotStocksSnapshotProvider: Retour snapshot fallback (dateJour=$dateJour, depotId=${params.depotId})',
    );
  }

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
      // Normaliser la date à minuit
      // CRITICAL: Normaliser AVANT toute utilisation pour éviter les rebuild loops
      // Si dateJour est null, utiliser la date d'aujourd'hui normalisée une seule fois
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);
      final rawDate = params.dateJour ?? todayNormalized;
      final dateJour = DateTime(rawDate.year, rawDate.month, rawDate.day);

      // Guard de régression : vérifier que dateJour est bien normalisé (debug only)
      if (kDebugMode) {
        assert(
          dateJour.hour == 0 && dateJour.minute == 0 && dateJour.second == 0 && dateJour.millisecond == 0,
          '⚠️ depotStocksSnapshotProvider: dateJour doit être normalisé (YYYY-MM-DD 00:00:00.000)',
        );
      }

      // Log pour vérifier si les params changent constamment
      if (kDebugMode) {
        debugPrint(
          '🔄 depotStocksSnapshotProvider: Début - depotId=${params.depotId}, dateJour=$dateJour (normalisé)',
        );
      }

      StocksKpiRepository repo;

      // Try/catch pour la création du repository
      try {
        repo = ref.watch(stocksKpiRepositoryProvider);
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('❌ depotStocksSnapshotProvider ERROR(creation repo): $e');
          debugPrint('Stack: $stack');
        }
        return _fallbackSnapshot(dateJour, params);
      }

      // Try/catch pour les appels Supabase
      try {
        // 1) Global totals per depot
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: Appel fetchDepotProductTotals (dateJour=$dateJour)...',
          );
        }
        final globalList = await repo.fetchDepotProductTotals(
          depotId: params.depotId,
          dateJour: dateJour,
        );
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: fetchDepotProductTotals OK (${globalList.length} items)',
          );
        }

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
        // Utiliser dateJour pour garantir cohérence avec les totaux globaux
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: Appel fetchDepotOwnerTotals (avec dateJour=$dateJour)...',
          );
        }
        final owners = await repo.fetchDepotOwnerTotals(
          depotId: params.depotId,
          dateJour: dateJour,
        );
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: fetchDepotOwnerTotals OK (${owners.length} items)',
          );
        }

        // 3) Citerne-level snapshots
        // Utilise la vue snapshot de stock actuel
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: Appel fetchCiterneGlobalSnapshots (vue snapshot avec dateJour=$dateJour)...',
          );
        }
        final citerneRowsRaw = await repo.fetchCiterneGlobalSnapshots(
          depotId: params.depotId,
          dateJour: dateJour,
        );
        
        // Guard de régression : vérifier que toutes les lignes ont la même date_jour (debug only)
        if (kDebugMode && citerneRowsRaw.isNotEmpty) {
          final distinctDates = citerneRowsRaw
              .map((row) => '${row.dateJour.year}-${row.dateJour.month.toString().padLeft(2, '0')}-${row.dateJour.day.toString().padLeft(2, '0')}')
              .toSet();
          if (distinctDates.length > 1) {
            debugPrint(
              '⚠️ depotStocksSnapshotProvider: Plusieurs dates distinctes détectées dans citerneRowsRaw: ${distinctDates.join(", ")}. '
              'Le repository devrait avoir filtré à une seule date.',
            );
          } else {
            debugPrint(
              '✅ depotStocksSnapshotProvider: Toutes les lignes ont la même date_jour: ${distinctDates.first}',
            );
          }
          debugPrint(
            '🔄 depotStocksSnapshotProvider: fetchCiterneGlobalSnapshots OK (${citerneRowsRaw.length} items)',
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
        if (kDebugMode) {
          debugPrint(
            '🔄 depotStocksSnapshotProvider: Agrégation citernes OK (${citerneRows.length} items après agrégation)',
          );
          debugPrint(
            '✅ depotStocksSnapshotProvider: Succès - retour snapshot normal (dateJour=$dateJour)',
          );
        }

        const bool isFallback = false;
        return DepotStocksSnapshot(
          dateJour: dateJour,
          isFallback: isFallback,
          totals: totals,
          owners: owners,
          citerneRows: citerneRows,
        );
      } catch (e, stack) {
        if (kDebugMode) {
          debugPrint('❌ depotStocksSnapshotProvider ERROR(fetch): $e');
          debugPrint('Stack: $stack');
        }
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

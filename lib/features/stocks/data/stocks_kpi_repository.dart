import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/stocks_kpi_models.dart';

/// Loader injectable pour les vues KPI.
/// En prod, on n'en fournit pas => le repo utilise Supabase normalement.
/// En test, on injecte un loader qui renvoie une liste de maps en mémoire.
typedef StocksKpiViewLoader = Future<List<Map<String, dynamic>>> Function(
  String viewName, {
  Map<String, dynamic>? filters,
});

class StocksKpiRepository {
  StocksKpiRepository(
    this.client, {
    StocksKpiViewLoader? loader,
  }) : _loader = loader;

  final SupabaseClient client;
  final StocksKpiViewLoader? _loader;

  Future<List<Map<String, dynamic>>> _fetchRows(
    String viewName, {
    Map<String, dynamic>? filters,
  }) async {
    // 🔹 En test: si un loader est fourni, on ne touche PAS à Supabase.
    if (_loader != null) {
      return _loader!(viewName, filters: filters);
    }

    // 🔹 En prod: comportement normal avec Supabase.
    var query = client.from(viewName).select();

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
    }

    final result = await query;
    final rows = result as List<dynamic>;
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    final filters = <String, dynamic>{};

    if (depotId != null) {
      filters['depot_id'] = depotId;
    }
    if (produitId != null) {
      filters['produit_id'] = produitId;
    }
    if (dateJour != null) {
      final dateStr = DateTime(
        dateJour.year,
        dateJour.month,
        dateJour.day,
      ).toIso8601String().split('T').first;
      filters['date_jour'] = dateStr;
    }

    final rows = await _fetchRows(
      'v_kpi_stock_global',
      filters: filters.isEmpty ? null : filters,
    );

    return rows.map(DepotGlobalStockKpi.fromMap).toList();
  }

  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    final filters = <String, dynamic>{};

    if (depotId != null) {
      filters['depot_id'] = depotId;
    }
    if (proprietaireType != null) {
      filters['proprietaire_type'] = proprietaireType;
    }
    if (dateJour != null) {
      final dateStr = DateTime(
        dateJour.year,
        dateJour.month,
        dateJour.day,
      ).toIso8601String().split('T').first;
      filters['date_jour'] = dateStr;
    }

    final rows = await _fetchRows(
      'v_kpi_stock_owner',
      filters: filters.isEmpty ? null : filters,
    );

    return rows.map(DepotOwnerStockKpi.fromMap).toList();
  }

  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? citerneId,
    String? depotId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    final filters = <String, dynamic>{};

    if (citerneId != null) {
      filters['citerne_id'] = citerneId;
    }
    if (depotId != null) {
      filters['depot_id'] = depotId;
    }
    if (proprietaireType != null) {
      filters['proprietaire_type'] = proprietaireType;
    }
    if (dateJour != null) {
      final dateStr = DateTime(
        dateJour.year,
        dateJour.month,
        dateJour.day,
      ).toIso8601String().split('T').first;
      filters['date_jour'] = dateStr;
    }

    final rows = await _fetchRows(
      'v_stocks_citerne_owner',
      filters: filters.isEmpty ? null : filters,
    );

    return rows.map(CiterneOwnerStockSnapshot.fromMap).toList();
  }

  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? citerneId,
    String? depotId,
    String? proprietaireType,
    DateTime? dateDernierMouvement,
  }) async {
    final filters = <String, dynamic>{};

    if (citerneId != null) {
      filters['citerne_id'] = citerneId;
    }
    if (depotId != null) {
      filters['depot_id'] = depotId;
    }
    if (proprietaireType != null) {
      filters['proprietaire_type'] = proprietaireType;
    }
    if (dateDernierMouvement != null) {
      final dateStr = DateTime(
        dateDernierMouvement.year,
        dateDernierMouvement.month,
        dateDernierMouvement.day,
      ).toIso8601String().split('T').first;
      filters['date_dernier_mouvement'] = dateStr;
    }

    final rows = await _fetchRows(
      'v_stocks_citerne_global',
      filters: filters.isEmpty ? null : filters,
    );

    return rows.map(CiterneGlobalStockSnapshot.fromMap).toList();
  }
}

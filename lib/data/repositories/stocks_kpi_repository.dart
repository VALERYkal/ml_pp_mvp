import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper pour convertir proprement toute valeur numérique en double.
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  throw ArgumentError('Value $value (${value.runtimeType}) is not numeric');
}

/// KPI global de stock par dépôt & produit (toutes propriétés confondues).
///
/// Source SQL attendue :
///   v_kpi_stock_global
/// Colonnes utilisées :
///   - depot_id
///   - depot_nom
///   - produit_id
///   - produit_nom
///   - stock_ambiant_total
///   - stock_15c_total
class DepotGlobalStockKpi {
  final String depotId;
  final String depotNom;
  final String produitId;
  final String produitNom;
  final double stockAmbiantTotal;
  final double stock15cTotal;

  const DepotGlobalStockKpi({
    required this.depotId,
    required this.depotNom,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
  });

  factory DepotGlobalStockKpi.fromMap(Map<String, dynamic> map) {
    return DepotGlobalStockKpi(
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
    );
  }
}

/// KPI de stock par dépôt, propriétaire (MONALUXE/PARTENAIRE) & produit.
///
/// Source SQL attendue :
///   v_kpi_stock_owner
/// Colonnes utilisées :
///   - depot_id
///   - depot_nom
///   - proprietaire_type
///   - produit_id
///   - produit_nom
///   - stock_ambiant_total
///   - stock_15c_total
class DepotOwnerStockKpi {
  final String depotId;
  final String depotNom;
  final String proprietaireType;
  final String produitId;
  final String produitNom;
  final double stockAmbiantTotal;
  final double stock15cTotal;

  const DepotOwnerStockKpi({
    required this.depotId,
    required this.depotNom,
    required this.proprietaireType,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
  });

  factory DepotOwnerStockKpi.fromMap(Map<String, dynamic> map) {
    return DepotOwnerStockKpi(
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      proprietaireType: map['proprietaire_type'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
    );
  }
}

/// Snapshot de stock par citerne, propriétaire et produit.
///
/// Source SQL attendue :
///   v_stocks_citerne_owner
/// Colonnes utilisées :
///   - citerne_id
///   - citerne_nom
///   - produit_id
///   - produit_nom
///   - proprietaire_type
///   - date_jour
///   - stock_ambiant_total
///   - stock_15c_total
class CiterneOwnerStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final String proprietaireType;
  final DateTime dateJour;
  final double stockAmbiantTotal;
  final double stock15cTotal;

  const CiterneOwnerStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.proprietaireType,
    required this.dateJour,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
  });

  factory CiterneOwnerStockSnapshot.fromMap(Map<String, dynamic> map) {
    return CiterneOwnerStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      proprietaireType: map['proprietaire_type'] as String,
      dateJour: DateTime.parse(map['date_jour'] as String),
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
    );
  }
}

/// Snapshot global par citerne & produit (tous propriétaires confondus).
///
/// Source SQL attendue :
///   v_stocks_citerne_global
/// Colonnes utilisées :
///   - citerne_id
///   - citerne_nom
///   - produit_id
///   - produit_nom
///   - date_jour
///   - stock_ambiant_total
///   - stock_15c_total
///   - capacite_totale (Phase 3.4)
class CiterneGlobalStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final DateTime dateJour;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final double capaciteTotale;

  const CiterneGlobalStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.dateJour,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.capaciteTotale,
  });

  factory CiterneGlobalStockSnapshot.fromMap(Map<String, dynamic> map) {
    // La vue SQL expose 'date_dernier_mouvement' (ou peut être null si pas de mouvement)
    // On utilise DateTime.now() comme fallback si la date est absente
    final dateStr = map['date_dernier_mouvement'] as String?;
    final dateJour = dateStr != null 
        ? DateTime.parse(dateStr) 
        : DateTime.now();
    
    return CiterneGlobalStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      dateJour: dateJour,
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
      capaciteTotale: _toDouble(map['capacite_totale']),
    );
  }
}

/// Repository dédié aux KPI de stock basés sur les vues SQL.
/// 
/// IMPORTANT :
/// - Ce repository est additif : il ne remplace pas StocksRepository existant.
/// - Injecter SupabaseClient depuis Supabase.instance.client dans un provider
///   (phase 3.2), pas ici.
class StocksKpiRepository {
  final SupabaseClient _client;

  StocksKpiRepository(this._client);

  /// Retourne les totaux globaux par dépôt & produit.
  ///
  /// Si [depotId] est fourni, on filtre sur ce dépôt.
  /// Si [produitId] est fourni, on filtre sur ce produit.
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
  }) async {
    final query = _client.from('v_kpi_stock_global').select<Map<String, dynamic>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }

    final rows = await query;
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(DepotGlobalStockKpi.fromMap)
        .toList();
  }

  /// Retourne les totaux par dépôt, propriétaire & produit.
  ///
  /// Utilisé pour le breakdown MONALUXE vs PARTENAIRE.
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
  }) async {
    final query = _client.from('v_kpi_stock_owner').select<Map<String, dynamic>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }
    if (proprietaireType != null) {
      query.eq('proprietaire_type', proprietaireType);
    }

    final rows = await query;
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(DepotOwnerStockKpi.fromMap)
        .toList();
  }

  /// Retourne le snapshot par citerne, propriétaire & produit.
  ///
  /// Permet d'alimenter les cartes "TANK1 Monaluxe / Partenaire", etc.
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
  }) async {
    final query =
        _client.from('v_stocks_citerne_owner').select<Map<String, dynamic>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (citerneId != null) {
      query.eq('citerne_id', citerneId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }
    if (proprietaireType != null) {
      query.eq('proprietaire_type', proprietaireType);
    }

    final rows = await query;
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(CiterneOwnerStockSnapshot.fromMap)
        .toList();
  }

  /// Retourne le snapshot global par citerne & produit (tous propriétaires confondus).
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    final query =
        _client.from('v_stocks_citerne_global').select<Map<String, dynamic>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (citerneId != null) {
      query.eq('citerne_id', citerneId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }

    final rows = await query;
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(CiterneGlobalStockSnapshot.fromMap)
        .toList();
  }
}


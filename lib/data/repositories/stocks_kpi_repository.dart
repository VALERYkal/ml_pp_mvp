import 'package:flutter/foundation.dart';
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
///   v_stocks_citerne_global_daily
/// Colonnes utilisées :
///   - citerne_id
///   - citerne_nom
///   - produit_id
///   - produit_nom
///   - date_jour
///   - stock_ambiant_total
///   - stock_15c_total
///   - capacite_totale
///   - capacite_securite
class CiterneGlobalStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String produitId;
  final String produitNom;
  final DateTime dateJour;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final double capaciteTotale;
  final double capaciteSecurite;

  const CiterneGlobalStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.produitId,
    required this.produitNom,
    required this.dateJour,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.capaciteTotale,
    required this.capaciteSecurite,
  });

  factory CiterneGlobalStockSnapshot.fromMap(Map<String, dynamic> map) {
    return CiterneGlobalStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      dateJour: DateTime.parse(map['date_jour'] as String),
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
      capaciteTotale: _toDouble(map['capacite_totale']),
      capaciteSecurite: _toDouble(map['capacite_securite']),
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

  /// Helper pour formater une date en format ISO YYYY-MM-DD (UTC).
  String _formatYmd(DateTime date) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
  }

  /// Filtre les rows pour ne garder que celles avec le date_jour le plus récent.
  /// 
  /// Précondition : rows doit être trié par date_jour DESC.
  /// Si rows est vide, retourne une liste vide.
  /// 
  /// Garde-fous :
  /// - Vérifie en debug que le tri DESC est respecté (anti-régression)
  /// - Gère explicitement le cas où date_jour est null avec warnings appropriés
  /// - En debug, log un warning si plusieurs dates distinctes étaient présentes
  List<Map<String, dynamic>> _filterToLatestDate(
    List<Map<String, dynamic>> rows, {
    DateTime? dateJour,
  }) {
    if (rows.isEmpty) return [];
    
    // Garde-fou 1 : Vérifier en debug que le tri DESC est respecté
    if (kDebugMode && rows.length > 1) {
      final sampleSize = rows.length > 20 ? 20 : rows.length;
      final dates = rows
          .take(sampleSize)
          .map((r) => r['date_jour'] as String?)
          .whereType<String>()
          .toList();
      
      if (dates.length > 1) {
        final sortedDesc = List<String>.from(dates)..sort((a, b) => b.compareTo(a));
        if (dates.join(',') != sortedDesc.join(',')) {
          debugPrint(
            '⚠️ StocksKpiRepository._filterToLatestDate: Tri DESC non respecté sur les $sampleSize premières lignes. '
            'Dates: ${dates.take(5).join(", ")}'
          );
        }
      }
    }
    
    final firstDate = rows.first['date_jour'] as String?;
    
    // Garde-fou 2 : Gestion explicite du cas date_jour null
    if (firstDate == null) {
      if (dateJour == null) {
        // Cas normal : pas de date_jour demandé, pas de date_jour dans les données
        if (kDebugMode) {
          debugPrint(
            '⚠️ StocksKpiRepository._filterToLatestDate: date_jour absent des données (dateJour non fourni, comportement normal)'
          );
        }
        return rows;
      } else {
        // Cas anormal : date_jour demandé mais absent des données
        debugPrint(
          '⚠️ StocksKpiRepository._filterToLatestDate: date_jour missing, cannot enforce snapshot day. '
          'dateJour demandé: ${_formatYmd(dateJour)}, mais aucune ligne n\'a date_jour. '
          'Retour de toutes les lignes sans filtrage (risque de sur-compte).'
        );
        return rows;
      }
    }
    
    // En debug : vérifier s'il y avait plusieurs dates distinctes
    if (kDebugMode) {
      final distinctDates = rows
          .map((r) => r['date_jour'] as String?)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Trier DESC pour log cohérent
      
      if (distinctDates.length > 1) {
        debugPrint(
          '⚠️ StocksKpiRepository._filterToLatestDate: Plusieurs dates distinctes détectées avant filtrage '
          '(dates: ${distinctDates.join(", ")}) - filtrage à la date la plus récente: $firstDate'
        );
      }
    }
    
    // Filtrer pour ne garder que la date la plus récente
    return rows.where((r) => r['date_jour'] == firstDate).toList();
  }

  /// Retourne les totaux globaux par dépôt & produit.
  ///
  /// Si [depotId] est fourni, on filtre sur ce dépôt.
  /// Si [produitId] est fourni, on filtre sur ce produit.
  /// Si [dateJour] est fourni, on filtre sur cette date (<= dateJour pour prendre la dernière disponible).
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    final query = _client
        .from('v_kpi_stock_global')
        .select<List<Map<String, dynamic>>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }
    // If a date is provided, pick the latest row <= that date.
    if (dateJour != null) {
      query.lte('date_jour', _formatYmd(dateJour));
    }

    // Deterministic: latest date first (dashboard consumes newest snapshot)
    query.order('date_jour', ascending: false);

    final rows = await query;
    final list = rows as List<Map<String, dynamic>>;
    return list.map(DepotGlobalStockKpi.fromMap).toList();
  }

  /// Retourne les totaux par dépôt, propriétaire & produit.
  ///
  /// Utilisé pour le breakdown MONALUXE vs PARTENAIRE.
  /// Si [dateJour] est fourni, on filtre sur cette date (<= dateJour pour prendre la dernière disponible).
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    final query = _client
        .from('v_kpi_stock_owner')
        .select<List<Map<String, dynamic>>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }
    if (proprietaireType != null) {
      query.eq('proprietaire_type', proprietaireType);
    }
    // If a date is provided, pick the latest row <= that date.
    if (dateJour != null) {
      query.lte('date_jour', _formatYmd(dateJour));
    }

    // Deterministic: latest date first (dashboard consumes newest snapshot)
    query.order('date_jour', ascending: false);

    final rows = await query;
    // Cast sûr : rows peut être List<dynamic> avec items Map<String, dynamic>
    final list = (rows as List).cast<Map<String, dynamic>>();
    
    // Si dateJour est fourni, filtrer pour ne garder que la date la plus récente
    final filteredList = (dateJour != null && list.isNotEmpty)
        ? _filterToLatestDate(list, dateJour: dateJour)
        : list;
    
    return filteredList.map(DepotOwnerStockKpi.fromMap).toList();
  }

  /// Retourne le snapshot par citerne, propriétaire & produit.
  ///
  /// Permet d'alimenter les cartes "TANK1 Monaluxe / Partenaire", etc.
  /// Si [dateJour] est fourni, on filtre sur cette date (<= dateJour pour prendre la dernière disponible).
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    final query = _client
        .from('v_stocks_citerne_owner')
        .select<List<Map<String, dynamic>>>();

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
    // If a date is provided, pick the latest row <= that date.
    if (dateJour != null) {
      query.lte('date_jour', _formatYmd(dateJour));
    }

    // Deterministic: latest date first (dashboard consumes newest snapshot)
    query.order('date_jour', ascending: false);

    final rows = await query;
    // Cast sûr : rows peut être List<dynamic> avec items Map<String, dynamic>
    final list = (rows as List).cast<Map<String, dynamic>>();
    
    // Si dateJour est fourni, filtrer pour ne garder que la date la plus récente
    final filteredList = (dateJour != null && list.isNotEmpty)
        ? _filterToLatestDate(list, dateJour: dateJour)
        : list;
    
    return filteredList.map(CiterneOwnerStockSnapshot.fromMap).toList();
  }

  /// Retourne le snapshot global par citerne & produit (tous propriétaires confondus).
  /// Si [dateJour] est fourni, on prend le dernier snapshot dont date_jour <= dateJour
  /// (et on garantit une seule date_jour via _filterToLatestDate).
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    final query = _client
        .from('v_stocks_citerne_global_daily') // ✅ nouvelle vue "daily"
        .select<List<Map<String, dynamic>>>();

    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (citerneId != null) {
      query.eq('citerne_id', citerneId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }

    if (dateJour != null) {
      query.lte('date_jour', _formatYmd(dateJour));
    }

    // Deterministic: latest date first
    query.order('date_jour', ascending: false);

    final rows = await query;

    // Cast sûr
    final list = (rows as List).cast<Map<String, dynamic>>();

    // Si dateJour est fourni, filtrer pour ne garder que la date la plus récente
    final filteredList = (dateJour != null && list.isNotEmpty)
        ? _filterToLatestDate(list, dateJour: dateJour)
        : list;

    return filteredList.map(CiterneGlobalStockSnapshot.fromMap).toList();
  }

  /// Récupère la capacité totale d'un dépôt (somme de toutes les citernes actives)
  ///
  /// [depotId] : Identifiant du dépôt (requis)
  /// [produitId] : Optionnel, filtre par produit si fourni
  ///
  /// Retourne la somme des capacités totales de toutes les citernes actives du dépôt.
  /// Si aucune citerne active n'est trouvée, retourne 0.0.
  Future<double> fetchDepotTotalCapacity({
    required String depotId,
    String? produitId,
  }) async {
    var query = _client
        .from('citernes')
        .select<List<Map<String, dynamic>>>('capacite_totale')
        .eq('depot_id', depotId)
        .eq('statut', 'active');

    if (produitId != null) {
      query = query.eq('produit_id', produitId);
    }

    final rows = await query;
    final list = rows as List<Map<String, dynamic>>;

    double total = 0.0;
    for (final row in list) {
      final capacite = row['capacite_totale'];
      if (capacite != null) {
        total += (capacite is num ? capacite.toDouble() : 0.0);
      }
    }

    return total;
  }
}

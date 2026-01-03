import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper pour convertir proprement toute valeur numérique en double.
double _toDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw ArgumentError('Value $value (${value.runtimeType}) is not numeric');
}


/// KPI global de stock par dépôt & produit (toutes propriétés confondues).
///
/// Source SQL : v_stock_actuel (via fetchDepotProductTotals avec agrégation Dart)
/// Colonnes utilisées :
///   - depot_id
///   - depot_nom
///   - produit_id
///   - produit_nom
///   - stock_ambiant_total (agrégé)
///   - stock_15c_total (agrégé)
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
/// Source SQL : v_stock_actuel (via fetchDepotOwnerTotals avec agrégation Dart)
/// Colonnes utilisées :
///   - depot_id
///   - depot_nom
///   - proprietaire_type
///   - produit_id
///   - produit_nom
///   - stock_ambiant_total (agrégé)
///   - stock_15c_total (agrégé)
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

  /// ⚠️ IMPORTANT — CONTRAT STOCK ACTUEL
  /// Toute lecture de stock "actuel" DOIT passer par v_stock_actuel.
  /// Les vues snapshot sont dépréciées pour l'actuel (AXE A).
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Récupère les lignes de stock actuel depuis la vue canonique v_stock_actuel.
  ///
  /// Cette vue inclut automatiquement :
  /// - réceptions validées
  /// - sorties validées
  /// - ajustements (stocks_adjustments)
  ///
  /// [depotId] : Identifiant du dépôt (requis)
  /// [produitId] : Optionnel, filtre par produit
  ///
  /// Retourne : Liste de Map contenant les données brutes de v_stock_actuel
  Future<List<Map<String, dynamic>>> fetchStockActuelRows({
    required String depotId,
    String? produitId,
  }) async {
    final query = _client
        .from('v_stock_actuel')
        .select<List<Map<String, dynamic>>>()
        .eq('depot_id', depotId);

    if (produitId != null) {
      query.eq('produit_id', produitId);
    }

    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Retourne les totaux globaux par dépôt & produit.
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par (depot_id, produit_id).
  ///
  /// Si [depotId] est fourni, on filtre sur ce dépôt (requis pour fetchStockActuelRows).
  /// Si [produitId] est fourni, on filtre sur ce produit.
  /// ⚠️ [dateJour] est ignoré : v_stock_actuel = toujours état actuel.
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour, // Ignoré : v_stock_actuel = toujours état actuel
  }) async {
    if (depotId == null) {
      // Si pas de depotId, retourner liste vide (comportement conservé)
      return [];
    }

    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    final rows = await fetchStockActuelRows(
      depotId: depotId,
      produitId: produitId,
    );

    // Agréger par (depot_id, produit_id) tous propriétaires confondus
    final Map<String, ({
      String depotId,
      String depotNom,
      String produitId,
      String produitNom,
      double stockAmbiant,
      double stock15c,
    })> aggregated = {};

    for (final row in rows) {
      final rowProduitId = (row['produit_id'] as String?) ?? '';
      final key = '$depotId::$rowProduitId';

      final stockAmbiant = _toDouble(row['stock_ambiant'] ?? row['stock_ambiant_total'] ?? 0.0);
      final stock15c = _toDouble(row['stock_15c'] ?? row['stock_15c_total'] ?? 0.0);
      final depotNom = (row['depot_nom'] as String?) ?? '';
      final produitNom = (row['produit_nom'] as String?) ?? '';

      if (aggregated.containsKey(key)) {
        final current = aggregated[key]!;
        aggregated[key] = (
          depotId: current.depotId,
          depotNom: current.depotNom,
          produitId: current.produitId,
          produitNom: current.produitNom,
          stockAmbiant: current.stockAmbiant + stockAmbiant,
          stock15c: current.stock15c + stock15c,
        );
      } else {
        aggregated[key] = (
          depotId: depotId,
          depotNom: depotNom,
          produitId: rowProduitId,
          produitNom: produitNom,
          stockAmbiant: stockAmbiant,
          stock15c: stock15c,
        );
      }
    }

    // Convertir en liste de DepotGlobalStockKpi
    return aggregated.values.map((agg) {
      return DepotGlobalStockKpi(
        depotId: agg.depotId,
        depotNom: agg.depotNom,
        produitId: agg.produitId,
        produitNom: agg.produitNom,
        stockAmbiantTotal: agg.stockAmbiant,
        stock15cTotal: agg.stock15c,
      );
    }).toList();
  }

  /// Retourne les totaux par dépôt, propriétaire & produit.
  ///
  /// Utilisé pour le breakdown MONALUXE vs PARTENAIRE.
  /// ⚠️ [dateJour] est ignoré : v_stock_actuel = toujours état actuel.
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par proprietaire_type.
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour, // Ignoré : v_stock_actuel = toujours état actuel
  }) async {
    if (depotId == null) {
      // Si pas de depotId, retourner liste vide (comportement conservé)
      return [];
    }

    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    final rows = await fetchStockActuelRows(
      depotId: depotId,
      produitId: produitId,
    );

    // Agréger par (depot_id, produit_id, proprietaire_type)
    final Map<String, ({
      String depotId,
      String depotNom,
      String produitId,
      String produitNom,
      String proprietaireType,
      double stockAmbiant,
      double stock15c,
    })> aggregated = {};

    for (final row in rows) {
      // Filtrer par proprietaireType si fourni
      final rowProprietaireType = (row['proprietaire_type'] as String?)?.toUpperCase().trim();
      if (rowProprietaireType == null || rowProprietaireType.isEmpty) {
        continue; // Ignorer les rows sans proprietaire_type
      }
      if (proprietaireType != null && rowProprietaireType != proprietaireType.toUpperCase().trim()) {
        continue; // Filtrer par proprietaireType si fourni
      }

      final rowProduitId = (row['produit_id'] as String?) ?? '';
      final key = '$depotId::${rowProduitId}::$rowProprietaireType';

      final stockAmbiant = _toDouble(row['stock_ambiant'] ?? row['stock_ambiant_total'] ?? 0.0);
      final stock15c = _toDouble(row['stock_15c'] ?? row['stock_15c_total'] ?? 0.0);
      final depotNom = (row['depot_nom'] as String?) ?? '';
      final produitNom = (row['produit_nom'] as String?) ?? '';

      if (aggregated.containsKey(key)) {
        final current = aggregated[key]!;
        aggregated[key] = (
          depotId: current.depotId,
          depotNom: current.depotNom,
          produitId: current.produitId,
          produitNom: current.produitNom,
          proprietaireType: current.proprietaireType,
          stockAmbiant: current.stockAmbiant + stockAmbiant,
          stock15c: current.stock15c + stock15c,
        );
      } else {
        aggregated[key] = (
          depotId: depotId,
          depotNom: depotNom,
          produitId: rowProduitId,
          produitNom: produitNom,
          proprietaireType: rowProprietaireType,
          stockAmbiant: stockAmbiant,
          stock15c: stock15c,
        );
      }
    }

    // Convertir en liste de DepotOwnerStockKpi
    final result = aggregated.values.map((agg) {
      return DepotOwnerStockKpi(
        depotId: agg.depotId,
        depotNom: agg.depotNom,
        proprietaireType: agg.proprietaireType,
        produitId: agg.produitId,
        produitNom: agg.produitNom,
        stockAmbiantTotal: agg.stockAmbiant,
        stock15cTotal: agg.stock15c,
      );
    }).toList();

    // Trier par proprietaire_type (MONALUXE puis PARTENAIRE)
    result.sort((a, b) => a.proprietaireType.compareTo(b.proprietaireType));

    // Fallback safe : si résultat vide, retourner MONALUXE et PARTENAIRE avec 0.0
    if (result.isEmpty) {
      // Récupérer le nom du dépôt pour le fallback
      String depotNom = '';
      try {
        final depotRow =
            await _client
                    .from('depots')
                    .select('id, nom')
                    .eq('id', depotId)
                    .maybeSingle()
                as Map<String, dynamic>?;
        depotNom = (depotRow?['nom'] as String?) ?? '';
      } catch (_) {
        // Ignorer si erreur récupération dépôt
      }

      return [
        DepotOwnerStockKpi(
          depotId: depotId,
          depotNom: depotNom,
          proprietaireType: 'MONALUXE',
          produitId: produitId ?? '',
          produitNom: '',
          stockAmbiantTotal: 0.0,
          stock15cTotal: 0.0,
        ),
        DepotOwnerStockKpi(
          depotId: depotId,
          depotNom: depotNom,
          proprietaireType: 'PARTENAIRE',
          produitId: produitId ?? '',
          produitNom: '',
          stockAmbiantTotal: 0.0,
          stock15cTotal: 0.0,
        ),
      ];
    }

    return result;
  }

  /// Récupère les stocks actuels par citerne depuis v_stock_actuel (source de vérité canonique).
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par (citerne_id, produit_id) tous propriétaires confondus.
  ///
  /// [depotId] : Optionnel, filtre par dépôt (requis pour fetchStockActuelRows)
  /// [citerneId] : Optionnel, filtre par citerne (appliqué côté Dart)
  /// [produitId] : Optionnel, filtre par produit (peut être passé à fetchStockActuelRows)
  ///
  /// Retourne : Liste de Map contenant les données agrégées par citerne
  Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    if (depotId == null) {
      // Si pas de depotId, retourner liste vide (comportement conservé)
      return [];
    }

    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    final rows = await fetchStockActuelRows(
      depotId: depotId,
      produitId: produitId,
    );

    // Agréger par (citerne_id, produit_id) tous propriétaires confondus
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final row in rows) {
      final rowCiterneId = (row['citerne_id'] as String?) ?? '';
      final rowProduitId = (row['produit_id'] as String?) ?? '';

      // Filtrer par citerneId si fourni
      if (citerneId != null && rowCiterneId != citerneId) {
        continue;
      }

      final key = '$rowCiterneId::$rowProduitId';

      final stockAmbiant = _toDouble(row['stock_ambiant'] ?? row['stock_ambiant_total'] ?? 0.0);
      final stock15c = _toDouble(row['stock_15c'] ?? row['stock_15c_total'] ?? 0.0);

      if (aggregated.containsKey(key)) {
        final current = aggregated[key]!;
        aggregated[key] = Map<String, dynamic>.from(current)
          ..['stock_ambiant_total'] = (_toDouble(current['stock_ambiant_total'] ?? 0.0) + stockAmbiant)
          ..['stock_15c_total'] = (_toDouble(current['stock_15c_total'] ?? 0.0) + stock15c);
      } else {
        aggregated[key] = {
          'citerne_id': rowCiterneId,
          'citerne_nom': (row['citerne_nom'] as String?) ?? 'Citerne',
          'produit_id': rowProduitId,
          'produit_nom': (row['produit_nom'] as String?) ?? '',
          'depot_id': (row['depot_id'] as String?) ?? depotId,
          'depot_nom': (row['depot_nom'] as String?) ?? '',
          'stock_ambiant_total': stockAmbiant,
          'stock_15c_total': stock15c,
          'updated_at': row['updated_at'] ?? row['date_jour'],
        };
      }
    }

    // Convertir en liste et trier par nom de citerne
    final result = aggregated.values.toList();
    result.sort((a, b) {
      final nomA = (a['citerne_nom'] as String?) ?? '';
      final nomB = (b['citerne_nom'] as String?) ?? '';
      return nomA.compareTo(nomB);
    });

    return result;
  }

  /// Récupère les stocks actuels par dépôt et propriétaire depuis v_stock_actuel (source de vérité canonique).
  ///
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par (depot_id, produit_id, proprietaire_type).
  ///
  /// Colonnes retournées :
  ///   - depot_id, depot_nom
  ///   - produit_id, produit_nom
  ///   - proprietaire_type (MONALUXE ou PARTENAIRE)
  ///   - stock_ambiant_total (NUMERIC)
  ///   - stock_15c_total (NUMERIC)
  ///
  /// [depotId] : Identifiant du dépôt (requis)
  /// [produitId] : Optionnel, filtre par produit
  ///
  /// Retourne : Liste de Map contenant les données agrégées
  Future<List<Map<String, dynamic>>> fetchDepotOwnerStocksFromSnapshot({
    required String depotId,
    String? produitId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '🔍 StocksKpiRepository.fetchDepotOwnerStocksFromSnapshot: '
        'depotId=$depotId, produitId=$produitId',
      );
    }

    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    final rows = await fetchStockActuelRows(
      depotId: depotId,
      produitId: produitId,
    );

    // Agréger par (depot_id, produit_id, proprietaire_type)
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final row in rows) {
      final rowProduitId = (row['produit_id'] as String?) ?? '';
      final rowProprietaireType = (row['proprietaire_type'] as String?)?.toUpperCase().trim();

      // Ignorer les rows sans proprietaire_type
      if (rowProprietaireType == null || rowProprietaireType.isEmpty) {
        continue;
      }

      final key = '$depotId::$rowProduitId::$rowProprietaireType';

      final stockAmbiant = _toDouble(row['stock_ambiant'] ?? row['stock_ambiant_total'] ?? 0.0);
      final stock15c = _toDouble(row['stock_15c'] ?? row['stock_15c_total'] ?? 0.0);
      final depotNom = (row['depot_nom'] as String?) ?? '';
      final produitNom = (row['produit_nom'] as String?) ?? '';

      if (aggregated.containsKey(key)) {
        final current = aggregated[key]!;
        aggregated[key] = Map<String, dynamic>.from(current)
          ..['stock_ambiant_total'] = (_toDouble(current['stock_ambiant_total'] ?? 0.0) + stockAmbiant)
          ..['stock_15c_total'] = (_toDouble(current['stock_15c_total'] ?? 0.0) + stock15c);
      } else {
        aggregated[key] = {
          'depot_id': depotId,
          'depot_nom': depotNom,
          'produit_id': rowProduitId,
          'produit_nom': produitNom,
          'proprietaire_type': rowProprietaireType,
          'stock_ambiant_total': stockAmbiant,
          'stock_15c_total': stock15c,
        };
      }
    }

    // Convertir en liste et trier par proprietaire_type (MONALUXE puis PARTENAIRE)
    final result = aggregated.values.toList();
    result.sort((a, b) {
      final propA = (a['proprietaire_type'] as String?) ?? '';
      final propB = (b['proprietaire_type'] as String?) ?? '';
      return propA.compareTo(propB);
    });

    if (kDebugMode) {
      debugPrint(
        '🔍 StocksKpiRepository.fetchDepotOwnerStocksFromSnapshot: '
        'Retourné ${result.length} lignes pour depotId=$depotId',
      );
      if (result.isNotEmpty) {
        final sample = result.first;
        debugPrint('🔍 Colonnes disponibles: ${sample.keys.toList()}');
      }
    }

    return result;
  }

  /// [DEPRECATED] Alias de compatibilité pour fetchCiterneGlobalSnapshots.
  ///
  /// ⚠️ Cette méthode est maintenue uniquement pour compatibilité avec le code existant.
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Utilise v_stock_actuel via fetchCiterneStocksFromSnapshot() (ignore dateJour car v_stock_actuel = état actuel).
  ///
  /// [depotId] : Optionnel, filtre par dépôt
  /// [citerneId] : Optionnel, filtre par citerne
  /// [produitId] : Optionnel, filtre par produit
  /// [dateJour] : Ignoré (v_stock_actuel = toujours état actuel)
  ///
  /// Retourne : Liste de CiterneGlobalStockSnapshot mappée depuis v_stock_actuel (agrégation Dart)
  @Deprecated(
    'Utiliser fetchCiterneStocksFromSnapshot() directement. Cette méthode est maintenue pour compatibilité.',
  )
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour, // Ignoré : v_stock_actuel = toujours état actuel
  }) async {
    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    // Récupérer les stocks depuis v_stock_actuel (via fetchCiterneStocksFromSnapshot)
    final stockRows = await fetchCiterneStocksFromSnapshot(
      depotId: depotId,
      citerneId: citerneId,
      produitId: produitId,
    );

    // Récupérer les citernes pour obtenir capacite_totale, capacite_securite et noms
    final citerneIds = stockRows
        .map((r) => r['citerne_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final citernesMap = <String, Map<String, dynamic>>{};
    if (citerneIds.isNotEmpty) {
      final citernesQuery = _client
          .from('citernes')
          .select<List<Map<String, dynamic>>>(
            'id, nom, capacite_totale, capacite_securite, produit_id',
          )
          .in_('id', citerneIds);

      final citernesRows = await citernesQuery;
      for (final c in citernesRows) {
        final id = c['id'] as String?;
        if (id != null) {
          citernesMap[id] = c;
        }
      }
    }

    // Récupérer les produits pour obtenir les noms
    final produitIds = stockRows
        .map((r) => r['produit_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final produitsMap = <String, String>{};
    if (produitIds.isNotEmpty) {
      final produits =
          await _client.from('produits').select('id, nom').in_('id', produitIds)
              as List;
      for (final p in produits) {
        final id = p['id'] as String?;
        final nom = p['nom'] as String?;
        if (id != null && nom != null) {
          produitsMap[id] = nom;
        }
      }
    }

    // Mapper les stocks vers CiterneGlobalStockSnapshot
    final now = DateTime.now();
    return stockRows.map((m) {
      final map = Map<String, dynamic>.from(m);
      final citerneId = map['citerne_id'] as String?;
      final produitId = map['produit_id'] as String?;
      final citerneData = citernesMap[citerneId ?? ''];

      // Adapter les clés et enrichir avec les capacités
      // fetchCiterneStocksFromSnapshot retourne déjà stock_ambiant_total/stock_15c_total (agrégation Dart)
      map['stock_ambiant_total'] ??= map['stock_ambiant'] ?? 0.0;
      map['stock_15c_total'] ??= map['stock_15c'] ?? 0.0;
      // Utiliser updated_at si disponible, sinon date actuelle
      final dateStr = map['updated_at'] ?? map['date_jour'];
      map['date_jour'] = dateStr is String
          ? dateStr
          : (dateStr is DateTime
                ? dateStr.toIso8601String().split('T').first
                : now.toIso8601String().split('T').first);
      map['capacite_totale'] ??=
          (citerneData?['capacite_totale'] as num?)?.toDouble() ?? 0.0;
      map['capacite_securite'] ??=
          (citerneData?['capacite_securite'] as num?)?.toDouble() ?? 0.0;

      // S'assurer que citerne_nom et produit_nom sont présents
      map['citerne_nom'] ??= (citerneData?['nom'] as String?) ?? 'Citerne';
      map['produit_nom'] ??= produitsMap[produitId ?? ''] ?? '';

      return CiterneGlobalStockSnapshot.fromMap(map);
    }).toList();
  }

  /// [DEPRECATED] Alias de compatibilité pour fetchCiterneOwnerSnapshots.
  ///
  /// ⚠️ Cette méthode est maintenue uniquement pour compatibilité avec le code existant.
  /// SOURCE CANONIQUE — inclut adjustments (AXE A)
  /// Lit depuis v_stock_actuel et agrège côté Dart par (citerne, produit, propriétaire).
  ///
  /// [depotId] : Optionnel, filtre par dépôt (requis pour fetchStockActuelRows)
  /// [citerneId] : Optionnel, filtre par citerne (appliqué côté Dart)
  /// [produitId] : Optionnel, filtre par produit (peut être passé à fetchStockActuelRows)
  /// [proprietaireType] : Optionnel, filtre par propriétaire (appliqué côté Dart)
  /// [dateJour] : Ignoré (v_stock_actuel = toujours état actuel)
  ///
  /// Retourne : Liste de CiterneOwnerStockSnapshot avec l'état actuel par (citerne, produit, propriétaire)
  @Deprecated(
    'Utiliser les providers snapshot directement. Cette méthode est maintenue pour compatibilité.',
  )
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour, // Ignoré : v_stock_actuel = toujours état actuel
  }) async {
    if (depotId == null) {
      // Si pas de depotId, retourner liste vide (comportement conservé)
      return [];
    }

    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    final rows = await fetchStockActuelRows(
      depotId: depotId,
      produitId: produitId,
    );

    // Agréger par (citerne_id, produit_id, proprietaire_type)
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final row in rows) {
      final rowCiterneId = (row['citerne_id'] as String?) ?? '';
      final rowProduitId = (row['produit_id'] as String?) ?? '';
      final rowProprietaireType = (row['proprietaire_type'] as String?)?.toUpperCase().trim();

      // Filtrer par citerneId si fourni
      if (citerneId != null && rowCiterneId != citerneId) {
        continue;
      }
      // Filtrer par proprietaireType si fourni
      if (proprietaireType != null && rowProprietaireType != proprietaireType.toUpperCase().trim()) {
        continue;
      }
      // Ignorer les rows sans proprietaire_type
      if (rowProprietaireType == null || rowProprietaireType.isEmpty) {
        continue;
      }

      final key = '$rowCiterneId::$rowProduitId::$rowProprietaireType';

      final stockAmbiant = _toDouble(row['stock_ambiant'] ?? row['stock_ambiant_total'] ?? 0.0);
      final stock15c = _toDouble(row['stock_15c'] ?? row['stock_15c_total'] ?? 0.0);

      if (aggregated.containsKey(key)) {
        // Agrégation : additionner les volumes (normalement une seule ligne par clé dans v_stock_actuel)
        final current = aggregated[key]!;
        aggregated[key] = Map<String, dynamic>.from(current)
          ..['stock_ambiant_total'] = (_toDouble(current['stock_ambiant_total'] ?? 0.0) + stockAmbiant)
          ..['stock_15c_total'] = (_toDouble(current['stock_15c_total'] ?? 0.0) + stock15c);
      } else {
        // Utiliser updated_at ou date_jour pour dateJour
        final updatedAt = row['updated_at'] ?? row['date_jour'];
        final dateStr = updatedAt is String
            ? updatedAt
            : (updatedAt is DateTime
                ? updatedAt.toIso8601String().split('T').first
                : DateTime.now().toIso8601String().split('T').first);

        aggregated[key] = {
          'citerne_id': rowCiterneId,
          'citerne_nom': (row['citerne_nom'] as String?) ?? 'Citerne',
          'produit_id': rowProduitId,
          'produit_nom': (row['produit_nom'] as String?) ?? '',
          'proprietaire_type': rowProprietaireType,
          'date_jour': dateStr,
          'stock_ambiant_total': stockAmbiant,
          'stock_15c_total': stock15c,
        };
      }
    }

    // Convertir en liste de CiterneOwnerStockSnapshot
    return aggregated.values.map((map) {
      return CiterneOwnerStockSnapshot.fromMap(map);
    }).toList();
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

    double total = 0.0;
    for (final row in rows) {
      final capacite = row['capacite_totale'];
      if (capacite != null) {
        total += (capacite is num ? capacite.toDouble() : 0.0);
      }
    }

    return total;
  }
}

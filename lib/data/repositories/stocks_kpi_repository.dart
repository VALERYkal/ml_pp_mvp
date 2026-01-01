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
///   v_stock_actuel_owner_snapshot (snapshot état actuel)
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

  /// Helper pour formater une date en format ISO YYYY-MM-DD (UTC).
  String _formatYmd(DateTime date) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;
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
    return rows.map(DepotGlobalStockKpi.fromMap).toList();
  }

  /// Retourne les totaux par dépôt, propriétaire & produit.
  ///
  /// Utilisé pour le breakdown MONALUXE vs PARTENAIRE.
  /// ⚠️ [dateJour] est ignoré : v_stock_actuel_owner_snapshot = toujours état actuel.
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour, // Ignoré : snapshot = toujours état actuel
  }) async {
    // Utiliser v_stock_actuel_owner_snapshot (source de vérité snapshot actuel)
    final query = _client
        .from('v_stock_actuel_owner_snapshot')
        .select<List<Map<String, dynamic>>>();

    // Filtrer par depot_id (obligatoire pour éviter de charger tous les dépôts)
    if (depotId != null) {
      query.eq('depot_id', depotId);
    }
    if (produitId != null) {
      query.eq('produit_id', produitId);
    }
    if (proprietaireType != null) {
      query.eq('proprietaire_type', proprietaireType);
    }

    // Ordre déterministe : MONALUXE puis PARTENAIRE
    query.order('proprietaire_type', ascending: true);

    final rows = await query;
    // Cast sûr : rows peut être List<dynamic> avec items Map<String, dynamic>
    final list = (rows as List).cast<Map<String, dynamic>>();

    final result = list.map(DepotOwnerStockKpi.fromMap).toList();

    // Fallback safe : si résultat vide, retourner MONALUXE et PARTENAIRE avec 0.0
    if (result.isEmpty && depotId != null) {
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

  /// Récupère les stocks actuels par citerne depuis la vue snapshot.
  ///
  /// Cette méthode lit depuis v_stock_actuel_snapshot qui représente
  /// le dernier état connu de chaque citerne (tous propriétaires confondus).
  ///
  /// [depotId] : Optionnel, filtre par dépôt
  /// [citerneId] : Optionnel, filtre par citerne
  /// [produitId] : Optionnel, filtre par produit
  ///
  /// Retourne : Liste de Map contenant les données brutes de la vue SQL
  Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    final query = _client
        .from('v_stock_actuel_snapshot')
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

    // déterministe
    query.order('citerne_nom', ascending: true);

    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Récupère les stocks actuels par dépôt et propriétaire depuis la vue snapshot.
  ///
  /// Vue SQL : v_stock_actuel_owner_snapshot
  /// Colonnes attendues :
  ///   - depot_id, depot_nom
  ///   - produit_id, produit_nom
  ///   - proprietaire_type (MONALUXE ou PARTENAIRE)
  ///   - stock_ambiant_total (NUMERIC)
  ///   - stock_15c_total (NUMERIC)
  ///
  /// [depotId] : Identifiant du dépôt (requis)
  /// [produitId] : Optionnel, filtre par produit
  ///
  /// Retourne : Liste de Map contenant les données brutes de la vue SQL
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

    final query = _client
        .from('v_stock_actuel_owner_snapshot')
        .select<List<Map<String, dynamic>>>();

    query.eq('depot_id', depotId);

    if (produitId != null) {
      query.eq('produit_id', produitId);
    }

    // Ordre déterministe : MONALUXE puis PARTENAIRE
    query.order('proprietaire_type', ascending: true);

    final rows = await query;
    final result = (rows as List).cast<Map<String, dynamic>>();

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
  /// Utilise v_stock_actuel_snapshot comme source de vérité (ignore dateJour car snapshot = état actuel).
  ///
  /// [depotId] : Optionnel, filtre par dépôt
  /// [citerneId] : Optionnel, filtre par citerne
  /// [produitId] : Optionnel, filtre par produit
  /// [dateJour] : Ignoré (snapshot = toujours état actuel)
  ///
  /// Retourne : Liste de CiterneGlobalStockSnapshot mappée depuis v_stock_actuel_snapshot
  @Deprecated(
    'Utiliser fetchCiterneStocksFromSnapshot() directement. Cette méthode est maintenue pour compatibilité.',
  )
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour, // Ignoré : snapshot = toujours état actuel
  }) async {
    // Récupérer les stocks depuis v_stock_actuel_snapshot
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
      // v_stock_actuel_snapshot peut retourner stock_ambiant/stock_15c ou stock_ambiant_total/stock_15c_total
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
  /// Lit depuis stocks_journaliers pour obtenir les snapshots par citerne et propriétaire.
  ///
  /// [depotId] : Optionnel, filtre par dépôt
  /// [citerneId] : Optionnel, filtre par citerne
  /// [produitId] : Optionnel, filtre par produit
  /// [proprietaireType] : Optionnel, filtre par propriétaire
  /// [dateJour] : Ignoré (snapshot = toujours état actuel, utilise MAX(date_jour))
  ///
  /// Retourne : Liste de CiterneOwnerStockSnapshot avec le dernier état connu par (citerne, produit, propriétaire)
  @Deprecated(
    'Utiliser les providers snapshot directement. Cette méthode est maintenue pour compatibilité.',
  )
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour, // Ignoré : snapshot = toujours état actuel
  }) async {
    // Construire la requête pour obtenir le dernier stock par (citerne, produit, propriétaire)
    // On utilise une sous-requête pour obtenir le MAX(date_jour) puis on joint
    final query = _client
        .from('stocks_journaliers')
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

    // Trier par date_jour DESC pour obtenir les plus récents en premier
    query.order('date_jour', ascending: false);

    final allRows = await query;
    final rows = (allRows as List).cast<Map<String, dynamic>>();

    // Grouper par (citerne_id, produit_id, proprietaire_type) et prendre le premier (plus récent)
    final grouped = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final key =
          '${row['citerne_id']}::${row['produit_id']}::${row['proprietaire_type']}';
      if (!grouped.containsKey(key)) {
        grouped[key] = row;
      }
    }

    // Récupérer les noms des citernes et produits
    final citerneIds = grouped.values
        .map((r) => r['citerne_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    final produitIds = grouped.values
        .map((r) => r['produit_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final citernesMap = <String, String>{};
    if (citerneIds.isNotEmpty) {
      final citernes =
          await _client.from('citernes').select('id, nom').in_('id', citerneIds)
              as List;
      for (final c in citernes) {
        final id = c['id'] as String?;
        final nom = c['nom'] as String?;
        if (id != null && nom != null) {
          citernesMap[id] = nom;
        }
      }
    }

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

    // Mapper vers CiterneOwnerStockSnapshot
    return grouped.values.map((row) {
      final map = Map<String, dynamic>.from(row);
      final citerneId = map['citerne_id'] as String? ?? '';
      final produitId = map['produit_id'] as String? ?? '';

      map['citerne_nom'] = citernesMap[citerneId] ?? 'Citerne';
      map['produit_nom'] = produitsMap[produitId] ?? '';
      map['stock_ambiant_total'] = map['stock_ambiant'] ?? 0.0;
      map['stock_15c_total'] = map['stock_15c'] ?? 0.0;

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

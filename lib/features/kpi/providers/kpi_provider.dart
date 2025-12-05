import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_provider.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper de parsing robuste pour convertir num | String → double
/// Gère null, num, String avec virgules/points, et valeurs invalides
/// 
/// Formats supportés :
/// - "9954.5" (format US : point comme séparateur décimal)
/// - "9,954.5" (format US avec séparateur de milliers : virgule comme milliers, point comme décimal)
/// - "9.954,5" (format européen : point comme milliers, virgule comme décimal)
/// - " 9954.5 " (avec espaces, trimés)
double _toD(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return 0.0;
    
    // Supprimer les espaces (séparateurs de milliers possibles)
    final withoutSpaces = trimmed.replaceAll(' ', '');
    
    // Détecter le format : si on a à la fois des points et des virgules
    final hasComma = withoutSpaces.contains(',');
    final hasDot = withoutSpaces.contains('.');
    
    if (hasComma && hasDot) {
      // Format mixte : déterminer lequel est le séparateur décimal
      final lastComma = withoutSpaces.lastIndexOf(',');
      final lastDot = withoutSpaces.lastIndexOf('.');
      
      if (lastComma > lastDot) {
        // Format européen : "9.954,5" -> point = milliers, virgule = décimal
        final normalized = withoutSpaces.replaceAll('.', '').replaceAll(',', '.');
        return double.tryParse(normalized) ?? 0.0;
      } else {
        // Format US : "9,954.5" -> virgule = milliers, point = décimal
        final normalized = withoutSpaces.replaceAll(',', '');
        return double.tryParse(normalized) ?? 0.0;
      }
    } else if (hasComma) {
      // Seulement virgule : probablement format européen (virgule = décimal)
      final normalized = withoutSpaces.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    } else if (hasDot) {
      // Seulement point : format US (point = décimal) ou milliers uniquement
      // Si plusieurs points, c'est probablement des milliers
      final dotCount = '.'.allMatches(withoutSpaces).length;
      if (dotCount > 1) {
        // Plusieurs points = séparateurs de milliers, pas de décimales
        final normalized = withoutSpaces.replaceAll('.', '');
        return double.tryParse(normalized) ?? 0.0;
      } else {
        // Un seul point = séparateur décimal
        return double.tryParse(withoutSpaces) ?? 0.0;
      }
    } else {
      // Pas de séparateur, nombre entier
      return double.tryParse(withoutSpaces) ?? 0.0;
    }
  }
  return 0.0;
}

/// Fonction pure pour calculer les KPI Réceptions depuis des rows brutes
/// 
/// Cette fonction est 100% pure : pas de dépendance à Supabase, Riverpod, ou RLS.
/// Elle peut être testée isolément avec des données mockées.
/// 
/// RÈGLE MÉTIER :
/// - Pas de fallback automatique : si volume_15c est null, il reste à 0
/// - Les écarts entre volume_ambiant et volume_15c sont visibles dans le KPI
/// - Compte séparément les réceptions MONALUXE vs PARTENAIRE
KpiReceptions computeKpiReceptions(List<Map<String, dynamic>> rows) {
  var count = 0;
  var volumeAmbient = 0.0;
  var volume15c = 0.0;
  var countMonaluxe = 0;
  var countPartenaire = 0;

  for (final row in rows) {
    count++;

    // Mapping strict des volumes - NE JAMAIS utiliser volume_ambiant comme fallback pour volume_15c
    final vAmb = _toD(row['volume_ambiant']);
    final v15c = _toD(row['volume_corrige_15c'] ?? row['volume_15c']);

    volumeAmbient += vAmb;
    volume15c += v15c;

    // Comptage par type de propriétaire
    final proprietaireType = (row['proprietaire_type'] as String?)?.toUpperCase();
    if (proprietaireType == 'MONALUXE') {
      countMonaluxe++;
    } else if (proprietaireType == 'PARTENAIRE') {
      countPartenaire++;
    }
  }

  return KpiReceptions(
    count: count,
    volumeAmbient: volumeAmbient,
    volume15c: volume15c,
    countMonaluxe: countMonaluxe,
    countPartenaire: countPartenaire,
  );
}

/// Fonction pure pour calculer les KPI Sorties depuis des rows brutes
/// 
/// Cette fonction est 100% pure : pas de dépendance à Supabase, Riverpod, ou RLS.
/// Elle peut être testée isolément avec des données mockées.
/// 
/// RÈGLE MÉTIER :
/// - Pas de fallback automatique : si volume_15c est null, il reste à 0
/// - Les écarts entre volume_ambiant et volume_15c sont visibles dans le KPI
/// - Compte séparément les sorties MONALUXE vs PARTENAIRE
KpiSorties computeKpiSorties(List<Map<String, dynamic>> rows) {
  var count = 0;
  var volumeAmbient = 0.0;
  var volume15c = 0.0;
  var countMonaluxe = 0;
  var countPartenaire = 0;

  for (final row in rows) {
    count++;

    // Mapping strict des volumes - NE JAMAIS utiliser volume_ambiant comme fallback pour volume_15c
    // Priorité à volume_corrige_15c, sinon volume_15c, sinon 0
    final vAmb = _toD(row['volume_ambiant']);
    final v15c = _toD(row['volume_corrige_15c'] ?? row['volume_15c']);

    volumeAmbient += vAmb;
    volume15c += v15c;

    // Comptage par type de propriétaire (normalisé en uppercase)
    final proprietaireType = (row['proprietaire_type'] as String?)?.toUpperCase();
    if (proprietaireType == 'MONALUXE') {
      countMonaluxe++;
    } else if (proprietaireType == 'PARTENAIRE') {
      countPartenaire++;
    }
  }

  return KpiSorties(
    count: count,
    volumeAmbient: volumeAmbient,
    volume15c: volume15c,
    countMonaluxe: countMonaluxe,
    countPartenaire: countPartenaire,
  );
}

/// Type alias pour les rows brutes de réceptions
typedef ReceptionRow = Map<String, dynamic>;

/// Type alias pour les rows brutes de sorties
typedef SortieRow = Map<String, dynamic>;

/// Provider brut pour les réceptions du jour (rows brutes depuis Supabase)
/// 
/// Ce provider est overridable dans les tests pour injecter des données mockées
/// sans dépendre de Supabase ou de RLS.
/// 
/// Retourne les rows brutes avec les champs :
/// - volume_corrige_15c (ou volume_15c)
/// - volume_ambiant
/// - proprietaire_type (optionnel)
/// - id, date_reception, statut (pour debug)
Future<List<ReceptionRow>> _fetchReceptionsRawOfDay(
  SupabaseClient supa,
  String? depotId,
  DateTime today,
) async {
  // Formatage de la date pour la requête
  final dayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  
  print('🔍 DEBUG KPI: Recherche réceptions pour la date: $dayStr, depotId: $depotId');
  
  List result;
  
  if (depotId != null && depotId.isNotEmpty) {
    // Filtrage par dépôt via citernes (inner join)
    result = await supa
        .from('receptions')
        .select('id, volume_corrige_15c, volume_ambiant, proprietaire_type, date_reception, statut, citernes!inner(depot_id)')
        .eq('statut', 'validee')
        .eq('date_reception', dayStr)
        .eq('citernes.depot_id', depotId);
  } else {
    // Global - récupérer toutes les réceptions validées du jour
    result = await supa
        .from('receptions')
        .select('id, volume_corrige_15c, volume_ambiant, proprietaire_type, date_reception, statut')
        .eq('statut', 'validee')
        .eq('date_reception', dayStr);
  }
  
  print('🔍 DEBUG KPI: Nombre de réceptions trouvées: ${result.length}');
  
  return List<Map<String, dynamic>>.from(result);
}

/// Provider brut pour les réceptions du jour (rows brutes)
/// 
/// Ce provider peut être override dans les tests avec des données mockées.
final receptionsRawTodayProvider = FutureProvider.autoDispose<List<ReceptionRow>>((ref) async {
  final profil = await ref.watch(profilProvider.future);
  final depotId = profil?.depotId;
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  final supa = Supabase.instance.client;
  
  return _fetchReceptionsRawOfDay(supa, depotId, today);
});

/// Récupère les sorties du jour (rows brutes depuis Supabase)
/// 
/// Ce provider est overridable dans les tests pour injecter des données mockées
/// sans dépendre de Supabase ou de RLS.
/// 
/// Retourne les rows brutes avec les champs :
/// - volume_corrige_15c (ou volume_15c)
/// - volume_ambiant
/// - proprietaire_type (optionnel)
/// - id, date_sortie, statut (pour debug)
Future<List<SortieRow>> _fetchSortiesRawOfDay(
  SupabaseClient supa,
  String? depotId,
  DateTime today,
) async {
  final dayStart = today.toUtc().toIso8601String();
  final dayEnd = today.add(const Duration(days: 1)).toUtc().toIso8601String();
  
  print('🔍 DEBUG KPI: Recherche sorties pour la date: $dayStart -> $dayEnd, depotId: $depotId');
  
  List result;
  
  if (depotId != null && depotId.isNotEmpty) {
    // Filtrage par dépôt via citernes (inner join)
    result = await supa
        .from('sorties_produit')
        .select('id, volume_corrige_15c, volume_ambiant, proprietaire_type, date_sortie, statut, citernes!inner(depot_id)')
        .eq('statut', 'validee')
        .gte('date_sortie', dayStart)
        .lt('date_sortie', dayEnd)
        .eq('citernes.depot_id', depotId);
  } else {
    // Global - récupérer toutes les sorties validées du jour
    result = await supa
        .from('sorties_produit')
        .select('id, volume_corrige_15c, volume_ambiant, proprietaire_type, date_sortie, statut')
        .eq('statut', 'validee')
        .gte('date_sortie', dayStart)
        .lt('date_sortie', dayEnd);
  }
  
  print('🔍 DEBUG KPI: Nombre de sorties trouvées: ${result.length}');
  
  return List<Map<String, dynamic>>.from(result);
}

/// Provider brut pour les sorties du jour (rows brutes)
/// 
/// Ce provider peut être override dans les tests avec des données mockées.
final sortiesRawTodayProvider = FutureProvider.autoDispose<List<SortieRow>>((ref) async {
  final profil = await ref.watch(profilProvider.future);
  final depotId = profil?.depotId;
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);
  final supa = Supabase.instance.client;
  
  return _fetchSortiesRawOfDay(supa, depotId, today);
});

/// Provider unifié pour tous les KPIs du dashboard
/// 
/// Ce provider centralise toutes les données KPI nécessaires pour les dashboards
/// et applique automatiquement le filtrage par dépôt selon le profil utilisateur.
final kpiProviderProvider = FutureProvider.autoDispose<KpiSnapshot>((ref) async {
  try {
    print('🔍 DEBUG KPI Provider: Début de la récupération des données');
    // 1) Contexte utilisateur (RLS) : dépôt, propriétaire, etc.
    final profil = await ref.watch(profilProvider.future);
    final depotId = profil?.depotId; // null => global si rôle le permet
    final supa = Supabase.instance.client;
    
    print('🔍 DEBUG KPI Provider: depotId=$depotId');
    
    // 2) Calcul des dates pour les requêtes
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final from7d = today.subtract(const Duration(days: 6));
    
    // 3) Requêtes parallèles pour optimiser les performances
    // Utiliser les nouveaux providers pour les réceptions et sorties (retournent KpiReceptions et KpiSorties)
    final receptionsKpi = await ref.watch(receptionsKpiTodayProvider.future);
    final sortiesKpi = await ref.watch(sortiesKpiTodayProvider.future);
    
    final futures = await Future.wait([
      _fetchStocksActuels(supa, depotId),
      _fetchTrucksToFollow(supa, depotId),
      _fetchTrend7d(supa, depotId, from7d, today),
    ]);

    final stocks = futures[0] as _StocksData;
    final trucks = futures[1] as KpiTrucksToFollow;
    final trend7d = futures[2] as List<KpiTrendPoint>;
  
  // 4) Construction du snapshot unifié avec null-safety
  
  // Debug temporaire (peut être retiré ensuite)
  print('[KPI] receptions: 15C=${receptionsKpi.volume15c} | amb=${receptionsKpi.volumeAmbient} | count=${receptionsKpi.count} | monaluxe=${receptionsKpi.countMonaluxe} | partenaire=${receptionsKpi.countPartenaire}');
  print('[KPI Sorties] count=${sortiesKpi.count}, mona=${sortiesKpi.countMonaluxe}, part=${sortiesKpi.countPartenaire}, vol15c=${sortiesKpi.volume15c}');
  
  // Convertir KpiReceptions et KpiSorties en KpiNumberVolume pour KpiSnapshot (compatibilité)
  final receptionsKpiVolume = receptionsKpi.toKpiNumberVolume();
  final sortiesKpiVolume = sortiesKpi.toKpiNumberVolume();
  
  final stocksKpi = KpiStocks.fromNullable(
    totalAmbient: stocks.totalAmbient,
    total15c: stocks.total15c,
    capacityTotal: stocks.capacityTotal,
  );
  
  // Debug temporaire (peut être retiré ensuite)
  print('[KPI] stocks: 15C=${stocksKpi.total15c} | amb=${stocksKpi.totalAmbient} | cap=${stocksKpi.capacityTotal}');
  
  final balance = KpiBalanceToday.fromNullable(
    receptions15c: receptionsKpi.volume15c,
    sorties15c: sortiesKpi.volume15c,
    receptionsAmbient: receptionsKpi.volumeAmbient,
    sortiesAmbient: sortiesKpi.volumeAmbient,
  );
  
  print('🔍 DEBUG KPI: Balance calculée - receptions15c=${receptionsKpi.volume15c}, sorties15c=${sortiesKpi.volume15c}');
  print('🔍 DEBUG KPI: Balance calculée - receptionsAmbient=${receptionsKpi.volumeAmbient}, sortiesAmbient=${sortiesKpi.volumeAmbient}');
  print('🔍 DEBUG KPI: Balance finale - delta15c=${balance.delta15c}, deltaAmbient=${balance.deltaAmbient}');
  
    return KpiSnapshot(
      receptionsToday: receptionsKpiVolume,
      sortiesToday: sortiesKpiVolume,
      stocks: stocksKpi,
      balanceToday: balance,
      trucksToFollow: trucks,
      trend7d: trend7d,
    );
  } catch (e) {
    // En cas d'erreur, retourner un snapshot vide pour éviter les crashes
    return KpiSnapshot.empty;
  }
});

// ============================================================================
// FONCTIONS PRIVÉES DE RÉCUPÉRATION DES DONNÉES
// ============================================================================

/// Données temporaires pour les stocks
class _StocksData {
  final double totalAmbient;
  final double total15c;
  final double capacityTotal;
  
  _StocksData({
    required this.totalAmbient,
    required this.total15c,
    required this.capacityTotal,
  });
}

/// Récupère les stocks actuels
Future<_StocksData> _fetchStocksActuels(
  SupabaseClient supa,
  String? depotId,
) async {
  print('🔍 DEBUG KPI: Récupération des stocks actuels, depotId: $depotId');
  
  // 1) Si on filtre par dépôt => récupérer les citerne_id correspondants
  List<String>? citerneIds;
  if (depotId != null && depotId.isNotEmpty) {
    final citRows = await supa
        .from('citernes')
        .select('id')
        .eq('depot_id', depotId);
    citerneIds = (citRows as List).map((e) => e['id'] as String).toList();
    print('🔍 DEBUG KPI: Citernes trouvées pour le dépôt: ${citerneIds.length}');
    if (citerneIds.isEmpty) {
      return _StocksData(
        totalAmbient: 0.0,
        total15c: 0.0,
        capacityTotal: 0.0,
      );
    }
  }

  // 2) Charger la vue (une ligne par citerne = dernier stock)
  var stocksQuery = supa
      .from('v_citerne_stock_actuel')
      .select('citerne_id, stock_ambiant, stock_15c');

  if (citerneIds != null) {
    stocksQuery = stocksQuery.in_('citerne_id', citerneIds);
  }

  final stocksResult = await stocksQuery;
  print('🔍 DEBUG KPI: Stocks trouvés: ${stocksResult.length} citernes');
  
  // 3) Récupération des capacités des citernes
  var citernesQuery = supa.from('citernes').select('id, capacite_totale');
  
  if (citerneIds != null) {
    citernesQuery = citernesQuery.in_('id', citerneIds);
  }
  
  final citernesResult = await citernesQuery;
  
  // Création d'une map des capacités
  final capacities = <String, double>{};
  for (final row in citernesResult) {
    final id = row['id'] as String?;
    final cap = (row['capacite_totale'] as num?)?.toDouble() ?? 0.0;
    if (id != null) capacities[id] = cap;
  }
  
  double totalAmbient = 0.0;
  double total15c = 0.0;
  double capacityTotal = 0.0;
  
  for (final row in stocksResult) {
    final citerneId = row['citerne_id'] as String?;
    
    // Mapping strict des stocks - NE JAMAIS utiliser stock_ambiant comme fallback pour stock_15c
    final stockAmbient = _toD(row['stock_ambiant']);
    final stock15c = _toD(row['stock_15c']);
    
    print('🔍 DEBUG Stock Citerne $citerneId: stockAmbientRaw=${row['stock_ambiant']}, stock15cRaw=${row['stock_15c']}');
    print('🔍 DEBUG Stock Citerne $citerneId: stock_ambiant=$stockAmbient, stock_15c=$stock15c');
    
    if (citerneId != null) {
      totalAmbient += stockAmbient;
      total15c += stock15c;
      capacityTotal += capacities[citerneId] ?? 0.0;
    }
  }
  
  print('🔍 DEBUG FINAL Stocks: totalAmbient=$totalAmbient, total15c=$total15c, capacityTotal=$capacityTotal');
  
  return _StocksData(
    totalAmbient: totalAmbient,
    total15c: total15c,
    capacityTotal: capacityTotal,
  );
}

/// Récupère les camions à suivre
/// 
/// RÈGLE MÉTIER CDR (Cours de Route) :
/// - DECHARGE est EXCLU (cours terminé, déjà pris en charge dans Réceptions/Stocks)
/// - "Au chargement" = CHARGEMENT (camion chez le fournisseur)
/// - "En route" = TRANSIT + FRONTIERE (camions en transit)
/// - "Arrivés" = ARRIVE (camions arrivés au dépôt mais pas encore déchargés)
/// - totalCamionsASuivre = cours non déchargés (CHARGEMENT + TRANSIT + FRONTIERE + ARRIVE)
/// - volumeTotal = somme des volumes des cours non déchargés
Future<KpiTrucksToFollow> _fetchTrucksToFollow(
  SupabaseClient supa,
  String? depotId,
) async {
  print('🔍 DEBUG KPI: Récupération camions à suivre, depotId: $depotId');
  
  // Statuts à suivre - On exclut uniquement DECHARGE (cours terminé)
  const statutsNonDecharges = ['CHARGEMENT', 'TRANSIT', 'FRONTIERE', 'ARRIVE'];
  
  // Requête Supabase avec filtrage par statuts non déchargés
  var query = supa
      .from('cours_de_route')
      .select('id, volume, statut, depot_destination_id')
      .in_('statut', statutsNonDecharges);
  
  // Filtrage par dépôt si spécifié
  if (depotId != null && depotId.isNotEmpty) {
    query = query.eq('depot_destination_id', depotId);
  }
  
  final rows = await query;
  print('🔍 DEBUG KPI: ${rows.length} cours de route non déchargés trouvés');
  
  // Variables pour les 3 catégories
  int trucksLoading = 0;   // Au chargement
  int trucksOnRoute = 0;   // En route
  int trucksArrived = 0;   // Arrivés
  double volumeLoading = 0.0;
  double volumeOnRoute = 0.0;
  double volumeArrived = 0.0;
  
  for (final row in (rows as List)) {
    final rawStatut = (row['statut'] as String?)?.trim();
    if (rawStatut == null) continue;
    
    final statut = rawStatut.toUpperCase();
    final volume = _toD(row['volume']);
    
    // Classification par catégorie selon la règle métier
    if (statut == 'CHARGEMENT') {
      // Au chargement = camions chez le fournisseur
      trucksLoading++;
      volumeLoading += volume;
    } else if (statut == 'TRANSIT' || statut == 'FRONTIERE') {
      // En route = camions en transit (TRANSIT + FRONTIERE)
      trucksOnRoute++;
      volumeOnRoute += volume;
    } else if (statut == 'ARRIVE') {
      // Arrivés = camions arrivés au dépôt mais pas encore déchargés
      trucksArrived++;
      volumeArrived += volume;
    }
    // DECHARGE est exclu par le filtre .in_() ci-dessus
  }
  
  // Totaux
  final totalTrucks = trucksLoading + trucksOnRoute + trucksArrived;
  final totalPlannedVolume = volumeLoading + volumeOnRoute + volumeArrived;
  
  print('🔍 DEBUG KPI Camions: total=$totalTrucks, loading=$trucksLoading, onRoute=$trucksOnRoute, arrived=$trucksArrived');
  print('🔍 DEBUG KPI Volumes: total=${totalPlannedVolume}L, loading=${volumeLoading}L, onRoute=${volumeOnRoute}L, arrived=${volumeArrived}L');
  
  return KpiTrucksToFollow(
    totalTrucks: totalTrucks,
    totalPlannedVolume: totalPlannedVolume,
    trucksLoading: trucksLoading,
    trucksOnRoute: trucksOnRoute,
    trucksArrived: trucksArrived,
    volumeLoading: volumeLoading,
    volumeOnRoute: volumeOnRoute,
    volumeArrived: volumeArrived,
  );
}

/// Récupère les tendances sur 7 jours
Future<List<KpiTrendPoint>> _fetchTrend7d(
  SupabaseClient supa,
  String? depotId,
  DateTime from7d,
  DateTime today,
) async {
  // TODO: Implémenter la logique réelle des tendances 7 jours
  // Pour l'instant, retourner des données de test pour éviter les erreurs
  final points = <KpiTrendPoint>[];
  for (int i = 0; i < 7; i++) {
    final day = from7d.add(Duration(days: i));
    points.add(KpiTrendPoint(
      day: day,
      receptions15c: 1000.0 + (i * 100), // Données de test
      sorties15c: 800.0 + (i * 50),     // Données de test
    ));
  }
  return points;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper de parsing robuste pour convertir num | String → double
/// Gère null, num, String avec virgules/points, et valeurs invalides
double _toD(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.')) ?? 0.0;
  return 0.0;
}

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
    // Utiliser le nouveau provider pour les réceptions
    final receptionsKpi = await ref.watch(receptionsKpiTodayProvider.future);
    
    final futures = await Future.wait([
      _fetchSortiesOfDay(supa, depotId, today),
      _fetchStocksActuels(supa, depotId),
      _fetchTrucksToFollow(supa, depotId),
      _fetchTrend7d(supa, depotId, from7d, today),
    ]);

    final sorties = futures[0] as _SortiesData;
    final stocks = futures[1] as _StocksData;
    final trucks = futures[2] as KpiTrucksToFollow;
    final trend7d = futures[3] as List<KpiTrendPoint>;
  
  // 4) Construction du snapshot unifié avec null-safety
  
  // Debug temporaire (peut être retiré ensuite)
  print('[KPI] receptions: 15C=${receptionsKpi.volume15c} | amb=${receptionsKpi.volumeAmbient} | count=${receptionsKpi.count}');
  
  final sortiesKpi = KpiNumberVolume.fromNullable(
    count: sorties.count,
    volume15c: sorties.volume15c,
    volumeAmbient: sorties.volumeAmbient,
  );
  
  final stocksKpi = KpiStocks.fromNullable(
    totalAmbient: stocks.totalAmbient,
    total15c: stocks.total15c,
    capacityTotal: stocks.capacityTotal,
  );
  
  // Debug temporaire (peut être retiré ensuite)
  print('[KPI] stocks: 15C=${stocksKpi.total15c} | amb=${stocksKpi.totalAmbient} | cap=${stocksKpi.capacityTotal}');
  
  final balance = KpiBalanceToday.fromNullable(
    receptions15c: receptionsKpi.volume15c,
    sorties15c: sorties.volume15c,
    receptionsAmbient: receptionsKpi.volumeAmbient,
    sortiesAmbient: sorties.volumeAmbient,
  );
  
  print('🔍 DEBUG KPI: Balance calculée - receptions15c=${receptionsKpi.volume15c}, sorties15c=${sorties.volume15c}');
  print('🔍 DEBUG KPI: Balance calculée - receptionsAmbient=${receptionsKpi.volumeAmbient}, sortiesAmbient=${sorties.volumeAmbient}');
  print('🔍 DEBUG KPI: Balance finale - delta15c=${balance.delta15c}, deltaAmbient=${balance.deltaAmbient}');
  
    return KpiSnapshot(
      receptionsToday: receptionsKpi,
      sortiesToday: sortiesKpi,
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

/// Données temporaires pour les réceptions
class _ReceptionsData {
  final int count;
  final double volume15c;
  final double volumeAmbient;
  
  _ReceptionsData({
    required this.count,
    required this.volume15c,
    required this.volumeAmbient,
  });
}

/// Données temporaires pour les sorties
class _SortiesData {
  final int count;
  final double volume15c;
  final double volumeAmbient;
  
  _SortiesData({
    required this.count,
    required this.volume15c,
    required this.volumeAmbient,
  });
}

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

/// Récupère les réceptions du jour
Future<_ReceptionsData> _fetchReceptionsOfDay(
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
        .select('id, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)')
        .eq('statut', 'validee')
        .eq('date_reception', dayStr)
        .eq('citernes.depot_id', depotId);
  } else {
    // Global - récupérer toutes les réceptions validées du jour
    result = await supa
        .from('receptions')
        .select('id, volume_corrige_15c, volume_ambiant, date_reception, statut')
        .eq('statut', 'validee')
        .eq('date_reception', dayStr);
  }
  
  print('🔍 DEBUG KPI: Nombre de réceptions trouvées: ${result.length}');
  
  int count = 0;
  double volume15c = 0.0;
  double volumeAmbient = 0.0;
  
  for (final row in result) {
    count++;
    
    // Mapping strict des volumes - NE JAMAIS utiliser volume_ambiant comme fallback pour volume_corrige_15c
    final v15 = _toD(row['volume_corrige_15c']);
    final va = _toD(row['volume_ambiant']);
    
    volume15c += v15;
    volumeAmbient += va;
    
    // Debug détaillé pour chaque réception
    print('🔍 DEBUG Réception $count: v15Raw=${row['volume_corrige_15c']}, vaRaw=${row['volume_ambiant']}');
    print('🔍 DEBUG Réception $count: v15=$v15, va=$va, total15c=$volume15c, totalAmbient=$volumeAmbient');
    print('🔍 DEBUG Réception $count: date=${row['date_reception']}, statut=${row['statut']}');
  }
  
  print('🔍 DEBUG FINAL Réceptions du jour: count=$count, volume15c=$volume15c, volumeAmbient=$volumeAmbient');
  
  return _ReceptionsData(
    count: count,
    volume15c: volume15c,
    volumeAmbient: volumeAmbient,
  );
}

/// Récupère les sorties du jour
Future<_SortiesData> _fetchSortiesOfDay(
  SupabaseClient supa,
  String? depotId,
  DateTime today,
) async {
  final dayStart = today.toUtc().toIso8601String();
  final dayEnd = today.add(const Duration(days: 1)).toUtc().toIso8601String();
  
  List result;
  
  if (depotId != null && depotId.isNotEmpty) {
    // Filtrage par dépôt via citernes (inner join)
    result = await supa
        .from('sorties_produit')
        .select('id, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)')
        .eq('statut', 'validee')
        .gte('date_sortie', dayStart)
        .lt('date_sortie', dayEnd)
        .eq('citernes.depot_id', depotId);
  } else {
    // Global
    result = await supa
        .from('sorties_produit')
        .select('id, volume_corrige_15c, volume_ambiant')
        .eq('statut', 'validee')
        .gte('date_sortie', dayStart)
        .lt('date_sortie', dayEnd);
  }
  
  int count = 0;
  double volume15c = 0.0;
  double volumeAmbient = 0.0;
  
  for (final row in result) {
    count++;
    
    // Mapping strict des volumes - NE JAMAIS utiliser volume_ambiant comme fallback pour volume_corrige_15c
    final v15 = _toD(row['volume_corrige_15c']);
    final va = _toD(row['volume_ambiant']);
    
    volume15c += v15;
    volumeAmbient += va;
    
    // Debug pour les sorties
    print('🔍 DEBUG Sortie $count: v15Raw=${row['volume_corrige_15c']}, vaRaw=${row['volume_ambiant']}');
    print('🔍 DEBUG Sortie $count: v15=$v15, va=$va, total15c=$volume15c, totalAmbient=$volumeAmbient');
  }
  
  return _SortiesData(
    count: count,
    volume15c: volume15c,
    volumeAmbient: volumeAmbient,
  );
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

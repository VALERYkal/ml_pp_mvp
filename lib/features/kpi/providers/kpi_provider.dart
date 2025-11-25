import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper de parsing robuste pour convertir num | String ? double
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
final kpiProviderProvider = FutureProvider.autoDispose<KpiSnapshot>((
  ref,
) async {
  try {
    print('?? DEBUG KPI Provider: Début de la récupération des données');
    // 1) Contexte utilisateur (RLS) : dépôt, propriétaire, etc.
    final profil = await ref.watch(profilProvider.future);
    final depotId = profil?.depotId; // null => global si rôle le permet
    final supa = Supabase.instance.client;

    print('?? DEBUG KPI Provider: depotId=$depotId');

    // 2) Calcul des dates pour les requêtes
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final from7d = today.subtract(const Duration(days: 6));

    // 3) Requêtes parallèles pour optimiser les performances
    final futures = await Future.wait([
      _fetchReceptionsOfDay(supa, depotId, today),
      _fetchSortiesOfDay(supa, depotId, today),
      _fetchStocksActuels(supa, depotId),
      _fetchTrucksToFollow(supa, depotId),
      _fetchTrend7d(supa, depotId, from7d, today),
    ]);

    final receptions = futures[0] as _ReceptionsData;
    final sorties = futures[1] as _SortiesData;
    final stocks = futures[2] as _StocksData;
    final trucks = futures[3] as KpiTrucksToFollow;
    final trend7d = futures[4] as List<KpiTrendPoint>;

    // 4) Construction du snapshot unifié avec null-safety
    final receptionsKpi = KpiNumberVolume.fromNullable(
      count: receptions.count,
      volume15c: receptions.volume15c,
      volumeAmbient: receptions.volumeAmbient,
    );

    // Debug temporaire (peut être retiré ensuite)
    print(
      '[KPI] receptions: 15C=${receptionsKpi.volume15c} | amb=${receptionsKpi.volumeAmbient} | count=${receptionsKpi.count}',
    );

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
    print(
      '[KPI] stocks: 15C=${stocksKpi.total15c} | amb=${stocksKpi.totalAmbient} | cap=${stocksKpi.capacityTotal}',
    );

    final balance = KpiBalanceToday.fromNullable(
      receptions15c: receptions.volume15c,
      sorties15c: sorties.volume15c,
      receptionsAmbient: receptions.volumeAmbient,
      sortiesAmbient: sorties.volumeAmbient,
    );

    print(
      '?? DEBUG KPI: Balance calculée - receptions15c=${receptions.volume15c}, sorties15c=${sorties.volume15c}',
    );
    print(
      '?? DEBUG KPI: Balance calculée - receptionsAmbient=${receptions.volumeAmbient}, sortiesAmbient=${sorties.volumeAmbient}',
    );
    print(
      '?? DEBUG KPI: Balance finale - delta15c=${balance.delta15c}, deltaAmbient=${balance.deltaAmbient}',
    );

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
  final dayStr =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  print(
    '?? DEBUG KPI: Recherche réceptions pour la date: $dayStr, depotId: $depotId',
  );

  List result;

  if (depotId != null && depotId.isNotEmpty) {
    // Filtrage par dépôt via citernes (inner join)
    result = await supa
        .from('receptions')
        .select(
          'id, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)',
        )
        .eq('statut', 'validee')
        .eq('date_reception', dayStr)
        .eq('citernes.depot_id', depotId);
  } else {
    // Global - récupérer toutes les réceptions validées du jour
    result = await supa
        .from('receptions')
        .select(
          'id, volume_corrige_15c, volume_ambiant, date_reception, statut',
        )
        .eq('statut', 'validee')
        .eq('date_reception', dayStr);
  }

  print('?? DEBUG KPI: Nombre de réceptions trouvées: ${result.length}');

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
    print(
      '?? DEBUG Réception $count: v15Raw=${row['volume_corrige_15c']}, vaRaw=${row['volume_ambiant']}',
    );
    print(
      '?? DEBUG Réception $count: v15=$v15, va=$va, total15c=$volume15c, totalAmbient=$volumeAmbient',
    );
    print(
      '?? DEBUG Réception $count: date=${row['date_reception']}, statut=${row['statut']}',
    );
  }

  print(
    '?? DEBUG FINAL Réceptions du jour: count=$count, volume15c=$volume15c, volumeAmbient=$volumeAmbient',
  );

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
        .select(
          'id, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)',
        )
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
    print(
      '?? DEBUG Sortie $count: v15Raw=${row['volume_corrige_15c']}, vaRaw=${row['volume_ambiant']}',
    );
    print(
      '?? DEBUG Sortie $count: v15=$v15, va=$va, total15c=$volume15c, totalAmbient=$volumeAmbient',
    );
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
  print('?? DEBUG KPI: Récupération des stocks actuels, depotId: $depotId');

  // 1) Si on filtre par dépôt => récupérer les citerne_id correspondants
  List<String>? citerneIds;
  if (depotId != null && depotId.isNotEmpty) {
    final citRows = await supa
        .from('citernes')
        .select('id')
        .eq('depot_id', depotId);
    citerneIds = (citRows as List).map((e) => e['id'] as String).toList();
    print(
      '?? DEBUG KPI: Citernes trouvées pour le dépôt: ${citerneIds.length}',
    );
    if (citerneIds.isEmpty) {
      return _StocksData(totalAmbient: 0.0, total15c: 0.0, capacityTotal: 0.0);
    }
  }

  // 2) Charger la vue (une ligne par citerne = dernier stock)
  var stocksQuery = supa
      .from('v_citerne_stock_actuel')
      .select('citerne_id, stock_ambiant, stock_15c');

  if (citerneIds != null) {
    stocksQuery = stocksQuery.inFilter('citerne_id', citerneIds);
  }

  final stocksResult = await stocksQuery;
  print('?? DEBUG KPI: Stocks trouvés: ${stocksResult.length} citernes');

  // 3) Récupération des capacités des citernes
  var citernesQuery = supa.from('citernes').select('id, capacite_totale');

  if (citerneIds != null) {
    citernesQuery = citernesQuery.inFilter('id', citerneIds);
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

    print(
      '?? DEBUG Stock Citerne $citerneId: stockAmbientRaw=${row['stock_ambiant']}, stock15cRaw=${row['stock_15c']}',
    );
    print(
      '?? DEBUG Stock Citerne $citerneId: stock_ambiant=$stockAmbient, stock_15c=$stock15c',
    );

    if (citerneId != null) {
      totalAmbient += stockAmbient;
      total15c += stock15c;
      capacityTotal += capacities[citerneId] ?? 0.0;
    }
  }

  print(
    '?? DEBUG FINAL Stocks: totalAmbient=$totalAmbient, total15c=$total15c, capacityTotal=$capacityTotal',
  );

  return _StocksData(
    totalAmbient: totalAmbient,
    total15c: total15c,
    capacityTotal: capacityTotal,
  );
}

/// Récupère les camions à suivre
Future<KpiTrucksToFollow> _fetchTrucksToFollow(
  SupabaseClient supa,
  String? depotId,
) async {
  final query = supa
      .from('cours_de_route')
      .select('statut, volume, depot_destination_id');

  if (depotId != null && depotId.isNotEmpty) {
    query.eq('depot_destination_id', depotId);
  }

  final rows = await query;

  int trucksEnRoute = 0;
  int trucksEnAttente = 0;
  double volumeEnRoute = 0.0;
  double volumeEnAttente = 0.0;

  for (final row in rows as List) {
    final statut = (row['statut'] as String?)?.toUpperCase();
    final volume = (row['volume'] as num?)?.toDouble() ?? 0.0;

    if (statut == null) continue;

    if (statut == 'CHARGEMENT' ||
        statut == 'TRANSIT' ||
        statut == 'FRONTIERE') {
      trucksEnRoute++;
      volumeEnRoute += volume;
    } else if (statut == 'ARRIVE') {
      trucksEnAttente++;
      volumeEnAttente += volume;
    }
  }

  final totalTrucks = trucksEnRoute + trucksEnAttente;
  final totalPlannedVolume = volumeEnRoute + volumeEnAttente;

  return KpiTrucksToFollow(
    totalTrucks: totalTrucks,
    totalPlannedVolume: totalPlannedVolume,
    trucksEnRoute: trucksEnRoute,
    trucksEnAttente: trucksEnAttente,
    volumeEnRoute: volumeEnRoute,
    volumeEnAttente: volumeEnAttente,
  );
}

/// Récupère les tendances sur 7 jours
Future<List<KpiTrendPoint>> _fetchTrend7d(
  SupabaseClient supa,
  String? depotId,
  DateTime from7d,
  DateTime today,
) async {
  final points = <KpiTrendPoint>[];
  for (int i = 0; i < 7; i++) {
    final day = from7d.add(Duration(days: i));

    final receptions = await _fetchReceptionsOfDay(supa, depotId, day);
    final sorties = await _fetchSortiesOfDay(supa, depotId, day);

    points.add(
      KpiTrendPoint(
        day: day,
        receptions15c: receptions.volume15c,
        sorties15c: sorties.volume15c,
      ),
    );
  }
  return points;
}


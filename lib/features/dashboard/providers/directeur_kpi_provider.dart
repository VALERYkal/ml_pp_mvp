// ⚠️ DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DirecteurKpiData {
  final int receptionsJour;
  final int sortiesJour;
  final int citernesSousSeuil;
  final int totalCiternes;
  final double ratioUtilisation; // 0..1
  final double
  volumeTotalReceptions; // unité = ce que tu affiches (v15 si dispo, sinon ambiant)
  final double volumeTotalSorties;
  const DirecteurKpiData({
    required this.receptionsJour,
    required this.sortiesJour,
    required this.citernesSousSeuil,
    required this.totalCiternes,
    required this.ratioUtilisation,
    required this.volumeTotalReceptions,
    required this.volumeTotalSorties,
  });
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _isoUtc(DateTime d) =>
    d.toUtc().toIso8601String().split('.').first + 'Z';

/// Provider legacy pour les KPIs Directeur
///
/// ⚠️ NOTE : Ce provider utilise DateTime.now().toUtc() pour calculer la date du jour.
/// Pour les KPI "du jour" du dashboard principal, utiliser kpiProviderProvider qui utilise la date métier locale.
final directeurKpiProvider = FutureProvider<DirecteurKpiData>((ref) async {
  final supa = Supabase.instance.client;
  // LEGACY: Utilise UTC système (peut être corrigé dans une tâche séparée)
  final now = DateTime.now().toUtc();
  final dayStart = DateTime.utc(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  // Réceptions du jour (DATE)
  final recs = await supa
      .from('receptions')
      .select('id, volume_corrige_15c, volume_ambiant')
      .eq('statut', 'validee')
      .eq('date_reception', _ymd(dayStart));

  // Sorties du jour (TIMESTAMPTZ)
  final sorties = await supa
      .from('sorties_produit')
      .select('id, volume_corrige_15c, volume_ambiant')
      .eq('statut', 'validee')
      .gte('date_sortie', _isoUtc(dayStart))
      .lt('date_sortie', _isoUtc(dayEnd));

  double sumReceptions = 0.0;
  for (final m in (recs as List)) {
    final v15 = (m['volume_corrige_15c'] as num?)?.toDouble();
    final va = (m['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
    sumReceptions += (v15 ?? va);
  }

  double sumSorties = 0.0;
  for (final m in (sorties as List)) {
    final v15 = (m['volume_corrige_15c'] as num?)?.toDouble();
    final va = (m['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
    sumSorties += (v15 ?? va);
  }

  // Citernes & stocks actuels
  final citernes = await supa
      .from('citernes')
      .select('id, capacite_totale, capacite_securite');

  final latest = await supa
      .from('v_citerne_stock_snapshot_agg')
      .select('citerne_id, stock_ambiant_total');

  final stockByCiterne = <String, double>{};
  for (final m in (latest as List)) {
    final id = m['citerne_id'] as String?;
    final stock = (m['stock_ambiant_total'] as num?)?.toDouble() ?? 0.0;
    if (id != null) stockByCiterne[id] = stock;
  }

  double totalStock = 0.0;
  double totalCapacite = 0.0;
  int nbSousSeuil = 0;

  for (final c in (citernes as List)) {
    final id = c['id'] as String?;
    if (id == null) continue;
    final stock = stockByCiterne[id] ?? 0.0;
    final cap = (c['capacite_totale'] as num?)?.toDouble() ?? 0.0;
    final seuil = (c['capacite_securite'] as num?)?.toDouble() ?? 0.0;

    totalStock += stock;
    totalCapacite += cap;
    if (stock < seuil) nbSousSeuil++;
  }

  final totalCit = (citernes as List).length;
  final ratio = totalCapacite > 0 ? (totalStock / totalCapacite) : 0.0;

  return DirecteurKpiData(
    receptionsJour: (recs as List).length,
    sortiesJour: (sorties as List).length,
    citernesSousSeuil: nbSousSeuil,
    totalCiternes: totalCit,
    ratioUtilisation: ratio,
    volumeTotalReceptions: sumReceptions,
    volumeTotalSorties: sumSorties,
  );
});

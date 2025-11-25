// ?? DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminKpis {
  final int erreurs24h;
  final int receptionsJour;
  final int sortiesJour;
  final int citernesSousSeuil;
  final int produitsActifs;
  const AdminKpis({
    required this.erreurs24h,
    required this.receptionsJour,
    required this.sortiesJour,
    required this.citernesSousSeuil,
    required this.produitsActifs,
  });
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _isoUtc(DateTime d) =>
    d.toUtc().toIso8601String().split('.').first + 'Z';

final adminKpiProvider = FutureProvider<AdminKpis>((ref) async {
  final supa = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final dayStart = DateTime.utc(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final last24h = now.subtract(const Duration(hours: 24));

  // 1) logs 24h (vue de compat)
  final logsErr = await supa
      .from('logs')
      .select('id')
      .gte('created_at', _isoUtc(last24h));

  // 2) réceptions du jour (DATE)
  final recs = await supa
      .from('receptions')
      .select('id')
      .eq('statut', 'validee')
      .eq('date_reception', _ymd(dayStart));

  // 3) sorties du jour (TIMESTAMPTZ)
  final sorties = await supa
      .from('sorties_produit')
      .select('id')
      .eq('statut', 'validee')
      .gte('date_sortie', _isoUtc(dayStart))
      .lt('date_sortie', _isoUtc(dayEnd));

  // 4) citernes sous seuil
  final citernes = await supa.from('citernes').select('id,capacite_securite');

  final latest = await supa
      .from('v_citerne_stock_actuel')
      .select('citerne_id,stock_ambiant');

  final stockByCiterne = <String, double>{};
  for (final m in (latest as List)) {
    final id = m['citerne_id'] as String?;
    final stock = (m['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
    if (id != null) stockByCiterne[id] = stock;
  }

  int nbCitSousSeuil = 0;
  for (final m in (citernes as List)) {
    final id = m['id'] as String?;
    final seuil = (m['capacite_securite'] as num?)?.toDouble() ?? 0.0;
    if (id == null) continue;
    final stock = stockByCiterne[id] ?? 0.0;
    if (stock < seuil) nbCitSousSeuil++;
  }

  // 5) produits actifs
  final produitsActifs = await supa
      .from('produits')
      .select('id')
      .eq('actif', true);

  return AdminKpis(
    erreurs24h: (logsErr as List).length,
    receptionsJour: (recs as List).length,
    sortiesJour: (sorties as List).length,
    citernesSousSeuil: nbCitSousSeuil,
    produitsActifs: (produitsActifs as List).length,
  );
});


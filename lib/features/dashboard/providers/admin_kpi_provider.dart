// ⚠️ DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/stocks_kpi_repository.dart';
import '../../profil/providers/profil_provider.dart';

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

/// Provider legacy pour les KPIs Admin
///
/// ⚠️ NOTE : Ce provider utilise DateTime.now().toUtc() pour calculer la date du jour.
/// Pour les KPI "du jour" du dashboard principal, utiliser kpiProviderProvider qui utilise la date métier locale.
final adminKpiProvider = FutureProvider<AdminKpis>((ref) async {
  final supa = Supabase.instance.client;
  // LEGACY: Utilise UTC système (peut être corrigé dans une tâche séparée)
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
  // SOURCE CANONIQUE — inclut adjustments (AXE A)
  // Récupérer le depotId depuis le profil
  final profil = ref.watch(profilProvider).valueOrNull;
  final depotId = profil?.depotId;
  int nbCitSousSeuil = 0;
  if (depotId != null) {
    final repo = StocksKpiRepository(supa);
    // Récupérer les stocks depuis v_stock_actuel
    final stockRows = await repo.fetchStockActuelRows(depotId: depotId);
    // Agréger par citerne_id (somme de tous les propriétaires)
    final stockByCiterne = <String, double>{};
    for (final row in stockRows) {
      final citerneId = (row['citerne_id'] as String?) ?? '';
      if (citerneId.isEmpty) continue;
      final stockAmbiant = (row['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
      stockByCiterne[citerneId] = (stockByCiterne[citerneId] ?? 0.0) + stockAmbiant;
    }
    // Récupérer les citernes du dépôt avec leurs seuils
    final citernes = await supa
        .from('citernes')
        .select('id, capacite_securite')
        .eq('depot_id', depotId);
    for (final m in (citernes as List)) {
      final id = (m['id'] as String?) ?? '';
      if (id.isEmpty) continue;
      final seuil = (m['capacite_securite'] as num?)?.toDouble() ?? 0.0;
      final stock = stockByCiterne[id] ?? 0.0;
      if (stock < seuil) nbCitSousSeuil++;
    }
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

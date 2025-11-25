import 'package:supabase_flutter/supabase_flutter.dart';

class StocksTotals {
  final double totalAmbiant;
  final double total15c;
  final DateTime? lastDay;
  const StocksTotals({required this.totalAmbiant, required this.total15c, required this.lastDay});
}

class StocksRepository {
  final SupabaseClient _supa;
  StocksRepository(this._supa);

  /// Somme des stocks actuels depuis la vue v_citerne_stock_actuel.
  /// - Si [depotId] est renseigné, on filtre via les citernes du dépôt.
  /// - [produitId] optionnel (pour réutilisation ultérieure).
  Future<StocksTotals> totauxActuels({String? depotId, String? produitId}) async {
    // 1) Si on filtre par dépôt => récupérer les citerne_id correspondants
    List<String>? citerneIds;
    if (depotId != null && depotId.isNotEmpty) {
      final citRows = await _supa.from('citernes').select('id').eq('depot_id', depotId);
      citerneIds = (citRows as List).map((e) => e['id'] as String).toList();
      if (citerneIds.isEmpty) {
        return const StocksTotals(totalAmbiant: 0, total15c: 0, lastDay: null);
      }
    }

    // 2) Charger la vue (une ligne par citerne = dernier stock)
    final sel = _supa
        .from('v_citerne_stock_actuel')
        .select('citerne_id, produit_id, stock_ambiant, stock_15c, date_jour');

    if (citerneIds != null) {
      sel.inFilter('citerne_id', citerneIds);
    }
    if (produitId != null && produitId.isNotEmpty) {
      sel.eq('produit_id', produitId);
    }

    final rows = await sel;

    double amb = 0.0, s15 = 0.0;
    DateTime? lastDay;
    for (final m in (rows as List)) {
      amb += (m['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
      s15 += (m['stock_15c'] as num?)?.toDouble() ?? 0.0;

      final dj = m['date_jour'];
      if (dj != null) {
        final d = DateTime.parse(dj.toString());
        if (lastDay == null || d.isAfter(lastDay)) lastDay = d;
      }
    }

    // Debug (retirable)
    // ignore: avoid_print
    print(
      '?? KPI3 stocks: amb=$amb, 15c=$s15, lastDay=$lastDay'
      '${depotId != null ? ' depot=' + depotId : ''}${produitId != null ? ' produit=' + produitId : ''}',
    );

    return StocksTotals(totalAmbiant: amb, total15c: s15, lastDay: lastDay);
  }
}





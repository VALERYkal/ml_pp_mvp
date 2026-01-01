import 'package:supabase_flutter/supabase_flutter.dart';

class StocksTotals {
  final double totalAmbiant;
  final double total15c;
  final DateTime? lastDay;
  const StocksTotals({
    required this.totalAmbiant,
    required this.total15c,
    required this.lastDay,
  });
}

class StocksRepository {
  final SupabaseClient _supa;
  StocksRepository(this._supa);

  /// Somme des stocks actuels depuis la vue v_stock_actuel (source de vérité canonique).
  /// - Si [depotId] est renseigné, on filtre via les citernes du dépôt.
  /// - [produitId] optionnel (pour réutilisation ultérieure).
  ///
  /// La vue v_stock_actuel inclut automatiquement :
  /// - réceptions validées
  /// - sorties validées
  /// - ajustements (stocks_adjustments)
  Future<StocksTotals> totauxActuels({
    String? depotId,
    String? produitId,
  }) async {
    // SOURCE CANONIQUE — inclut adjustments (AXE A)
    // Charger depuis v_stock_actuel (une ligne par citerne/produit/propriétaire)
    final sel = _supa
        .from('v_stock_actuel')
        .select('citerne_id, produit_id, stock_ambiant, stock_15c, updated_at');

    if (depotId != null && depotId.isNotEmpty) {
      sel.eq('depot_id', depotId);
    }
    if (produitId != null && produitId.isNotEmpty) {
      sel.eq('produit_id', produitId);
    }

    final rows = await sel;

    // Agréger les volumes (somme de toutes les lignes)
    double amb = 0.0, s15 = 0.0;
    DateTime? lastDay;
    for (final m in (rows as List)) {
      amb += (m['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
      s15 += (m['stock_15c'] as num?)?.toDouble() ?? 0.0;

      final updatedAt = m['updated_at'];
      if (updatedAt != null) {
        final d = DateTime.parse(updatedAt.toString());
        if (lastDay == null || d.isAfter(lastDay)) lastDay = d;
      }
    }

    // Debug (retirable)
    // ignore: avoid_print
    print(
      '📦 KPI3 stocks: amb=$amb, 15c=$s15, lastDay=$lastDay'
      '${depotId != null ? ' depot=$depotId' : ''}${produitId != null ? ' produit=$produitId' : ''}',
    );

    return StocksTotals(totalAmbiant: amb, total15c: s15, lastDay: lastDay);
  }
}

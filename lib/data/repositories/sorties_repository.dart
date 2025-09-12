import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SortiesStats {
  final int nbCamions;
  final double volAmbiant;
  final double vol15c;
  const SortiesStats({
    required this.nbCamions,
    required this.volAmbiant,
    required this.vol15c,
  });
}

class SortiesRepository {
  final SupabaseClient _supa;
  SortiesRepository(this._supa);

  /// Stats du jour local (fenêtre [startUtcIso, endUtcIso[ en UTC).
  /// Filtre par 'statut = validee'. Option: filtre par dépôt via citernes.depot_id.
  Future<SortiesStats> statsJour({
    required String startUtcIso,
    required String endUtcIso,
    String? depotId,
  }) async {
    // colonnes communes
    String baseCols = 'id, statut, volume_ambiant, volume_corrige_15c, date_sortie';
    var query = _supa.from('sorties_produit').select(baseCols);

    // join citernes si filtre dépôt
    if (depotId != null && depotId.isNotEmpty) {
      query = _supa.from('sorties_produit')
          .select('$baseCols, citernes!inner(depot_id)')
          .eq('citernes.depot_id', depotId);
    }

    final rows = await query
        .eq('statut', 'validee')
        .gte('date_sortie', startUtcIso)
        .lt('date_sortie', endUtcIso);

    int count = 0;
    double sAmb = 0, s15 = 0;
    for (final m in (rows as List)) {
      count++;
      sAmb += (m['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
      s15  += (m['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('📤 Sorties(jour) ${depotId!=null?'depot=$depotId ':''}'
            '>= $startUtcIso < $endUtcIso  => nb=$count, amb=$sAmb, 15C=$s15');
    }

    return SortiesStats(nbCamions: count, volAmbiant: sAmb, vol15c: s15);
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceptionsRepository {
  final SupabaseClient _supa;
  ReceptionsRepository(this._supa);

  /// Stats du jour: nb camions déchargés + volumes (ambiant & 15°C).
  /// - Filtre par dépôt: inner join citernes.depot_id
  Future<({int nbCamions, double volAmbiant, double vol15c})> statsJour({
    required DateTime dayUtc,
    String? depotId,
  }) async {
    // On travaille en DATE métier => égalité YYYY-MM-DD (UTC)
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final eqDay = ymd(DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day));

    try {
      List rows;

      if (depotId != null && depotId.isNotEmpty) {
        // Filtrage par dépôt via citernes
        rows = await _supa
            .from('receptions')
            .select('id, statut, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)')
            .eq('statut', 'validee')
            .eq('date_reception', eqDay)
            .eq('citernes.depot_id', depotId);
      } else {
        // Global
        rows = await _supa
            .from('receptions')
            .select('id, statut, volume_corrige_15c, volume_ambiant')
            .eq('statut', 'validee')
            .eq('date_reception', eqDay);
      }

      int count = 0;
      double sAmb = 0.0, s15 = 0.0;

      for (final m in rows) {
        count++;
        // Ambiant : privilégier la colonne volume_ambiant si présente, sinon 0
        final amb = (m['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
        final v15 = (m['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;
        sAmb += amb;
        s15 += v15;
      }

      // Debug non intrusif (retire-les si OK)
      if (kDebugMode) {
        print(
          '🔎 Réceptions(${eqDay}${depotId != null ? ' depot=' + depotId : ''}) => nb=$count, amb=$sAmb, 15C=$s15',
        );
      }

      return (nbCamions: count, volAmbiant: sAmb, vol15c: s15);
    } on PostgrestException catch (e) {
      // Aide au diagnostic RLS/schéma
      if (kDebugMode) {
        print('❗PostgrestException receptions.statsJour: ${e.message}');
      }
      rethrow;
    }
  }
}

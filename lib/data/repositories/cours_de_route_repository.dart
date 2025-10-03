import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/kpi/models/kpi_models.dart';

class CoursDeRouteRepository {
  final SupabaseClient _supa;
  CoursDeRouteRepository(this._supa);

  /// Retourne {enRoute, enAttente} pour un depotId (optionnel) - COMPATIBILITÉ
  Future<({int enRoute, int enAttente})> countsCamionsASuivre({
    String? depotId,
  }) async {
    final counts = await countsEnRouteEtAttente(depotId: depotId);
    return (enRoute: counts.enRoute, enAttente: counts.attente);
  }

  /// Compte & volume prévisionnel (litres) par statut:
  /// - enRoute: statut IN ('CHARGEMENT','TRANSIT','FRONTIERE')
  /// - attente: statut = 'ARRIVE'
  /// NB: On suppose que `cours_de_route.volume` est en litres (sinon convertir en amont).
  Future<CoursCounts> countsEnRouteEtAttente({
    String? depotId,
    String? produitId,
  }) async {
    final query = _supa
        .from('cours_de_route')
        .select('id, statut, volume, depot_destination_id, produit_id');

    if (depotId != null && depotId.isNotEmpty)
      query.eq('depot_destination_id', depotId);
    if (produitId != null && produitId.isNotEmpty)
      query.eq('produit_id', produitId);

    final rows = await query;

    int enRoute = 0, attente = 0;
    double enRouteL = 0.0, attenteL = 0.0;

    for (final m in (rows as List)) {
      final s = (m['statut'] as String?)?.toUpperCase();
      final v = (m['volume'] as num?)?.toDouble() ?? 0.0;

      if (s == null) continue;
      if (s == 'CHARGEMENT' || s == 'TRANSIT' || s == 'FRONTIERE') {
        enRoute++;
        enRouteL += v;
      } else if (s == 'ARRIVE') {
        attente++;
        attenteL += v;
      }
    }

    // Debug (retirable)
    if (kDebugMode) {
      print(
        '🚚 KPI1: enRoute=$enRoute (${enRouteL}L), attente=$attente (${attenteL}L)'
        '${depotId != null ? ' depot=' + depotId : ''}${produitId != null ? ' produit=' + produitId : ''}',
      );
    }

    return CoursCounts(
      enRoute: enRoute,
      attente: attente,
      enRouteLitres: enRouteL,
      attenteLitres: attenteL,
    );
  }
}

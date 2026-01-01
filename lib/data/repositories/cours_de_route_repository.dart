import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/kpi/models/kpi_models.dart';

class CoursDeRouteRepository {
  final SupabaseClient _supa;
  CoursDeRouteRepository(this._supa);

  /// Retourne les compteurs pour le KPI "Camions à suivre" - COMPATIBILITÉ LEGACY
  ///
  /// RÈGLE MÉTIER CDR :
  /// - loading = CHARGEMENT (camion chez le fournisseur)
  /// - onRoute = TRANSIT + FRONTIERE (camions en transit)
  /// - arrived = ARRIVE (camions arrivés mais pas encore déchargés)
  /// - DECHARGE = EXCLU (cours terminé)
  Future<({int enRoute, int enAttente})> countsCamionsASuivre({
    String? depotId,
  }) async {
    final counts = await countsEnRouteEtAttente(depotId: depotId);
    // Pour compatibilité: enRoute = onRoute, enAttente = loading
    return (enRoute: counts.enRoute, enAttente: counts.attente);
  }

  /// Compte & volume prévisionnel (litres) par statut pour le KPI "Camions à suivre".
  ///
  /// RÈGLE MÉTIER CDR (Cours de Route) :
  /// - DECHARGE est EXCLU (cours terminé, déjà pris en charge dans Réceptions/Stocks)
  /// - Au chargement (attente) : statut = 'CHARGEMENT' → camions chez le fournisseur
  /// - En route (enRoute) : statut IN ('TRANSIT', 'FRONTIERE') → camions en transit
  /// - Arrivés : statut = 'ARRIVE' → camions arrivés au dépôt mais pas encore déchargés
  /// - totalCamionsASuivre = cours non déchargés (CHARGEMENT + TRANSIT + FRONTIERE + ARRIVE)
  ///
  /// NB: On suppose que `cours_de_route.volume` est en litres.
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
      final rawStatut = (m['statut'] as String?)?.trim();
      if (rawStatut == null) {
        continue;
      }

      final s = rawStatut.toUpperCase();
      final v = (m['volume'] as num?)?.toDouble() ?? 0.0;

      // IGNORER DECHARGE (cours terminé, déjà pris en charge)
      if (s == 'DECHARGE') {
        continue;
      }

      // Comptage selon le statut - règle métier à 3 catégories
      // Note: Ce repository legacy combine onRoute + arrived dans enRoute
      if (s == 'CHARGEMENT') {
        // Au chargement = camions chez le fournisseur
        attente++;
        attenteL += v;
      } else if (s == 'TRANSIT' || s == 'FRONTIERE' || s == 'ARRIVE') {
        // En route (legacy) = TRANSIT + FRONTIERE + ARRIVE
        enRoute++;
        enRouteL += v;
      }
      // Tout autre statut inconnu est ignoré silencieusement
    }

    // Debug (retirable)
    if (kDebugMode) {
      print(
        '🚚 KPI Camions à suivre: enRoute=$enRoute (${enRouteL}L), attente=$attente (${attenteL}L)'
        '${depotId != null ? ' depot=$depotId' : ''}${produitId != null ? ' produit=$produitId' : ''}',
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

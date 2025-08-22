/* ===========================================================
   ML_PP MVP — ReceptionService
   Rôle: encapsuler l'accès Supabase pour créer un brouillon
   de réception et valider via la RPC `validate_reception`.
   =========================================================== */
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs; // éviter collisions
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';

class ReceptionService {
  ReceptionService(this.client, this.refRepo);
  final SupabaseClient client;
  final refs.ReferentielsRepo refRepo;

  /// Insère une réception en statut 'brouillon'.
  /// - Résout produit_id: si input.produitId est fourni → l'utiliser,
  ///   sinon lookup par code via référentiels.
  /// - Calcule volume_ambiant et volume_corrige_15c (approx MVP).
  Future<String> createDraft(ReceptionInput input) async {
    // Charger référentiels si nécessaire
    await refRepo.loadProduits();
    await refRepo.loadCiternesActives();

    final produitId = (input.produitId != null && input.produitId!.isNotEmpty)
        ? input.produitId!
        : (refRepo.getProduitIdByCodeSync(input.produitCode) ??
            (throw Exception('Produit introuvable pour code ${input.produitCode}. Rafraîchissez les référentiels.')));

    // Vérification compatibilité stricte
    if (!refRepo.isProduitCompatible(input.citerneId, produitId)) {
      throw Exception('Produit incompatible avec la citerne sélectionnée.');
    }

    final dateStr = formatSqlDate(input.dateReception ?? DateTime.now());
    final volAmb = computeVolumeAmbiant(input.indexAvant, input.indexApres);
    final vol15 = computeV15(
      volumeAmbiant: volAmb,
      temperatureC: input.temperatureC,
      densiteA15: input.densiteA15,
      produitCode: input.produitCode,
    );

    final payload = {
      'proprietaire_type': input.proprietaireType,
      'partenaire_id': input.proprietaireType == 'PARTENAIRE' ? input.partenaireId : null,
      'citerne_id': input.citerneId,
      'produit_id': produitId,
      'index_avant': input.indexAvant,
      'index_apres': input.indexApres,
      'temperature_ambiante_c': input.temperatureC,
      'densite_a_15': input.densiteA15,
      'volume_ambiant': volAmb,
      'volume_corrige_15c': vol15,
      'cours_de_route_id': input.coursDeRouteId,
      'note': input.note,
      'statut': 'brouillon',
      'date_reception': dateStr,
      // created_by est rempli par trigger si null
    };

    final res = await client.from('receptions').insert(payload).select('id').single();
    return res['id'] as String;
  }

  /// Appelle la RPC côté serveur (security definer + contrôles rôle/métier).
  Future<void> validateReception(String receptionId) async {
    await client.rpc('validate_reception', params: {'p_reception_id': receptionId});
  }
}



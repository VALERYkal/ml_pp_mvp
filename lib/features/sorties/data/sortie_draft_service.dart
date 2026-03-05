/* ===========================================================
   ML_PP — SortieDraftService
   - createDraft: insert ligne 'brouillon' dans sorties_produit
   - validate: appelle RPC validate_sortie
   =========================================================== */
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'sortie_input.dart';

class SortieDraftService {
  final SupabaseClient client;
  SortieDraftService(this.client);

  Future<String> createDraft(SortieInput input) async {
    // 1) Validations de base
    if (input.indexApres == null ||
        input.indexAvant == null ||
        input.indexApres! <= input.indexAvant!) {
      throw ArgumentError('index_apres doit être > index_avant');
    }
    if (!(input.proprietaireType == 'MONALUXE' ||
        input.proprietaireType == 'PARTENAIRE')) {
      throw ArgumentError('proprietaire_type invalide');
    }
    if (input.clientId == null && input.partenaireId == null) {
      throw ArgumentError('Un bénéficiaire (client ou partenaire) est requis');
    }
    if (input.chauffeurNom == null ||
        input.chauffeurNom!.isEmpty ||
        input.plaqueCamion == null ||
        input.plaqueCamion!.isEmpty ||
        input.transporteur == null ||
        input.transporteur!.isEmpty) {
      throw ArgumentError(
        'chauffeur_nom, plaque_camion et transporteur sont requis',
      );
    }

    // 2) Compatibilité produit/citerne
    final citerne = await client
        .from('citernes')
        .select('id, produit_id')
        .eq('id', input.citerneId)
        .maybeSingle();
    if (citerne == null || citerne['produit_id'] != input.produitId) {
      throw StateError(
        'La citerne sélectionnée n\'est pas compatible avec le produit choisi',
      );
    }

    // 3) Calculs (ambiant & 15°C)
    final double volumeAmbiant = input.indexApres! - input.indexAvant!;
    final double v15 = calcV15(
      volumeObserveL: volumeAmbiant,
      temperatureC: input.temperatureC ?? 15.0,
      densiteA15: input.densiteA15 ?? 0.83,
    );

    // 4) Insert brouillon
    final payload = {
      'citerne_id': input.citerneId,
      'produit_id': input.produitId,
      'client_id': input.clientId,
      'partenaire_id': input.partenaireId,
      'index_avant': input.indexAvant,
      'index_apres': input.indexApres,
      'volume_ambiant': volumeAmbiant,
      'temperature_ambiante_c': input.temperatureC,
      'densite_a_15_kgm3': input.densiteA15,
      'volume_corrige_15c': v15,
      'proprietaire_type': input.proprietaireType,
      'note': input.note,
      'statut': 'brouillon',
      'date_sortie':
          input.dateSortie?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'chauffeur_nom': input.chauffeurNom,
      'plaque_camion': input.plaqueCamion,
      'plaque_remorque': input.plaqueRemorque,
      'transporteur': input.transporteur,
    };

    final row = await client
        .from('sorties_produit')
        .insert(payload)
        .select('id')
        .single();
    final id = row['id'] as String;

    // 5) Log action
    await client.from('log_actions').insert({
      'action': 'SORTIE_CREEE',
      'module': 'sorties',
      'niveau': 'INFO',
      'details': payload,
      'cible_id': id,
    });

    return id;
  }
}

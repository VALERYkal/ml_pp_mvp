// 📌 Module : Sorties - Service
// 🧭 Description : Service Supabase pour créer des sorties
//
// Contrat actuel :
// - STAGING : la DB calcule volume_15c / volume_corrige_15c via le trigger
//   `sorties_compute_15c_before_ins_lookup()`.
//   L'application envoie volume_ambiant, temperature_ambiante_c et
//   densite_a_15_kgm3 (champ legacy utilisé comme densité observée).
//
// - Hors STAGING : on conserve le chemin compatible legacy en envoyant
//   volume_corrige_15c + densite_a_15_kgm3.
//
// Important :
// - Le runtime UI actif passe par createValidated().
// - Les anciennes méthodes createSortieMonaluxe/createSortiePartenaire sont
//   conservées comme wrappers pour compatibilité interne, mais elles délèguent
//   désormais vers le contrat unique createValidated().

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/errors/sortie_service_exception.dart';

const String appEnv =
    String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const String supabaseEnv =
    String.fromEnvironment('SUPABASE_ENV', defaultValue: 'PROD');
const bool isStaging = (appEnv == 'staging') || (supabaseEnv == 'STAGING');

class SortieService {
  final SupabaseClient client;

  SortieService(this.client);

  /// Wrapper de compatibilité.
  ///
  /// Délègue au contrat unique createValidated() afin d'éviter toute divergence
  /// de payload entre plusieurs méthodes.
  Future<void> createSortieMonaluxe({
    required String citerneId,
    required String produitId,
    required String clientId,
    required double indexAvant,
    required double indexApres,
    required double volumeAmbiant,
    required double volume15c,
    required double temperature,
    required double densite15,
    DateTime? dateSortie,
    String? note,
  }) async {
    await createValidated(
      citerneId: citerneId,
      produitId: produitId,
      indexAvant: indexAvant,
      indexApres: indexApres,
      temperatureCAmb: temperature,
      densiteA15: densite15,
      volumeCorrige15C: volume15c,
      proprietaireType: 'MONALUXE',
      clientId: clientId,
      note: note,
      dateSortie: dateSortie,
    );
  }

  /// Wrapper de compatibilité.
  ///
  /// Délègue au contrat unique createValidated().
  Future<void> createSortiePartenaire({
    required String citerneId,
    required String produitId,
    required String partenaireId,
    required double indexAvant,
    required double indexApres,
    required double volumeAmbiant,
    required double volume15c,
    required double temperature,
    required double densite15,
    DateTime? dateSortie,
    String? note,
  }) async {
    await createValidated(
      citerneId: citerneId,
      produitId: produitId,
      indexAvant: indexAvant,
      indexApres: indexApres,
      temperatureCAmb: temperature,
      densiteA15: densite15,
      volumeCorrige15C: volume15c,
      proprietaireType: 'PARTENAIRE',
      partenaireId: partenaireId,
      note: note,
      dateSortie: dateSortie,
    );
  }

  /// Point d'entrée canonique de création de sortie validée.
  ///
  /// Règles :
  /// - STAGING :
  ///   - ne pas envoyer volume_corrige_15c
  ///   - envoyer densite_a_15_kgm3 comme input legacy interprété par la DB
  ///     comme densité observée
  /// - Hors STAGING :
  ///   - conserver volume_corrige_15c
  ///   - conserver densite_a_15_kgm3
  ///
  /// Note sémantique :
  /// Le paramètre [densiteA15] garde son nom historique pour compatibilité
  /// d'API Flutter, mais en STAGING il est transmis dans le champ legacy
  /// densite_a_15_kgm3 attendu par le trigger lookup-grid.
  Future<void> createValidated({
    required String citerneId,
    required String produitId,
    required double indexAvant,
    required double indexApres,
    required double temperatureCAmb,
    required double densiteA15,
    double? volumeCorrige15C,
    required String proprietaireType,
    String? clientId,
    String? partenaireId,
    String? chauffeurNom,
    String? plaqueCamion,
    String? plaqueRemorque,
    String? transporteur,
    String? note,
    DateTime? dateSortie,
  }) async {
    final volumeAmbiant = indexApres - indexAvant;
    final volume15c = volumeCorrige15C ?? volumeAmbiant;

    final proprietaireTypeNormalized = proprietaireType.toUpperCase().trim();
    final proprietaireTypeFinal = proprietaireTypeNormalized.isEmpty
        ? 'MONALUXE'
        : (proprietaireTypeNormalized == 'PARTENAIRE'
              ? 'PARTENAIRE'
              : 'MONALUXE');

    if (proprietaireTypeFinal == 'MONALUXE') {
      if (clientId == null || clientId.trim().isEmpty) {
        throw SortieServiceException(
          'Le client est obligatoire pour une sortie MONALUXE.',
          code: 'CLIENT_REQUIRED',
        );
      }
    } else if (proprietaireTypeFinal == 'PARTENAIRE') {
      if (partenaireId == null || partenaireId.trim().isEmpty) {
        throw SortieServiceException(
          'Le partenaire est obligatoire pour une sortie PARTENAIRE.',
          code: 'PARTENAIRE_REQUIRED',
        );
      }
    } else {
      throw SortieServiceException(
        'proprietaire_type inconnu: $proprietaireType',
        code: 'INVALID_PROPRIETAIRE_TYPE',
      );
    }

    final payload = <String, dynamic>{
      'citerne_id': citerneId,
      'produit_id': produitId,
      'client_id': proprietaireTypeFinal == 'MONALUXE' ? clientId!.trim() : null,
      'partenaire_id':
          proprietaireTypeFinal == 'PARTENAIRE' ? partenaireId!.trim() : null,
      'index_avant': indexAvant,
      'index_apres': indexApres,
      'volume_ambiant': volumeAmbiant,

      // Compatibilité transitoire :
      // - STAGING : la DB calcule volume_15c/volume_corrige_15c
      // - Hors STAGING : on garde le chemin legacy existant
      if (!isStaging) 'volume_corrige_15c': volume15c,

      'temperature_ambiante_c': temperatureCAmb,

      // Contrat DB réel :
      // STAGING attend densite_a_15_kgm3 comme input legacy utilisé comme
      // densité observée. Hors STAGING, on conserve aussi ce champ.
      'densite_a_15_kgm3': densiteA15,

      'proprietaire_type': proprietaireTypeFinal,
      'statut': 'validee',
      if (dateSortie != null) 'date_sortie': dateSortie.toUtc().toIso8601String(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (chauffeurNom != null && chauffeurNom.trim().isNotEmpty)
        'chauffeur_nom': chauffeurNom.trim(),
      if (plaqueCamion != null && plaqueCamion.trim().isNotEmpty)
        'plaque_camion': plaqueCamion.trim(),
      if (plaqueRemorque != null && plaqueRemorque.trim().isNotEmpty)
        'plaque_remorque': plaqueRemorque.trim(),
      if (transporteur != null && transporteur.trim().isNotEmpty)
        'transporteur': transporteur.trim(),
    };

    if (kDebugMode) {
      debugPrint('[SORTIE][CALL] insert sorties_produit');
      debugPrint(
        '[SORTIE][ENV] isStaging=$isStaging appEnv=$appEnv supabaseEnv=$supabaseEnv',
      );
      debugPrint('[SORTIE][PAYLOAD] $payload');
    }

    try {
      await client.from('sorties_produit').insert(payload).select('id').single();

      if (kDebugMode) {
        debugPrint('[SORTIE] OK - Sortie $proprietaireTypeFinal créée');
      }
    } on PostgrestException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[SORTIE][ERROR] code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
        );
        debugPrint('[SORTIE][ERROR] stackTrace: $st');
      }

      final userMessage = _mapErrorToUserMessage(e.message);

      throw SortieServiceException(
        userMessage,
        code: e.code,
        hint: e.hint,
        details: e.details,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SORTIE][ERROR] Unknown exception: $e');
        debugPrint('[SORTIE][ERROR] stackTrace: $st');
      }
      rethrow;
    }
  }

  /// Mappe les erreurs SQL du trigger vers des messages utilisateur lisibles
  String _mapErrorToUserMessage(String? errorMessage) {
    if (errorMessage == null) {
      return 'Erreur lors de la création de la sortie';
    }

    if (errorMessage.contains('Citerne introuvable')) {
      return 'La citerne sélectionnée n\'existe pas';
    } else if (errorMessage.contains('inactive') ||
        errorMessage.contains('maintenance')) {
      return 'La citerne est inactive ou en maintenance';
    } else if (errorMessage.contains('Produit incompatible')) {
      return 'Le produit ne correspond pas à la citerne sélectionnée';
    } else if (errorMessage.contains('capacité de sécurité') ||
        errorMessage.contains('stock disponible') ||
        errorMessage.contains('Sortie dépasserait') ||
        errorMessage.contains('STOCK_INSUFFISANT_15C')) {
      return 'Le stock disponible est insuffisant pour cette sortie';
    } else if (errorMessage.contains('Aucun stock journalier')) {
      return 'Aucun stock disponible pour cette citerne';
    } else if (errorMessage.contains('Client obligatoire')) {
      return 'Un client est requis pour une sortie MONALUXE';
    } else if (errorMessage.contains('Partenaire obligatoire')) {
      return 'Un partenaire est requis pour une sortie PARTENAIRE';
    } else if (errorMessage.contains('partenaire_id doit être NULL')) {
      return 'Un partenaire ne peut pas être renseigné pour une sortie MONALUXE';
    } else if (errorMessage.contains('client_id doit être NULL')) {
      return 'Un client ne peut pas être renseigné pour une sortie PARTENAIRE';
    } else if (errorMessage.contains('SORTIE_INPUT_MISSING')) {
      return 'Des données obligatoires sont manquantes pour calculer la sortie.';
    } else if (errorMessage.contains('SORTIE_INPUT_INVALID')) {
      return 'Les valeurs de volume de la sortie sont invalides.';
    } else if (errorMessage.contains('SORTIE_VOLUMETRICS_FAILED')) {
      return 'Le calcul volumétrique de la sortie a échoué.';
    } else if (errorMessage.contains('SORTIE_VOLUMETRICS_BLOCKED')) {
      return 'Le moteur volumétrique de sortie n’est pas disponible dans cet environnement.';
    }

    return errorMessage;
  }
}

// 📌 Module : Sorties - Service
// 🧭 Description : Service Supabase pour créer des sorties
// 
// Architecture simplifiée : Les validations métier sont gérées par le trigger SQL
// `fn_sorties_after_insert()`. Ce service fait uniquement l'insert et gère les erreurs SQL.

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/errors/sortie_service_exception.dart';
// no riverpod import here; provider is defined in providers/sortie_providers.dart

class SortieService {
  final SupabaseClient client;

  SortieService(this.client);

  /// Crée une sortie MONALUXE validée.
  /// 
  /// Le trigger SQL `fn_sorties_after_insert()` gère :
  /// - Les validations métier (citerne active, produit compatible, stock suffisant, etc.)
  /// - Le débit du stock journalier
  /// - La journalisation dans log_actions
  /// 
  /// Cette méthode fait uniquement l'insert et gère les erreurs SQL.
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
    final payload = {
      'citerne_id': citerneId,
      'produit_id': produitId,
      'client_id': clientId,
      'partenaire_id': null, // MONALUXE → partenaire_id doit être NULL
      'index_avant': indexAvant,
      'index_apres': indexApres,
      'volume_ambiant': volumeAmbiant,
      'volume_corrige_15c': volume15c,
      'temperature_ambiante_c': temperature,
      'densite_a_15': densite15,
      'proprietaire_type': 'MONALUXE',
      'statut': 'validee', // Le MVP valide directement
      if (dateSortie != null) 'date_sortie': dateSortie.toUtc().toIso8601String(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      // created_by sera géré par le trigger ou la DB
    };

    log('[SortieService] INSERT sortie MONALUXE');
    log('[SortieService] payload=$payload');

    try {
      await client
          .from('sorties_produit')
          .insert(payload)
          .select('id')
          .single();
      
      log('[SortieService] OK - Sortie MONALUXE créée');
    } on PostgrestException catch (e, st) {
      log('[SortieService][PostgrestException] message=${e.message}', stackTrace: st);
      log('[SortieService] code=${e.code} hint=${e.hint}');
      
      // Mapper les erreurs du trigger vers des messages utilisateur lisibles
      final userMessage = _mapErrorToUserMessage(e.message);
      
      throw SortieServiceException(userMessage, code: e.code, hint: e.hint);
    } catch (e, st) {
      log('[SortieService][Unknown] $e', stackTrace: st);
      rethrow;
    }
  }

  /// Crée une sortie PARTENAIRE validée.
  /// 
  /// Le trigger SQL `fn_sorties_after_insert()` gère :
  /// - Les validations métier (citerne active, produit compatible, stock suffisant, etc.)
  /// - Le débit du stock journalier
  /// - La journalisation dans log_actions
  /// 
  /// Cette méthode fait uniquement l'insert et gère les erreurs SQL.
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
    final payload = {
      'citerne_id': citerneId,
      'produit_id': produitId,
      'client_id': null, // PARTENAIRE → client_id doit être NULL
      'partenaire_id': partenaireId,
      'index_avant': indexAvant,
      'index_apres': indexApres,
      'volume_ambiant': volumeAmbiant,
      'volume_corrige_15c': volume15c,
      'temperature_ambiante_c': temperature,
      'densite_a_15': densite15,
      'proprietaire_type': 'PARTENAIRE',
      'statut': 'validee', // Le MVP valide directement
      if (dateSortie != null) 'date_sortie': dateSortie.toUtc().toIso8601String(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      // created_by sera géré par le trigger ou la DB
    };

    log('[SortieService] INSERT sortie PARTENAIRE');
    log('[SortieService] payload=$payload');

    try {
      await client
          .from('sorties_produit')
          .insert(payload)
          .select('id')
          .single();
      
      log('[SortieService] OK - Sortie PARTENAIRE créée');
    } on PostgrestException catch (e, st) {
      log('[SortieService][PostgrestException] message=${e.message}', stackTrace: st);
      log('[SortieService] code=${e.code} hint=${e.hint}');
      
      // Mapper les erreurs du trigger vers des messages utilisateur lisibles
      final userMessage = _mapErrorToUserMessage(e.message);
      
      throw SortieServiceException(userMessage, code: e.code, hint: e.hint);
    } catch (e, st) {
      log('[SortieService][Unknown] $e', stackTrace: st);
      rethrow;
    }
  }

  /// 🔁 Méthode de compatibilité pour l'UI existante.
  /// Elle route vers createSortieMonaluxe ou createSortiePartenaire
  /// en fonction de [proprietaireType].
  /// 
  /// Cette méthode adapte les noms de paramètres de l'UI vers les méthodes spécialisées.
  Future<void> createValidated({
    required String citerneId,
    required String produitId,
    required double indexAvant,
    required double indexApres,
    required double temperatureCAmb,
    required double densiteA15,
    double? volumeCorrige15C,
    String proprietaireType = 'MONALUXE',
    String? clientId,
    String? partenaireId,
    String? chauffeurNom,
    String? plaqueCamion,
    String? plaqueRemorque,
    String? transporteur,
    String? note,
    DateTime? dateSortie,
  }) async {
    // Calculer volumeAmbiant depuis les indices
    final volumeAmbiant = indexApres - indexAvant;
    
    // Utiliser volumeCorrige15C si fourni, sinon calculer depuis volumeAmbiant
    // (normalement l'UI fournit toujours volumeCorrige15C)
    final volume15c = volumeCorrige15C ?? volumeAmbiant;

    // Normaliser proprietaireType
    final proprietaireTypeNormalized = proprietaireType.toUpperCase().trim();
    final proprietaireTypeFinal = proprietaireTypeNormalized.isEmpty 
        ? 'MONALUXE' 
        : (proprietaireTypeNormalized == 'PARTENAIRE' ? 'PARTENAIRE' : 'MONALUXE');

    if (proprietaireTypeFinal == 'MONALUXE') {
      if (clientId == null || clientId.trim().isEmpty) {
        throw SortieServiceException(
          'Le client est obligatoire pour une sortie MONALUXE.',
          code: 'CLIENT_REQUIRED',
        );
      }

      // Construire le payload avec les champs optionnels
      final payload = {
        'citerne_id': citerneId,
        'produit_id': produitId,
        'client_id': clientId.trim(),
        'partenaire_id': null,
        'index_avant': indexAvant,
        'index_apres': indexApres,
        'volume_ambiant': volumeAmbiant,
        'volume_corrige_15c': volume15c,
        'temperature_ambiante_c': temperatureCAmb,
        'densite_a_15': densiteA15,
        'proprietaire_type': 'MONALUXE',
        'statut': 'validee',
        if (dateSortie != null) 'date_sortie': dateSortie.toUtc().toIso8601String(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (chauffeurNom != null && chauffeurNom.trim().isNotEmpty) 'chauffeur_nom': chauffeurNom.trim(),
        if (plaqueCamion != null && plaqueCamion.trim().isNotEmpty) 'plaque_camion': plaqueCamion.trim(),
        if (plaqueRemorque != null && plaqueRemorque.trim().isNotEmpty) 'plaque_remorque': plaqueRemorque.trim(),
        if (transporteur != null && transporteur.trim().isNotEmpty) 'transporteur': transporteur.trim(),
      };

      log('[SortieService] INSERT sortie MONALUXE (via createValidated)');
      log('[SortieService] payload=$payload');

      try {
        await client
            .from('sorties_produit')
            .insert(payload)
            .select('id')
            .single();
        
        log('[SortieService] OK - Sortie MONALUXE créée');
      } on PostgrestException catch (e, st) {
        log('[SortieService][PostgrestException] message=${e.message}', stackTrace: st);
        log('[SortieService] code=${e.code} hint=${e.hint}');
        
        final userMessage = _mapErrorToUserMessage(e.message);
        throw SortieServiceException(userMessage, code: e.code, hint: e.hint);
      } catch (e, st) {
        log('[SortieService][Unknown] $e', stackTrace: st);
        rethrow;
      }
    } else if (proprietaireTypeFinal == 'PARTENAIRE') {
      if (partenaireId == null || partenaireId.trim().isEmpty) {
        throw SortieServiceException(
          'Le partenaire est obligatoire pour une sortie PARTENAIRE.',
          code: 'PARTENAIRE_REQUIRED',
        );
      }

      // Construire le payload avec les champs optionnels
      final payload = {
        'citerne_id': citerneId,
        'produit_id': produitId,
        'client_id': null,
        'partenaire_id': partenaireId.trim(),
        'index_avant': indexAvant,
        'index_apres': indexApres,
        'volume_ambiant': volumeAmbiant,
        'volume_corrige_15c': volume15c,
        'temperature_ambiante_c': temperatureCAmb,
        'densite_a_15': densiteA15,
        'proprietaire_type': 'PARTENAIRE',
        'statut': 'validee',
        if (dateSortie != null) 'date_sortie': dateSortie.toUtc().toIso8601String(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        if (chauffeurNom != null && chauffeurNom.trim().isNotEmpty) 'chauffeur_nom': chauffeurNom.trim(),
        if (plaqueCamion != null && plaqueCamion.trim().isNotEmpty) 'plaque_camion': plaqueCamion.trim(),
        if (plaqueRemorque != null && plaqueRemorque.trim().isNotEmpty) 'plaque_remorque': plaqueRemorque.trim(),
        if (transporteur != null && transporteur.trim().isNotEmpty) 'transporteur': transporteur.trim(),
      };

      log('[SortieService] INSERT sortie PARTENAIRE (via createValidated)');
      log('[SortieService] payload=$payload');

      try {
        await client
            .from('sorties_produit')
            .insert(payload)
            .select('id')
            .single();
        
        log('[SortieService] OK - Sortie PARTENAIRE créée');
      } on PostgrestException catch (e, st) {
        log('[SortieService][PostgrestException] message=${e.message}', stackTrace: st);
        log('[SortieService] code=${e.code} hint=${e.hint}');
        
        final userMessage = _mapErrorToUserMessage(e.message);
        throw SortieServiceException(userMessage, code: e.code, hint: e.hint);
      } catch (e, st) {
        log('[SortieService][Unknown] $e', stackTrace: st);
        rethrow;
      }
    } else {
      throw SortieServiceException(
        'proprietaire_type inconnu: $proprietaireType',
        code: 'INVALID_PROPRIETAIRE_TYPE',
      );
    }
  }

  /// Mappe les erreurs SQL du trigger vers des messages utilisateur lisibles
  String _mapErrorToUserMessage(String? errorMessage) {
    if (errorMessage == null) {
      return 'Erreur lors de la création de la sortie';
    }

    if (errorMessage.contains('Citerne introuvable')) {
      return 'La citerne sélectionnée n\'existe pas';
    } else if (errorMessage.contains('inactive') || errorMessage.contains('maintenance')) {
      return 'La citerne est inactive ou en maintenance';
    } else if (errorMessage.contains('Produit incompatible')) {
      return 'Le produit ne correspond pas à la citerne sélectionnée';
    } else if (errorMessage.contains('capacité de sécurité') || 
               errorMessage.contains('stock disponible') ||
               errorMessage.contains('Sortie dépasserait')) {
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
    }

    return errorMessage;
  }
}

// Provider is defined in lib/features/sorties/providers/sortie_providers.dart

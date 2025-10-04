import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
// no riverpod import here; provider is defined in providers/sortie_providers.dart

/// Type pour l'injection de dépendance des appels RPC
typedef RpcRunner =
    Future<Map<String, dynamic>?> Function(String fn, {Map<String, dynamic>? params});

class SortieService {
  final RpcRunner _rpc;

  SortieService({RpcRunner? rpc})
    : _rpc =
          rpc ??
          ((fn, {params}) => Supabase.instance.client
              .rpc(fn, params: params)
              .then((r) => r as Map<String, dynamic>?));

  /// Insert direct "validée" (ne PAS envoyer 'statut' → défaut DB = 'validee').
  /// Les triggers DB calculent volume_ambiant si besoin, débitent le stock et loggent.
  Future<String> createValidated({
    required String citerneId,
    required String produitId,
    double? indexAvant,
    double? indexApres,
    double? temperatureCAmb,
    double? densiteA15,
    double? volumeCorrige15C, // si null → DB fallback sur ambiant
    String proprietaireType = 'MONALUXE', // 'MONALUXE' | 'PARTENAIRE'
    String? clientId,
    String? partenaireId,
    String? chauffeurNom,
    String? plaqueCamion,
    String? plaqueRemorque,
    String? transporteur,
    String? note,
    DateTime? dateSortie, // si null → DB met now()
  }) async {
    final payload = <String, dynamic>{
      'citerne_id': citerneId,
      'produit_id': produitId,
      if (clientId != null) 'client_id': clientId,
      if (partenaireId != null) 'partenaire_id': partenaireId,
      if (indexAvant != null) 'index_avant': indexAvant,
      if (indexApres != null) 'index_apres': indexApres,
      if (temperatureCAmb != null) 'temperature_ambiante_c': temperatureCAmb,
      if (densiteA15 != null) 'densite_a_15': densiteA15,
      if (volumeCorrige15C != null) 'volume_corrige_15c': volumeCorrige15C,
      'proprietaire_type': proprietaireType,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (chauffeurNom != null && chauffeurNom.trim().isNotEmpty)
        'chauffeur_nom': chauffeurNom.trim(),
      if (plaqueCamion != null && plaqueCamion.trim().isNotEmpty)
        'plaque_camion': plaqueCamion.trim(),
      if (plaqueRemorque != null && plaqueRemorque.trim().isNotEmpty)
        'plaque_remorque': plaqueRemorque.trim(),
      if (transporteur != null && transporteur.trim().isNotEmpty)
        'transporteur': transporteur.trim(),
      if (dateSortie != null) 'date_sortie': dateSortie.toIso8601String(),
      // NE PAS inclure 'statut' → défaut DB = 'validee'
    };

    // Petit garde UX (les triggers DB lèveront aussi)
    if (indexAvant != null && indexApres != null && indexApres <= indexAvant) {
      throw StateError('INDEX_INCOHERENTS: index_apres <= index_avant');
    }

    log('[SortieService] INSERT sorties_produit');
    log('[SortieService] payload=$payload');

    try {
      // Utilisation de l'injection de dépendance pour les tests
      final res = await _rpc('create_sortie', params: payload);

      if (res == null || res['id'] == null) {
        throw StateError('Réponse invalide du serveur');
      }

      final id = res['id'] as String;
      log('[SortieService] OK id=$id');
      return id;
    } on PostgrestException catch (e, st) {
      log('[SortieService][PostgrestException] message=${e.message}', stackTrace: st);
      log('[SortieService] code=${e.code} hint=${e.hint} details=${e.details}');
      log('[SortieService] payload=${payload}');

      // Log spécifique pour identifier les "duplicate update" sur la même journée
      if (e.message?.contains('duplicate') == true || e.message?.contains('unique') == true) {
        log('[SortieService] ⚠️ Possible double application détectée: ${e.message}');
      }

      rethrow;
    } catch (e, st) {
      log('[SortieService][Unknown] $e', stackTrace: st);
      log('[SortieService] payload=${payload}');
      rethrow;
    }
  }
}

// Provider is defined in lib/features/sorties/providers/sortie_providers.dart

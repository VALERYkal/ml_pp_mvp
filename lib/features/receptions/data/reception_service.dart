// ?? Module : Réceptions - Service
// ?? Description : Service Supabase pour créer/valider des réceptions

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reception_input.dart';
import '../../citernes/data/citerne_service.dart';
import '../../stocks_journaliers/data/stocks_service.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

class ReceptionService {
  final SupabaseClient _client;
  final CiterneService Function(SupabaseClient) _citerneServiceFactory;
  final StocksService Function(SupabaseClient) _stocksServiceFactory;
  final refs.ReferentielsRepo _refRepo;

  const ReceptionService.withClient(
    this._client, {
    CiterneService Function(SupabaseClient)? citerneServiceFactory,
    StocksService Function(SupabaseClient)? stocksServiceFactory,
    required refs.ReferentielsRepo refRepo,
  }) : _citerneServiceFactory =
           citerneServiceFactory ?? CiterneService.withClient,
       _stocksServiceFactory = stocksServiceFactory ?? StocksService.withClient,
       _refRepo = refRepo;

  /// Crée une réception "validée" (par défaut DB) et déclenche les effets (stocks + CDR DECHARGE).
  /// NE PAS envoyer 'statut' : la DB a DEFAULT 'validee' et un trigger applique les effets.
  Future<String> createValidated({
    String? coursDeRouteId,
    required String citerneId,
    required String produitId,
    required double indexAvant,
    required double indexApres,
    double? temperatureCAmb,
    double? densiteA15,
    double? volumeCorrige15C,
    String proprietaireType = 'MONALUXE',
    String? partenaireId,
    DateTime? dateReception,
    String? note,
  }) async {
    final Map<String, dynamic> payload = {
      if (coursDeRouteId != null) 'cours_de_route_id': coursDeRouteId,
      'citerne_id': citerneId,
      'produit_id': produitId,
      'index_avant': indexAvant,
      'index_apres': indexApres,
      if (temperatureCAmb != null) 'temperature_ambiante_c': temperatureCAmb,
      if (densiteA15 != null) 'densite_a_15': densiteA15,
      if (volumeCorrige15C != null) 'volume_corrige_15c': volumeCorrige15C,
      'proprietaire_type': proprietaireType,
      if (partenaireId != null) 'partenaire_id': partenaireId,
      if (dateReception != null)
        'date_reception': dateReception.toIso8601String().substring(0, 10),
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    };

    // Logs avant INSERT
    debugPrint('[ReceptionService] INSERT receptions');
    debugPrint('[ReceptionService] user=${_client.auth.currentUser?.id}');
    debugPrint('[ReceptionService] payload=${jsonEncode(payload)}');

    try {
      final row =
          await _client.from('receptions').insert(payload).select('id').single()
              as Map<String, dynamic>;

      debugPrint('[ReceptionService] OK id=${row['id']}');
      return row['id'] as String;
    } on PostgrestException catch (e, st) {
      debugPrint('[ReceptionService][PostgrestException] message=${e.message}');
      debugPrint('[ReceptionService] code=${e.code} hint=${e.hint}');
      debugPrint('[ReceptionService] details=${_safeJson(e.details)}');
      debugPrint('[ReceptionService] payload-again=${jsonEncode(payload)}');
      debugPrint('[ReceptionService] stack=\n$st');
      rethrow;
    } catch (e, st) {
      debugPrint('[ReceptionService][UnknownError] $e');
      debugPrint('[ReceptionService] stack=\n$st');
      debugPrint('[ReceptionService] payload-again=${jsonEncode(payload)}');
      rethrow;
    }
  }

  /// Crée un brouillon de réception avec toutes les validations métier
  Future<String> createDraft(ReceptionInput input) async {
    /// Alias pour compatibilité avec les tests
    Future<String> createReception(
      ReceptionInput input, {
      required Object refRepo, // param accepté mais ignoré pour compatibilité
    }) async {
      return createDraft(input);
    }

    try {
      // Charger référentiels si nécessaire
      await _refRepo.loadProduits();
      await _refRepo.loadCiternesActives();

      // Résolution du produit_id
      final produitId = (input.produitId != null && input.produitId!.isNotEmpty)
          ? input.produitId!
          : (_refRepo.getProduitIdByCodeSync(input.produitCode) ??
                (throw ArgumentError(
                  'Produit introuvable pour code ${input.produitCode}',
                )));

      // Validations métier
      await _validateInput(input, produitId);

      // Calculs volumes
      final volAmb = computeVolumeAmbiant(input.indexAvant, input.indexApres);
      final vol15 = calcV15(
        volumeObserveL: volAmb,
        temperatureC: input.temperatureC ?? 15.0,
        densiteA15: input.densiteA15 ?? 0.83,
      );

      // Préparation du payload
      final payload = {
        'cours_de_route_id': input.coursDeRouteId,
        'citerne_id': input.citerneId,
        'produit_id': produitId,
        'partenaire_id': input.partenaireId,
        'index_avant': input.indexAvant,
        'index_apres': input.indexApres,
        'volume_ambiant': volAmb,
        'volume_corrige_15c': vol15,
        'temperature_ambiante_c': input.temperatureC,
        'densite_a_15': input.densiteA15,
        'proprietaire_type': input.proprietaireType,
        'note': input.note,
        'statut': 'brouillon',
        'date_reception': formatSqlDate(input.dateReception ?? DateTime.now()),
        // created_by sera rempli par trigger si null
      };

      // Insertion
      final inserted =
          await _client.from('receptions').insert(payload).select('id').single()
              as Map<String, dynamic>;

      final receptionId = inserted['id'] as String;

      // Log action
      await _client.from('log_actions').insert({
        'module': 'receptions',
        'action': 'RECEPTION_CREEE',
        'niveau': 'INFO',
        'details': {
          'cours_de_route_id': input.coursDeRouteId,
          'citerne_id': input.citerneId,
          'produit_id': produitId,
          'proprietaire_type': input.proprietaireType,
        },
        'cible_id': receptionId,
      });

      return receptionId;
    } on PostgrestException catch (e) {
      debugPrint(
        '? ReceptionService.createDraft: Erreur Supabase - ${e.message}',
      );
      rethrow;
    }
  }

  /// Valide une réception (changement de statut + mise à jour stocks)
  Future<void> validate(String receptionId) async {
    try {
      // Vérification du rôle utilisateur
      final user = _client.auth.currentUser;
      if (user == null) {
        throw ArgumentError('Utilisateur non authentifié');
      }

      // Récupération de la réception
      final receptionData =
          await _client
                  .from('receptions')
                  .select()
                  .eq('id', receptionId)
                  .single()
              as Map<String, dynamic>;

      if (receptionData['statut'] != 'brouillon') {
        throw ArgumentError(
          'Seules les réceptions en brouillon peuvent être validées',
        );
      }

      // Mise à jour du statut
      await _client
          .from('receptions')
          .update({
            'statut': 'validee',
            'validated_by': user.id,
            'date_reception': formatSqlDate(DateTime.now()),
          })
          .eq('id', receptionId);

      // Les stocks journaliers sont mis à jour automatiquement par les triggers DB
      // Pas besoin d'appel côté client

      // Si c'est un cours de route Monaluxe, le passer à "DECHARGE"
      if (receptionData['cours_de_route_id'] != null) {
        await _client
            .from('cours_de_route')
            .update({'statut': 'DECHARGE'})
            .eq('id', receptionData['cours_de_route_id']);
      }

      // Log validation
      await _client.from('log_actions').insert({
        'module': 'receptions',
        'action': 'RECEPTION_VALIDEE',
        'niveau': 'INFO',
        'details': {'reception_id': receptionId},
        'cible_id': receptionId,
      });
    } on PostgrestException catch (e) {
      debugPrint('? ReceptionService.validate: Erreur Supabase - ${e.message}');
      debugPrint(
        '? ReceptionService.validate: code=${e.code} hint=${e.hint} details=${e.details}',
      );

      // Log spécifique pour identifier les "duplicate update" sur la même journée
      if (e.message?.contains('duplicate') == true ||
          e.message?.contains('unique') == true) {
        debugPrint(
          '?? ReceptionService.validate: Possible double application détectée: ${e.message}',
        );
      }

      rethrow;
    }
  }

  /// Validations métier pour createDraft
  Future<void> _validateInput(ReceptionInput input, String produitId) async {
    // Validation des indices
    if (input.indexAvant == null || input.indexApres == null) {
      throw ArgumentError('Les indices avant et après sont requis');
    }
    if (input.indexApres! <= input.indexAvant!) {
      throw ArgumentError(
        'Les indices sont incohérents (index après <= index avant)',
      );
    }

    // Validation citerne
    final citerneService = _citerneServiceFactory(_client);
    final citerne = await citerneService.getById(input.citerneId);
    if (citerne == null) {
      throw ArgumentError('Citerne introuvable');
    }
    if (citerne.statut != 'active') {
      throw ArgumentError('Citerne inactive');
    }

    // Vérification compatibilité produit/citerne
    if (citerne.produitId != produitId) {
      throw ArgumentError('Produit incompatible avec la citerne sélectionnée');
    }

    // Vérification capacité
    final volAmb = computeVolumeAmbiant(input.indexAvant, input.indexApres);
    final stocksService = _stocksServiceFactory(_client);
    final stockToday = await stocksService.getAmbientForToday(
      citerneId: input.citerneId,
      produitId: produitId,
    );
    final capaciteDisponible =
        citerne.capaciteTotale - citerne.capaciteSecurite - stockToday;
    if (volAmb > capaciteDisponible) {
      throw ArgumentError('Volume > capacité disponible (sécurité incluse)');
    }

    // Validation propriétaire
    if (input.proprietaireType == 'MONALUXE') {
      if (input.coursDeRouteId == null) {
        throw ArgumentError(
          'Cours de route requis pour une réception Monaluxe',
        );
      }
    } else if (input.proprietaireType == 'PARTENAIRE') {
      if (input.partenaireId == null || input.partenaireId!.isEmpty) {
        throw ArgumentError('Partenaire requis pour une réception Partenaire');
      }
    } else {
      throw ArgumentError('Type de propriétaire invalide');
    }
  }
}

String _safeJson(dynamic v) {
  try {
    if (v == null) return 'null';
    if (v is String) return v;
    return jsonEncode(v);
  } catch (_) {
    return v.toString();
  }
}

final receptionServiceProvider = Provider<ReceptionService>((ref) {
  final repo = ref.read(refs.referentielsRepoProvider);
  return ReceptionService.withClient(Supabase.instance.client, refRepo: repo);
});


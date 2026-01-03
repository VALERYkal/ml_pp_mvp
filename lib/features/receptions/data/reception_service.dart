// 📌 Module : Réceptions - Service
// 🧭 Description : Service Supabase pour créer/valider des réceptions

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;

import '../data/reception_input.dart';
import '../../citernes/data/citerne_service.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/core/errors/reception_validation_exception.dart';
import 'package:ml_pp_mvp/core/errors/reception_insert_exception.dart';

class ReceptionService {
  final SupabaseClient _client;
  final CiterneService Function(SupabaseClient) _citerneServiceFactory;
  final refs.ReferentielsRepo _refRepo;

  const ReceptionService.withClient(
    this._client, {
    CiterneService Function(SupabaseClient)? citerneServiceFactory,
    required refs.ReferentielsRepo refRepo,
  }) : _citerneServiceFactory =
           citerneServiceFactory ?? CiterneService.withClient,
       _refRepo = refRepo;

  /// Crée une réception "validée" (par défaut DB) et déclenche les effets (stocks + CDR DECHARGE).
  /// NE PAS envoyer 'statut' : la DB a DEFAULT 'validee' et un trigger applique les effets.
  ///
  /// Applique toutes les validations métier avant l'insertion :
  /// - Indices/volume (index_avant >= 0, index_apres > index_avant, volume_ambiant >= 0)
  /// - Citerne/produit (citerne active, produit compatible)
  /// - Propriétaire (normalisation, partenaire_id requis si PARTENAIRE)
  /// - Volume 15°C (OBLIGATOIRE : température et densité requises, volume_15c toujours calculé)
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
    // ============================================================
    // VALIDATIONS MÉTIER AVANT INSERT
    // ============================================================

    // 1) Validation indices / volume
    if (indexAvant < 0) {
      throw ReceptionValidationException(
        'L\'index avant doit être supérieur ou égal à 0',
        field: 'index_avant',
      );
    }

    if (indexApres <= indexAvant) {
      throw ReceptionValidationException(
        'L\'index après doit être strictement supérieur à l\'index avant',
        field: 'index_apres',
      );
    }

    final volumeAmbiant = indexApres - indexAvant;
    if (volumeAmbiant < 0) {
      throw ReceptionValidationException(
        'Le volume ambiant calculé est négatif (index_apres - index_avant < 0)',
        field: 'volume_ambiant',
      );
    }

    // 2) Validation citerne / produit
    final citerneService = _citerneServiceFactory(_client);
    final citerne = await citerneService.getById(citerneId);

    if (citerne == null) {
      throw ReceptionValidationException(
        'Citerne introuvable',
        field: 'citerne_id',
      );
    }

    if (citerne.statut != 'active') {
      throw ReceptionValidationException(
        'Citerne inactive ou en maintenance',
        field: 'citerne_id',
      );
    }

    if (citerne.produitId != produitId) {
      throw ReceptionValidationException(
        'Produit de la réception différent du produit de la citerne',
        field: 'produit_id',
      );
    }

    // 🚨 PROD-LOCK: Normalisation proprietaire_type UPPERCASE - DO NOT MODIFY
    // RÈGLE MÉTIER : proprietaire_type doit toujours être 'MONALUXE' ou 'PARTENAIRE' en uppercase.
    // PARTENAIRE → partenaire_id OBLIGATOIRE.
    // Si cette logique est modifiée, mettre à jour:
    // - Tests unitaires (reception_service_test.dart)
    // - Tests E2E (reception_flow_e2e_test.dart)
    // - Schéma DB (contraintes CHECK si applicable)

    // Normaliser proprietaire_type en uppercase
    final proprietaireTypeNormalized = proprietaireType.toUpperCase().trim();
    final proprietaireTypeFinal = proprietaireTypeNormalized.isEmpty
        ? 'MONALUXE'
        : (proprietaireTypeNormalized == 'PARTENAIRE'
              ? 'PARTENAIRE'
              : 'MONALUXE');

    if (proprietaireTypeFinal == 'PARTENAIRE') {
      if (partenaireId == null || partenaireId.trim().isEmpty) {
        throw ReceptionValidationException(
          'Partenaire obligatoire pour une réception PARTENAIRE',
          field: 'partenaire_id',
        );
      }
    }

    // 🚨 PROD-LOCK: Validation température/densité OBLIGATOIRES - DO NOT MODIFY
    // RÈGLE MÉTIER : La conversion à 15°C est obligatoire pour toutes les réceptions.
    // Température et densité sont des champs OBLIGATOIRES.
    // Si cette validation est modifiée, mettre à jour:
    // - Tests unitaires (reception_service_test.dart)
    // - Tests E2E (reception_flow_e2e_test.dart)
    // - Documentation métier

    if (temperatureCAmb == null) {
      throw ReceptionValidationException(
        'La température ambiante (°C) est obligatoire pour calculer le volume à 15°C.',
        field: 'temperature_ambiante_c',
      );
    }

    if (densiteA15 == null) {
      throw ReceptionValidationException(
        'La densité à 15°C est obligatoire pour calculer le volume corrigé.',
        field: 'densite_a_15',
      );
    }

    // Récupérer le code produit pour le calcul
    final produits = await _refRepo.loadProduits();

    // Trouver le produit correspondant
    refs.ProduitRef? produit;
    try {
      produit = produits.firstWhere((p) => p.id == produitId);
    } catch (_) {
      // Si produit non trouvé, utiliser le premier disponible comme fallback
      if (produits.isNotEmpty) {
        produit = produits.first;
      }
    }

    // 🚨 PROD-LOCK: Calcul volume 15°C OBLIGATOIRE - DO NOT MODIFY
    // RÈGLE MÉTIER : volume_corrige_15c est TOUJOURS calculé (non-null).
    // Température et densité sont garanties non-null par validation ci-dessus.
    // Si cette logique est modifiée, mettre à jour:
    // - Tests unitaires (reception_service_test.dart)
    // - Tests E2E (reception_flow_e2e_test.dart)
    // - Schéma DB (contrainte NOT NULL sur volume_corrige_15c)

    // Calculer le volume à 15°C (toujours calculé car température et densité sont non-null)
    double volumeCorrige15CFinal;
    if (produit != null) {
      // Utiliser computeV15 qui gère le produitCode
      volumeCorrige15CFinal = computeV15(
        volumeAmbiant: volumeAmbiant,
        temperatureC: temperatureCAmb, // non-null garanti par validation
        densiteA15: densiteA15, // non-null garanti par validation
        produitCode: produit.code,
      );
    } else {
      // Fallback si produit non trouvé : utiliser volume_ambiant
      // (cas rare, mais on évite une exception)
      volumeCorrige15CFinal = volumeAmbiant;
    }

    // Si volumeCorrige15C était fourni explicitement, on l'utilise (priorité)
    if (volumeCorrige15C != null) {
      volumeCorrige15CFinal = volumeCorrige15C;
    }

    // ============================================================
    // PRÉPARATION DU PAYLOAD
    // ============================================================
    final Map<String, dynamic> payload = {
      if (coursDeRouteId != null) 'cours_de_route_id': coursDeRouteId,
      'citerne_id': citerneId,
      'produit_id': produitId,
      'index_avant': indexAvant,
      'index_apres': indexApres,
      'volume_ambiant': volumeAmbiant,
      'temperature_ambiante_c':
          temperatureCAmb, // toujours présent (validation obligatoire)
      'densite_a_15': densiteA15, // toujours présent (validation obligatoire)
      'volume_corrige_15c':
          volumeCorrige15CFinal, // toujours calculé (non-null)
      'proprietaire_type': proprietaireTypeFinal,
      if (partenaireId != null && partenaireId.trim().isNotEmpty)
        'partenaire_id': partenaireId.trim(),
      if (dateReception != null)
        'date_reception': dateReception.toIso8601String().substring(0, 10),
      if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
      // NE PAS envoyer 'statut' : la DB a DEFAULT 'validee' et un trigger applique les effets
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
      // Mapper l'erreur Postgres en exception centralisée
      final insertException = ReceptionInsertException.fromPostgrest(e);

      // Logs détaillés pour diagnostic
      debugPrint(
        '[ReceptionService][PostgrestException] ${insertException.toLogString()}',
      );
      debugPrint('[ReceptionService] payload=${jsonEncode(payload)}');
      debugPrint('[ReceptionService] stack=\n$st');

      // Relancer l'exception centralisée
      throw insertException;
    } catch (e, st) {
      // Si c'est déjà une ReceptionInsertException, la relancer
      if (e is ReceptionInsertException) rethrow;

      // Sinon, logger et relancer
      debugPrint('[ReceptionService][UnknownError] $e');
      debugPrint('[ReceptionService] stack=\n$st');
      debugPrint('[ReceptionService] payload=${jsonEncode(payload)}');
      rethrow;
    }
  }

  // DB-STRICT: createDraft et validate ont été supprimés.
  // Les réceptions sont créées directement validées via createValidated().
  // La DB applique automatiquement les effets (stocks + CDR DECHARGE) via triggers.
}

final receptionServiceProvider = Riverpod.Provider<ReceptionService>((ref) {
  final repo = ref.read(refs.referentielsRepoProvider);
  return ReceptionService.withClient(Supabase.instance.client, refRepo: repo);
});

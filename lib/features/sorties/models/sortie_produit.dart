// 📁 lib/features/sorties/models/sortie_produit.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sortie_produit.freezed.dart';
part 'sortie_produit.g.dart';

@freezed
class SortieProduit with _$SortieProduit {
  const factory SortieProduit({
    required String id,

    @JsonKey(name: 'citerne_id') required String citerneId,
    @JsonKey(name: 'produit_id') required String produitId,

    // Bénéficiaire (au moins l'un des deux doit être fourni côté DB via CHECK)
    @JsonKey(name: 'client_id') String? clientId,
    @JsonKey(name: 'partenaire_id') String? partenaireId,

    // Mesures
    @JsonKey(name: 'index_avant') required double indexAvant,
    @JsonKey(name: 'index_apres') required double indexApres,
    @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
    @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
    @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
    @JsonKey(name: 'densite_a_15') double? densiteA15,

    // Statut & propriété
    @JsonKey(name: 'statut') @Default('brouillon') String statut,
    @JsonKey(name: 'proprietaire_type') @Default('MONALUXE') String proprietaireType,

    // Logistique
    @JsonKey(name: 'date_sortie') DateTime? dateSortie,
    @JsonKey(name: 'chauffeur_nom') String? chauffeurNom,
    @JsonKey(name: 'plaque_camion') String? plaqueCamion,
    @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
    @JsonKey(name: 'transporteur') String? transporteur,

    // Audit
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'validated_by') String? validatedBy,

    String? note,
  }) = _SortieProduit;

  factory SortieProduit.fromJson(Map<String, dynamic> json) => _$SortieProduitFromJson(json);
}

// 📌 Module : Réceptions - Modèle
// 🧭 Description : Modèle de réception (une seule citerne par réception)

import 'package:freezed_annotation/freezed_annotation.dart';
import 'owner_type.dart';

part 'reception.freezed.dart';
part 'reception.g.dart';

@freezed
class Reception with _$Reception {
  const Reception._();

  const factory Reception({
    required String id,

    @JsonKey(name: 'cours_de_route_id') String? coursDeRouteId,
    @JsonKey(name: 'citerne_id') required String citerneId,
    @JsonKey(name: 'produit_id') required String produitId,
    @JsonKey(name: 'partenaire_id') String? partenaireId,

    @JsonKey(name: 'index_avant') required double indexAvant,
    @JsonKey(name: 'index_apres') required double indexApres,
    @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
    @JsonKey(name: 'densite_a_15_kgm3') double? densiteA15Kgm3,
    @JsonKey(name: 'volume_15c') double? volume15c,
    @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
    @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,

    @JsonKey(name: 'proprietaire_type')
    @OwnerTypeConverter()
    required OwnerType proprietaireType,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'statut') String? statut,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'validated_by') String? validatedBy,
  }) = _Reception;

  factory Reception.fromJson(Map<String, dynamic> json) =>
      _$ReceptionFromJson(json);

  /// Volume @15 °C effectif : canonique DB puis fallback legacy (lecture uniquement).
  double? get effectiveVolume15c => volume15c ?? volumeCorrige15c;

  bool get hasCanonicalVolume15c => volume15c != null;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reception.freezed.dart';
part 'reception.g.dart';

enum OwnerType { MONALUXE, PARTENAIRE }

class OwnerTypeConverter implements JsonConverter<OwnerType, String> {
  const OwnerTypeConverter();
  @override
  OwnerType fromJson(String json) =>
      json.toUpperCase() == 'PARTENAIRE' ? OwnerType.PARTENAIRE : OwnerType.MONALUXE;
  @override
  String toJson(OwnerType obj) => obj.name.toLowerCase();
}

@freezed
class Reception with _$Reception {
  const factory Reception({
    required String id,
    @JsonKey(name: 'cours_de_route_id') required String coursDeRouteId,
    @JsonKey(name: 'citerne_id') required String citerneId,
    @JsonKey(name: 'produit_id') required String produitId,
    @JsonKey(name: 'partenaire_id') String? partenaireId,
    @JsonKey(name: 'index_avant') required double indexAvant,
    @JsonKey(name: 'index_apres') required double indexApres,
    @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
    @JsonKey(name: 'densite_a_15') double? densiteA15,
    @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
    @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
    @JsonKey(name: 'proprietaire_type') @OwnerTypeConverter() required OwnerType proprietaireType,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String? statut,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'validated_by') String? validatedBy,
    @JsonKey(name: 'date_reception') DateTime? dateReception,
  }) = _Reception;

  factory Reception.fromJson(Map<String, dynamic> json) =>
      _$ReceptionFromJson(json);
}

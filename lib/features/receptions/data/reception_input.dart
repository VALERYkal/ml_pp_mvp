import 'package:freezed_annotation/freezed_annotation.dart';

part 'reception_input.freezed.dart';
part 'reception_input.g.dart';

@freezed
class ReceptionInput with _$ReceptionInput {
  const factory ReceptionInput({
    required String citerneId,
    String? coursDeRouteId,
    // 'MONALUXE' | 'PARTENAIRE'
    required String proprietaireType,
    @JsonKey(name: 'produit_code') required String produitCode,
    String? produitId,
    double? indexAvant,
    double? indexApres,
    double? temperatureC,
    double? densiteA15,
    DateTime? dateReception, // gère le formatage dans le repo si besoin
    String? partenaireId,
    String? note,
  }) = _ReceptionInput;

  factory ReceptionInput.fromJson(Map<String, dynamic> json) =>
      _$ReceptionInputFromJson(json);
}

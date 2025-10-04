/* ===========================================================
   Patch mineur — ReceptionInput
   Ajout: `produitId` (optionnel). Si fourni (ex: via CDR sélectionné),
   le service l'utilise tel quel et ne fait PAS de lookup par code.
   =========================================================== */

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reception_input.freezed.dart';
part 'reception_input.g.dart';

@freezed
class ReceptionInput with _$ReceptionInput {
  const factory ReceptionInput({
    required String proprietaireType, // 'MONALUXE' | 'PARTENAIRE'
    String? partenaireId, // requis si PARTENAIRE
    required String citerneId, // citerne active
    required String produitCode, // 'ESS' | 'AGO' (reste utile pour calcul @15°C)
    String? produitId, // <-- NEW: override direct du produit (UUID)
    double? indexAvant,
    double? indexApres,
    double? temperatureC,
    double? densiteA15,
    DateTime? dateReception, // SQL date -> yyyy-MM-dd
    String? coursDeRouteId, // requis si Monaluxe lié à un cours 'arrivé'
    String? note,
  }) = _ReceptionInput;

  factory ReceptionInput.fromJson(Map<String, dynamic> json) => _$ReceptionInputFromJson(json);
}

// 📌 Module : Stocks Adjustments - Modèle
// 🧭 Description : Modèle d'ajustement de stock (correction officielle)

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_adjustment.freezed.dart';
part 'stock_adjustment.g.dart';

@freezed
class StockAdjustment with _$StockAdjustment {
  const factory StockAdjustment({
    required String id,
    @JsonKey(name: 'mouvement_type') required String mouvementType,
    @JsonKey(name: 'mouvement_id') required String mouvementId,
    @JsonKey(name: 'delta_ambiant') required double deltaAmbiant,
    @JsonKey(name: 'delta_15c') required double delta15c,
    required String reason,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _StockAdjustment;

  factory StockAdjustment.fromJson(Map<String, dynamic> json) =>
      _$StockAdjustmentFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_adjustment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockAdjustmentImpl _$$StockAdjustmentImplFromJson(
  Map<String, dynamic> json,
) => _$StockAdjustmentImpl(
  id: json['id'] as String,
  mouvementType: json['mouvement_type'] as String,
  mouvementId: json['mouvement_id'] as String,
  deltaAmbiant: (json['delta_ambiant'] as num).toDouble(),
  delta15c: (json['delta_15c'] as num).toDouble(),
  reason: json['reason'] as String,
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$StockAdjustmentImplToJson(
  _$StockAdjustmentImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'mouvement_type': instance.mouvementType,
  'mouvement_id': instance.mouvementId,
  'delta_ambiant': instance.deltaAmbiant,
  'delta_15c': instance.delta15c,
  'reason': instance.reason,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
};

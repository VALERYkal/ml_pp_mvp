// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceptionInputImpl _$$ReceptionInputImplFromJson(Map<String, dynamic> json) =>
    _$ReceptionInputImpl(
      proprietaireType: json['proprietaireType'] as String,
      partenaireId: json['partenaireId'] as String?,
      citerneId: json['citerneId'] as String,
      produitCode: json['produitCode'] as String,
      produitId: json['produitId'] as String?,
      indexAvant: (json['indexAvant'] as num?)?.toDouble(),
      indexApres: (json['indexApres'] as num?)?.toDouble(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      densiteA15: (json['densiteA15'] as num?)?.toDouble(),
      dateReception: json['dateReception'] == null
          ? null
          : DateTime.parse(json['dateReception'] as String),
      coursDeRouteId: json['coursDeRouteId'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ReceptionInputImplToJson(
  _$ReceptionInputImpl instance,
) => <String, dynamic>{
  'proprietaireType': instance.proprietaireType,
  'partenaireId': instance.partenaireId,
  'citerneId': instance.citerneId,
  'produitCode': instance.produitCode,
  'produitId': instance.produitId,
  'indexAvant': instance.indexAvant,
  'indexApres': instance.indexApres,
  'temperatureC': instance.temperatureC,
  'densiteA15': instance.densiteA15,
  'dateReception': instance.dateReception?.toIso8601String(),
  'coursDeRouteId': instance.coursDeRouteId,
  'note': instance.note,
};

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
  if (instance.partenaireId case final value?) 'partenaireId': value,
  'citerneId': instance.citerneId,
  'produitCode': instance.produitCode,
  if (instance.produitId case final value?) 'produitId': value,
  if (instance.indexAvant case final value?) 'indexAvant': value,
  if (instance.indexApres case final value?) 'indexApres': value,
  if (instance.temperatureC case final value?) 'temperatureC': value,
  if (instance.densiteA15 case final value?) 'densiteA15': value,
  if (instance.dateReception?.toIso8601String() case final value?)
    'dateReception': value,
  if (instance.coursDeRouteId case final value?) 'coursDeRouteId': value,
  if (instance.note case final value?) 'note': value,
};

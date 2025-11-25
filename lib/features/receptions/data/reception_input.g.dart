// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceptionInputImpl _$$ReceptionInputImplFromJson(Map<String, dynamic> json) =>
    _$ReceptionInputImpl(
      citerneId: json['citerneId'] as String,
      coursDeRouteId: json['coursDeRouteId'] as String?,
      proprietaireType: json['proprietaireType'] as String,
      produitCode: json['produit_code'] as String,
      produitId: json['produitId'] as String?,
      indexAvant: (json['indexAvant'] as num?)?.toDouble(),
      indexApres: (json['indexApres'] as num?)?.toDouble(),
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      densiteA15: (json['densiteA15'] as num?)?.toDouble(),
      dateReception: json['dateReception'] == null
          ? null
          : DateTime.parse(json['dateReception'] as String),
      partenaireId: json['partenaireId'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ReceptionInputImplToJson(
        _$ReceptionInputImpl instance) =>
    <String, dynamic>{
      'citerneId': instance.citerneId,
      if (instance.coursDeRouteId case final value?) 'coursDeRouteId': value,
      'proprietaireType': instance.proprietaireType,
      'produit_code': instance.produitCode,
      if (instance.produitId case final value?) 'produitId': value,
      if (instance.indexAvant case final value?) 'indexAvant': value,
      if (instance.indexApres case final value?) 'indexApres': value,
      if (instance.temperatureC case final value?) 'temperatureC': value,
      if (instance.densiteA15 case final value?) 'densiteA15': value,
      if (instance.dateReception?.toIso8601String() case final value?)
        'dateReception': value,
      if (instance.partenaireId case final value?) 'partenaireId': value,
      if (instance.note case final value?) 'note': value,
    };

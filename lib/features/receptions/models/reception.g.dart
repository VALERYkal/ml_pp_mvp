// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceptionImpl _$$ReceptionImplFromJson(Map<String, dynamic> json) =>
    _$ReceptionImpl(
      id: json['id'] as String,
      coursDeRouteId: json['cours_de_route_id'] as String?,
      citerneId: json['citerne_id'] as String,
      produitId: json['produit_id'] as String,
      partenaireId: json['partenaire_id'] as String?,
      indexAvant: (json['index_avant'] as num).toDouble(),
      indexApres: (json['index_apres'] as num).toDouble(),
      temperatureAmbianteC: (json['temperature_ambiante_c'] as num?)
          ?.toDouble(),
      densiteA15: (json['densite_a_15'] as num?)?.toDouble(),
      volumeCorrige15c: (json['volume_corrige_15c'] as num?)?.toDouble(),
      volumeAmbiant: (json['volume_ambiant'] as num?)?.toDouble(),
      proprietaireType: const OwnerTypeConverter().fromJson(
        json['proprietaire_type'] as String,
      ),
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      statut: json['statut'] as String?,
      createdBy: json['created_by'] as String?,
      validatedBy: json['validated_by'] as String?,
    );

Map<String, dynamic> _$$ReceptionImplToJson(
  _$ReceptionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  if (instance.coursDeRouteId case final value?) 'cours_de_route_id': value,
  'citerne_id': instance.citerneId,
  'produit_id': instance.produitId,
  if (instance.partenaireId case final value?) 'partenaire_id': value,
  'index_avant': instance.indexAvant,
  'index_apres': instance.indexApres,
  if (instance.temperatureAmbianteC case final value?)
    'temperature_ambiante_c': value,
  if (instance.densiteA15 case final value?) 'densite_a_15': value,
  if (instance.volumeCorrige15c case final value?) 'volume_corrige_15c': value,
  if (instance.volumeAmbiant case final value?) 'volume_ambiant': value,
  'proprietaire_type': const OwnerTypeConverter().toJson(
    instance.proprietaireType,
  ),
  if (instance.note case final value?) 'note': value,
  if (instance.createdAt?.toIso8601String() case final value?)
    'created_at': value,
  if (instance.statut case final value?) 'statut': value,
  if (instance.createdBy case final value?) 'created_by': value,
  if (instance.validatedBy case final value?) 'validated_by': value,
};

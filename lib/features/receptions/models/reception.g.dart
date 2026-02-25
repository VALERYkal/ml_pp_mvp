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
      densiteA15Kgm3: (json['densite_a_15_kgm3'] as num?)?.toDouble(),
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

Map<String, dynamic> _$$ReceptionImplToJson(_$ReceptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cours_de_route_id': instance.coursDeRouteId,
      'citerne_id': instance.citerneId,
      'produit_id': instance.produitId,
      'partenaire_id': instance.partenaireId,
      'index_avant': instance.indexAvant,
      'index_apres': instance.indexApres,
      'temperature_ambiante_c': instance.temperatureAmbianteC,
      'densite_a_15_kgm3': instance.densiteA15Kgm3,
      'volume_corrige_15c': instance.volumeCorrige15c,
      'volume_ambiant': instance.volumeAmbiant,
      'proprietaire_type': const OwnerTypeConverter().toJson(
        instance.proprietaireType,
      ),
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
      'statut': instance.statut,
      'created_by': instance.createdBy,
      'validated_by': instance.validatedBy,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sortie_produit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SortieProduitImpl _$$SortieProduitImplFromJson(Map<String, dynamic> json) =>
    _$SortieProduitImpl(
      id: json['id'] as String,
      citerneId: json['citerne_id'] as String,
      produitId: json['produit_id'] as String,
      clientId: json['client_id'] as String?,
      partenaireId: json['partenaire_id'] as String?,
      indexAvant: (json['index_avant'] as num).toDouble(),
      indexApres: (json['index_apres'] as num).toDouble(),
      volumeAmbiant: (json['volume_ambiant'] as num?)?.toDouble(),
      volumeCorrige15c: (json['volume_corrige_15c'] as num?)?.toDouble(),
      temperatureAmbianteC: (json['temperature_ambiante_c'] as num?)
          ?.toDouble(),
      densiteA15: (json['densite_a_15'] as num?)?.toDouble(),
      statut: json['statut'] as String? ?? 'brouillon',
      proprietaireType: json['proprietaire_type'] as String? ?? 'MONALUXE',
      dateSortie: json['date_sortie'] == null
          ? null
          : DateTime.parse(json['date_sortie'] as String),
      chauffeurNom: json['chauffeur_nom'] as String?,
      plaqueCamion: json['plaque_camion'] as String?,
      plaqueRemorque: json['plaque_remorque'] as String?,
      transporteur: json['transporteur'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
      validatedBy: json['validated_by'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$SortieProduitImplToJson(_$SortieProduitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'citerne_id': instance.citerneId,
      'produit_id': instance.produitId,
      'client_id': instance.clientId,
      'partenaire_id': instance.partenaireId,
      'index_avant': instance.indexAvant,
      'index_apres': instance.indexApres,
      'volume_ambiant': instance.volumeAmbiant,
      'volume_corrige_15c': instance.volumeCorrige15c,
      'temperature_ambiante_c': instance.temperatureAmbianteC,
      'densite_a_15': instance.densiteA15,
      'statut': instance.statut,
      'proprietaire_type': instance.proprietaireType,
      'date_sortie': instance.dateSortie?.toIso8601String(),
      'chauffeur_nom': instance.chauffeurNom,
      'plaque_camion': instance.plaqueCamion,
      'plaque_remorque': instance.plaqueRemorque,
      'transporteur': instance.transporteur,
      'created_at': instance.createdAt?.toIso8601String(),
      'created_by': instance.createdBy,
      'validated_by': instance.validatedBy,
      'note': instance.note,
    };

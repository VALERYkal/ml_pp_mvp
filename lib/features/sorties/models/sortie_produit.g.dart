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

Map<String, dynamic> _$$SortieProduitImplToJson(
  _$SortieProduitImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'citerne_id': instance.citerneId,
  'produit_id': instance.produitId,
  if (instance.clientId case final value?) 'client_id': value,
  if (instance.partenaireId case final value?) 'partenaire_id': value,
  'index_avant': instance.indexAvant,
  'index_apres': instance.indexApres,
  if (instance.volumeAmbiant case final value?) 'volume_ambiant': value,
  if (instance.volumeCorrige15c case final value?) 'volume_corrige_15c': value,
  if (instance.temperatureAmbianteC case final value?)
    'temperature_ambiante_c': value,
  if (instance.densiteA15 case final value?) 'densite_a_15': value,
  'statut': instance.statut,
  'proprietaire_type': instance.proprietaireType,
  if (instance.dateSortie?.toIso8601String() case final value?)
    'date_sortie': value,
  if (instance.chauffeurNom case final value?) 'chauffeur_nom': value,
  if (instance.plaqueCamion case final value?) 'plaque_camion': value,
  if (instance.plaqueRemorque case final value?) 'plaque_remorque': value,
  if (instance.transporteur case final value?) 'transporteur': value,
  if (instance.createdAt?.toIso8601String() case final value?)
    'created_at': value,
  if (instance.createdBy case final value?) 'created_by': value,
  if (instance.validatedBy case final value?) 'validated_by': value,
  if (instance.note case final value?) 'note': value,
};

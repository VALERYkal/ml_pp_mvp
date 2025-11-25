// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cours_de_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CoursDeRouteImpl _$$CoursDeRouteImplFromJson(Map<String, dynamic> json) =>
    _$CoursDeRouteImpl(
      id: json['id'] as String,
      fournisseurId: json['fournisseur_id'] as String,
      produitId: json['produit_id'] as String,
      produitCode: json['produit_code'] as String?,
      depotDestinationId: json['depot_destination_id'] as String,
      transporteur: json['transporteur'] as String?,
      plaqueCamion: json['plaque_camion'] as String?,
      plaqueRemorque: json['plaque_remorque'] as String?,
      chauffeur: json['chauffeur'] as String?,
      volume: (json['volume'] as num?)?.toDouble(),
      pays: json['pays'] as String?,
      dateChargement: json['date_chargement'] == null
          ? null
          : DateTime.parse(json['date_chargement'] as String),
      dateArriveePrevue: json['date_arrivee_prevue'] == null
          ? null
          : DateTime.parse(json['date_arrivee_prevue'] as String),
      statut: $enumDecode(_$StatutCoursEnumMap, json['statut']),
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CoursDeRouteImplToJson(_$CoursDeRouteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fournisseur_id': instance.fournisseurId,
      'produit_id': instance.produitId,
      if (instance.produitCode case final value?) 'produit_code': value,
      'depot_destination_id': instance.depotDestinationId,
      if (instance.transporteur case final value?) 'transporteur': value,
      if (instance.plaqueCamion case final value?) 'plaque_camion': value,
      if (instance.plaqueRemorque case final value?) 'plaque_remorque': value,
      if (instance.chauffeur case final value?) 'chauffeur': value,
      if (instance.volume case final value?) 'volume': value,
      if (instance.pays case final value?) 'pays': value,
      if (instance.dateChargement?.toIso8601String() case final value?)
        'date_chargement': value,
      if (instance.dateArriveePrevue?.toIso8601String() case final value?)
        'date_arrivee_prevue': value,
      'statut': _$StatutCoursEnumMap[instance.statut]!,
      if (instance.note case final value?) 'note': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updated_at': value,
    };

const _$StatutCoursEnumMap = {
  StatutCours.chargement: 'chargement',
  StatutCours.transit: 'transit',
  StatutCours.frontiere: 'frontiere',
  StatutCours.arrive: 'arrive',
  StatutCours.decharge: 'decharge',
  StatutCours.inconnu: 'inconnu',
};

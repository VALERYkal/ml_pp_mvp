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
      dateChargement: json['date_chargement'] == null
          ? null
          : DateTime.parse(json['date_chargement'] as String),
      dateArriveePrevue: json['date_arrivee_prevue'] == null
          ? null
          : DateTime.parse(json['date_arrivee_prevue'] as String),
      pays: json['pays'] as String?,
      statut: json['statut'] == null
          ? StatutCours.chargement
          : const StatutCoursConverter().fromJson(json['statut'] as String),
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
      'produit_code': instance.produitCode,
      'depot_destination_id': instance.depotDestinationId,
      'transporteur': instance.transporteur,
      'plaque_camion': instance.plaqueCamion,
      'plaque_remorque': instance.plaqueRemorque,
      'chauffeur': instance.chauffeur,
      'volume': instance.volume,
      'date_chargement': instance.dateChargement?.toIso8601String(),
      'date_arrivee_prevue': instance.dateArriveePrevue?.toIso8601String(),
      'pays': instance.pays,
      'statut': const StatutCoursConverter().toJson(instance.statut),
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

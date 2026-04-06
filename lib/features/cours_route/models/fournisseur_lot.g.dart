// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fournisseur_lot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FournisseurLotImpl _$$FournisseurLotImplFromJson(Map<String, dynamic> json) =>
    _$FournisseurLotImpl(
      id: json['id'] as String,
      fournisseurId: json['fournisseur_id'] as String,
      produitId: json['produit_id'] as String,
      produitCode: json['produit_code'] as String?,
      reference: json['reference'] as String,
      dateLot: json['date_lot'] == null
          ? null
          : DateTime.parse(json['date_lot'] as String),
      statut: json['statut'] == null
          ? StatutFournisseurLot.ouvert
          : const StatutFournisseurLotConverter().fromJson(
              json['statut'] as String,
            ),
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$FournisseurLotImplToJson(
  _$FournisseurLotImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'fournisseur_id': instance.fournisseurId,
  'produit_id': instance.produitId,
  'produit_code': instance.produitCode,
  'reference': instance.reference,
  'date_lot': instance.dateLot?.toIso8601String(),
  'statut': const StatutFournisseurLotConverter().toJson(instance.statut),
  'note': instance.note,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

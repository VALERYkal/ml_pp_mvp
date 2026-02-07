// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fournisseur.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FournisseurImpl _$$FournisseurImplFromJson(Map<String, dynamic> json) =>
    _$FournisseurImpl(
      id: json['id'] as String,
      nom: json['nom'] as String,
      contactPersonne: json['contact_personne'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
      pays: json['pays'] as String?,
      noteSupplementaire: json['note_supplementaire'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FournisseurImplToJson(_$FournisseurImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'contact_personne': instance.contactPersonne,
      'email': instance.email,
      'telephone': instance.telephone,
      'adresse': instance.adresse,
      'pays': instance.pays,
      'note_supplementaire': instance.noteSupplementaire,
      'created_at': instance.createdAt?.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profil.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfilImpl _$$ProfilImplFromJson(Map<String, dynamic> json) => _$ProfilImpl(
  id: json['id'] as String,
  userId: json['user_id'] as String?,
  nomComplet: json['nom_complet'] as String?,
  role: const UserRoleConverter().fromJson(json['role'] as String),
  depotId: json['depot_id'] as String?,
  email: json['email'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$ProfilImplToJson(_$ProfilImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'nom_complet': instance.nomComplet,
      'role': const UserRoleConverter().toJson(instance.role),
      'depot_id': instance.depotId,
      'email': instance.email,
      'created_at': instance.createdAt?.toIso8601String(),
    };

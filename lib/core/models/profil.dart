// 📁 lib/core/models/profil.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/core/models/user_role_converter.dart';

part 'profil.freezed.dart';
part 'profil.g.dart';

@freezed
class Profil with _$Profil {
  const factory Profil({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'nom_complet') String? nomComplet,
    @JsonKey(name: 'role') @UserRoleConverter() required UserRole role,
    @JsonKey(name: 'depot_id') String? depotId,
    String? email,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profil;

  factory Profil.fromJson(Map<String, dynamic> json) => _$ProfilFromJson(json);

  /// Factory avec parsing robuste du rôle
  factory Profil.fromMap(Map<String, dynamic> map) {
    return Profil(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      nomComplet: map['nom_complet'] as String?,
      role: UserRoleX.fromStringOrDefault(map['role'] as String?),
      depotId: map['depot_id'] as String?,
      email: map['email'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}

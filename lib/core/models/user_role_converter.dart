// lib/core/models/user_role_converter.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Convertisseur tolérant (insensible à la casse, gère alias).
class UserRoleConverter implements JsonConverter<UserRole, Object?> {
  const UserRoleConverter();

  static final Map<String, UserRole> _from = {
    'admin': UserRole.admin,
    'directeur': UserRole.directeur,
    'gerant': UserRole.gerant,
    'gérant': UserRole.gerant,
    'operateur': UserRole.operateur,
    'opérateur': UserRole.operateur,
    'pca': UserRole.pca,
    'lecture': UserRole.lecture,
    'director': UserRole.directeur,
    'manager': UserRole.gerant,
    'operator': UserRole.operateur,
    'read_only': UserRole.lecture,
    'read-only': UserRole.lecture,
    'readonly': UserRole.lecture,
    'read': UserRole.lecture,
    'viewer': UserRole.lecture,
  };

  @override
  UserRole fromJson(Object? json) {
    if (json == null) return UserRole.lecture;
    final key = json.toString().trim().toLowerCase();
    return _from[key] ?? UserRole.lecture;
  }

  @override
  Object toJson(UserRole role) => role.wire;
}

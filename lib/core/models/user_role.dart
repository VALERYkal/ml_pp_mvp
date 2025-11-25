import 'package:freezed_annotation/freezed_annotation.dart';

enum UserRole { 
  admin, 
  directeur, 
  gerant, 
  operateur, 
  pca, 
  lecture 
}

class UserRoleConverter implements JsonConverter<UserRole, String> {
  const UserRoleConverter();
  @override
  UserRole fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'admin': return UserRole.admin;
      case 'directeur': return UserRole.directeur;
      case 'gerant': 
      case 'gérant': 
        return UserRole.gerant;
      case 'operateur': 
      case 'opérateur': 
        return UserRole.operateur;
      case 'pca': return UserRole.pca;
      case 'lecture': return UserRole.lecture;
      default: return UserRole.lecture;
    }
  }
  @override
  String toJson(UserRole role) => role.name;
}

extension UserRoleX on UserRole {
  /// Nom canonique utilisé côté API / base de données.
  String get wire {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.directeur:
        return 'directeur';
      case UserRole.gerant:
        return 'gerant';
      case UserRole.operateur:
        return 'operateur';
      case UserRole.pca:
        return 'pca';
      case UserRole.lecture:
        return 'lecture';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  String get dashboardPath {
    switch (this) {
      case UserRole.admin:
        return '/dashboard/admin';
      case UserRole.directeur:
        return '/dashboard/directeur';
      case UserRole.gerant:
        return '/dashboard/gerant';
      case UserRole.operateur:
        return '/dashboard/operateur';
      case UserRole.pca:
        return '/dashboard/pca';
      case UserRole.lecture:
        return '/dashboard/lecture';
    }
  }
}

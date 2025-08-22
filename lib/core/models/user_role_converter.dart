// 📌 Module : Core Models
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.profils` (contrainte role_check)
// 🧭 Description : Convertisseur JSON pour l'enum UserRole

import 'package:json_annotation/json_annotation.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Convertisseur JSON pour l'enum UserRole
/// 
/// Permet la sérialisation/désérialisation automatique
/// de l'enum UserRole avec json_serializable.
/// 
/// Utilisé par :
/// - Le modèle Profil pour le champ role
/// - Les autres modèles qui utilisent UserRole
class UserRoleConverter implements JsonConverter<UserRole, String> {
  /// Constructeur par défaut
  const UserRoleConverter();

  @override
  UserRole fromJson(String json) {
    // Utilise le parsing robuste avec fallback sécurisé
    return UserRoleX.fromStringOrDefault(json, fallback: UserRole.lecture);
  }

  @override
  String toJson(UserRole object) => object.value;
}

// 📌 Module : Auth Tests - Test Fixtures
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Fixtures pour les tests d'authentification

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Fixtures pour les tests d'authentification
class AuthFixtures {
  /// Utilisateur test admin
  static User get adminUser => User(
        id: 'admin-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'admin@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Utilisateur test directeur
  static User get directeurUser => User(
        id: 'directeur-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'directeur@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Utilisateur test gérant
  static User get gerantUser => User(
        id: 'gerant-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'gerant@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Utilisateur test opérateur
  static User get operateurUser => User(
        id: 'operateur-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'operateur@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Utilisateur test PCA
  static User get pcaUser => User(
        id: 'pca-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'pca@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Utilisateur test lecture
  static User get lectureUser => User(
        id: 'lecture-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'lecture@test.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
        phone: '',
        confirmedAt: DateTime.now().toIso8601String(),
        lastSignInAt: DateTime.now().toIso8601String(),
        role: 'authenticated',
        updatedAt: DateTime.now().toIso8601String(),
      );

  /// Profil test admin
  static Profil get adminProfil => Profil(
        id: 'admin-profil-id',
        userId: 'admin-user-id',
        role: 'admin',
        nomComplet: 'Admin User',
        email: 'admin@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Profil test directeur
  static Profil get directeurProfil => Profil(
        id: 'directeur-profil-id',
        userId: 'directeur-user-id',
        role: 'directeur',
        nomComplet: 'Directeur User',
        email: 'directeur@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Profil test gérant
  static Profil get gerantProfil => Profil(
        id: 'gerant-profil-id',
        userId: 'gerant-user-id',
        role: 'gerant',
        nomComplet: 'Gerant User',
        email: 'gerant@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Profil test opérateur
  static Profil get operateurProfil => Profil(
        id: 'operateur-profil-id',
        userId: 'operateur-user-id',
        role: 'operateur',
        nomComplet: 'Operateur User',
        email: 'operateur@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Profil test PCA
  static Profil get pcaProfil => Profil(
        id: 'pca-profil-id',
        userId: 'pca-user-id',
        role: 'pca',
        nomComplet: 'PCA User',
        email: 'pca@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Profil test lecture
  static Profil get lectureProfil => Profil(
        id: 'lecture-profil-id',
        userId: 'lecture-user-id',
        role: 'lecture',
        nomComplet: 'Lecture User',
        email: 'lecture@test.com',
        depotId: 'depot-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  /// Données JSON pour profil admin
  static Map<String, dynamic> get adminProfilJson => {
        'id': 'admin-profil-id',
        'user_id': 'admin-user-id',
        'role': 'admin',
        'nom_complet': 'Admin User',
        'email': 'admin@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Données JSON pour profil directeur
  static Map<String, dynamic> get directeurProfilJson => {
        'id': 'directeur-profil-id',
        'user_id': 'directeur-user-id',
        'role': 'directeur',
        'nom_complet': 'Directeur User',
        'email': 'directeur@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Données JSON pour profil gérant
  static Map<String, dynamic> get gerantProfilJson => {
        'id': 'gerant-profil-id',
        'user_id': 'gerant-user-id',
        'role': 'gerant',
        'nom_complet': 'Gerant User',
        'email': 'gerant@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Données JSON pour profil opérateur
  static Map<String, dynamic> get operateurProfilJson => {
        'id': 'operateur-profil-id',
        'user_id': 'operateur-user-id',
        'role': 'operateur',
        'nom_complet': 'Operateur User',
        'email': 'operateur@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Données JSON pour profil PCA
  static Map<String, dynamic> get pcaProfilJson => {
        'id': 'pca-profil-id',
        'user_id': 'pca-user-id',
        'role': 'pca',
        'nom_complet': 'PCA User',
        'email': 'pca@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Données JSON pour profil lecture
  static Map<String, dynamic> get lectureProfilJson => {
        'id': 'lecture-profil-id',
        'user_id': 'lecture-user-id',
        'role': 'lecture',
        'nom_complet': 'Lecture User',
        'email': 'lecture@test.com',
        'depot_id': 'depot-1',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  /// Liste de tous les utilisateurs test
  static List<User> get allUsers => [
        adminUser,
        directeurUser,
        gerantUser,
        operateurUser,
        pcaUser,
        lectureUser,
      ];

  /// Liste de tous les profils test
  static List<Profil> get allProfils => [
        adminProfil,
        directeurProfil,
        gerantProfil,
        operateurProfil,
        pcaProfil,
        lectureProfil,
      ];

  /// Liste de tous les rôles
  static List<UserRole> get allRoles => UserRole.values;

  /// Credentials de test pour chaque rôle
  static Map<String, Map<String, String>> get testCredentials => {
        'admin': {'email': 'admin@test.com', 'password': 'admin123'},
        'directeur': {'email': 'directeur@test.com', 'password': 'directeur123'},
        'gerant': {'email': 'gerant@test.com', 'password': 'gerant123'},
        'operateur': {'email': 'operateur@test.com', 'password': 'operateur123'},
        'pca': {'email': 'pca@test.com', 'password': 'pca123'},
        'lecture': {'email': 'lecture@test.com', 'password': 'lecture123'},
      };

  /// Credentials invalides pour les tests d'erreur
  static Map<String, String> get invalidCredentials => {
        'email': 'invalid@test.com',
        'password': 'wrongpassword',
      };

  /// Messages d'erreur attendus
  static Map<String, String> get expectedErrorMessages => {
        'invalid_credentials': 'Identifiants invalides',
        'email_not_confirmed': 'Email non confirmé',
        'network_error': 'Problème réseau',
        'too_many_requests': 'Trop de tentatives. Réessayez plus tard.',
        'permission_denied': 'Accès au profil refusé (policies RLS). Contactez l\'administrateur.',
        'generic_error': 'Erreur inattendue. Réessaie.',
      };

  /// Routes attendues pour chaque rôle
  static Map<String, String> get expectedRoutes => {
        'admin': '/dashboard/admin',
        'directeur': '/dashboard/directeur',
        'gerant': '/dashboard/gerant',
        'operateur': '/dashboard/operateur',
        'pca': '/dashboard/pca',
        'lecture': '/dashboard/lecture',
      };

  /// Menu items attendus pour chaque rôle
  static Map<String, List<String>> get expectedMenuItems => {
        'admin': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
          'Administration',
          'Utilisateurs',
          'Paramètres',
        ],
        'directeur': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
          'Rapports',
        ],
        'gerant': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
          'Gestion des stocks',
        ],
        'operateur': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
        ],
        'pca': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
          'Rapports',
        ],
        'lecture': [
          'Cours de route',
          'Réceptions',
          'Sorties',
          'Stocks',
          'Rapports',
        ],
      };

  /// Permissions attendues pour chaque rôle
  static Map<String, Map<String, bool>> get expectedPermissions => {
        'admin': {
          'canCreateMovements': true,
          'canValidateMovements': true,
          'canManageUsers': true,
          'canAccessReports': true,
          'isReadOnly': false,
        },
        'directeur': {
          'canCreateMovements': true,
          'canValidateMovements': true,
          'canManageUsers': false,
          'canAccessReports': true,
          'isReadOnly': false,
        },
        'gerant': {
          'canCreateMovements': true,
          'canValidateMovements': true,
          'canManageUsers': false,
          'canAccessReports': false,
          'isReadOnly': false,
        },
        'operateur': {
          'canCreateMovements': true,
          'canValidateMovements': false,
          'canManageUsers': false,
          'canAccessReports': false,
          'isReadOnly': false,
        },
        'pca': {
          'canCreateMovements': false,
          'canValidateMovements': false,
          'canManageUsers': false,
          'canAccessReports': true,
          'isReadOnly': true,
        },
        'lecture': {
          'canCreateMovements': false,
          'canValidateMovements': false,
          'canManageUsers': false,
          'canAccessReports': true,
          'isReadOnly': true,
        },
      };
}

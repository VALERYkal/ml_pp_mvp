// ?? Module : Core Services
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-08-07
// ??? Source SQL : Table `auth.users` (Supabase Auth)
// ?? Description : Service d'authentification via Supabase Auth

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'authentification via Supabase Auth
///
/// Gère toutes les opérations d'authentification :
/// - Connexion par email/password
/// - Déconnexion
/// - Vérification de l'état de connexion
/// - Gestion des erreurs d'authentification
///
/// Ce service est utilisé par :
/// - Les écrans d'authentification
/// - Les providers Riverpod pour la gestion d'état
/// - Les guards de navigation
class AuthService {
  /// Client Supabase injecté via constructeur
  final SupabaseClient _client;

  /// Constructeur avec injection de dépendance
  ///
  /// [client] : Instance du client Supabase
  /// Utilisé pour permettre les tests unitaires
  const AuthService.withSupabase(this._client);

  /// Authentifie un utilisateur avec email et mot de passe
  ///
  /// [email] : Adresse email de l'utilisateur
  /// [password] : Mot de passe de l'utilisateur
  ///
  /// Retourne :
  /// - `User` : L'utilisateur connecté en cas de succès
  ///
  /// Exceptions possibles :
  /// - `AuthException` : Erreur d'authentification (mauvais credentials, etc.)
  /// - `PostgrestException` : Erreur de connexion à Supabase
  ///
  /// Exemple d'utilisation :
  /// ```dart
  /// try {
  ///   final user = await authService.signIn('user@example.com', 'password');
  ///   // Connexion réussie
  /// } on AuthException catch (e) {
  ///   // Gérer l'erreur d'authentification
  /// }
  /// ```
  Future<User> signIn(String email, String password) async {
    try {
      debugPrint('?? AuthService: Tentative de connexion pour $email');

      // Validation des paramètres
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email et mot de passe requis');
      }

      // Connexion via Supabase Auth
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Aucun utilisateur retourné après connexion');
      }

      debugPrint('? AuthService: Connexion réussie pour ${response.user!.email}');
      return response.user!;
    } on AuthException catch (e) {
      debugPrint('? AuthService: Erreur d\'authentification - ${e.message}');
      rethrow;
    } on PostgrestException catch (e) {
      debugPrint('? AuthService: Erreur Supabase - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('? AuthService: Erreur inattendue - $e');
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur courant
  ///
  /// Retourne :
  /// - `void` : Déconnexion réussie
  ///
  /// Exceptions possibles :
  /// - `AuthException` : Erreur lors de la déconnexion
  Future<void> signOut() async {
    try {
      debugPrint('?? AuthService: Déconnexion de l\'utilisateur');

      await _client.auth.signOut();

      debugPrint('? AuthService: Déconnexion réussie');
    } on AuthException catch (e) {
      debugPrint('? AuthService: Erreur lors de la déconnexion - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('? AuthService: Erreur inattendue lors de la déconnexion - $e');
      rethrow;
    }
  }

  /// Récupère l'utilisateur courant connecté
  ///
  /// Retourne :
  /// - `User?` : L'utilisateur connecté s'il existe
  /// - `null` : Si aucun utilisateur n'est connecté
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Vérifie si un utilisateur est connecté
  ///
  /// Retourne :
  /// - `true` : Un utilisateur est connecté
  /// - `false` : Aucun utilisateur connecté
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Écoute les changements d'état d'authentification
  ///
  /// Retourne un stream qui émet les changements d'état
  /// Utilisé pour réagir automatiquement aux connexions/déconnexions
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}





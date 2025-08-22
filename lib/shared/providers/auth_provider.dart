// 📌 Module : Shared Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `auth.users` (Supabase Auth)
// 🧭 Description : Provider Riverpod pour le service d'authentification

import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';

/// Provider pour l'instance du service AuthService
/// 
/// Injecte automatiquement le client Supabase dans le service.
/// Utilisé par tous les autres providers et écrans d'authentification.
/// 
/// Exemple d'utilisation :
/// ```dart
/// final authService = ref.read(authServiceProvider);
/// final user = await authService.signIn(email, password);
/// ```
final authServiceProvider = Riverpod.Provider<AuthService>((ref) {
  final client = Supabase.instance.client;
  return AuthService.withSupabase(client);
});

/// Provider pour l'utilisateur courant connecté
/// 
/// Récupère automatiquement l'utilisateur connecté depuis Supabase Auth.
/// Gère les états : loading, error, success.
/// 
/// États possibles :
/// - `AsyncData<User?>` : Utilisateur récupéré avec succès (peut être null)
/// - `AsyncLoading` : Chargement en cours
/// - `AsyncError` : Erreur lors de la récupération
/// 
/// Utilisé par :
/// - Les écrans d'authentification pour vérifier l'état de connexion
/// - Les guards de navigation pour protéger les routes
/// - Les providers de profil pour récupérer les données utilisateur
final currentUserProvider = Riverpod.FutureProvider<User?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getCurrentUser();
});

/// Provider pour vérifier si l'utilisateur est authentifié
/// 
/// Retourne :
/// - `true` : L'utilisateur est connecté
/// - `false` : L'utilisateur n'est pas connecté
/// 
/// Utilisé pour :
/// - La redirection automatique vers le login
/// - L'affichage conditionnel d'éléments UI
/// - La protection des routes
final isAuthenticatedProvider = Riverpod.Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

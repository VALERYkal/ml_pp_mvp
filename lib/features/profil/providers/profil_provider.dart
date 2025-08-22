// 📌 Module : Profil Feature - Providers Layer
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.profils`
// 🧭 Description : Provider Riverpod pour la gestion du profil utilisateur

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/profil.dart';
import '../../../core/models/user_role.dart';
import '../data/profil_service.dart';

/// Provider pour l'instance du service ProfilService
/// 
/// Injecte automatiquement le client Supabase dans le service
/// Utilisé par tous les autres providers du module profil
final profilServiceProvider = Riverpod.Provider<ProfilService>((ref) {
  final client = Supabase.instance.client;
  return ProfilService.withClient(client);
});

/// Provider asynchrone pour le profil utilisateur courant
/// 
/// Récupère automatiquement le profil de l'utilisateur connecté
/// via Supabase Auth et le service ProfilService.
/// 
/// États possibles :
/// - `AsyncData<Profil?>` : Profil récupéré avec succès (peut être null)
/// - `AsyncLoading` : Chargement en cours
/// - `AsyncError` : Erreur lors de la récupération
/// 
/// Utilisé par :
/// - Les écrans d'authentification pour vérifier le profil
/// - Les écrans de navigation pour afficher les infos utilisateur
/// - Les services de validation des permissions
final profilProvider = Riverpod.FutureProvider<Profil?>((ref) async {
  try {
    // Récupération du service via injection de dépendance
    final profilService = ref.read(profilServiceProvider);
    
    // Récupération de l'utilisateur courant depuis Supabase Auth
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    if (currentUser == null) {
      debugPrint('⚠️ ProfilProvider: Aucun utilisateur connecté');
      return null;
    }
    
    final userId = currentUser.id;
    debugPrint('🔍 ProfilProvider: Récupération du profil pour userId: $userId');
    
    // Appel du service pour récupérer le profil
    final profil = await profilService.getCurrentProfil(userId);
    
    if (profil == null) {
      debugPrint('⚠️ ProfilProvider: Aucun profil trouvé pour l\'utilisateur connecté');
    } else {
      debugPrint('✅ ProfilProvider: Profil récupéré - Role: ${profil.role}');
    }
    
    return profil;
    
  } catch (e) {
    debugPrint('❌ ProfilProvider: Erreur lors de la récupération du profil - $e');
    rethrow;
  }
});

/// Provider pour vérifier si l'utilisateur a un profil
/// 
/// Retourne :
/// - `true` : L'utilisateur a un profil valide
/// - `false` : L'utilisateur n'a pas de profil ou n'est pas connecté
/// 
/// Utilisé pour :
/// - La redirection post-login
/// - L'affichage conditionnel d'éléments UI
final hasProfilProvider = Riverpod.Provider<bool>((ref) {
  final profilAsync = ref.watch(profilProvider);
  
  return profilAsync.when(
    data: (profil) => profil != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider pour le profil de l'utilisateur courant
/// 
/// Retourne :
/// - `Profil?` : Le profil de l'utilisateur si connecté et avec profil
/// - `null` : Si pas de profil ou utilisateur non connecté
/// 
/// Utilisé pour :
/// - La validation des permissions
/// - L'affichage conditionnel des fonctionnalités
final userProfilProvider = Riverpod.Provider<Profil?>((ref) {
  final profilAsync = ref.watch(profilProvider);
  
  return profilAsync.when(
    data: (profil) => profil,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider pour le rôle de l'utilisateur courant avec fallback sécurisé
/// 
/// Retourne :
/// - `UserRole` : Le rôle de l'utilisateur (fallback: UserRole.lecture)
/// 
/// Utilisé pour :
/// - La redirection post-login
/// - La validation des permissions
final userRoleProvider = Riverpod.Provider<UserRole>((ref) {
  final profil = ref.watch(userProfilProvider);
  return profil?.role ?? UserRole.lecture; // fallback non-admin
});

/// Provider pour vérifier si l'utilisateur a un rôle spécifique
/// 
/// [role] : Le rôle à vérifier (chaîne de caractères)
/// 
/// Retourne :
/// - `true` : L'utilisateur a le rôle spécifié
/// - `false` : L'utilisateur n'a pas ce rôle ou n'est pas connecté
/// 
/// Utilisé pour :
/// - L'affichage conditionnel des écrans
/// - La validation des actions autorisées
bool hasRole(Riverpod.WidgetRef ref, String role) {
  final userRole = ref.watch(userRoleProvider);
  return userRole.value == role;
}

/// Provider pour vérifier si l'utilisateur a un des rôles spécifiés
/// 
/// [roles] : Liste des rôles autorisés (chaînes de caractères)
/// 
/// Retourne :
/// - `true` : L'utilisateur a au moins un des rôles spécifiés
/// - `false` : L'utilisateur n'a aucun de ces rôles ou n'est pas connecté
/// 
/// Utilisé pour :
/// - L'affichage conditionnel des fonctionnalités
/// - La validation des permissions multi-rôles
bool hasAnyRole(Riverpod.WidgetRef ref, List<String> roles) {
  final userRole = ref.watch(userRoleProvider);
  return roles.contains(userRole.value);
}

// ?? Module : Profil Feature - Providers Layer
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-08-07
// ??? Source SQL : Table `public.profils`
// ?? Description : Provider Riverpod pour la gestion du profil utilisateur

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/profil.dart';
import '../../../core/models/user_role.dart';
import '../data/profil_service.dart';
import '../../../shared/providers/session_provider.dart';

/// Provider pour l'instance du service ProfilService
///
/// Utilise le constructeur par défaut qui injecte automatiquement
/// le client Supabase dans le service
final profilServiceProvider = Provider<ProfilService>((ref) {
  return ProfilService();
});

// ?? Utilisateur réactif basé sur le flux d'auth (et non un snapshot figé)
final reactiveUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(appAuthStateProvider); // StreamProvider<AppAuthState>
  return auth.maybeWhen(data: (a) => a.session?.user, orElse: () => null);
});

/// AsyncNotifier qui expose le profil courant (ou null si non connecté)
///
/// Comportement :
/// 1. Attend que l'utilisateur soit connecté
/// 2. Tente getByCurrentUser() ; si null, tente getOrCreateByCurrentUser()
/// 3. Journalise clairement, sans SnackBar (le provider ne doit pas afficher d'UI)
/// 4. Expose un AsyncValue<Profil?> pour la gestion d'état
class CurrentProfilNotifier extends AsyncNotifier<Profil?> {
  @override
  Future<Profil?> build() async {
    // ?? Log début (temporaire, à retirer après)
    debugPrint('?? CurrentProfilProvider: build() started (auth user watching)');

    // ?? CORRECTIF : Force le rebuild sur changement d'utilisateur (RÉACTIF)
    final user = ref.watch(reactiveUserProvider);
    if (user == null) {
      debugPrint('?? CurrentProfilProvider: no user (post-auth), returning null');
      return null;
    }

    final svc = ref.read(profilServiceProvider);

    // 1) tente de récupérer
    final existing = await svc.getByCurrentUser();
    if (existing != null) {
      // print log
      // ignore: avoid_print
      print('? ProfilProvider: Profil trouvé - role: ${existing.role}');
      debugPrint('?? CurrentProfilProvider: Profil trouvé - role: ${existing.role}');
      return existing;
    }

    // 2) sinon, créer (get-or-create)
    // tu peux dériver defaultRole, email depuis auth.currentUser
    final email = user.email;
    final created = await svc.getOrCreateByCurrentUser(
      defaultRole: 'lecture', // ou 'directeur' si tu préfères provisoirement
      email: email,
    );

    // ignore: avoid_print
    print('? ProfilProvider: Profil créé - role: ${created.role}');
    debugPrint('?? CurrentProfilProvider: Profil créé - role: ${created.role}');
    return created;
  }
}

/// Provider principal pour le profil utilisateur courant
///
/// Utilise AsyncNotifier pour une gestion d'état plus robuste
/// avec get-or-create automatique
final currentProfilProvider = AsyncNotifierProvider<CurrentProfilNotifier, Profil?>(
  () => CurrentProfilNotifier(),
);

/// Provider de compatibilité pour l'ancien nom
/// @deprecated Utilisez currentProfilProvider à la place
final profilProvider = currentProfilProvider;

/// Provider pour vérifier si l'utilisateur a un profil
///
/// Retourne :
/// - `true` : L'utilisateur a un profil valide
/// - `false` : L'utilisateur n'a pas de profil ou n'est pas connecté
///
/// Utilisé pour :
/// - La redirection post-login
/// - L'affichage conditionnel d'éléments UI
final hasProfilProvider = Provider<bool>((ref) {
  final profilAsync = ref.watch(currentProfilProvider);

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
final userProfilProvider = Provider<Profil?>((ref) {
  final profilAsync = ref.watch(currentProfilProvider);

  return profilAsync.when(data: (profil) => profil, loading: () => null, error: (_, __) => null);
});

/// Provider pour le rôle de l'utilisateur courant (nullable)
///
/// IMPORTANT : renvoie null tant que le profil n'est pas disponible.
/// On ne fallback PAS en lecture pendant le chargement.
///
/// Retourne :
/// - `UserRole?` : Le rôle de l'utilisateur (null pendant le chargement)
///
/// Utilisé pour :
/// - La redirection post-login (avec attente du rôle)
/// - La validation des permissions
final userRoleProvider = Provider<UserRole?>((ref) {
  final p = ref.watch(currentProfilProvider);
  final roleStr = p.maybeWhen(data: (v) => v?.role, orElse: () => null);
  final role = (roleStr == null) ? null : const UserRoleConverter().fromJson(roleStr);
  debugPrint('?? userRoleProvider -> $role (state=$p)');
  return role;
});

/// Provider "colle" qui invalide le profil si l'ID user change
///
/// Couvre les cas bord où currentProfilProvider.build() resterait mémorisé
/// et force la reconstruction quand l'utilisateur change
final profilAuthSyncProvider = Provider<void>((ref) {
  ref.listen(appAuthStateProvider, (prev, next) {
    final prevUserId = prev?.asData?.value.session?.user?.id;
    final nextUserId = next.asData?.value.session?.user?.id;
    if (prevUserId != nextUserId) {
      debugPrint('?? ProfilAuthSync: user changed -> invalidate currentProfilProvider');
      ref.invalidate(currentProfilProvider);
    }
  });
});





// lib/shared/providers/session_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

/// ⚠️ Modèle d'état d'auth interne à l'app (à ne pas confondre avec supabase.AuthState)
@immutable
class AppAuthState {
  final Session? session;

  const AppAuthState({required this.session});

  bool get isAuthenticated => session != null;

  User? get user => session?.user;
}

/// Fournit un flux AppAuthState basé sur onAuthStateChange de Supabase.
/// - Rafraîchit à chaque login/logout/refresh token.
/// - Converti en AppAuthState minimal, consommable par l'UI/Router.
final authStateProvider = StreamProvider<AppAuthState>((ref) {
  final auth = Supabase.instance.client.auth;

  // Émettre l'état initial immédiatement (utile au démarrage de l'app)
  final initial = AppAuthState(session: auth.currentSession);

  // Stream des changements provenant de Supabase
  final supabaseStream = auth.onAuthStateChange.map<AppAuthState>((AuthState e) {
    // e.session correspond à la session après l'événement (peut être null)
    return AppAuthState(session: e.session);
  });

  // On renvoie un stream qui commence par l'état initial
  return Stream<AppAuthState>.multi((controller) async {
    controller.add(initial);
    final sub = supabaseStream.listen(controller.add, onError: controller.addError);
    controller.onCancel = () => sub.cancel();
  });
});

/// Dérivé pratique : booléen d'authentification, avec fallback sur l'état instantané
final isAuthenticatedProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.maybeWhen(
    data: (s) => s.isAuthenticated,
    orElse: () {
      // fallback instantané si le stream n'a pas encore émis
      return Supabase.instance.client.auth.currentSession != null;
    },
  );
});

/// Dérivé instantané : utilisateur courant à l'instant T (sans écouter le stream)
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Dérivé instantané : session courante à l'instant T (sans écouter le stream)
final currentSessionProvider = Provider<Session?>((ref) {
  return Supabase.instance.client.auth.currentSession;
});

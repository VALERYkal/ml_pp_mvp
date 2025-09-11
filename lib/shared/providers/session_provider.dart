// lib/shared/providers/session_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

/// ⚠️ Modèle d'état d'auth interne à l'app (à ne pas confondre avec supabase.AuthState)
@immutable
class AppAuthState {
  final Session? session;
  final Stream<AuthState> authStream;

  const AppAuthState({required this.session, required this.authStream});

  bool get isAuthenticated => session != null;

  User? get user => session?.user;
}

/// Fournit un flux AppAuthState basé sur onAuthStateChange de Supabase.
/// - Rafraîchit à chaque login/logout/refresh token.
/// - Converti en AppAuthState minimal, consommable par l'UI/Router.
final appAuthStateProvider = StreamProvider<AppAuthState>((ref) async* {
  final auth = Supabase.instance.client.auth; // <-- GoTrueClient

  // Stream des changements d'auth
  final stream = auth.onAuthStateChange;

  // Emit une première valeur immédiate pour initialiser le router
  yield AppAuthState(
    session: auth.currentSession,
    authStream: stream,
  );

  await for (final e in stream) {
    yield AppAuthState(
      session: e.session,
      authStream: stream,
    );
  }
});

/// Dérivé pratique : booléen d'authentification, avec fallback sur l'état instantané
final isAuthenticatedProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(appAuthStateProvider);
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

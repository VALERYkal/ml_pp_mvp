# Fix Android Login Redirect Issue

**Date:** 2026-01-12  
**Status:** ✅ Completed

## Problème Identifié

Sur Android, après un login réussi (toast "Connexion réussie" affiché), l'application reste bloquée sur l'écran de connexion au lieu de rediriger vers le dashboard approprié selon le rôle utilisateur.

## Cause Racine

Le `GoRouter` utilise un `refreshListenable` (via `GoRouterCompositeRefresh`) qui écoute les changements d'état d'authentification et de rôle. Sur Android, il semble y avoir un léger délai dans la propagation de ces événements, ce qui empêche le redirect automatique de se déclencher immédiatement après le login.

## Solution Implémentée

### 1. Ajout d'un Fallback Navigation dans LoginScreen

**Fichier:** `lib/features/auth/screens/login_screen.dart`

**Changements:**
- Ajout de l'import `go_router` pour accéder à `context.go()`
- Après un login réussi, ajout d'un appel à `context.go('/')` pour forcer la navigation
- Ajout de logs de diagnostic avec `debugPrint` pour tracer le flux d'exécution
- Vérification de `context.mounted` avant la navigation pour éviter les erreurs

**Code ajouté (lignes 143-155):**
```dart
// ✅ Succès de connexion
debugPrint('✅ Login OK, session=${Supabase.instance.client.auth.currentSession?.user.id}');

_showSuccess('Connexion réussie');

// 🔄 Fallback navigation: force GoRouter à recalculer le redirect
// (nécessaire sur Android où le refreshListenable peut avoir un délai)
if (!mounted) return;

// On navigue vers "/" pour déclencher le redirect central du router
// qui redirigera automatiquement vers le dashboard selon le rôle
debugPrint('🔄 Triggering navigation fallback to / ...');
context.go('/');
```

### 2. Amélioration des Logs de Diagnostic dans AppRouter

**Fichier:** `lib/shared/navigation/app_router.dart`

**Changements:**
- Amélioration des logs dans la fonction `redirect` pour mieux diagnostiquer le flux
- Ajout de logs détaillés pour chaque cas de redirection (non authentifié, rôle manquant, redirection finale)
- Conservation de la logique existante sans modification fonctionnelle

**Code modifié (lignes 175-206):**
```dart
redirect: (context, state) {
  final loc = state.fullPath ?? state.uri.path;

  // ✅ LIRE ICI, à la volée (pas capturé en amont)
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  final role = ref.read(userRoleProvider); // UserRole? nullable

  // 🧪 Logs diagnostiques (temporaires pour debug Android)
  debugPrint(
    '🔁 RouterRedirect: loc=$loc, isAuth=$isAuthenticated, role=$role, from=${state.uri}',
  );

  // 1) Non connecté -> /login sauf si on y est déjà
  if (!isAuthenticated) {
    debugPrint('   ➜ Not authenticated -> redirecting to /login');
    return (loc == '/login') ? null : '/login';
  }

  // 2) Connecté mais rôle pas encore prêt -> /splash (neutre si déjà dessus)
  if (role == null) {
    debugPrint('   ➜ Authenticated but role not ready -> redirecting to /splash');
    return (loc == '/splash') ? null : '/splash';
  }

  // 3) Connecté + rôle prêt : normalisation
  if (loc.isEmpty || loc == '/' || loc == '/login' || loc == '/dashboard') {
    final targetPath = role.dashboardPath;
    debugPrint('   ➜ Authenticated + role ready -> redirecting to $targetPath');
    return targetPath; // ton getter existant
  }

  debugPrint('   ➜ No redirect needed, staying at $loc');
  return null; // rien à faire
},
```

## Architecture Préservée

✅ **Pas de modification de la logique du router:** Le système de redirection centralisé via `GoRouter.redirect` reste la source de vérité.

✅ **Pas de route codée en dur selon le rôle:** Le `LoginScreen` ne connaît pas les routes spécifiques aux rôles, il déclenche simplement une navigation vers `/` qui active le redirect central.

✅ **Système de refresh préservé:** Le `GoRouterCompositeRefresh` continue de fonctionner normalement, le fallback est juste une sécurité supplémentaire.

## Flux d'Exécution

### Avant le Fix
1. Utilisateur clique sur "Se connecter"
2. `authService.signIn()` réussit
3. Toast "Connexion réussie" affiché
4. ❌ **BLOQUÉ:** Attente infinie du `refreshListenable` qui ne se déclenche pas immédiatement sur Android

### Après le Fix
1. Utilisateur clique sur "Se connecter"
2. `authService.signIn()` réussit
3. Log: `✅ Login OK, session={user_id}`
4. Toast "Connexion réussie" affiché
5. Log: `🔄 Triggering navigation fallback to / ...`
6. `context.go('/')` déclenché
7. GoRouter évalue le `redirect`:
   - Log: `🔁 RouterRedirect: loc=/, isAuth=true, role=...`
   - Si rôle prêt: redirection vers le dashboard approprié
   - Si rôle pas prêt: redirection vers `/splash` (écran de chargement)
8. ✅ **Utilisateur redirigé vers le bon dashboard**

## Logs de Diagnostic

Les logs suivants permettent de tracer le problème:

```
✅ Login OK, session=abc-123-def
🔄 Triggering navigation fallback to / ...
🔁 RouterRedirect: loc=/, isAuth=true, role=UserRole.operateur, from=Uri(/)
   ➜ Authenticated + role ready -> redirecting to /dashboard/operateur
```

## Prochaines Étapes

### À Court Terme (Tests)
1. Tester sur Android physique et émulateur
2. Vérifier les logs dans la console
3. Tester avec différents rôles (admin, gérant, opérateur, etc.)

### À Moyen Terme (Nettoyage)
Une fois le problème confirmé résolu:
1. Retirer les logs de diagnostic temporaires (`debugPrint`)
2. Documenter le comportement dans les commentaires du code
3. Considérer si ce pattern doit être appliqué à d'autres écrans

## Notes Techniques

- **`context.mounted`:** Vérifie que le widget est toujours dans l'arbre avant de naviguer (évite les erreurs)
- **`context.go('/')`:** Navigation impérative qui force GoRouter à réévaluer le redirect
- **Fallback pattern:** Solution robuste qui ne casse pas le comportement normal mais ajoute une sécurité

## Références

- **Fichiers modifiés:**
  - `lib/features/auth/screens/login_screen.dart`
  - `lib/shared/navigation/app_router.dart`
  
- **Fichiers liés (non modifiés):**
  - `lib/shared/navigation/router_refresh.dart` (système de refresh)
  - `lib/shared/providers/session_provider.dart` (état d'authentification)
  - `lib/features/profil/providers/profil_provider.dart` (provider de rôle)

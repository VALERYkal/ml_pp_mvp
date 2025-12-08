# 🧪 Documentation - Tests d'Intégration Auth

**Version :** 1.0.0  
**Date :** 2025-12-08  
**Statut :** ✅ Phase 4 Complétée

## 📋 Vue d'ensemble

Ce document décrit l'architecture, les patterns et les bonnes pratiques pour les tests d'intégration d'authentification dans `test/integration/auth/auth_integration_test.dart`.

### Objectifs

- ✅ Valider la redirection par rôle (admin, directeur, gérant, opérateur, PCA, lecture)
- ✅ Vérifier les guards de navigation (accès aux routes protégées)
- ✅ Tester les flux d'authentification (login, logout, états de chargement)
- ✅ Assurer la conformité des menus selon les rôles

### Résultats

- **14 tests passent** ✅
- **3 tests skippés** (comme prévu)
- **0 test en échec**
- **Phase 4 complétée** : Tests admin direct & logout stabilisés

---

## 🏗️ Architecture des Tests

### Structure du Fichier

```
test/integration/auth/auth_integration_test.dart
├── Helpers & Mocks
│   ├── _FakeCurrentProfilNotifier
│   ├── _DummyRefresh
│   ├── _FakeSession
│   └── _routerLocation()
├── Setup
│   ├── setUpAll() - Initialisation Flutter binding
│   ├── setUp() - Initialisation des mocks
│   └── createTestApp() - Helper pour créer l'app de test
└── Tests
    ├── Role-based Redirection (6 tests)
    ├── Menu Conformity by Role (4 tests)
    ├── Authentication Flow (4 tests, 3 skippés)
    ├── Navigation Guards (2 tests)
    └── Logout Flow (1 test)
```

### Composants Clés

#### 1. `setUpAll()` - Initialisation Globale

```dart
setUpAll(() async {
  // Initialiser le binding Flutter pour les tests
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Note: Supabase.initialize() n'est PAS appelé car les plugins natifs
  // (SharedPreferences, path_provider) ne sont pas disponibles dans les tests widget.
  // Tous les providers sont mockés, donc Supabase n'est pas nécessaire.
});
```

**Pourquoi pas d'initialisation Supabase ?**
- Les plugins natifs ne sont pas disponibles dans les tests widget
- Tous les providers qui utilisent Supabase sont mockés
- L'override de `isAuthenticatedProvider` empêche l'accès à `Supabase.instance`

#### 2. `createTestApp()` - Helper Principal

```dart
Widget createTestApp({required Profil? profil}) {
  // Si un profil est fourni, créer une session fake pour simuler l'authentification
  final session = profil != null ? _FakeSession(mockUser) : null;
  final authState = AppAuthState(
    session: session,
    authStream: const Stream.empty(),
  );
  
  return ProviderScope(
    overrides: [
      // Override des providers pour éviter l'accès à Supabase
      authServiceProvider.overrideWithValue(mockAuthService),
      profilServiceProvider.overrideWithValue(mockProfilService),
      currentProfilProvider.overrideWith(
        () => _FakeCurrentProfilNotifier(profil),
      ),
      appAuthStateProvider.overrideWith(
        (ref) => Stream.value(authState),
      ),
      // ⚠️ CRITIQUE : Override isAuthenticatedProvider pour éviter l'accès à Supabase.instance
      isAuthenticatedProvider.overrideWith(
        (ref) {
          final asyncState = ref.watch(appAuthStateProvider);
          return asyncState.when(
            data: (s) => s.isAuthenticated,
            loading: () => false,
            error: (_, __) => false,
          );
        },
      ),
      currentUserProvider.overrideWith(
        (ref) => mockAuthService.getCurrentUser(),
      ),
      goRouterRefreshProvider.overrideWith((ref) => _DummyRefresh(ref)),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.read(appRouterProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}
```

**Points clés :**
- ✅ Crée une session fake si un profil est fourni (simule l'authentification)
- ✅ Override `isAuthenticatedProvider` pour éviter l'accès à `Supabase.instance`
- ✅ Tous les providers sont mockés pour isoler les tests

#### 3. Helpers et Mocks

##### `_FakeSession`
```dart
class _FakeSession extends Session {
  _FakeSession(User user)
      : super(
          accessToken: 'fake-token',
          tokenType: 'bearer',
          user: user,
          expiresIn: 3600,
          refreshToken: 'fake-refresh-token',
        );
}
```
- Simule une session Supabase authentifiée
- Utilisée quand un profil est fourni dans `createTestApp()`

##### `_FakeCurrentProfilNotifier`
```dart
class _FakeCurrentProfilNotifier extends CurrentProfilNotifier {
  final Profil? _profil;
  final AsyncValue<Profil?>? _forcedState;

  @override
  Future<Profil?> build() async {
    if (_forcedState != null) {
      state = _forcedState!;
      return _forcedState!.valueOrNull;
    }
    return _profil;
  }
}
```
- Contrôle l'état du profil dans les tests
- Permet de simuler les états loading/error si nécessaire

##### `_DummyRefresh`
```dart
class _DummyRefresh extends GoRouterCompositeRefresh {
  _DummyRefresh(Ref ref) : super(ref: ref, authStream: const Stream.empty());
}
```
- Implémentation factice de `GoRouterCompositeRefresh`
- Évite les dépendances au stream d'authentification réel

---

## 🎯 Patterns de Test

### Pattern 1 : Test de Redirection par Rôle

```dart
testWidgets('should redirect admin to admin dashboard', (
  WidgetTester tester,
) async {
  // Arrange
  final adminProfil = Profil(
    id: 'profil-id',
    userId: 'test-user-id',
    role: UserRole.admin,
    nomComplet: 'Admin User',
    email: 'admin@example.com',
    depotId: 'depot-1',
    createdAt: DateTime.now(),
  );

  await tester.pumpWidget(createTestApp(profil: adminProfil));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Tableau de bord'), findsWidgets);
  expect(find.text(UserRole.admin.value), findsOneWidget);
  expect(_routerLocation(tester), equals(UserRole.admin.dashboardPath));
});
```

**Étapes :**
1. Créer un profil avec le rôle souhaité
2. Utiliser `createTestApp()` avec ce profil
3. Vérifier la redirection vers le bon dashboard
4. Vérifier l'affichage des éléments UI attendus

### Pattern 2 : Test avec Overrides Locaux

Pour les tests nécessitant un contrôle plus fin (ex: logout flow), utiliser des overrides locaux :

```dart
testWidgets('should redirect to login after logout', (
  WidgetTester tester,
) async {
  // Arrange
  final adminProfil = Profil(/* ... */);
  final fakeSession = _FakeSession(mockUser);
  final initialAuthState = AppAuthState(
    session: fakeSession,
    authStream: const Stream.empty(),
  );
  final authStateController = StreamController<AppAuthState>.broadcast();
  authStateController.add(initialAuthState);

  // Configurer signOut() pour émettre un nouvel état non authentifié
  when(mockAuthService.signOut()).thenAnswer((_) async {
    authStateController.add(
      const AppAuthState(session: null, authStream: Stream.empty()),
    );
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Overrides locaux avec StreamController pour gérer la transition auth → non-auth
        appAuthStateProvider.overrideWith(
          (ref) async* {
            yield initialAuthState;
            yield* authStateController.stream;
          },
        ),
        isAuthenticatedProvider.overrideWith(/* ... */),
        // ... autres overrides
      ],
      child: Consumer(/* ... */),
    ),
  );
  
  // Act & Assert
  await tester.pumpAndSettle();
  expect(find.text('Tableau de bord'), findsWidgets);
  
  // Taper sur logout
  final logoutIconFinder = find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.logout),
  );
  expect(logoutIconFinder, findsOneWidget);
  await tester.tap(logoutIconFinder);
  await tester.pumpAndSettle();
  
  // Vérifier la redirection vers login
  expect(find.byType(LoginScreen), findsOneWidget);
});
```

**Quand utiliser ce pattern ?**
- Tests nécessitant des transitions d'état dynamiques (logout, changement de rôle)
- Tests nécessitant un contrôle précis du stream d'authentification
- Tests qui ne peuvent pas utiliser `createTestApp()` directement

### Pattern 3 : Assertions Défensives

Toujours vérifier l'existence d'un widget avant d'interagir avec :

```dart
// ✅ BON
final dashboardShellFinder = find.byType(DashboardShell);
expect(dashboardShellFinder, findsOneWidget);
final dashboardElement = tester.firstElement(dashboardShellFinder);

// ❌ MAUVAIS
final ctx = tester.element(find.byType(DashboardShell)); // Peut échouer si non trouvé
```

**Règle d'or :** Toujours utiliser `expect(finder, findsOneWidget)` avant d'accéder à `.element`, `.evaluate().single`, ou `tester.element()`.

---

## 🔧 Résolution de Problèmes

### Problème 1 : "You must initialize the supabase instance"

**Symptôme :**
```
Failed assertion: line 32 pos 7: '_instance._initialized'
You must initialize the supabase instance before calling Supabase.instance
```

**Solution :**
- ✅ Override `isAuthenticatedProvider` dans `createTestApp()` pour éviter l'accès à `Supabase.instance`
- ✅ Tous les providers qui utilisent Supabase doivent être mockés
- ✅ Ne pas initialiser Supabase dans `setUpAll()` (plugins natifs non disponibles)

### Problème 2 : Redirection vers `/login` au lieu du dashboard

**Symptôme :**
- Le test s'attend à être sur le dashboard mais est redirigé vers `/login`
- `isAuthenticated` retourne `false` même avec un profil fourni

**Solution :**
- ✅ Vérifier que `createTestApp()` crée une session fake quand un profil est fourni
- ✅ Vérifier que `isAuthenticatedProvider` est bien override
- ✅ Vérifier que `appAuthStateProvider` émet un `AppAuthState` avec `session != null`

### Problème 3 : "Bad state: No element"

**Symptôme :**
```
Bad state: No element
```

**Solution :**
- ✅ Toujours utiliser des assertions défensives avant d'accéder à un élément
- ✅ Utiliser `tester.firstElement(finder)` au lieu de `tester.element(finder)`
- ✅ Vérifier que le widget est visible avec `await tester.ensureVisible(finder)`

---

## 📊 Couverture des Tests

### Tests de Redirection par Rôle (6 tests)
- ✅ Admin → `/dashboard/admin`
- ✅ Directeur → `/dashboard/directeur`
- ✅ Gérant → `/dashboard/gerant`
- ✅ Opérateur → `/dashboard/operateur`
- ✅ PCA → `/dashboard/pca`
- ✅ Lecture → `/dashboard/lecture`

### Tests de Conformité des Menus (4 tests)
- ✅ Admin voit tous les items
- ✅ Directeur voit les items de management
- ✅ Opérateur voit uniquement les items opérationnels
- ✅ Lecture voit uniquement les items en lecture seule

### Tests de Flux d'Authentification (4 tests, 3 skippés)
- ✅ Redirection vers login quand non authentifié
- ⏭️ Redirection vers login quand profil est null (skippé)
- ⏭️ Gestion de l'état de chargement (skippé)
- ⏭️ Gestion de l'état d'erreur (skippé)

### Tests de Guards de Navigation (2 tests)
- ✅ Empêche l'accès aux routes admin pour les non-admin
- ✅ Permet l'accès aux routes admin pour les admin

### Tests de Logout (1 test)
- ✅ Redirection vers login après logout

---

## 🚀 Exécution des Tests

### Lancer tous les tests Auth
```bash
flutter test test/integration/auth/auth_integration_test.dart
```

### Lancer avec output détaillé
```bash
flutter test test/integration/auth/auth_integration_test.dart -r expanded
```

### Lancer un test spécifique
```bash
flutter test test/integration/auth/auth_integration_test.dart --plain-name "should redirect admin to admin dashboard"
```

---

## 📝 Bonnes Pratiques

### ✅ À Faire

1. **Utiliser `createTestApp()`** pour les tests simples de redirection
2. **Assertions défensives** avant chaque interaction avec un widget
3. **Overrides locaux** pour les tests nécessitant un contrôle fin
4. **`pumpAndSettle()`** après chaque navigation ou changement d'état
5. **Réutiliser les patterns** des tests qui passent

### ❌ À Éviter

1. **Ne pas accéder à `Supabase.instance`** directement dans les tests
2. **Ne pas utiliser `.element` sans vérification préalable**
3. **Ne pas oublier `pumpAndSettle()`** après les interactions
4. **Ne pas modifier le code de production** (`lib/`) pour faire passer les tests
5. **Ne pas créer de nouveaux helpers globaux** sans nécessité

---

## 🔄 Évolution Future

### Phase 5 - Nettoyage & Factorisation (À venir)
- Mutualiser les patterns qui reviennent partout
- Créer des helpers locaux pour les setups communs
- Améliorer la lisibilité des tests

### Phase 6 - Propagation (À venir)
- Réutiliser ce socle Auth pour les tests E2E Sorties
- Réutiliser pour les tests E2E Stocks
- Réutiliser pour les tests E2E Réceptions

---

## 📚 Références

- [Guide de Tests Général](../testing_guide.md)
- [Architecture des Mocks](../../technical/mock_architecture.md)
- [Architecture de l'Application](../architecture.md)

---

**Dernière mise à jour :** 2025-12-08  
**Auteur :** Valery Kalonga  
**Statut :** ✅ Phase 4 Complétée - Tests Stables


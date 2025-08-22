# 🧪 Guide de Tests - ML_PP MVP

## 📋 Vue d'ensemble

Ce guide explique comment exécuter et maintenir les tests pour ML_PP MVP, avec un focus sur les tests de l'écran de login.

## 🏗️ Architecture des Tests

### Structure des Tests
```
test/
├── features/
│   ├── auth/
│   │   └── screens/
│   │       └── login_screen_test.dart    # Tests de l'écran de login
│   └── cours_route/
│       └── screens/
│           └── cours_route_list_screen_test.dart
├── integration/                           # Tests d'intégration
└── unit/                                 # Tests unitaires
```

### Technologies Utilisées
- **flutter_test** : Framework de test Flutter
- **mockito** : Mocking pour les services
- **riverpod** : Gestion d'état pour les tests
- **build_runner** : Génération automatique des mocks

## 🚀 Exécution des Tests

### Prérequis
```bash
# Installer les dépendances
flutter pub get

# Générer les mocks (nécessaire avant les tests)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Exécution Complète
```bash
# Exécuter tous les tests
flutter test

# Exécuter avec couverture
flutter test --coverage

# Exécuter un test spécifique
flutter test test/features/auth/screens/login_screen_test.dart
```

### Script Automatisé
```bash
# Utiliser le script fourni
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

## 🧪 Tests de l'Écran de Login

### Scénarios Testés

#### 1. **Rendu Correct** (`renders correctly with all form elements`)
- ✅ Vérification de la présence de tous les éléments UI
- ✅ Champs email et mot de passe
- ✅ Bouton de connexion
- ✅ Messages d'aide

#### 2. **Validation des Champs** (`shows validation errors for empty fields`)
- ✅ Validation des champs vides
- ✅ Validation du format email
- ✅ Validation de la longueur du mot de passe

#### 3. **Connexion Réussie** (`successful login calls signIn and redirects`)
- ✅ Appel au service d'authentification
- ✅ Récupération du profil utilisateur
- ✅ Redirection vers le dashboard approprié

#### 4. **Gestion des Erreurs** (`failed login shows error message`)
- ✅ Affichage des messages d'erreur AuthException
- ✅ Gestion des erreurs PostgrestException
- ✅ Gestion des erreurs inattendues

#### 5. **États de Chargement** (`shows loading state during login`)
- ✅ Affichage de l'indicateur de chargement
- ✅ Désactivation du bouton pendant le chargement

#### 6. **Fonctionnalités UX** (`toggles password visibility`)
- ✅ Affichage/masquage du mot de passe
- ✅ Changement d'icône

### Configuration des Mocks

```dart
// Génération des mocks
@GenerateMocks([AuthService, GoRouter])
import 'login_screen_test.mocks.dart';

// Configuration du container
container = Riverpod.ProviderContainer(
  overrides: [
    authServiceProvider.overrideWithValue(mockAuthService),
  ],
);
```

### Exemples de Tests

#### Test de Connexion Réussie
```dart
testWidgets('successful login calls signIn and redirects', (WidgetTester tester) async {
  // Arrange - Configuration du mock
  when(mockAuthService.signIn('test@example.com', 'password123'))
      .thenAnswer((_) async => mockUser);

  // Act - Remplir le formulaire et se connecter
  await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password')), 'password123');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();

  // Assert - Vérification de l'appel au service
  verify(mockAuthService.signIn('test@example.com', 'password123')).called(1);
});
```

#### Test de Gestion d'Erreur
```dart
testWidgets('failed login shows error message', (WidgetTester tester) async {
  // Arrange - Configuration du mock pour un échec
  when(mockAuthService.signIn('test@example.com', 'wrongpassword'))
      .thenThrow(AuthException('Invalid login credentials'));

  // Act - Tenter la connexion
  await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password')), 'wrongpassword');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();

  // Assert - Vérification du message d'erreur
  expect(find.text('Email ou mot de passe incorrect'), findsOneWidget);
});
```

## 🔧 Configuration

### Fichier build.yaml
```yaml
targets:
  $default:
    builders:
      mockito|mockBuilder:
        enabled: true
        generate_for:
          - test/**.dart
```

### Dépendances (pubspec.yaml)
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  mockito: ^5.4.4
```

## 📊 Couverture de Tests

### Métriques Visées
- **Couverture de code** : > 80%
- **Tests critiques** : 100% (login, navigation, erreurs)
- **Tests d'intégration** : Fonctionnalités principales

### Commandes de Couverture
```bash
# Générer un rapport de couverture
flutter test --coverage

# Visualiser la couverture (nécessite lcov)
genhtml coverage/lcov.info -o coverage/html
```

## 🐛 Dépannage

### Problèmes Courants

#### 1. **Erreur de Mock Non Généré**
```bash
# Solution : Régénérer les mocks
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 2. **Erreur de Provider Non Trouvé**
```dart
// Solution : Vérifier les overrides
Riverpod.ProviderScope(
  parent: container,
  overrides: [
    authServiceProvider.overrideWithValue(mockAuthService),
  ],
  child: MaterialApp(...),
)
```

#### 3. **Test Qui Échoue Inexplicablement**
```dart
// Solution : Ajouter des délais appropriés
await tester.pumpAndSettle(); // Attendre que l'état se stabilise
```

## 📝 Bonnes Pratiques

### 1. **Organisation des Tests**
- Un fichier de test par écran
- Groupes logiques de tests
- Noms de tests descriptifs

### 2. **Configuration des Mocks**
- Mocker uniquement les dépendances externes
- Utiliser des données de test réalistes
- Nettoyer les mocks entre les tests

### 3. **Assertions**
- Tester le comportement, pas l'implémentation
- Vérifier les messages d'erreur exacts
- Tester les cas limites

### 4. **Performance**
- Utiliser `pumpAndSettle()` pour les animations
- Éviter les `await` en dehors de `testWidgets`
- Nettoyer les ressources dans `tearDown`

## 🎯 Prochaines Étapes

### Tests à Ajouter
1. **Tests d'intégration** : Flux complet de connexion
2. **Tests de performance** : Temps de réponse
3. **Tests de sécurité** : Validation des inputs
4. **Tests d'accessibilité** : Support des lecteurs d'écran

### Améliorations
1. **CI/CD** : Intégration continue avec GitHub Actions
2. **Tests E2E** : Tests de bout en bout avec integration_test
3. **Monitoring** : Métriques de qualité des tests

---

## ✅ Checklist de Tests

- [x] Tests de rendu des widgets
- [x] Tests de validation des formulaires
- [x] Tests d'appel aux services
- [x] Tests de gestion d'erreurs
- [x] Tests d'états de chargement
- [x] Tests de navigation
- [x] Tests de fonctionnalités UX
- [x] Configuration des mocks
- [x] Scripts d'automatisation
- [x] Documentation complète

**Statut** : Tests complets et fonctionnels pour l'écran de login ✅

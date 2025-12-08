# 🧪 Guide de Tests - ML_PP MVP

## 📋 Vue d'ensemble

Ce guide explique comment exécuter et maintenir les tests pour ML_PP MVP, avec un focus sur les tests de l'écran de login.

## 📁 Structure des Tests

### Suite Officielle

La suite de tests officielle se trouve sous `test/features/**`. Cette structure reflète l'architecture modulaire de l'application et contient tous les tests actifs et maintenus :

```
test/features/
├── auth/                    # Tests d'authentification
│   ├── screens/
│   │   └── login_screen_test.dart
│   └── ...
├── cours_route/             # Tests Cours de Route (CDR)
│   ├── models/
│   ├── providers/
│   ├── screens/
│   └── integration/
├── receptions/              # Tests Réceptions
│   ├── data/
│   ├── e2e/
│   ├── integration/
│   ├── kpi/
│   └── screens/
├── sorties/                 # Tests Sorties (✅ Full Green)
│   ├── data/                # Tests unitaires SortieService
│   ├── kpi/                  # Tests KPI Sorties
│   ├── screens/             # Tests widget formulaire
│   └── sorties_e2e_test.dart # Test E2E complet (✅ Vert)
└── ...                      # Modules futurs
```

**Important** : Tous les nouveaux tests **DOIVENT** être ajoutés sous `test/features/**` pour garantir la cohérence et la maintenabilité.

### Tests Legacy (Archives)

Le dossier `test_legacy/**` contient d'anciens tests qui ne reflètent plus l'état actuel de l'application. Ces tests sont conservés uniquement à des fins de référence historique ou pour faciliter les migrations futures.

```
test_legacy/
├── _attic/
│   └── cours_route_legacy/   # Anciens tests CDR (ancien modèle, ancienne UI)
└── receptions/
    └── reception_form_screen_legacy_test.dart  # Ancien test formulaire Réceptions
```

**⚠️ Note importante** : Les tests dans `test_legacy/**` **ne sont PAS exécutés par défaut** lors de l'exécution de `flutter test`. Ils sont conservés uniquement pour référence et ne doivent pas être modifiés.

## 🏗️ Architecture des Tests

### Structure des Tests (Détail)

```
test/
├── features/                # Suite officielle (voir ci-dessus)
├── integration/             # Tests d'intégration globaux
├── unit/                    # Tests unitaires généraux
└── ...                      # Autres tests utilitaires
```

### Technologies Utilisées
- **flutter_test** : Framework de test Flutter
- **mockito** : Mocking pour les services
- **riverpod** : Gestion d'état pour les tests
- **build_runner** : Génération automatique des mocks

### Tests d'Intégration Auth
- **Documentation complète** : [`testing/auth_integration_tests.md`](testing/auth_integration_tests.md)
- **Tests Auth** : `test/integration/auth/auth_integration_test.dart`
- **Statut** : ✅ Phase 4 Complétée (14 tests passent)

## 🚀 Exécution des Tests

### Prérequis
```bash
# Installer les dépendances
flutter pub get

# Générer les mocks (nécessaire avant les tests)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Commandes Canoniques

#### Suite Officielle (Recommandé)

Pour lancer uniquement la suite officielle de tests (recommandé pour le développement quotidien) :

```bash
# Exécuter tous les tests de la suite officielle
flutter test test/features -r expanded

# Exécuter avec couverture
flutter test test/features --coverage
```

#### Tous les Tests

Pour lancer tous les tests (y compris les tests dans `test/integration/`, `test/unit/`, etc.) :

```bash
# Exécuter tous les tests du projet
flutter test -r expanded

# Exécuter avec couverture
flutter test --coverage
```

**Note** : Cette commande n'inclut **PAS** les tests dans `test_legacy/**`, qui ne sont pas exécutés par défaut.

### Exécution de Tests Spécifiques

```bash
# Exécuter un module spécifique
flutter test test/features/receptions -r expanded
flutter test test/features/cours_route -r expanded
flutter test test/features/sorties -r expanded

# Exécuter un test spécifique
flutter test test/features/auth/screens/login_screen_test.dart

# Exécuter un test d'intégration
flutter test test/integration/reception_flow_test.dart
```

### Script Automatisé
```bash
# Utiliser le script fourni
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

## 🧪 Tests du Module Sorties (✅ Full Green)

### Vue d'ensemble

Le module Sorties dispose d'une couverture de tests complète avec **100% de tests verts** :

- ✅ **Tests unitaires** : `SortieService.createValidated()` 100% couvert
- ✅ **Tests d'intégration** : `sorties_submission_test.dart` vert, validation du câblage formulaire → service
- ✅ **Tests E2E UI** : `sorties_e2e_test.dart` vert, validation du scénario utilisateur complet

### Tests Unitaires

**Fichier** : `test/features/sorties/data/sortie_service_test.dart`

- ✅ Rejette indices incohérents
- ✅ Rejette bénéficiaire manquant
- ✅ Rejette stock insuffisant
- ✅ Normalisation des champs, validations métier, calcul volume 15°C : tous validés

### Tests d'Intégration

**Fichier** : `test/integration/sorties_submission_test.dart`

- ✅ Navigation → affichage formulaire → saisie → interception `createValidated()`
- ✅ Validation du câblage formulaire → service

### Tests E2E

**Fichier** : `test/features/sorties/sorties_e2e_test.dart`

- ✅ Navigation complète : dashboard → onglet Sorties → bouton "Nouvelle sortie" → formulaire
- ✅ Remplissage des champs : approche white-box via accès direct aux `TextEditingController`
- ✅ Soumission validée : flow complet sans plantage, retour à la liste ou message de succès
- ✅ Test en mode "boîte noire UI" : valide le scénario utilisateur complet

### Exécution

```bash
# Tous les tests Sorties
flutter test test/features/sorties -r expanded

# Test E2E spécifique
flutter test test/features/sorties/sorties_e2e_test.dart -r expanded

# Test d'intégration
flutter test test/integration/sorties_submission_test.dart -r expanded
```

---

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

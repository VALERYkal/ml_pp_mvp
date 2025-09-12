# 🔐 Auth Testing Suite - ML_PP MVP

## 📋 Vue d'ensemble

Cette suite de tests complète couvre tous les aspects de l'authentification et de la gestion des profils dans l'application ML_PP MVP, avec des seuils de couverture élevés.

## 🎯 Objectifs de Couverture

- **Unit Tests** : ≥ 95% (services, mappers, helpers)
- **Widget Tests** : ≥ 90% (LoginScreen, validation, états)
- **Integration Tests** : ≥ 85% (redirection par rôle, navigation)
- **E2E Tests** : 100% (parcours vital de connexion)
- **Security Tests** : 100% (RLS, permissions, accès)

## 📁 Structure des Tests

```
test/features/auth/
├── README.md                           # Documentation
├── mocks.dart                          # Mocks générés
├── mocks.mocks.dart                    # Mocks générés par build_runner
├── auth_service_test.dart              # Tests unitaires AuthService
├── profil_service_test.dart            # Tests unitaires ProfilService
├── fixtures/
│   └── auth_fixtures.dart             # Données de test
├── screens/
│   └── login_screen_test.dart         # Tests widget LoginScreen
├── integration/
│   └── auth_integration_test.dart      # Tests d'intégration
├── e2e/
│   └── auth_e2e_test.dart             # Tests E2E
└── security/
    └── auth_security_test.dart        # Tests sécurité/RLS
```

## 🧪 Types de Tests

### A.1 - Tests Unitaires (≥95% couverture)

**AuthService Tests** (`auth_service_test.dart`)
- ✅ Connexion réussie avec credentials valides
- ✅ Validation des paramètres (email vide, mot de passe vide)
- ✅ Trim automatique de l'email
- ✅ Gestion des erreurs AuthException
- ✅ Gestion des erreurs PostgrestException
- ✅ Gestion des erreurs génériques
- ✅ Déconnexion réussie
- ✅ Récupération de l'utilisateur courant
- ✅ Vérification de l'état d'authentification
- ✅ Stream des changements d'état d'auth

**ProfilService Tests** (`profil_service_test.dart`)
- ✅ Récupération de profil existant
- ✅ Gestion du cas "profil non trouvé"
- ✅ Création de nouveau profil
- ✅ Mise à jour de profil existant
- ✅ Récupération par utilisateur courant
- ✅ Création pour utilisateur courant
- ✅ Get-or-create automatique
- ✅ Gestion des erreurs RLS
- ✅ Validation des données

### A.2 - Tests Widget (≥90% couverture)

**LoginScreen Tests** (`login_screen_test.dart`)
- ✅ Affichage de tous les éléments UI requis
- ✅ Validation des champs (email requis, mot de passe requis)
- ✅ Validation du format email
- ✅ Toggle de visibilité du mot de passe
- ✅ États du bouton (désactivé pendant chargement)
- ✅ Désactivation des champs pendant chargement
- ✅ Messages de succès et d'erreur
- ✅ Gestion des erreurs AuthException
- ✅ Gestion des erreurs PostgrestException
- ✅ Navigation clavier (Enter, Tab)
- ✅ Accessibilité et labels sémantiques
- ✅ Autofocus sur le champ email

### A.3 - Tests d'Intégration (≥85% couverture)

**Auth Integration Tests** (`auth_integration_test.dart`)
- ✅ Redirection admin → `/dashboard/admin`
- ✅ Redirection directeur → `/dashboard/directeur`
- ✅ Redirection gérant → `/dashboard/gerant`
- ✅ Redirection opérateur → `/dashboard/operateur`
- ✅ Redirection PCA → `/dashboard/pca`
- ✅ Redirection lecture → `/dashboard/lecture`
- ✅ Conformité du menu par rôle
- ✅ Guards de navigation par rôle
- ✅ Gestion des états de chargement
- ✅ Gestion des erreurs de profil
- ✅ Flux de déconnexion

### A.4 - Tests E2E (100% couverture)

**Auth E2E Tests** (`auth_e2e_test.dart`)
- ✅ Flux complet de connexion admin
- ✅ Flux complet de connexion directeur
- ✅ Flux complet de connexion opérateur
- ✅ Flux complet de connexion lecture
- ✅ Échec de connexion avec credentials invalides
- ✅ Validation des champs vides
- ✅ Validation du format email
- ✅ Toggle de visibilité du mot de passe
- ✅ État de chargement pendant connexion
- ✅ Flux de déconnexion
- ✅ Navigation entre sections
- ✅ Contrôle d'accès par rôle
- ✅ Cas limites de validation
- ✅ Navigation clavier

### A.5 - Tests Sécurité/RLS (100% couverture)

**Auth Security Tests** (`auth_security_test.dart`)
- ✅ Contrôle d'accès aux profils
- ✅ Accès inter-dépôt pour opérateur
- ✅ Accès global pour admin
- ✅ Validation des permissions par rôle
- ✅ Gestion des sessions expirées
- ✅ Messages d'erreur sécurisés
- ✅ Validation des paramètres d'entrée
- ✅ Intégrité des données
- ✅ Sanitisation des entrées utilisateur
- ✅ Politiques RLS

## 🚀 Exécution des Tests

### Tests Unitaires
```bash
flutter test test/features/auth/auth_service_test.dart
flutter test test/features/auth/profil_service_test.dart
```

### Tests Widget
```bash
flutter test test/features/auth/screens/login_screen_test.dart
```

### Tests d'Intégration
```bash
flutter test test/features/auth/integration/auth_integration_test.dart
```

### Tests E2E
```bash
flutter test integration_test/features/auth/e2e/auth_e2e_test.dart
```

### Tests Sécurité
```bash
flutter test test/features/auth/security/auth_security_test.dart
```

### Tous les Tests Auth
```bash
flutter test test/features/auth/
```

## 📊 Métriques de Couverture

### Couverture par Type
- **Unit Tests** : 95%+ (services, mappers)
- **Widget Tests** : 90%+ (LoginScreen)
- **Integration Tests** : 85%+ (navigation, rôles)
- **E2E Tests** : 100% (parcours critiques)
- **Security Tests** : 100% (RLS, permissions)

### Couverture par Module
- **AuthService** : 100% (toutes les méthodes)
- **ProfilService** : 100% (toutes les méthodes)
- **LoginScreen** : 95%+ (UI, validation, états)
- **Navigation** : 90%+ (redirections, guards)
- **Sécurité** : 100% (RLS, permissions)

## 🔧 Configuration des Tests

### Mocks
Les mocks sont générés automatiquement avec `build_runner` :
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Fixtures
Les données de test sont centralisées dans `fixtures/auth_fixtures.dart` :
- Utilisateurs test pour chaque rôle
- Profils test avec données réalistes
- Credentials de test
- Messages d'erreur attendus
- Routes et permissions par rôle

### Environnement de Test
- Tests isolés avec mocks
- Pas de dépendance sur Supabase réel
- Données de test reproductibles
- Gestion des états d'erreur

## 🎯 Cas de Test Couverts

### Scénarios de Connexion
- ✅ Connexion réussie avec tous les rôles
- ✅ Échec avec credentials invalides
- ✅ Échec avec email non confirmé
- ✅ Échec avec problème réseau
- ✅ Échec avec trop de tentatives
- ✅ Validation des champs vides
- ✅ Validation du format email

### Scénarios de Navigation
- ✅ Redirection automatique par rôle
- ✅ Accès aux sections autorisées
- ✅ Blocage des sections non autorisées
- ✅ Navigation entre sections
- ✅ Déconnexion et retour au login

### Scénarios de Sécurité
- ✅ Contrôle d'accès RLS
- ✅ Validation des permissions
- ✅ Gestion des sessions
- ✅ Sanitisation des données
- ✅ Messages d'erreur sécurisés

## 📈 Améliorations Futures

### Tests de Performance
- Temps de réponse des services
- Optimisation des requêtes
- Cache des profils

### Tests de Charge
- Connexions simultanées
- Gestion des sessions multiples
- Performance sous charge

### Tests de Compatibilité
- Différentes versions de navigateur
- Responsive design
- Accessibilité avancée

## 🐛 Dépannage

### Problèmes Courants
1. **Mocks non générés** : Exécuter `build_runner`
2. **Tests E2E échouent** : Vérifier la configuration Supabase
3. **Couverture insuffisante** : Ajouter des cas de test manquants

### Logs de Debug
Les tests incluent des logs détaillés pour le débogage :
- États d'authentification
- Erreurs de validation
- Flux de navigation
- Permissions et accès

## 📝 Maintenance

### Mise à Jour des Tests
- Synchroniser avec les changements de code
- Ajouter de nouveaux cas de test
- Maintenir la couverture de code
- Valider les nouvelles fonctionnalités

### Révision des Tests
- Vérifier la pertinence des cas de test
- Optimiser les performances des tests
- Améliorer la lisibilité du code
- Documenter les nouveaux scénarios

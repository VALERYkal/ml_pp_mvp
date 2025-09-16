# 🏗️ Architecture des Mocks - Guide Technique

**Date :** 15 janvier 2025  
**Version :** 1.0  
**Statut :** ✅ Implémenté  

## 📋 Vue d'ensemble

Ce document décrit l'architecture des mocks dans le projet ML_PP MVP après la résolution du conflit `MockCoursDeRouteService`.

## 🎯 Principe de Base

### 🔄 Centralisation des Mocks CDR
- **Un seul endroit** pour les mocks du module Cours de Route
- **Réutilisabilité** maximale entre les tests
- **Maintenance simplifiée** et cohérente

### 📁 Structure Actuelle

```
test/
├── helpers/
│   └── cours_route_test_helpers.dart          # 🎯 Mocks CDR centralisés
├── features/
│   ├── cours_route/
│   │   ├── providers/
│   │   │   └── cours_route_providers_test.dart # ✅ Utilise le helper
│   │   └── screens/
│   │       └── cours_route_filters_test.dart   # ✅ Utilise le helper
│   ├── auth/                                   # ✅ Mocks propres
│   ├── receptions/                             # ✅ Mocks propres
│   └── sorties/                                # ✅ Mocks propres
```

## 🔧 Implémentation

### 📄 Helper Central : `test/helpers/cours_route_test_helpers.dart`

```dart
// Mock classes - Utilisation des mocks déjà générés dans d'autres fichiers
// Pas de @GenerateMocks ici pour éviter les conflits avec les autres fichiers de test
class MockCoursDeRouteService extends Mock implements CoursDeRouteService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

// Helpers pour la configuration des mocks
class CoursRouteTestHelpers {
  static MockCoursDeRouteService createMockService() {
    return MockCoursDeRouteService();
  }

  static void setupMocks(
    MockCoursDeRouteService mockService,
    MockSupabaseClient mockSupabase,
  ) {
    // Configuration des mocks selon les besoins des tests
    when(mockService.getAll()).thenAnswer((_) async => CoursRouteFixtures.sampleList());
    when(mockService.getActifs()).thenAnswer((_) async => CoursRouteFixtures.activeCoursList());
    // ... autres configurations
  }
}
```

### 📄 Utilisation dans les Tests

```dart
// Dans cours_route_providers_test.dart
import '../../../helpers/cours_route_test_helpers.dart';

void main() {
  late MockCoursDeRouteService mockService;
  
  setUp(() {
    mockService = MockCoursDeRouteService();
    // Configuration spécifique si nécessaire
  });
  
  // Tests...
}
```

## 🚀 Avantages de cette Architecture

### ✅ **Centralisation**
- **Un seul endroit** pour modifier les mocks CDR
- **Cohérence** garantie entre tous les tests
- **Maintenance** simplifiée

### ✅ **Réutilisabilité**
- **Même mock** utilisé dans tous les tests CDR
- **Configuration** partagée et standardisée
- **DRY** (Don't Repeat Yourself) respecté

### ✅ **Isolation**
- **Modules séparés** : Chaque module garde ses mocks spécifiques
- **Pas de conflit** entre les générations Mockito
- **Tests indépendants** et stables

### ✅ **Performance**
- **Pas de duplication** de génération de mocks
- **Build runner** plus rapide
- **Tests** plus rapides

## 📋 Guidelines pour les Développeurs

### 🆕 **Ajouter un nouveau test CDR**

1. **Importer le helper central** :
   ```dart
   import '../../../helpers/cours_route_test_helpers.dart';
   ```

2. **Utiliser le mock central** :
   ```dart
   late MockCoursDeRouteService mockService;
   
   setUp(() {
     mockService = MockCoursDeRouteService();
   });
   ```

3. **Configurer si nécessaire** :
   ```dart
   // Configuration spécifique au test
   when(mockService.specificMethod()).thenAnswer((_) async => expectedResult);
   ```

### ⚠️ **À éviter**

- ❌ **Ne pas** ajouter `@GenerateMocks([CoursDeRouteService])`
- ❌ **Ne pas** créer de nouveaux mocks CDR ailleurs
- ❌ **Ne pas** importer des fichiers `.mocks.dart` pour CDR

### ✅ **Bonnes pratiques**

- ✅ **Utiliser** le helper central pour tous les tests CDR
- ✅ **Configurer** les mocks selon les besoins spécifiques
- ✅ **Documenter** les configurations complexes
- ✅ **Tester** les mocks dans les tests unitaires

## 🔄 Migration des Tests Existants

### 📋 Checklist de Migration

Pour migrer un test CDR existant :

- [ ] **Supprimer** `@GenerateMocks([CoursDeRouteService])`
- [ ] **Supprimer** `import '...mocks.dart'`
- [ ] **Ajouter** `import '../../../helpers/cours_route_test_helpers.dart'`
- [ ] **Vérifier** que `MockCoursDeRouteService` fonctionne
- [ ] **Tester** que le test passe
- [ ] **Supprimer** le fichier `.mocks.dart` obsolète

### 🔧 Script de Migration (PowerShell)

```powershell
# Trouver tous les fichiers avec @GenerateMocks([CoursDeRouteService])
Get-ChildItem -Path "test" -Recurse -Filter "*.dart" | 
  Select-String -Pattern "@GenerateMocks.*CoursDeRouteService" | 
  Select-Object -ExpandProperty Filename

# Vérifier les imports de mocks CDR
Get-ChildItem -Path "test" -Recurse -Filter "*.dart" | 
  Select-String -Pattern "import.*cours.*mocks\.dart" | 
  Select-Object -ExpandProperty Filename
```

## 🧪 Tests et Validation

### 📊 Tests de Validation

```bash
# Tests CDR clés
flutter test test/features/cours_route/models/cours_de_route_transitions_test.dart test/features/cours_route/providers/cdr_kpi_provider_test.dart test/features/cours_route/screens/cdr_detail_decharge_simple_test.dart

# Build runner
flutter packages pub run build_runner build

# Vérification des conflits
grep -r "@GenerateMocks.*CoursDeRouteService" test/
```

### ✅ Critères de Succès

- [ ] **Build runner** : Pas d'erreur Mockito
- [ ] **Tests CDR** : Tous les tests clés passent
- [ ] **Conflits** : Aucun conflit Mockito détecté
- [ ] **Performance** : Tests plus rapides
- [ ] **Maintenance** : Code plus maintenable

## 🔮 Évolutions Futures

### 📈 Améliorations Possibles

1. **Mock Factory** : Factory pattern pour créer des mocks configurés
2. **Mock Builder** : Builder pattern pour des configurations complexes
3. **Mock Registry** : Registry centralisé pour tous les mocks
4. **Mock Validation** : Validation automatique des mocks

### 🚨 Prévention des Conflits

1. **Code Review** : Vérifier les nouveaux `@GenerateMocks`
2. **CI/CD** : Tests automatiques pour détecter les conflits
3. **Documentation** : Guidelines claires pour les développeurs
4. **Monitoring** : Surveillance des erreurs de build runner

## 📚 Ressources

### 📖 Documentation
- [Guide de correction du conflit](mock_conflict_fix_summary.md)
- [Changelog](../CHANGELOG.md)
- [Architecture générale](../architecture.md)

### 🔧 Outils
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Build Runner](https://pub.dev/packages/build_runner)

### 🆘 Support
- **Issues** : Créer une issue pour les problèmes de mocks
- **Discussions** : Utiliser les discussions pour les questions
- **Code Review** : Demander une review pour les changements

---

**✅ Architecture des mocks stabilisée et documentée !**  
**🎯 Conflits Mockito résolus définitivement !**  
**🚀 Tests CDR optimisés et maintenables !**

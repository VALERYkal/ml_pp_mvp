# ⚡ Fix Rapide - Conflit Mockito MockCoursDeRouteService

**🚨 Problème :** `Invalid @GenerateMocks annotation: Mockito cannot generate a mock with a name which conflicts with another class declared in this library: MockCoursDeRouteService`

**✅ Solution :** Centralisation des mocks CDR dans le helper central

## 🔧 Actions Rapides

### 1. **Supprimer les conflits**
```bash
# Dans les fichiers de test CDR, supprimer :
@GenerateMocks([CoursDeRouteService])
import '...mocks.dart';
```

### 2. **Ajouter l'import du helper**
```dart
import '../../../helpers/cours_route_test_helpers.dart';
```

### 3. **Utiliser le mock central**
```dart
late MockCoursDeRouteService mockService;

setUp(() {
  mockService = MockCoursDeRouteService(); // ✅ Du helper central
});
```

### 4. **Nettoyer et régénérer**
```bash
# Supprimer les fichiers .mocks.dart obsolètes
rm test/features/cours_route/providers/cours_route_providers_test.mocks.dart
rm test/features/cours_route/screens/cours_route_filters_test.mocks.dart

# Régénérer les mocks
flutter packages pub run build_runner build
```

## ✅ Validation

```bash
# Tests CDR clés
flutter test test/features/cours_route/models/cours_de_route_transitions_test.dart test/features/cours_route/providers/cdr_kpi_provider_test.dart test/features/cours_route/screens/cdr_detail_decharge_simple_test.dart

# Vérifier qu'il n'y a plus de conflits
grep -r "@GenerateMocks.*CoursDeRouteService" test/
# ✅ Aucun résultat attendu
```

## 📁 Fichiers Modifiés

- ✅ `test/features/cours_route/providers/cours_route_providers_test.dart`
- ✅ `test/features/cours_route/screens/cours_route_filters_test.dart`
- ✅ `test/helpers/cours_route_test_helpers.dart`

## 🗑️ Fichiers Supprimés

- ❌ `test/features/cours_route/providers/cours_route_providers_test.mocks.dart`
- ❌ `test/features/cours_route/screens/cours_route_filters_test.mocks.dart`

## 🎯 Résultat

- ✅ **Build runner** : Fonctionne sans erreur
- ✅ **Tests CDR** : Tous passent (19 + 9 + 6)
- ✅ **Architecture** : Mocks centralisés et réutilisables
- ✅ **Maintenance** : Plus simple et cohérente

---

**🎉 Conflit résolu ! Tests CDR fonctionnels !**

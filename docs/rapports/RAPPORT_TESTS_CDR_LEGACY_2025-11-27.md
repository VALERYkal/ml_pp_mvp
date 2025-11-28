# 📊 RAPPORT D'ANALYSE DES TESTS MODULE CDR
## État des lieux et problématique des tests legacy

| **Document** | Rapport technique |
|--------------|-------------------|
| **Projet** | ML_PP MVP (Monaluxe) |
| **Module** | Cours de Route (CDR) |
| **Date** | 27 novembre 2025 |
| **Auteur** | Équipe QA/Tests |
| **Destinataires** | Équipe Développement |

---

## 📋 RÉSUMÉ EXÉCUTIF

Le module Cours de Route (CDR) contient actuellement **20 fichiers de tests** mais seuls **5 fichiers sont fonctionnels** (87 tests passent). Les autres fichiers ne compilent plus en raison d'une **dette technique accumulée** : le code de production a évolué sans mise à jour correspondante des tests.

### Indicateurs clés

| Métrique | Valeur | Statut |
|----------|--------|--------|
| Fichiers de tests total | 20 | - |
| Fichiers fonctionnels | 5 | ✅ 25% |
| Fichiers cassés | 15 | ❌ 75% |
| Tests unitaires OK | 87 | ✅ |
| Tests en échec compilation | ~100+ | ❌ |

---

## 🔍 ANALYSE DÉTAILLÉE PAR CATÉGORIE

### ✅ TESTS FONCTIONNELS (5 fichiers - 87 tests)

| Fichier | Tests | Couverture | Dernière mise à jour |
|---------|-------|------------|---------------------|
| `providers/cdr_kpi_provider_test.dart` | 21 | KPI, compteurs, catégories métier | 27/11/2025 |
| `providers/cdr_list_provider_test.dart` | 31 | Liste, filtres, tri, statuts | 27/11/2025 |
| `models/cours_de_route_test.dart` | 22 | Modèle, sérialisation | Récent |
| `models/cours_de_route_transitions_test.dart` | 11 | Machine d'état | Récent |
| `models/statut_converter_test.dart` | 2 | Conversion statuts DB | Récent |

**Commande pour exécuter ces tests :**
```bash
flutter test test/features/cours_route/models/ test/features/cours_route/providers/cdr_kpi_provider_test.dart test/features/cours_route/providers/cdr_list_provider_test.dart
```

---

### ❌ TESTS CASSÉS - ERREURS DE COMPILATION

#### 1. `security/cours_route_security_test.dart`

**Criticité : 🔴 HAUTE** — Tests de sécurité et contrôle d'accès

| Type d'erreur | Description | Occurrences |
|---------------|-------------|-------------|
| Import manquant | `lib/features/auth/models/user_role.dart` | 1 |
| Import manquant | `lib/shared/providers/auth_provider.dart` | 1 |
| Type inexistant | `UserRole` | 12 |
| Type inexistant | `AuthState` | 6 |
| Type inexistant | `PostgrestException` | 3 |
| Méthode inexistante | `CoursRouteListScreen()` | 4 |
| Méthode inexistante | `CoursRouteDetailScreen()` | 2 |
| Mock incompatible | `MockSupabaseClient` → `SupabaseClient` | 7 |
| Méthode inexistante | `verify()`, `any` (Mockito) | 4 |

**Cause racine :** L'architecture d'authentification a été refactorisée. Les fichiers `user_role.dart` et `auth_provider.dart` ont été déplacés vers `lib/core/` ou supprimés.

---

#### 2. `integration/cours_route_integration_test.dart`

**Criticité : 🟠 MOYENNE** — Tests d'intégration du flux CDR

| Type d'erreur | Description | Occurrences |
|---------------|-------------|-------------|
| Import manquant | `lib/shared/models/ref_data_cache.dart` | 1 (via helper) |
| Type inexistant | `RefDataCache` | Multiple |
| Méthode inexistante | `CoursDeRoute.toMap()` | 1 |
| Provider inexistant | `refDataProvider` signature modifiée | Multiple |

**Cause racine :** Le système de cache de données de référence (`RefDataCache`) a été restructuré ou supprimé.

---

#### 3. `providers/cours_route_providers_test.dart`

**Criticité : 🟠 MOYENNE** — Tests des providers Riverpod

| Type d'erreur | Description | Occurrences |
|---------------|-------------|-------------|
| Helper cassé | `cours_route_test_helpers.dart` ne compile plus | Bloquant |
| Import manquant | `UserRole`, `AuthState` via helper | Multiple |
| Mock incompatible | `any` de Mockito avec types non-nullable | 6 |
| Type mismatch | `int` vers `double?` pour volume | 1 |

**Cause racine :** Le fichier helper partagé `cours_route_test_helpers.dart` référence des types qui n'existent plus.

---

#### 4. `screens/*.dart` (6 fichiers)

**Criticité : 🟡 FAIBLE** — Tests widgets/écrans

| Fichier | Problème principal |
|---------|-------------------|
| `cours_route_list_screen_test.dart` | Dépend de helpers cassés |
| `cours_route_form_screen_test.dart` | Dépend de helpers cassés |
| `cdr_list_simple_test.dart` | Dépend de `ref_data_provider` |
| `cdr_detail_decharge_test.dart` | Dépend de mocks incompatibles |
| `cdr_detail_decharge_simple_test.dart` | Dépend de mocks incompatibles |
| `cours_route_filters_test.dart` | Dépend de `CoursFilters` |

---

#### 5. Fichiers auxiliaires cassés

| Fichier | Problème |
|---------|----------|
| `data/cours_de_route_service_test.dart` | Mock Supabase incompatible |
| `e2e/cours_route_e2e_test.dart` | Supabase non initialisé |
| `run_all_cdr_tests.dart` | Référence des tests cassés |
| `run_cours_route_tests.dart` | Référence des tests cassés |

---

## 🔎 FICHIERS MANQUANTS DANS LE CODE DE PRODUCTION

L'analyse révèle que les fichiers suivants, référencés par les tests, **n'existent plus** ou ont été **déplacés** :

| Chemin référencé dans les tests | Existe ? | Emplacement actuel |
|---------------------------------|----------|-------------------|
| `lib/features/auth/models/user_role.dart` | ❌ | `lib/core/models/user_role.dart` |
| `lib/shared/providers/auth_provider.dart` | ❌ | Supprimé ou refactorisé |
| `lib/features/auth/providers/auth_provider.dart` | ❌ | Supprimé ou refactorisé |
| `lib/shared/models/ref_data_cache.dart` | ❌ | Supprimé ou fusionné |

---

## 📉 IMPACT SUR LE PROJET

### 1. Blocage CI/CD
```bash
# Cette commande échoue systématiquement :
flutter test test/features/cours_route/

# Exit code: 255 (erreurs de compilation)
```

### 2. Couverture de test réelle

| Aspect | Tests OK | Tests manquants | Gap |
|--------|----------|-----------------|-----|
| Modèles | ✅ 35 | 0 | - |
| Providers (KPI) | ✅ 21 | 0 | - |
| Providers (Liste) | ✅ 31 | 0 | - |
| Sécurité/RBAC | ❌ 0 | ~20 | ⚠️ Critique |
| Intégration | ❌ 0 | ~15 | ⚠️ Important |
| Écrans/Widgets | ❌ 0 | ~50 | ⚠️ Important |
| Service Supabase | ❌ 0 | ~10 | ⚠️ Modéré |

### 3. Risques identifiés

| Risque | Niveau | Description |
|--------|--------|-------------|
| Régression sécurité | 🔴 ÉLEVÉ | Pas de tests RBAC fonctionnels |
| Régression UI | 🟠 MOYEN | Pas de tests écrans |
| Confiance développeur | 🟡 FAIBLE | Tests "menteurs" dans le repo |

---

## 🛠️ RECOMMANDATIONS

### Option A : Nettoyage immédiat (recommandé)

**Effort estimé : 1-2 heures**

1. **Archiver les tests cassés** :
```bash
mkdir -p test/_attic/cours_route_legacy
mv test/features/cours_route/security/ test/_attic/cours_route_legacy/
mv test/features/cours_route/integration/ test/_attic/cours_route_legacy/
mv test/features/cours_route/screens/ test/_attic/cours_route_legacy/
mv test/features/cours_route/data/ test/_attic/cours_route_legacy/
mv test/features/cours_route/e2e/ test/_attic/cours_route_legacy/
mv test/features/cours_route/providers/cours_route_providers_test.dart test/_attic/cours_route_legacy/
mv test/helpers/cours_route_test_helpers.dart test/_attic/cours_route_legacy/
mv test/fixtures/cours_route_fixtures.dart test/_attic/cours_route_legacy/
```

2. **Supprimer les runners obsolètes** :
```bash
rm test/features/cours_route/run_*.dart
```

3. **Vérifier que les tests restants passent** :
```bash
flutter test test/features/cours_route/
# Attendu : 87 tests passent
```

### Option B : Réécriture progressive (moyen terme)

**Effort estimé : 2-3 jours**

| Priorité | Fichier | Pattern à utiliser |
|----------|---------|-------------------|
| P1 | Tests sécurité RBAC | `FakeService` + `ProviderContainer` |
| P2 | Tests service Supabase | `FakeSupabaseClient` |
| P3 | Tests écrans critiques | Widget tests simplifiés |
| P4 | Tests intégration | À évaluer selon besoin |

### Option C : Refactoring architecture auth (long terme)

Si l'équipe souhaite restaurer les tests de sécurité, il faudra :
1. Documenter la nouvelle architecture d'authentification
2. Créer un `MockAuthProvider` compatible
3. Réécrire les tests RBAC avec les nouveaux types

---

## 📝 CONCLUSION

Le module CDR possède une **base de tests solide** pour les modèles et providers (87 tests fonctionnels), mais accumule une **dette technique significative** sur les tests d'intégration, sécurité et écrans.

**Action immédiate recommandée** : Archiver les tests cassés (Option A) pour :
- Débloquer `flutter test`
- Éviter la confusion dans l'équipe
- Permettre un CI/CD fonctionnel

**À planifier** : Réécriture des tests critiques (sécurité RBAC) selon le nouveau pattern `FakeService` démontré dans `cdr_kpi_provider_test.dart` et `cdr_list_provider_test.dart`.

---

## 📎 ANNEXES

### A. Commandes utiles

```bash
# Exécuter uniquement les tests fonctionnels CDR
flutter test test/features/cours_route/models/ \
  test/features/cours_route/providers/cdr_kpi_provider_test.dart \
  test/features/cours_route/providers/cdr_list_provider_test.dart

# Vérifier la compilation sans exécuter
flutter analyze test/features/cours_route/

# Lister tous les fichiers de tests CDR
find test/features/cours_route -name "*_test.dart"
```

### B. Structure recommandée pour nouveaux tests

```dart
// Pattern FakeService (recommandé)
class FakeCoursDeRouteService implements CoursDeRouteService {
  final List<CoursDeRoute> _seedData;
  FakeCoursDeRouteService({List<CoursDeRoute>? seedData})
      : _seedData = seedData ?? [];
  
  @override
  Future<List<CoursDeRoute>> getAll() async => _seedData;
  // ...
}

// Création du container de test
ProviderContainer createTestContainer({required List<CoursDeRoute> seedData}) {
  return ProviderContainer(
    overrides: [
      coursDeRouteServiceProvider.overrideWithValue(
        FakeCoursDeRouteService(seedData: seedData),
      ),
    ],
  );
}
```

### C. Fichiers de référence

Les fichiers suivants servent de **modèle** pour l'écriture de nouveaux tests :
- `test/features/cours_route/providers/cdr_kpi_provider_test.dart`
- `test/features/cours_route/providers/cdr_list_provider_test.dart`

---

**Fin du rapport**

*Ce rapport a été généré automatiquement. Pour toute question, contacter l'équipe QA.*


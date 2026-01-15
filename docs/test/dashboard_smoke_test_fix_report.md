# 🎯 Dashboard Smoke Test — Rapport de Fix

**Date** : 2026-01-15  
**Contexte** : Widget tests `dashboard_screens_smoke_test.dart` échouaient avec `PostgrestException 400`  
**Statut** : ✅ **RÉSOLU**

---

## 🔴 Problème Initial

### Symptômes
```
PostgrestException(message: , code: 400, details: , hint: null)
```

Les tests widget du dashboard échouaient car :
1. Les providers stocks KPI (`depotStocksSnapshotProvider`, `depotOwnerStockFromSnapshotProvider`) tentaient de faire des requêtes Supabase réelles
2. `stocksKpiRepositoryProvider` créait un vrai `StocksKpiRepository` avec un `SupabaseClient` qui retourne toujours 400 dans `TestWidgetsFlutterBinding`
3. Aucun mock/fake n'était en place pour intercepter ces appels réseau

### Impact
- ❌ 7 tests dashboard smoke échouaient systématiquement
- ❌ Impossible de valider le rendu des écrans dashboard en widget tests
- ❌ RenderFlex overflow secondaire (5.4 pixels) dans la section "Détail par propriétaire"

---

## ✅ Solution Implémentée

### Approche : **Fake Repository Pattern**

#### Principe
Puisque `StocksKpiRepository` est une **classe concrète (non abstract)** et que `stocksKpiRepositoryProvider` est un **`Provider<T>` synchrone**, la solution optimale est :

1. **Créer un fake repository** qui extend la classe concrète
2. **Satisfaire le constructeur** avec un fake `SupabaseClient`
3. **Override uniquement les méthodes utilisées** par les providers dashboard
4. **Déléguer les wrappers** (`*Journalier`) vers les méthodes de base

#### Implémentation

**Classe `_FakeStocksKpiRepository`** dans le test :

```dart
class _FakeStocksKpiRepository extends StocksKpiRepository {
  _FakeStocksKpiRepository()
      : super(SupabaseClient('https://fake.supabase.co', 'fake-anon-key'));

  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({...}) async {
    return [
      DepotGlobalStockKpi(
        depotId: depotId ?? 'test-depot',
        depotNom: 'DEPOT TEST',
        produitId: produitId ?? 'P1',
        produitNom: 'DIESEL',
        stockAmbiantTotal: 10000,
        stock15cTotal: 9500,
      ),
    ];
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({...}) async {
    return [
      DepotOwnerStockKpi(..., proprietaireType: 'MONALUXE', stockAmbiantTotal: 7000, stock15cTotal: 6650),
      DepotOwnerStockKpi(..., proprietaireType: 'PARTENAIRE', stockAmbiantTotal: 3000, stock15cTotal: 2850),
    ];
  }

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({...}) async {
    final d = dateJour ?? DateTime(2026, 1, 15);
    return [
      CiterneGlobalStockSnapshot(citerneId: 'C1', citerneNom: 'TANK 1', ..., stockAmbiantTotal: 6000, stock15cTotal: 5700, capaciteTotale: 15000),
      CiterneGlobalStockSnapshot(citerneId: 'C2', citerneNom: 'TANK 2', ..., stockAmbiantTotal: 4000, stock15cTotal: 3800, capaciteTotale: 15000),
    ];
  }

  @override
  Future<double> fetchDepotTotalCapacity({required String depotId, String? produitId}) async => 30000;

  @override
  Future<List<Map<String, dynamic>>> fetchStockActuelRows({required String depotId, String? produitId}) async => [];

  // Wrappers Journalier (délégation)
  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotalsJournalier({...}) =>
      fetchDepotProductTotals(depotId: depotId, produitId: produitId, dateJour: dateJour);

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotalsJournalier({...}) =>
      fetchDepotOwnerTotals(depotId: depotId, produitId: produitId, proprietaireType: proprietaireType, dateJour: dateJour);

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshotsJournalier({...}) =>
      fetchCiterneGlobalSnapshots(depotId: depotId, citerneId: citerneId, produitId: produitId, dateJour: dateJour);
}
```

**Override dans le test** :

```dart
return ProviderContainer(
  overrides: [
    appEnvSyncProvider.overrideWithValue(appEnv),
    supabaseClientProvider.overrideWithValue(
      SupabaseClient('https://fake.supabase.co', 'fake-anon-key'),
    ),
    // ✅ IMPORTANT: coupe le réseau pour les KPI stocks
    stocksKpiRepositoryProvider.overrideWithValue(_FakeStocksKpiRepository()),
    appAuthStateProvider.overrideWith(...),
    currentProfilProvider.overrideWith(...),
    kpiProviderProvider.overrideWith(...),
    citernesSousSeuilProvider.overrideWith(...),
  ],
);
```

### Fix Layout Overflow

**Optimisation des espacements** dans `lib/features/dashboard/widgets/role_dashboard.dart` :

Section "Détail par propriétaire" (2 occurrences : data + error states) :
- `SizedBox(height: 16)` → `SizedBox(height: 12)` (avant titre)
- `SizedBox(height: 12)` → `SizedBox(height: 8)` (avant LayoutBuilder + entre colonnes mobile)

**Gain** : 10 pixels d'espacement → élimine l'overflow de 5.4px

---

## 📊 Résultats

### Avant
```
00:01 +0 -7: Dashboard Screens Smoke Tests
  PostgrestException 400 (message: , code: 400, details: , hint: null)
  RenderFlex overflowed by 5.4 pixels on the bottom
```

### Après
```
00:01 +7: All tests passed!
```

### Bilan Global
- ✅ **496 tests passent** (99.6% de succès)
- ⏭️ **8 tests skipped** (tests d'intégration marqués `@Tags(['integration'])`)
- ❌ **2 tests échouent** (tests d'intégration nécessitant base de données réelle) :
  1. `test/features/sorties/sorties_e2e_test.dart` - E2E UI
  2. `test/features/stocks/stocks_kpi_repository_test.dart` - Repository test

---

## 🎓 Leçons Apprises

### ✅ Bonnes Pratiques
1. **Fake > Mock** : Pour les classes concrètes, extend et override est plus simple et plus robuste que créer des mocks complets
2. **Stub minimal** : Implémenter uniquement ce qui est réellement utilisé par les tests (pas besoin de tout stubber)
3. **Provider override** : Riverpod permet d'override facilement les providers synchrones avec `.overrideWithValue()`
4. **Layout testing** : Les widget tests détectent les overflows que le développement manuel peut manquer

### 🔧 Pattern Réutilisable
Ce pattern peut être réutilisé pour d'autres repositories :
```dart
class _FakeXxxRepository extends XxxRepository {
  _FakeXxxRepository() : super(fakeClient);
  
  @override
  Future<T> methodUsedByTests() async => testData;
  
  // Les autres méthodes héritent de la classe parente (peuvent throw si appelées)
}

// Dans le test :
xxxRepositoryProvider.overrideWithValue(_FakeXxxRepository())
```

---

## 📝 Fichiers Modifiés

1. **`test/features/dashboard/screens/dashboard_screens_smoke_test.dart`**
   - Ajout de `_FakeStocksKpiRepository` (145 lignes)
   - Override de `stocksKpiRepositoryProvider` dans `_createTestContainer()`
   - Import de `stocks_kpi_repository.dart` et `stocks_kpi_providers.dart`

2. **`lib/features/dashboard/widgets/role_dashboard.dart`**
   - Réduction des espacements dans 2 sections "Détail par propriétaire"

3. **`CHANGELOG.md`**
   - Documentation complète du fix avec contexte, solution et résultats

---

## 🚀 Prochaines Étapes (Optionnel)

Pour atteindre 100% de tests passants :
1. **Fixer `sorties_e2e_test.dart`** : Ajouter plus de mocking pour `RoleDepotChips` et le formulaire sortie
2. **Fixer `stocks_kpi_repository_test.dart`** : Soit skip le test (nécessite DB réelle), soit créer des fixtures complètes dans le fake

**Priorité** : Basse (2 tests sur 506 = 0.4% d'échec, et ce sont des tests d'intégration)

---

**Auteur** : Valery Kalonga  
**Date** : 2026-01-15  
**Status** : ✅ RÉSOLU & DOCUMENTÉ

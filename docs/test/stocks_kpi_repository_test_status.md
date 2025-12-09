# État actuel : test/features/stocks/stocks_kpi_repository_test.dart

**Date :** 2025-12-08  
**Fichier :** `test/features/stocks/stocks_kpi_repository_test.dart`

## Résumé

**État actuel (après application de la stratégie recommandée) :**

✅ **Le fichier compile sans erreur**  
❌ **Tous les tests échouent** à l'exécution avec l'erreur :
```
type 'Null' is not a subtype of type 'String'
```

**Problème :** `any as dynamic` ne fonctionne pas à l'exécution car `any` retourne `Null` et le cast ne change pas cela.

## Ce qui a été fait

### 1. Remplacement des fakes maison par des mocks Mockito

**Avant :**
- Classes fakes personnalisées : `_FakeSupabaseClientForStocksKpi`, `_FakeQueryBuilder`, `_FakeFilter`
- Problème : signature de `then` incompatible avec `PostgrestBuilder.then` (attendu `Map<String, dynamic>`, fourni `List<Map<String, dynamic>>`)

**Après :**
- Mocks Mockito locaux : `MockSupabaseClient`, `MockPostgrestQueryBuilder`, `MockPostgrestFilterBuilder`
- Helpers `stubQuerySuccess` et `stubQueryError` pour configurer les résultats des requêtes (sans appeler `when()` dans un stub)
- Stubs de base dans `setUp()` pour `from`, `select`, et `eq`

### 2. Correction des erreurs de compilation

**Problème initial :**
```
Error: The parameter 'onValue' of the method '_FakeFilter.then' has type 
'FutureOr<R> Function(List<Map<String, dynamic>>)', which does not match 
the corresponding type, 'FutureOr<R> Function(Map<String, dynamic>)', 
in the overridden method, 'PostgrestBuilder.then'.
```

**Solution appliquée :**
- Utilisation de `any as dynamic` pour contourner l'erreur de type dans `when(mockFilter.then<dynamic>(...))`
- Ajout du paramètre `String tableName` aux helpers pour éviter l'utilisation de `captureAny` (qui retourne `Null`)

### 3. Structure des tests

Les tests couvrent les 4 méthodes du repository :
- `fetchDepotProductTotals` (7 tests)
- `fetchDepotOwnerTotals` (5 tests)
- `fetchCiterneOwnerSnapshots` (5 tests)
- `fetchCiterneGlobalSnapshots` (5 tests)

**Total : 22 tests**

## Problème actuel

### Erreur d'exécution

```
type 'Null' is not a subtype of type 'String'
test/features/stocks/stocks_kpi_repository_test.dart 58:32  main.<fn>.<fn>
```

### Cause

Dans le `setUp()`, nous utilisons :
```dart
when(mockClient.from(any as dynamic)).thenReturn(mockQuery);
when(mockFilter.eq(any as dynamic, any)).thenReturn(mockFilter);
```

Le problème est que `any` retourne `Null` à l'exécution, et le cast `as dynamic` ne change pas cela. Quand mockito essaie de matcher les appels réels avec ces stubs, il reçoit `Null` au lieu d'une `String`, ce qui cause l'erreur de type.

### Code actuel (après refactoring)

**setUp() :**
```dart
setUp(() {
  mockClient = MockSupabaseClient();
  mockQuery = MockPostgrestQueryBuilder();
  mockFilter = MockPostgrestFilterBuilder();
  repository = StocksKpiRepository(mockClient);

  // Stub de base pour toutes les requêtes
  when(mockClient.from(any as dynamic)).thenReturn(mockQuery);
  when(mockQuery.select<Map<String, dynamic>>()).thenReturn(mockFilter);
  when(mockFilter.eq(any as dynamic, any)).thenReturn(mockFilter);
});
```

**Helpers :**
```dart
void stubQuerySuccess(List<Map<String, dynamic>> rows) {
  when(mockFilter.then<dynamic>(
    any as dynamic,
    onError: anyNamed('onError'),
  )).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments[0] as dynamic;
    final onError = invocation.namedArguments[#onError] as dynamic;
    return Future<List<Map<String, dynamic>>>.value(rows)
        .then(onValue, onError: onError);
  });
}
```

**Problème :** `any as dynamic` dans le `setUp()` ne fonctionne pas à l'exécution car `any` retourne `Null`.

## Solutions possibles

### Option 1 : Configurer les stubs directement dans chaque test

**Avantages :**
- Évite les helpers qui peuvent causer des conflits
- Plus explicite et lisible

**Inconvénients :**
- Plus de duplication de code
- Tests plus longs

**Exemple :**
```dart
test('should map rows correctly', () async {
  // Arrange
  when(mockClient.from('v_kpi_stock_global')).thenReturn(mockQuery);
  when(mockQuery.select<Map<String, dynamic>>()).thenReturn(mockFilter);
  when(mockFilter.eq('depot_id', any)).thenReturn(mockFilter);
  when(mockFilter.then<dynamic>(
    any as dynamic,
    onError: anyNamed('onError'),
  )).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments[0] as dynamic Function(List<Map<String, dynamic>>);
    return Future<List<Map<String, dynamic>>>.value(rows).then(onValue);
  });
  
  // Act & Assert
  // ...
});
```

### Option 2 : Utiliser `clearInteractions` et configurer les stubs dans `setUp`

**Avantages :**
- Centralise la configuration
- Réutilisable

**Inconvénients :**
- Nécessite de réinitialiser les mocks entre les tests
- Peut être complexe si les tests ont des besoins différents

### Option 3 : Créer de nouveaux mocks dans chaque test

**Avantages :**
- Isolation complète entre les tests
- Pas de conflit de stubs

**Inconvénients :**
- Plus de code dans chaque test
- Perte de la réutilisation des helpers

**Exemple :**
```dart
test('should map rows correctly', () async {
  // Arrange
  final mockClient = MockSupabaseClient();
  final mockQuery = MockPostgrestQueryBuilder();
  final mockFilter = MockPostgrestFilterBuilder();
  final repository = StocksKpiRepository(mockClient);
  
  when(mockClient.from('v_kpi_stock_global')).thenReturn(mockQuery);
  // ... configuration des stubs
  
  // Act & Assert
  // ...
});
```

### Option 4 : Utiliser une approche différente pour mocker `PostgrestFilterBuilder`

Au lieu de mocker `then`, on pourrait :
- Créer un fake qui implémente directement `Future<List<Map<String, dynamic>>>`
- Utiliser `when(mockFilter).thenReturn(Future.value(rows))` si possible

**Note :** Cette approche nécessite de vérifier si `PostgrestFilterBuilder` peut être traité comme un `Future` directement.

## Solution recommandée

**Option : Ne pas utiliser `any` dans le `setUp()`**

Au lieu d'utiliser `any` dans le `setUp()`, nous devrions :
1. **Option A :** Ne pas stubber `from` et `eq` dans le `setUp()`, mais le faire dans chaque test avec des valeurs concrètes
2. **Option B :** Utiliser `reset()` dans chaque test et re-stubber avec des valeurs concrètes
3. **Option C :** Utiliser un matcher personnalisé qui accepte n'importe quelle String

**Option A recommandée :** Supprimer les stubs de `from` et `eq` du `setUp()`, et les ajouter dans chaque test avec les valeurs concrètes attendues (ex: `when(mockClient.from('v_kpi_stock_global')).thenReturn(mockQuery);`).

## État de compilation

✅ **Le fichier compile sans erreur** (avec `any as dynamic`)

## État d'exécution

❌ **Tous les tests échouent** avec l'erreur `type 'Null' is not a subtype of type 'String'`

**Cause :** `any` retourne `Null` à l'exécution, et le cast `as dynamic` ne change pas cela. Mockito essaie de matcher les appels réels avec `Null` au lieu d'une `String`.

## Prochaines étapes

1. **Court terme :** Supprimer les stubs de `from` et `eq` du `setUp()`, et les ajouter dans chaque test avec des valeurs concrètes
2. **Moyen terme :** Vérifier que tous les tests passent
3. **Long terme :** Optimiser la duplication si nécessaire (peut-être créer un helper qui prend la table en paramètre, mais qui n'utilise pas `any`)

**Exemple de correction :**
```dart
setUp(() {
  // ... initialisation des mocks ...
  // Ne PAS stubber from() et eq() ici
});

test('should map rows correctly', () async {
  // Arrange
  when(mockClient.from('v_kpi_stock_global')).thenReturn(mockQuery);
  when(mockQuery.select<Map<String, dynamic>>()).thenReturn(mockFilter);
  when(mockFilter.eq('depot_id', any)).thenReturn(mockFilter);
  stubQuerySuccess(rows);
  
  // Act & Assert
  // ...
});
```

## Fichiers modifiés

- `test/features/stocks/stocks_kpi_repository_test.dart` : Remplacement complet des fakes par des mocks Mockito

## Fichiers non modifiés (contraintes respectées)

- ✅ Aucun fichier de production sous `lib/`
- ✅ Aucun autre fichier de test
- ✅ Signature publique de `StocksKpiRepository` inchangée

## Notes techniques

### Utilisation de `any as dynamic`

Le cast `any as dynamic` est nécessaire car :
- `any` retourne `Null` dans le contexte null-safe de Dart
- `PostgrestFilterBuilder.then` attend `FutureOr<R> Function(Map<String, dynamic>)`
- Mockito ne peut pas inférer automatiquement le type de la fonction callback

### Structure des helpers

Les helpers `stubSuccessRows` et `stubError` :
- Prennent un paramètre `String tableName` pour éviter `captureAny`
- Configurent tous les stubs nécessaires (`from`, `select`, `eq`, `then`)
- Utilisent `thenAnswer` pour intercepter le callback et retourner les données mockées

### Problème de récursivité

L'erreur "Cannot call `when` within a stub response" se produit car :
1. Un test appelle `stubSuccessRows(...)`
2. `stubSuccessRows` appelle `when(...)` pour configurer les stubs
3. Si un stub est déjà en cours d'exécution (via `thenAnswer`), mockito interdit d'appeler `when()` à nouveau
4. Cela peut arriver si les stubs sont configurés de manière récursive ou si plusieurs tests partagent les mêmes mocks


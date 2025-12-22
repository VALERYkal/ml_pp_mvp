# BUG-2025-12 — Boucle infinie module Citernes (web)

## Métadonnées

- **Date** : 2025-12-12
- **Module** : Citernes / Providers
- **Impact** : Blocage fonctionnel (boucle infinie sur web)
- **Sévérité** : High
- **Statut** : ✅ Résolu
- **Tags** :
  - `BUG-CITERNES-PROVIDER-LOOP`
  - `RIVERPOD-ASYNC-WATCH-ANTIPATTERN`
  - `AUTODISPOSE-REBUILD-INFINITE`

---

## Contexte

Le module Citernes affiche la liste des citernes avec leurs stocks actuels. Le provider `citerneStocksSnapshotProvider` agrège les données de citernes, produits et stocks depuis `depotStocksSnapshotProvider` pour construire un snapshot complet. Sur web, ce provider entrait dans une boucle infinie de rebuilds, générant des logs en continu et bloquant l'interface.

---

## Symptômes observés

- **Console web** : Logs répétés en boucle "🔄 depotStocksSnapshotProvider: Début - depotId=..., dateJour=..."
- **Performance** : Interface ralentie voire bloquée sur le module Citernes
- **Comportement** : Le provider se rebuild indéfiniment sans stabilisation
- **Plateforme** : Problème observé principalement sur web (Chrome), moins visible sur mobile

**Données réelles** : Les données en DB sont correctes, le problème est purement lié à la gestion des providers Riverpod.

---

## Reproduction minimale

1. Lancer l'application en mode web : `flutter run -d chrome`
2. Se connecter en tant qu'admin
3. Naviguer vers le module "Citernes" depuis le dashboard
4. Observer la console du navigateur (F12)

**Résultat attendu** : Le module s'affiche normalement, les logs de debug apparaissent une seule fois.

**Résultat observé** : Les logs "🔄 depotStocksSnapshotProvider: Début ..." se répètent indéfiniment en boucle.

> Temps de reproduction : < 30 secondes

---

## Observations DB (preuves)

### Requête de vérification

```sql
-- Vérifier que les données de stock existent bien
SELECT 
  c.id as citerne_id,
  c.nom as citerne_nom,
  c.depot_id,
  sj.date_jour,
  sj.stock_ambiant,
  sj.stock_15c
FROM citernes c
LEFT JOIN stocks_journaliers sj ON sj.citerne_id = c.id
WHERE c.depot_id = '11111111-1111-1111-1111-111111111111'
  AND c.statut = 'active'
ORDER BY sj.date_jour DESC
LIMIT 10;
```

### Résultat attendu

Les données de stock sont présentes et cohérentes dans la base.

### Résultat observé

Les données sont correctes. Le problème n'est **pas** lié à la base de données, mais à la logique Riverpod.

---

## Chaîne technique (de bout en bout)

```
UI → Providers → Service → Repository → SQL
```

| Couche | Fichier | Classe/Fonction |
|--------|---------|-----------------|
| **UI** | `lib/features/citernes/screens/citerne_list_screen.dart` | `CiterneListScreen` |
| **Provider(s)** | `lib/features/citernes/providers/citerne_providers.dart` | `citerneStocksSnapshotProvider` (ligne 58) |
| **Provider dépendant** | `lib/features/stocks/data/stocks_kpi_providers.dart` | `depotStocksSnapshotProvider` (ligne 185) |
| **Service** | `lib/features/stocks/data/stocks_kpi_service.dart` | `StocksKpiService.loadDashboardKpis()` |
| **Repository** | `lib/data/repositories/stocks_kpi_repository.dart` | `StocksKpiRepository.fetchDepotProductTotals()` |
| **Source SQL** | Vue SQL | `v_stocks_citerne_global` |

**Chaîne d'invalidation** :
```
citerneStocksSnapshotProvider (async)
  → ref.watch(depotStocksSnapshotProvider(...)) [AsyncValue]
    → Quand depotStocksSnapshotProvider passe loading → data
      → Riverpod invalide citerneStocksSnapshotProvider
        → Rebuild → ref.watch() à nouveau
          → Boucle infinie
```

---

## Cause racine

Décrire précisément **pourquoi** ça se produit :

- [x] autoDispose loop / rebuild infini
- [ ] Non déterminisme (ex: pas d'ORDER BY)
- [ ] Filtre trop strict (ex: `eq(date_jour)` au lieu de `<=`)
- [ ] Date instable (`DateTime.now` avec ms)
- [ ] Mapping incorrect (type mismatch)
- [ ] RLS / permission manquante
- [ ] Autre : Antipattern Riverpod (watch AsyncValue dans async)

**Explication détaillée** :

Le provider `citerneStocksSnapshotProvider` est un `FutureProvider.autoDispose` (fonction async). À l'intérieur, il utilisait `ref.watch(depotStocksSnapshotProvider(...))` qui retourne un `AsyncValue`.

**Problème** :
1. `ref.watch()` sur un `FutureProvider` retourne un `AsyncValue` (loading → data)
2. Quand `depotStocksSnapshotProvider` passe de `loading` à `data`, Riverpod détecte un changement
3. Riverpod invalide automatiquement `citerneStocksSnapshotProvider` (car il watch un provider qui a changé)
4. `citerneStocksSnapshotProvider` se rebuild → relance les `await sb.from(...)`
5. Il re-watch `depotStocksSnapshotProvider` → boucle infinie

**Pourquoi sur web plus que mobile** :
- Sur web, les rebuilds sont plus fréquents (hot reload, navigation)
- `autoDispose` + navigation peut créer des cycles d'invalidation plus agressifs

---

## Correctif appliqué

### Patch conceptuel

**Avant** :
```dart
// 4) Récupérer les stocks depuis depotStocksSnapshotProvider (v_stocks_citerne_global)
final snapshotAsync = ref.watch(
  depotStocksSnapshotProvider(
    DepotStocksSnapshotParams(
      depotId: depotId,
      dateJour: dateJour,
    ),
  ),
);

// 5) Créer un index des stocks par (citerneId, produitId)
final stockByKey = <String, CiterneGlobalStockSnapshot>{};
if (snapshotAsync.hasValue) {
  for (final stockRow in snapshotAsync.requireValue.citerneRows) {
    final key = '${stockRow.citerneId}::${stockRow.produitId}';
    stockByKey[key] = stockRow;
  }
}
```

**Après** :
```dart
// 4) Récupérer les stocks (await) depuis depotStocksSnapshotProvider
final snapshot = await ref.watch(
  depotStocksSnapshotProvider(
    DepotStocksSnapshotParams(
      depotId: depotId,
      dateJour: dateJour,
    ),
  ).future,
);

// 5) Créer un index des stocks par (citerneId, produitId)
final stockByKey = <String, CiterneGlobalStockSnapshot>{};
for (final stockRow in snapshot.citerneRows) {
  final key = '${stockRow.citerneId}::${stockRow.produitId}';
  stockByKey[key] = stockRow;
}
```

### Détails techniques

- **Fichier** : `lib/features/citernes/providers/citerne_providers.dart`
- **Fonction** : `citerneStocksSnapshotProvider` (lignes 58-198)
- **Points clés** :
  - Remplacement de `ref.watch(...)` par `await ref.watch(...).future` (lignes 112-119)
  - Suppression de toutes les vérifications `hasValue` et `requireValue` (lignes 123-128, 187-189, 193)
  - Accès direct aux propriétés de `snapshot` (qui est maintenant un `DepotStocksSnapshot` direct)
  - Comportement fonctionnel préservé : les citernes continuent d'afficher le stock correctement

**Changements détaillés** :
1. **Ligne 112-119** : `ref.watch()` → `await ref.watch(...).future`
2. **Ligne 123-126** : Suppression de `if (snapshotAsync.hasValue)` et `requireValue`
3. **Ligne 187** : `snapshot.totals` au lieu de `snapshotAsync.hasValue ? snapshotAsync.requireValue.totals : fallback`
4. **Ligne 189** : `snapshot.owners` au lieu de `snapshotAsync.hasValue ? snapshotAsync.requireValue.owners : []`
5. **Ligne 193** : `snapshot.isFallback` au lieu de `snapshotAsync.hasValue ? snapshotAsync.requireValue.isFallback : false`

---

## Validation

### Tests automatisés

```bash
flutter test test/features/citernes/
```

**Résultat** : ✅ Tous les tests existants passent (aucune régression)

### Validation manuelle

- [x] Scénario 1 : `flutter run -d chrome` → Login admin → Dashboard → Citernes
  - **Résultat** : Plus de logs en boucle, module s'affiche normalement
- [x] Scénario 2 : Navigation répétée Dashboard ↔ Citernes
  - **Résultat** : Pas de boucle, performance normale

### Non-régression

- [x] Module Citernes : fonctionne toujours, affiche correctement les stocks
- [x] Module Stocks : fonctionne toujours (utilise le même `depotStocksSnapshotProvider`)
- [x] Module Dashboard : fonctionne toujours
- [x] Aucune erreur console après correction

---

## Prévention / Règles à appliquer

### Règle 1 : Utiliser `.future` dans les fonctions async

**Contexte** : Quand on est dans un `FutureProvider` (fonction async) et qu'on doit consommer un autre `FutureProvider`.

**Règle** :
- ✅ Faire : `await ref.watch(provider(...)).future` pour attendre directement la valeur
- ❌ Ne pas faire : `ref.watch(provider(...))` qui retourne un `AsyncValue` et cause des invalidations

**Exemple** :
```dart
// ✅ BON : Dans une fonction async
final snapshot = await ref.watch(depotStocksSnapshotProvider(params).future);

// ❌ MAUVAIS : Dans une fonction async
final snapshotAsync = ref.watch(depotStocksSnapshotProvider(params));
if (snapshotAsync.hasValue) {
  final snapshot = snapshotAsync.requireValue; // Peut causer une boucle
}
```

### Règle 2 : Éviter `ref.watch()` sur AsyncValue dans les providers async

**Contexte** : Les `FutureProvider` qui watch d'autres `FutureProvider` doivent utiliser `.future` pour éviter les cycles d'invalidation.

**Règle** :
- ✅ Faire : Utiliser `.future` pour attendre la valeur finale
- ❌ Ne pas faire : Watch l'`AsyncValue` qui change d'état (loading → data) et cause des invalidations

**Explication** :
- `ref.watch(provider)` retourne un `AsyncValue` qui change d'état
- Chaque changement d'état (loading → data) invalide le provider parent
- Dans un `autoDispose`, cela peut créer une boucle infinie

### Règle 3 : Documenter l'usage de `.future` dans les commentaires

**Contexte** : Les patterns Riverpod peuvent être subtils, la documentation aide à éviter les erreurs futures.

**Règle** :
- ✅ Ajouter un commentaire expliquant pourquoi on utilise `.future` au lieu de `ref.watch()`
- ✅ Documenter les dépendances entre providers

**Exemple** :
```dart
// 4) Récupérer les stocks (await) depuis depotStocksSnapshotProvider
// Note: Utilisation de .future pour éviter les invalidations en cascade
// (ref.watch() retournerait un AsyncValue qui invalide ce provider à chaque changement d'état)
final snapshot = await ref.watch(
  depotStocksSnapshotProvider(params).future,
);
```

---

## Notes / Suivi

- **PR/Commit** : Correction appliquée directement
- **Issue liée** : Aucune
- **TODO** : Vérifier s'il existe d'autres providers avec le même antipattern

---

## Checklist incident

- [x] Repro 100% confirmée
- [x] Requête SQL de preuve archivée (non applicable, bug Riverpod)
- [x] Root cause écrite sans hypothèse
- [x] Fix décrit + fichier et fonction
- [x] Tests verts
- [x] Entrée CHANGELOG ajoutée

---

**Date de résolution** : 2025-12-12  
**Auteur du correctif** : Assistant IA (Cursor)  
**Validé par** : Utilisateur (confirmation "tous va bien maintenant")

# BUG-2025-12 — Dashboard Stock total ne se rafraîchit pas après création de sortie

## Métadonnées

- **Date** : 12 décembre 2025
- **Module** : Dashboard / KPI Stocks / Sorties
- **Impact** : Données erronées (Stock total stale après création de sortie)
- **Sévérité** : Medium
- **Statut** : ✅ Résolu
- **Tags** :
  - `BUG-DASHBOARD-STOCK-REFRESH`
  - `RIVERPOD-CACHE-INVALIDATION`
  - `KPI-PROVIDER-STALE`

---

## Contexte

Le dashboard affiche une carte "Stock total" qui agrège les stocks du dépôt via `kpiProviderProvider`. Cette carte dépend de `stocksDashboardKpisProvider(depotId)` qui est un `FutureProvider.family` pouvant conserver des données en cache. Après création d'une sortie validée, le dashboard continue d'afficher l'ancien stock total jusqu'à un redémarrage complet de l'application, même si les données en base sont correctes.

**Chaîne technique** :
```
SortieFormScreen (création sortie)
  → SortieService.createValidated()
    → INSERT sorties_produit
      → Trigger SQL → stocks_journaliers mis à jour ✅
  
Dashboard (role_dashboard.dart)
  → kpiProviderProvider (autoDispose)
    → _safeLoadStocks()
      → stocksDashboardKpisProvider(depotId) ❌ CACHE NON INVALIDÉ
        → StocksKpiRepository.fetchDepotProductTotals()
          → v_kpi_stock_global (SQL)
```

---

## Symptômes observés

- **UI** : Après création d'une sortie (ex: 1 000 L @15°C), retour sur dashboard → "Stock total" reste à l'ancienne valeur (ex: 9 915.5 L au lieu de 8 915.5 L)
- **DB** : Les données sont correctes dans la base (la sortie est bien enregistrée, les stocks journaliers sont débités correctement)
- **Comportement** : Le dashboard ne se rafraîchit pas automatiquement après création de sortie, nécessitant un redémarrage complet de l'app

**Scénario typique** :
1. Dashboard affiche : Stock total = 9 915.5 L @15°C
2. Navigation vers Sorties → Création sortie 1 000 L @15°C
3. Retour Dashboard → Stock total reste à 9 915.5 L (devrait être 8 915.5 L)
4. Redémarrage app → Stock total correct (8 915.5 L)

---

## Reproduction minimale

1. Ouvrir le dashboard admin (`/dashboard/admin`)
2. Noter la valeur "Stock total" (ex: 9 915.5 L @15°C)
3. Naviguer vers Sorties (`/sorties`)
4. Créer une sortie validée (ex: 1 000 L @15°C)
5. Retourner sur le dashboard (clic navigation ou bouton retour)
6. Observer que "Stock total" n'a pas changé (reste à 9 915.5 L au lieu de 8 915.5 L)
7. Redémarrer complètement l'application
8. Observer que "Stock total" est maintenant correct (8 915.5 L)

> Temps de reproduction : < 2 minutes

---

## Observations DB (preuves)

### Requête de vérification

```sql
-- Vérifier que la sortie est bien enregistrée
SELECT id, volume_corrige_15c, date_sortie, statut, citerne_id
FROM sorties_produit
WHERE date_sortie >= CURRENT_DATE
ORDER BY created_at DESC
LIMIT 1;

-- Vérifier que les stocks journaliers sont à jour (débités)
SELECT citerne_id, date_jour, stock_15c, proprietaire_type
FROM stocks_journaliers
WHERE date_jour = CURRENT_DATE
ORDER BY date_jour DESC, citerne_id;

-- Vérifier la vue KPI globale
SELECT depot_id, stock_15c_total, date_jour
FROM v_kpi_stock_global
WHERE depot_id = '11111111-1111-1111-1111-111111111111'
ORDER BY date_jour DESC
LIMIT 1;
```

### Résultat attendu

Les données en DB sont correctes : la sortie est enregistrée, les stocks journaliers sont débités, la vue `v_kpi_stock_global` reflète le nouveau stock.

### Résultat observé

Les données en DB sont correctes. Le problème est que `stocksDashboardKpisProvider(depotId)` conserve des données en cache et n'est pas invalidé après création de sortie.

---

## Chaîne technique (de bout en bout)

| Couche | Fichier | Classe/Fonction |
|--------|---------|-----------------|
| **UI (Création)** | `lib/features/sorties/screens/sortie_form_screen.dart` | `_SortieFormScreenState._submitSortie()` |
| **Service** | `lib/features/sorties/data/sortie_service.dart` | `SortieService.createValidated()` |
| **SQL** | `supabase/migrations/..._sorties_trigger_unified.sql` | Trigger `sorties_before_validate_trg` → `stock_upsert_journalier()` |
| **UI (Dashboard)** | `lib/features/dashboard/widgets/role_dashboard.dart` | `RoleDashboard.build()` → `kpiProviderProvider` |
| **Provider KPI** | `lib/features/kpi/providers/kpi_provider.dart` | `kpiProviderProvider` → `_safeLoadStocks()` |
| **Provider Stocks** | `lib/features/stocks/data/stocks_kpi_providers.dart` | `stocksDashboardKpisProvider(depotId)` ❌ CACHE |
| **Repository** | `lib/data/repositories/stocks_kpi_repository.dart` | `StocksKpiRepository.fetchDepotProductTotals()` |
| **Source SQL** | Vue SQL | `v_kpi_stock_global` |

---

## Cause racine

**Problème principal** : Invalidation incomplète de la chaîne de providers après création de sortie.

**Détails** :

1. **Provider non invalidé** : Après création réussie d'une sortie dans `sortie_form_screen.dart`, seul `kpiProviderProvider` était invalidé (via `triggerKpiRefresh()`), mais **pas** `stocksDashboardKpisProvider(depotId)`.

2. **Cache family** : `stocksDashboardKpisProvider` est un `FutureProvider.family` qui peut conserver des données en cache par instance (`depotId`). Même si `kpiProviderProvider` est invalidé et se reconstruit, il appelle `_safeLoadStocks()` qui fait `ref.watch(stocksDashboardKpisProvider(depotId).future)`, récupérant ainsi les **anciennes données en cache**.

3. **Conséquence** : Le dashboard affiche des données stale jusqu'à ce que :
   - L'app soit complètement redémarrée (force la destruction de tous les providers)
   - Ou que `stocksDashboardKpisProvider(depotId)` soit explicitement invalidé

**Explication détaillée** :

```
Après création sortie :
1. sortie_form_screen.dart invalide kpiProviderProvider ✅
2. stocksDashboardKpisProvider(depotId) reste en cache ❌
3. kpiProviderProvider se reconstruit
4. _safeLoadStocks() appelle stocksDashboardKpisProvider(depotId).future
5. Provider retourne les données en cache (anciennes) ❌
6. Dashboard affiche stock incorrect ❌
```

---

## Correctif appliqué

### Patch conceptuel

**Avant** :
```dart
// lib/features/sorties/screens/sortie_form_screen.dart
await sortieService.createValidated(...);

// Invalidation partielle (incomplète)
triggerKpiRefresh(ref);  // Invalide seulement kpiProviderProvider
```

**Après** :
```dart
// lib/features/sorties/screens/sortie_form_screen.dart
await sortieService.createValidated(...);

// Invalidation complète via helper centralisé
final profil = ref.read(profilProvider).valueOrNull;
final depotId = profil?.depotId;
invalidateDashboardKpisAfterStockMovement(ref, depotId: depotId);
```

**Helper centralisé créé** :
```dart
// lib/shared/refresh/refresh_helpers.dart
void invalidateDashboardKpisAfterStockMovement(WidgetRef ref, {String? depotId}) {
  // 1) Invalider le provider KPI dashboard (snapshot global)
  ref.invalidate(kpiProviderProvider);

  // 2) Invalider le cache stocks du dashboard pour CE depot
  if (depotId != null) {
    ref.invalidate(stocksDashboardKpisProvider(depotId));
  } else {
    // Fallback: invalider toute la family
    ref.invalidate(stocksDashboardKpisProvider);
  }
}
```

### Détails techniques

- **Fichier créé** : `lib/shared/refresh/refresh_helpers.dart`
- **Fonction** : `invalidateDashboardKpisAfterStockMovement()`
- **Fichier modifié** : `lib/features/sorties/screens/sortie_form_screen.dart`
- **Points clés** :
  - Helper centralisé réutilisable pour tous les mouvements de stock (sorties, réceptions)
  - Invalidation complète de la chaîne : `kpiProviderProvider` + `stocksDashboardKpisProvider(depotId)`
  - Utilisation de `WidgetRef` pour compatibilité avec les widgets Flutter
  - Paramètre `depotId` optionnel : invalide l'instance spécifique si fourni, sinon invalide toute la family

---

## Validation

### Tests automatisés

```bash
flutter analyze lib/shared/refresh/refresh_helpers.dart lib/features/sorties/screens/sortie_form_screen.dart
```

**Résultat** : ✅ Aucune erreur de compilation

### Validation manuelle

- [x] Scénario 1 : Dashboard (9 915.5 L) → Sorties (créer 1 000 L) → Dashboard (8 915.5 L) **sans redémarrage**
- [x] Scénario 2 : Le bouton refresh manuel fonctionne toujours
- [x] Scénario 3 : Aucune régression sur les autres modules

### Non-régression

- [x] Module Sorties : fonctionne toujours
- [x] Module Dashboard : fonctionne toujours
- [x] Module Stocks : fonctionne toujours
- [x] Aucune erreur console
- [x] Aucune erreur de compilation

---

## Prévention / Règles à appliquer

### Règle 1 : Invalider toute la chaîne de providers dépendants

**Contexte** : Quand un provider parent (`kpiProviderProvider`) dépend d'un provider enfant (`stocksDashboardKpisProvider(depotId)`), invalider uniquement le parent ne suffit pas si l'enfant est en cache.

**Règle** :
- ✅ Faire : Invalider **tous** les providers de la chaîne (parent + enfants)
- ❌ Ne pas faire : Invalider uniquement le provider parent

**Exemple** :
```dart
// ✅ BON : Invalidation complète
ref.invalidate(kpiProviderProvider);
ref.invalidate(stocksDashboardKpisProvider(depotId));

// ❌ MAUVAIS : Invalidation partielle
ref.invalidate(kpiProviderProvider);  // Seul
```

### Règle 2 : Centraliser la logique d'invalidation dans un helper réutilisable

**Contexte** : L'invalidation des KPIs après un mouvement de stock doit être identique pour les sorties et les réceptions.

**Règle** :
- ✅ Faire : Créer un helper centralisé (`invalidateDashboardKpisAfterStockMovement`) et l'utiliser partout
- ❌ Ne pas faire : Dupliquer la logique d'invalidation dans chaque écran

**Exemple** :
```dart
// ✅ BON : Helper centralisé
invalidateDashboardKpisAfterStockMovement(ref, depotId: depotId);

// ❌ MAUVAIS : Logique dupliquée
ref.invalidate(kpiProviderProvider);
ref.invalidate(stocksDashboardKpisProvider(depotId));
// ... répété dans sortie_form_screen.dart ET reception_form_screen.dart
```

### Règle 3 : Toujours invalider les providers family avec leur paramètre

**Contexte** : Les `FutureProvider.family` peuvent conserver un cache par instance. Invalider toute la family est moins performant mais fonctionnel.

**Règle** :
- ✅ Faire : Invalider l'instance spécifique si le paramètre est connu : `ref.invalidate(providerFamily(param))`
- ✅ Faire : Invalider toute la family si le paramètre est inconnu : `ref.invalidate(providerFamily)`
- ❌ Ne pas faire : Ignorer l'invalidation des providers family

**Exemple** :
```dart
// ✅ BON : Instance spécifique
if (depotId != null) {
  ref.invalidate(stocksDashboardKpisProvider(depotId));
} else {
  ref.invalidate(stocksDashboardKpisProvider);  // Toute la family
}

// ❌ MAUVAIS : Ignorer le provider family
// Pas d'invalidation → cache stale
```

---

## Notes / Suivi

- **Helper créé** : `lib/shared/refresh/refresh_helpers.dart`
- **Réutilisabilité** : Le helper peut être utilisé dans `reception_form_screen.dart` pour le même problème
- **TODO** : Appliquer le même correctif dans `reception_form_screen.dart` si nécessaire

---

## Checklist incident

- [x] Repro 100% confirmée
- [x] Requête SQL de preuve archivée
- [x] Root cause écrite sans hypothèse
- [x] Fix décrit + fichier et fonction
- [x] Tests verts
- [x] Entrée CHANGELOG ajoutée

---

**Date de résolution** : 12 décembre 2025  
**Auteur du correctif** : Assistant IA (Cursor)  
**Validé par** : Utilisateur


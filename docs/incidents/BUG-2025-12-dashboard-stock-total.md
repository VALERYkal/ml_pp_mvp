# BUG-2025-12-dashboard-stock-total

**Date** : 12 décembre 2025  
**Module** : Dashboard / KPI Stocks  
**Sévérité** : Moyenne (affichage incorrect, données correctes en DB)  
**Statut** : ✅ Résolu

**Tags** :
- `BUG-DASHBOARD-STOCK-TOTAL-ORDERING`
- `KPI-DATE-NON-DETERMINISTIC`

---

## Contexte

Le dashboard affiche une carte "Stock total" qui doit montrer le stock cumulé actuel du dépôt (volume @15°C et ambiant). Cette carte est alimentée par la vue SQL `v_kpi_stock_global` via une chaîne de providers Riverpod.

**Chaîne technique** :
```
UI (role_dashboard.dart)
  → kpiProviderProvider
    → _safeLoadStocks()
      → stocksDashboardKpisProvider(depotId)
        → StocksKpiService.loadDashboardKpis()
          → StocksKpiRepository.fetchDepotProductTotals()
            → Vue SQL: v_kpi_stock_global
```

---

## Symptômes observés

**Problème** : La carte "Stock total" sur le dashboard affichait **0.0 L** alors qu'une réception validée existait dans la base de données.

**Données réelles en DB** :
- Réception validée le 2025-12-12 : 10 000 L ambiant, 9 915.5 L @15°C
- Vue SQL `v_kpi_stock_global` contenait bien une ligne avec :
  - `stock_ambiant_total = 10000`
  - `stock_15c_total = 9915.5`
  - `date_jour = '2025-12-12'`

**Comportement observé** :
- ✅ Module Réceptions : affichait correctement la réception
- ✅ Module Stocks journaliers : affichait correctement le stock
- ✅ Module Citernes : affichait correctement le stock
- ❌ Dashboard "Stock total" : affichait 0.0 L

---

## Reproduction minimale

1. Créer une réception validée (ex: 10 000 L ambiant, 9 915.5 L @15°C) pour le dépôt Daipn
2. Vérifier dans Supabase que `v_kpi_stock_global` contient bien la ligne :
   ```sql
   SELECT * 
   FROM public.v_kpi_stock_global 
   WHERE depot_id = '11111111-1111-1111-1111-111111111111'
     AND date_jour = '2025-12-12';
   ```
3. Ouvrir le dashboard admin
4. Observer la carte "Stock total" : elle affiche **0.0 L** au lieu de **9 915.5 L @15°C**

---

## Observations DB

**Requête SQL de validation** :
```sql
SELECT *
FROM public.v_kpi_stock_global
WHERE depot_id = '11111111-1111-1111-1111-111111111111'
  AND date_jour <= '2025-12-12'
ORDER BY date_jour DESC
LIMIT 1;
```

**Résultat** : La requête retourne bien une ligne avec `stock_15c_total = 9915.5`.

**Conclusion** : Les données sont correctes dans la base. Le problème est dans la logique de récupération côté Flutter.

---

## Chaîne technique exacte

### 1. UI Layer
**Fichier** : `lib/features/dashboard/widgets/role_dashboard.dart`

La carte "Stock total" consomme `kpiProviderProvider` qui retourne un `KpiSnapshot` contenant les stocks.

### 2. Provider Layer
**Fichier** : `lib/features/kpi/providers/kpi_provider.dart`

**Provider** : `kpiProviderProvider` (ligne 285)
- Appelle `_safeLoadStocks(ref: ref, depotId: depotId)` (ligne 310)
- `_safeLoadStocks()` appelle `stocksDashboardKpisProvider(depotId).future` (ligne 533)

### 3. Service Layer
**Fichier** : `lib/features/stocks/data/stocks_kpi_service.dart`

**Méthode** : `StocksKpiService.loadDashboardKpis()` (ligne 47)
- Appelle `_repo.fetchDepotProductTotals(depotId: depotId, produitId: produitId)` (ligne 52)
- **Note** : `dateJour` n'est **pas** passé (valeur `null`)

### 4. Repository Layer
**Fichier** : `lib/data/repositories/stocks_kpi_repository.dart`

**Méthode** : `StocksKpiRepository.fetchDepotProductTotals()` (ligne 224)

**Code AVANT correction** :
```dart
Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
  String? depotId,
  String? produitId,
  DateTime? dateJour,
}) async {
  final query = _client
      .from('v_kpi_stock_global')
      .select<List<Map<String, dynamic>>>();

  if (depotId != null) {
    query.eq('depot_id', depotId);
  }
  if (produitId != null) {
    query.eq('produit_id', produitId);
  }
  if (dateJour != null) {
    query.eq('date_jour', _formatYmd(dateJour));  // ❌ Égalité stricte
  }
  // ❌ Pas d'ORDER BY → ordre non déterminé

  final rows = await query;
  final list = rows as List<Map<String, dynamic>>;
  return list.map(DepotGlobalStockKpi.fromMap).toList();
}
```

**Problème** :
- Quand `dateJour == null` (cas dashboard), aucune ligne n'est filtrée par date
- **Pas d'`ORDER BY`** → Supabase peut retourner les lignes dans n'importe quel ordre
- L'UI consomme `globalList.first` ou `globalList[0]` → peut être une ligne ancienne ou arbitraire
- Si la première ligne est une date ancienne avec stock = 0, le dashboard affiche 0.0 L

### 5. Vue SQL
**Vue** : `v_kpi_stock_global`

La vue contient bien les données correctes, mais sans ordre déterminé dans la requête, le repository peut retourner n'importe quelle ligne en premier.

---

## Cause racine

**Cause principale** : `fetchDepotProductTotals()` ne force pas un ordre déterminé ni la sélection de la date la plus récente lorsque `dateJour` est `null` (cas d'usage du dashboard).

**Problèmes identifiés** :
1. **Pas d'`ORDER BY`** : La requête Supabase retourne les lignes dans un ordre non garanti
2. **Filtre date trop strict** : `eq('date_jour', ...)` nécessite une égalité exacte, alors qu'on veut la dernière ligne ≤ date
3. **Consommation non déterministe** : L'UI consomme `globalList.first` qui peut être n'importe quelle ligne

**Impact** : Le dashboard affiche une valeur arbitraire (souvent 0.0 L si une ligne ancienne est retournée en premier) au lieu du stock le plus récent.

---

## Correctif appliqué

**Fichier modifié** : `lib/data/repositories/stocks_kpi_repository.dart`  
**Fonction** : `fetchDepotProductTotals()` (lignes 224-250)

**Code APRÈS correction** :
```dart
Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
  String? depotId,
  String? produitId,
  DateTime? dateJour,
}) async {
  final query = _client
      .from('v_kpi_stock_global')
      .select<List<Map<String, dynamic>>>();

  if (depotId != null) {
    query.eq('depot_id', depotId);
  }
  if (produitId != null) {
    query.eq('produit_id', produitId);
  }
  // ✅ If a date is provided, pick the latest row <= that date.
  if (dateJour != null) {
    query.lte('date_jour', _formatYmd(dateJour));  // ✅ <= au lieu de ==
  }

  // ✅ Deterministic: latest date first (dashboard consumes newest snapshot)
  query.order('date_jour', ascending: false);  // ✅ Ordre déterminé

  final rows = await query;
  final list = rows as List<Map<String, dynamic>>;
  return list.map(DepotGlobalStockKpi.fromMap).toList();
}
```

**Changements appliqués** :
1. **Filtre date** : `eq('date_jour', ...)` → `lte('date_jour', ...)`
   - Permet de récupérer la dernière ligne disponible ≤ à la date demandée
   - Si `dateJour == null`, pas de filtre date (comportement inchangé)
2. **Ordre déterminé** : Ajout de `query.order('date_jour', ascending: false)`
   - Garantit que la première ligne est toujours la plus récente
   - Comportement déterministe : le dashboard consomme toujours le snapshot le plus récent

**Résultat** :
- Si `dateJour != null` : retourne les lignes avec `date_jour <= dateJour`, triées par date décroissante (première = la plus récente)
- Si `dateJour == null` : retourne toutes les lignes, triées par date décroissante (première = la plus récente)

---

## Validation

### Tests unitaires
**Fichier** : `test/features/stocks/stocks_kpi_repository_test.dart`

**Résultat** : ✅ **25/25 tests passent** (aucune régression)

Les tests existants continuent de passer car :
- Le comportement avec `dateJour` fourni est amélioré mais non-cassant (`lte` au lieu de `eq`)
- Le comportement avec `dateJour == null` est maintenant déterministe (ordre garanti)

### Validation manuelle
**Scénario** : Après création d'une réception validée (10 000 L ambiant, 9 915.5 L @15°C)

**Résultat attendu** : Dashboard "Stock total" affiche **9 915.5 L @15°C** au lieu de **0.0 L**

**Statut** : ✅ Confirmé par l'utilisateur ("tous va bien maintenant")

---

## Prévention / Règles à appliquer à l'avenir

### Règle 1 : Toujours ORDER BY pour les requêtes de type "latest"
**Contexte** : Toute requête qui doit retourner "la dernière valeur" ou "la plus récente"

**Règle** :
- ✅ Toujours ajouter `query.order('date_jour', ascending: false)` (ou équivalent)
- ✅ Ne jamais supposer que Supabase retourne les lignes dans un ordre particulier
- ✅ Documenter dans le code que l'ordre est intentionnel

**Exemple** :
```dart
// ✅ BON
query.order('date_jour', ascending: false);
final rows = await query;
final latest = rows.first; // Déterministe

// ❌ MAUVAIS
final rows = await query;
final latest = rows.first; // Non-déterministe !
```

### Règle 2 : Utiliser `lte` au lieu de `eq` pour les filtres date "latest"
**Contexte** : Quand on veut "la dernière ligne disponible ≤ à une date"

**Règle** :
- ✅ Utiliser `lte('date_jour', date)` pour récupérer toutes les lignes ≤ date
- ✅ Combiner avec `ORDER BY date_jour DESC` pour prendre la première (la plus récente)
- ❌ Éviter `eq('date_jour', date)` qui nécessite une égalité exacte

**Exemple** :
```dart
// ✅ BON : Récupère la dernière ligne ≤ dateJour
if (dateJour != null) {
  query.lte('date_jour', _formatYmd(dateJour));
}
query.order('date_jour', ascending: false);

// ❌ MAUVAIS : Nécessite une égalité exacte
if (dateJour != null) {
  query.eq('date_jour', _formatYmd(dateJour));
}
```

### Règle 3 : Documenter le comportement attendu dans les commentaires
**Contexte** : Les méthodes qui retournent "la dernière valeur" doivent être claires

**Règle** :
- ✅ Ajouter un commentaire expliquant que la méthode retourne la ligne la plus récente
- ✅ Documenter le comportement quand `dateJour == null` (toutes les lignes, la plus récente en premier)

**Exemple** :
```dart
/// Retourne les totaux globaux par dépôt & produit.
///
/// Si [dateJour] est fourni, on filtre sur cette date (<= dateJour pour prendre la dernière disponible).
/// Les résultats sont toujours triés par date décroissante (la plus récente en premier).
```

---

## Notes complémentaires

- **Aucun impact sur les autres modules** : Seul le dashboard KPI est affecté par cette correction
- **Compatibilité préservée** : Les callers qui passent `dateJour` bénéficient d'un comportement amélioré mais non-cassant
- **Performance** : L'ajout de `ORDER BY` a un impact négligeable (index sur `date_jour` présent dans la vue)

---

**Date de résolution** : 12 décembre 2025  
**Auteur du correctif** : Assistant IA (Cursor)  
**Validé par** : Utilisateur (confirmation "tous va bien maintenant")


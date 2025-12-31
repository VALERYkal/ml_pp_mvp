# Contrat SQL - Vues Stocks (Interface stable pour Flutter)

**Date** : 31/12/2025  
**Version** : 3.0  
**Objectif** : Définir l'interface SQL stable que Flutter consommera pour les stocks

**⚠️ IMPORTANT** : Voir `docs/db/CONTRAT_STOCK_ACTUEL.md` pour la source de vérité officielle.

---

## But

**La source de vérité unique pour le stock actuel est `v_stock_actuel`.**

Cette vue expose le stock actuel corrigé (ambiant et 15°C) par dépôt, citerne, produit et propriétaire, en tenant compte des mouvements validés et des corrections officielles.

---

## Vue canonique (Source de vérité)

**Nom** : `public.v_stock_actuel`

**⚠️ DEPRECATED** : `v_stocks_citerne_global_daily` n'est plus la source de vérité. Voir `docs/db/CONTRAT_STOCK_ACTUEL.md`.

**Rôle** : **SOURCE DE VÉRITÉ UNIQUE** pour le stock actuel. Expose le stock actuel corrigé par dépôt, citerne, produit et propriétaire.

**Statut** : **Canonical view consumed by Flutter**. This is the single source of truth for all Flutter modules (Dashboard, Stocks, Citernes). 

**⚠️ DEPRECATED** : `v_stocks_citerne_global_daily` et `v_stock_actuel_snapshot` ne sont plus les sources de vérité. Voir `docs/db/CONTRAT_STOCK_ACTUEL.md`.

**Colonnes garanties (MUST expose)** :
- `citerne_id` (UUID) — **MANDATORY**
- `citerne_nom` (TEXT) — **MANDATORY**
- `produit_id` (UUID) — **MANDATORY**
- `produit_nom` (TEXT) — **MANDATORY**
- `depot_id` (UUID) — **MANDATORY**
- `depot_nom` (TEXT) — **MANDATORY**
- `date_jour` (DATE) — **CRITICAL** : Type DATE (not timestamp), represents the daily snapshot. MUST remain filterable.
- `stock_ambiant_total` (NUMERIC) — **MANDATORY**
- `stock_15c_total` (NUMERIC) — **MANDATORY**
- `capacite_totale` (NUMERIC) — **MANDATORY**

**Contract requirements** :
- `date_jour` MUST remain type DATE (not timestamp) and MUST be filterable.
- Legacy `v_stocks_citerne_global` is DB-only and not used by the app.

**Canonical invariant** :
- **`global_daily = SUM(owner rows)`** : For the same `(citerne_id, produit_id, date_jour)`, the values in `v_stocks_citerne_global_daily` MUST equal the sum of all rows in `stocks_journaliers` for that combination (all owners aggregated).

**Schéma validé** : Migration Supabase `supabase/migrations/20251223_1200_stocks_views_daily.sql`

---

## Filtres supportés

- `depot_id` : Filtrer par dépôt
- `citerne_id` : Filtrer par citerne
- `produit_id` : Filtrer par produit
- `date_jour` : **Règle officielle** = prendre la dernière date disponible ≤ dateJour (pattern `lte` + `order desc` + filter latest date)

**Pattern de filtrage date recommandé** :
```sql
WHERE date_jour <= '2025-12-09'
ORDER BY date_jour DESC
-- Puis appliquer un filtre pour ne garder que la première date (la plus récente)
```

---

## Vue legacy

**Nom** : `public.v_stocks_citerne_global`

**Statut** : Legacy DB only, conservée pour rétrocompatibilité, non utilisée par Flutter.

**Interdiction** : Toute nouvelle feature Flutter ne doit pas l'utiliser.

---

## Exemples SQL (copiables)

### Dernier snapshot pour un dépôt

```sql
SELECT *
FROM public.v_stocks_citerne_global_daily
WHERE depot_id = '[ID_DEPOT]'
ORDER BY date_jour DESC
LIMIT 1;
```

### Snapshot à une date (≤ dateJour)

```sql
SELECT *
FROM public.v_stocks_citerne_global_daily
WHERE depot_id = '[ID_DEPOT]'
  AND date_jour <= '2025-12-09'
ORDER BY date_jour DESC
LIMIT 1;
```

### Contrôle: somme par dépôt

```sql
SELECT 
  depot_id,
  depot_nom,
  SUM(stock_ambiant_total) AS stock_ambiant_total_depot,
  SUM(stock_15c_total) AS stock_15c_total_depot
FROM public.v_stocks_citerne_global_daily
WHERE date_jour <= '2025-12-09'
GROUP BY depot_id, depot_nom
ORDER BY depot_nom;
```

---

## Exemples Dart

### Utilisation canonique

```dart
final repo = StocksKpiRepository(supabaseClient);

// Récupérer le snapshot pour un dépôt à une date donnée
final snapshots = await repo.fetchCiterneGlobalSnapshots(
  depotId: 'depot-id',
  dateJour: DateTime(2025, 12, 9),
);

// Le repository applique automatiquement :
// - lte('date_jour', dateJour)
// - order('date_jour', ascending: false)
// - _filterToLatestDate pour ne garder qu'une seule date
```

---

## Références

- Repository canonique : `lib/data/repositories/stocks_kpi_repository.dart`
- Provider principal : `lib/features/stocks/data/stocks_kpi_providers.dart` → `depotStocksSnapshotProvider`
- Documentation technique : `docs/db/PHASE3_FLUTTER_RECONNEXION_STOCKS.md`

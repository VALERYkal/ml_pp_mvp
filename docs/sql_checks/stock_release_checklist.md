# Checklist Release Stock (5 requêtes)

**Projet** : ML_PP MVP  
**Module** : Stocks / Citernes / Dashboard  
**Date** : 13 décembre 2025  
**Statut** : ✅ Checklist de validation en production

---

## 🎯 Objectif

Cette checklist contient 5 requêtes SQL de validation à exécuter **obligatoirement** avant toute release concernant les stocks. Ces tests vérifient l'intégrité des données et la cohérence entre les différentes vues SQL.

**✅ Règle d'or d'exploitation** :
> **Si une seule requête retourne des lignes : STOP release.**  
> Tu corriges, puis tu relances les 5 tests jusqu'à 0 lignes partout.

---

## 0️⃣ (Optionnel) Contexte : sur quelle date tu es

**Objectif** : Vérifier la date la plus récente dans `stocks_journaliers` pour comprendre le contexte des données.

```sql
SELECT max(date_jour) AS max_date_jour
FROM public.stocks_journaliers;
```

**Résultat attendu** : Une ligne avec la date la plus récente (ex: `2025-12-13`)

**Utilisation** : Information contextuelle pour comprendre l'état des données avant de lancer les tests.

---

## 1️⃣ TEST A — v_stocks_citerne_global_daily = somme des "courants owner"

**Objectif** : Vérifier que la vue `v_stocks_citerne_global_daily` (vue canonique Flutter) agrège correctement les stocks de tous les propriétaires (MONALUXE + PARTENAIRE) pour chaque citerne.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Calcule le stock courant de chaque propriétaire (dernière date par propriétaire)
- Somme les stocks de tous les propriétaires par citerne/produit
- Compare avec `v_stocks_citerne_global_daily`
- Si des différences existent, elles sont retournées

> **Note** : `v_stocks_citerne_global` est legacy conservée en DB, l'app n'y touche plus. Ce test vérifie la vue canonique `v_stocks_citerne_global_daily`.

```sql
WITH owner_current AS (
  SELECT
    sj.citerne_id,
    sj.produit_id,
    sj.proprietaire_type,
    sj.date_jour,
    sj.stock_ambiant,
    sj.stock_15c,
    row_number() OVER (
      PARTITION BY sj.citerne_id, sj.produit_id, sj.proprietaire_type
      ORDER BY sj.date_jour DESC
    ) AS rn
  FROM public.stocks_journaliers sj
),
owner_last AS (
  SELECT * FROM owner_current WHERE rn = 1
),
owner_sum AS (
  SELECT
    citerne_id,
    produit_id,
    SUM(stock_ambiant) AS amb_sum,
    SUM(stock_15c)     AS v15_sum
  FROM owner_last
  GROUP BY 1,2
)
SELECT
  g.citerne_id,
  g.produit_id,
  g.stock_ambiant_total,
  os.amb_sum,
  g.stock_15c_total,
  os.v15_sum
FROM public.v_stocks_citerne_global_daily g
JOIN owner_sum os
  ON os.citerne_id = g.citerne_id
 AND os.produit_id = g.produit_id
WHERE
  (g.stock_ambiant_total IS DISTINCT FROM os.amb_sum)
  OR
  (g.stock_15c_total     IS DISTINCT FROM os.v15_sum);
```

**Si des lignes sont retournées** :
- ❌ La vue `v_stocks_citerne_global_daily` n'agrège pas correctement les stocks multi-propriétaires
- ❌ Vérifier la logique de la vue (dernière date par propriétaire vs dernière date globale)
- ❌ Voir : `docs/incidents/BUG-2025-12-stocks-multi-proprietaire-incoherence.md`

---

## 2️⃣ TEST B — Aucun doublon impossible dans stocks_journaliers

**Objectif** : Vérifier l'intégrité structurelle de la table `stocks_journaliers`. La contrainte UNIQUE `(citerne_id, produit_id, date_jour, proprietaire_type)` doit être respectée.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- La clé métier est `(citerne_id, produit_id, date_jour, proprietaire_type)`
- Il ne doit pas y avoir de doublons pour cette combinaison
- Si des doublons existent, c'est une violation de l'intégrité des données

```sql
SELECT
  citerne_id,
  produit_id,
  date_jour,
  proprietaire_type,
  COUNT(*) AS nb
FROM public.stocks_journaliers
GROUP BY 1,2,3,4
HAVING COUNT(*) > 1;
```

**Si des lignes sont retournées** :
- ❌ Violation de la contrainte UNIQUE
- ❌ Vérifier les triggers et les fonctions d'insertion
- ❌ Possible problème dans `stock_upsert_journalier()`

---

## 3️⃣ TEST C — KPI dépôt = somme des citernes (même vérité)

**Objectif** : Vérifier la cohérence entre la vue KPI au niveau dépôt (`v_kpi_stock_depot`) et la somme des citernes (`v_stocks_citerne_global_daily`, vue canonique Flutter).

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Le stock total d'un dépôt doit être égal à la somme des stocks de toutes ses citernes
- Les deux vues doivent refléter la même réalité
- Si des différences existent, il y a une incohérence dans les agrégations

```sql
WITH sum_citernes AS (
  SELECT
    depot_id,
    produit_id,
    SUM(stock_ambiant_total) AS amb_total,
    SUM(stock_15c_total)     AS v15_total
  FROM public.v_stocks_citerne_global_daily
  GROUP BY 1,2
),
depot_kpi AS (
  SELECT
    depot_id,
    produit_id,
    stock_ambiant_total AS amb_kpi,
    stock_15c_total     AS v15_kpi
  FROM public.v_kpi_stock_depot
)
SELECT
  k.depot_id,
  k.produit_id,
  k.amb_kpi, s.amb_total,
  k.v15_kpi, s.v15_total
FROM depot_kpi k
JOIN sum_citernes s
  ON s.depot_id = k.depot_id
 AND s.produit_id = k.produit_id
WHERE
  (k.amb_kpi IS DISTINCT FROM s.amb_total)
  OR
  (k.v15_kpi IS DISTINCT FROM s.v15_total);
```

**Si des lignes sont retournées** :
- ❌ Incohérence entre les vues KPI et les vues de détail
- ❌ Vérifier les agrégations dans `v_kpi_stock_depot`
- ❌ Vérifier que les deux vues utilisent la même logique de dernière date par propriétaire

---

## 4️⃣ TEST D — Dashboard legacy (v_citerne_stock_actuel) aligné avec la vue canonique

**Objectif** : Vérifier que la vue legacy `v_citerne_stock_actuel` (si encore utilisée) est alignée avec la vue canonique `v_stocks_citerne_global_daily`.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Si `v_citerne_stock_actuel` est encore utilisée, elle doit refléter les mêmes données que `v_stocks_citerne_global_daily` (vue canonique Flutter)
- Évite les incohérences entre différents modules utilisant des vues différentes
- Si des différences existent, il faut migrer vers la vue canonique

> **Note** : `v_stocks_citerne_global` est legacy conservée en DB, l'app n'y touche plus. La vue canonique est `v_stocks_citerne_global_daily`.

```sql
SELECT *
FROM (
  SELECT citerne_id, produit_id,
         SUM(stock_ambiant) amb1, SUM(stock_15c) v151
  FROM public.v_citerne_stock_actuel
  GROUP BY 1,2
) a
JOIN (
  SELECT citerne_id, produit_id,
         stock_ambiant_total amb2, stock_15c_total v152
  FROM public.v_stocks_citerne_global_daily
) b USING (citerne_id, produit_id)
WHERE a.amb1 IS DISTINCT FROM b.amb2
   OR a.v151 IS DISTINCT FROM b.v152;
```

**Si des lignes sont retournées** :
- ❌ Les deux vues ne reflètent pas la même réalité
- ❌ Vérifier la logique de `v_citerne_stock_actuel`
- ❌ Migrer les modules utilisant `v_citerne_stock_actuel` vers `v_stocks_citerne_global_daily`

---

## 5️⃣ TEST E — Aucun stock négatif (invariant métier)

**Objectif** : Vérifier l'invariant métier fondamental : un stock ne peut jamais être négatif.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Un stock physique ne peut pas être négatif
- Si des stocks négatifs existent, c'est une violation de l'invariant métier
- Possible problème dans les calculs de cumul ou dans les triggers de validation

```sql
SELECT *
FROM public.stocks_journaliers
WHERE stock_ambiant < 0
   OR stock_15c < 0;
```

**Si des lignes sont retournées** :
- ❌ Violation de l'invariant métier
- ❌ Vérifier les triggers de validation (ex: `sorties_before_validate_trg`)
- ❌ Vérifier la fonction `stock_upsert_journalier()`
- ❌ Vérifier les calculs de cumul dans `rebuild_stocks_journaliers()`

---

## 📋 Procédure de validation

### Étape 1 : Exécuter toutes les requêtes

Exécuter les 5 requêtes SQL dans l'ordre (0 à 5) et noter les résultats.

### Étape 2 : Vérifier les résultats

**✅ Tous les tests doivent retourner 0 lignes**

Si un test retourne des lignes :
1. ❌ **STOP release**
2. 🔍 Analyser les lignes retournées pour identifier la cause
3. 🔧 Corriger le problème (vue SQL, trigger, fonction, données)
4. 🔄 Relancer tous les tests
5. ✅ Répéter jusqu'à ce que tous les tests retournent 0 lignes

### Étape 3 : Documenter la validation

Une fois tous les tests verts :
- ✅ Noter la date de validation
- ✅ Noter la version/migration validée
- ✅ Conserver les résultats (0 lignes pour chaque test)

---

## 🔗 Références

- **Règle métier officielle** : `docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md`
- **Audit DB** : `docs/db/AUDIT_STOCKS_AMBIANT_15C_VERROUILLAGE.md`
- **Bug multi-propriétaire** : `docs/incidents/BUG-2025-12-stocks-multi-proprietaire-incoherence.md`
- **Vues SQL** : `v_stocks_citerne_global_daily` (canonique Flutter), `v_kpi_stock_depot`, `v_citerne_stock_actuel`, `v_stocks_citerne_global` (legacy conservée en DB, l'app n'y touche plus)
- **Table stocks_journaliers** : Schéma Supabase

---

## 📝 Historique des validations

| Date | Version/Migration | Validé par | Résultats |
|------|------------------|------------|-----------|
| 2025-12-13 | Initial | Équipe ML_PP MVP | ✅ Tous les tests verts |
| 2025-12-23 | Migration `20251223_1200_stocks_views_daily.sql` | Équipe ML_PP MVP | ✅ Vue canonique créée, contract checks ajoutés |

---

## ✅ PHASE 5 — Validation après déploiement migration (2025-12-23)

### Objectif
Vérifier que la migration de `v_stocks_citerne_global_daily` a été correctement déployée et que la vue fonctionne comme attendu.

**✅ À exécuter après chaque déploiement de la migration `20251223_1200_stocks_views_daily.sql`**

---

## 5.1️⃣ TEST F — Vérification du schéma de la vue canonique

**Objectif** : Vérifier que la vue `v_stocks_citerne_global_daily` expose les colonnes attendues avec les bons types.

**✅ Résultat attendu** : 10 colonnes avec les types corrects

**Explication** :
- La vue doit exposer exactement les colonnes documentées dans `docs/db/stocks_views_contract.md`
- Les types doivent être cohérents avec les attentes Flutter (DATE pour `date_jour`, NUMERIC pour stocks, TEXT pour noms)

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'v_stocks_citerne_global_daily'
ORDER BY ordinal_position;
```

**Résultats attendus** :
- `citerne_id` : `uuid` (ou type utilisé pour les IDs)
- `citerne_nom` : `text`
- `produit_id` : `uuid` (ou type utilisé pour les IDs)
- `produit_nom` : `text`
- `depot_id` : `uuid` (ou type utilisé pour les IDs)
- `depot_nom` : `text`
- `date_jour` : `date` (CRITICAL: doit être DATE, pas timestamp)
- `stock_ambiant_total` : `numeric` (ou `double precision`)
- `stock_15c_total` : `numeric` (ou `double precision`)
- `capacite_totale` : `numeric` (ou `double precision`)

**Si des colonnes manquent ou ont le mauvais type** :
- ❌ La migration n'a pas été correctement appliquée
- ❌ Vérifier le fichier de migration `20251223_1200_stocks_views_daily.sql`
- ❌ Relancer la migration si nécessaire

---

## 5.2️⃣ TEST G — Aucun doublon dans la vue canonique

**Objectif** : Vérifier l'intégrité structurelle de `v_stocks_citerne_global_daily`. La clé métier est `(citerne_id, produit_id, date_jour)`.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Pour chaque combinaison `(citerne_id, produit_id, date_jour)`, il ne doit y avoir qu'une seule ligne
- Si des doublons existent, c'est une violation de l'intégrité des données ou un problème dans la logique de la vue

```sql
SELECT citerne_id, produit_id, date_jour, COUNT(*) AS nb
FROM public.v_stocks_citerne_global_daily
GROUP BY citerne_id, produit_id, date_jour
HAVING COUNT(*) > 1;
```

**Si des lignes sont retournées** :
- ❌ Violation de l'intégrité (doublons dans `stocks_journaliers` ou problème dans la logique de GROUP BY)
- ❌ Vérifier que `stocks_journaliers` respecte la contrainte UNIQUE `(citerne_id, produit_id, date_jour, proprietaire_type)`
- ❌ Vérifier la logique de GROUP BY dans la vue (CTE `stocks_agreges`)

---

## 5.3️⃣ TEST H — Échantillon de données (smoke test)

**Objectif** : Vérifier que la vue retourne des données cohérentes et que les valeurs sont plausibles.

**✅ Résultat attendu** : Des lignes avec des données cohérentes (stocks ≥ 0, dates cohérentes, noms non vides)

**Explication** :
- La vue doit retourner des données pour les citernes existantes
- Les stocks doivent être ≥ 0 (invariant métier)
- Les dates doivent être cohérentes (pas de dates futures, dates dans une plage raisonnable)

```sql
SELECT *
FROM public.v_stocks_citerne_global_daily
ORDER BY date_jour DESC, citerne_id, produit_id
LIMIT 20;
```

**Vérifications manuelles à faire** :
- ✅ Les dates sont dans le passé ou aujourd'hui (pas de dates futures)
- ✅ Les stocks sont ≥ 0
- ✅ Les noms de citernes/produits/dépôts sont non vides (sauf si NULL est acceptable)
- ✅ Les `capacite_totale` sont cohérentes (≥ 0)
- ✅ Les `depot_id` correspondent aux dépôts existants

**Si des problèmes sont détectés** :
- ❌ Vérifier les données source dans `stocks_journaliers`
- ❌ Vérifier les jointures dans la vue (LEFT JOIN avec `citernes`, `produits`, `depots`)
- ❌ Vérifier que les agrégations (MONALUXE + PARTENAIRE) sont correctes

---

## 📋 Procédure de validation Phase 5

### Étape 1 : Exécuter les 3 requêtes de smoke-check

Exécuter les requêtes dans l'ordre (5.1, 5.2, 5.3) et noter les résultats.

### Étape 2 : Vérifier les résultats

**✅ Tous les tests doivent être verts** :
- TEST F : 10 colonnes avec types corrects
- TEST G : 0 lignes (pas de doublons)
- TEST H : Données cohérentes (vérification manuelle)

Si un test échoue :
1. ❌ **STOP deployment**
2. 🔍 Analyser le problème
3. 🔧 Corriger (migration SQL ou données source)
4. 🔄 Relancer tous les tests
5. ✅ Répéter jusqu'à ce que tous les tests soient verts

### Étape 3 : Documenter la validation

Une fois tous les tests verts :
- ✅ Noter la date de validation
- ✅ Noter la version/migration validée (`20251223_1200_stocks_views_daily.sql`)
- ✅ Conserver les résultats

---

## 🔍 VIEW CONTRACT — daily global

### Objectif
Vérifier que la vue canonique `v_stocks_citerne_global_daily` respecte le contrat d'interface Flutter.

**✅ À exécuter après chaque modification de la vue ou migration**

---

## 6.1️⃣ TEST I — View exists

**Objectif** : Vérifier que la vue `v_stocks_citerne_global_daily` existe dans le schéma public.

**✅ Résultat attendu** : `exists` = `true` (1 ligne)

```sql
SELECT to_regclass('public.v_stocks_citerne_global_daily') IS NOT NULL AS exists;
```

**Si `exists` = `false`** :
- ❌ La vue n'existe pas dans la base de données
- ❌ Exécuter la migration `20251223_1200_stocks_views_daily.sql`
- ❌ Vérifier que la migration a été appliquée correctement

---

## 6.2️⃣ TEST J — Columns contract

**Objectif** : Vérifier que la vue expose toutes les colonnes requises par le contrat Flutter avec les bons types.

**✅ Résultat attendu** : 10 colonnes avec types corrects

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema='public' AND table_name='v_stocks_citerne_global_daily'
ORDER BY ordinal_position;
```

**Résultats attendus (exact order)** :
1. `citerne_id` — type doit être UUID (ou équivalent)
2. `citerne_nom` — type doit être TEXT (ou character varying)
3. `produit_id` — type doit être UUID (ou équivalent)
4. `produit_nom` — type doit être TEXT (ou character varying)
5. `depot_id` — type doit être UUID (ou équivalent)
6. `depot_nom` — type doit être TEXT (ou character varying)
7. `date_jour` — **CRITICAL** : type DOIT être `date` (pas timestamp, pas timestamp with time zone)
8. `stock_ambiant_total` — type doit être numeric ou double precision
9. `stock_15c_total` — type doit être numeric ou double precision
10. `capacite_totale` — type doit être numeric ou double precision

**Si des colonnes manquent ou ont le mauvais type** :
- ❌ Le contrat n'est pas respecté
- ❌ Flutter peut échouer à lire la vue
- ❌ Vérifier la migration `20251223_1200_stocks_views_daily.sql` et corriger si nécessaire

---

## 6.3️⃣ TEST K — Filtering sanity (returns only <= date)

**Objectif** : Vérifier que le filtrage par `date_jour` fonctionne correctement et que la vue retourne des données cohérentes.

**✅ Résultat attendu** : Des lignes avec `date_jour <= CURRENT_DATE`, ordonnées par date décroissante

**Note** : Ajuster le `depot_id` si nécessaire pour votre environnement de test.

```sql
-- Pick a depot_id that exists in fixtures or run without filter
SELECT *
FROM public.v_stocks_citerne_global_daily
WHERE date_jour <= CURRENT_DATE
ORDER BY date_jour DESC
LIMIT 20;
```

**Vérifications manuelles** :
- ✅ Toutes les dates retournées sont ≤ CURRENT_DATE (pas de dates futures)
- ✅ Les stocks sont ≥ 0 (invariant métier)
- ✅ Les noms (citerne_nom, produit_nom, depot_nom) sont non vides
- ✅ Les `capacite_totale` sont cohérentes (≥ 0)
- ✅ Les `depot_id` correspondent aux dépôts existants
- ✅ Les données sont ordonnées correctement (date_jour DESC)

**Si des problèmes sont détectés** :
- ❌ Vérifier les données source dans `stocks_journaliers`
- ❌ Vérifier les jointures dans la vue (JOIN avec `citernes`, `produits`, `depots`)
- ❌ Vérifier que le GROUP BY et les agrégations sont corrects

---

## 6.4️⃣ TEST L — global_daily equals sum of owners

**Objectif** : Vérifier l'invariant canonique : `v_stocks_citerne_global_daily` doit être égal à la somme des lignes `stocks_journaliers` groupées par `(citerne_id, produit_id, date_jour)`.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- La vue `v_stocks_citerne_global_daily` agrège tous les propriétaires (MONALUXE + PARTENAIRE) pour chaque combinaison `(citerne_id, produit_id, date_jour)`
- Cette somme doit être exactement égale à la somme directe des `stock_ambiant` et `stock_15c` de `stocks_journaliers` pour la même combinaison
- Si des différences existent, c'est une violation de l'invariant canonique

```sql
WITH daily_view AS (
  SELECT
    citerne_id,
    produit_id,
    date_jour,
    stock_ambiant_total AS view_ambiant,
    stock_15c_total AS view_15c
  FROM public.v_stocks_citerne_global_daily
),
journaliers_sum AS (
  SELECT
    citerne_id,
    produit_id,
    date_jour,
    SUM(stock_ambiant) AS sum_ambiant,
    SUM(stock_15c) AS sum_15c
  FROM public.stocks_journaliers
  GROUP BY citerne_id, produit_id, date_jour
)
SELECT
  v.citerne_id,
  v.produit_id,
  v.date_jour,
  v.view_ambiant,
  j.sum_ambiant,
  v.view_15c,
  j.sum_15c
FROM daily_view v
JOIN journaliers_sum j
  ON j.citerne_id = v.citerne_id
  AND j.produit_id = v.produit_id
  AND j.date_jour = v.date_jour
WHERE
  (v.view_ambiant IS DISTINCT FROM j.sum_ambiant)
  OR
  (v.view_15c IS DISTINCT FROM j.sum_15c);
```

**Si des lignes sont retournées** :
- ❌ Violation de l'invariant canonique : `global_daily ≠ SUM(owner rows)`
- ❌ La vue `v_stocks_citerne_global_daily` ne correspond pas à la somme des `stocks_journaliers`
- ❌ Vérifier la logique de GROUP BY et d'agrégation dans la vue
- ❌ Vérifier que la vue agrège correctement tous les propriétaires (MONALUXE + PARTENAIRE)
- ❌ Vérifier la migration `20251223_1200_stocks_views_daily.sql`

---

**Checklist officielle de validation – À exécuter avant toute release concernant les stocks**







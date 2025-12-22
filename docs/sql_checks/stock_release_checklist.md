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

## 1️⃣ TEST A — v_stocks_citerne_global = somme des "courants owner"

**Objectif** : Vérifier que la vue `v_stocks_citerne_global` agrège correctement les stocks de tous les propriétaires (MONALUXE + PARTENAIRE) pour chaque citerne.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Calcule le stock courant de chaque propriétaire (dernière date par propriétaire)
- Somme les stocks de tous les propriétaires par citerne/produit
- Compare avec `v_stocks_citerne_global`
- Si des différences existent, elles sont retournées

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
FROM public.v_stocks_citerne_global g
JOIN owner_sum os
  ON os.citerne_id = g.citerne_id
 AND os.produit_id = g.produit_id
WHERE
  (g.stock_ambiant_total IS DISTINCT FROM os.amb_sum)
  OR
  (g.stock_15c_total     IS DISTINCT FROM os.v15_sum);
```

**Si des lignes sont retournées** :
- ❌ La vue `v_stocks_citerne_global` n'agrège pas correctement les stocks multi-propriétaires
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

**Objectif** : Vérifier la cohérence entre la vue KPI au niveau dépôt (`v_kpi_stock_depot`) et la somme des citernes (`v_stocks_citerne_global`).

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
  FROM public.v_stocks_citerne_global
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

**Objectif** : Vérifier que la vue legacy `v_citerne_stock_actuel` (si encore utilisée) est alignée avec la vue canonique `v_stocks_citerne_global`.

**✅ Résultat attendu** : **0 lignes**

**Explication** :
- Si `v_citerne_stock_actuel` est encore utilisée, elle doit refléter les mêmes données que `v_stocks_citerne_global`
- Évite les incohérences entre différents modules utilisant des vues différentes
- Si des différences existent, il faut migrer vers la vue canonique

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
  FROM public.v_stocks_citerne_global
) b USING (citerne_id, produit_id)
WHERE a.amb1 IS DISTINCT FROM b.amb2
   OR a.v151 IS DISTINCT FROM b.v152;
```

**Si des lignes sont retournées** :
- ❌ Les deux vues ne reflètent pas la même réalité
- ❌ Vérifier la logique de `v_citerne_stock_actuel`
- ❌ Migrer les modules utilisant `v_citerne_stock_actuel` vers `v_stocks_citerne_global`

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
- **Vues SQL** : `v_stocks_citerne_global`, `v_kpi_stock_depot`, `v_citerne_stock_actuel`
- **Table stocks_journaliers** : Schéma Supabase

---

## 📝 Historique des validations

| Date | Version/Migration | Validé par | Résultats |
|------|------------------|------------|-----------|
| 2025-12-13 | Initial | Équipe ML_PP MVP | ✅ Tous les tests verts |

---

**Checklist officielle de validation – À exécuter avant toute release concernant les stocks**







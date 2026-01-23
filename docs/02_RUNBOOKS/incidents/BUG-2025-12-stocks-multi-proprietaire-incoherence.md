# BUG-2025-12-stocks-multi-proprietaire-incoherence

**Date** : 13 décembre 2025  
**Module** : Stocks / Citernes / Dashboard  
**Sévérité** : 🔴 **CRITIQUE** (impact direct sur la réalité physique du stock)  
**Statut** : ✅ Résolu

**Tags** :
- `BUG-STOCKS-MULTI-PROPRIETAIRE`
- `SQL-VIEW-LOGIC-ERROR`
- `CRITICAL-BUSINESS-LOGIC`

---

## Contexte métier

ML_PP MVP gère des stocks pétroliers multi-propriétaires (MONALUXE / PARTENAIRE) dans des citernes physiques communes.

### Règles fondamentales

1. **Le stock ambiant est la source de vérité opérationnelle**
2. **Le stock à 15°C est indicatif / analytique**
3. **Le stock physique réel = somme des stocks de tous les propriétaires**
4. **Un propriétaire peut ne pas avoir de mouvement le jour courant tout en conservant son stock**

---

## Symptômes observés

### ❌ Problème dans le module Citernes

Certaines citernes (ex : TANK1) affichaient :

- uniquement le stock du dernier propriétaire ayant bougé
- en ignorant totalement le stock de l'autre propriétaire

### ❌ Problème dans le Dashboard et le module Stocks

Le stock total affiché (ex : 7 500 L) était inférieur à la somme :

- MONALUXE : 9 000 L
- PARTENAIRE : 4 000 L
- **Total attendu : 13 000 L** (mais affiché : 7 500 L)

### ⚠️ Exemple concret

| Citerne | MONALUXE | PARTENAIRE | Stock affiché (bug) | Stock réel |
|---------|----------|------------|---------------------|------------|
| TANK1   | 5 500 L  | 1 277 L    | 1 277 L ❌          | 6 777 L ✅  |

**Incohérence visuelle et métier manifeste** : Le stock physique réel n'était pas reflété correctement dans l'interface.

---

## Reproduction minimale

1. Créer une réception MONALUXE dans TANK1 (ex : 5 500 L) le 2025-12-10
2. Créer une réception PARTENAIRE dans TANK1 (ex : 1 277 L) le 2025-12-12
3. Ouvrir le module Citernes
4. Observer TANK1 : affiche **1 277 L** au lieu de **6 777 L**
5. Ouvrir le Dashboard
6. Observer "Stock total" : affiche **7 500 L** au lieu de **13 000 L**

---

## Observations DB

### Vue SQL problématique : `v_stocks_citerne_global` (legacy)

> **Note** : Cette vue est legacy conservée en DB, l'app n'y touche plus. La vue canonique Flutter est maintenant `v_stocks_citerne_global_daily`.

**Logique incorrecte (avant correction)** :

```sql
-- ❌ MAUVAISE LOGIQUE
WITH last_date AS (
  SELECT
    citerne_id,
    produit_id,
    MAX(date_jour) AS date_jour  -- ❌ Dernière date GLOBALE
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id
)
SELECT
  citerne_id,
  produit_id,
  SUM(stock_ambiant) AS stock_ambiant_total,
  SUM(stock_15c) AS stock_15c_total
FROM stocks_journaliers sj
JOIN last_date ld
  ON sj.citerne_id = ld.citerne_id
 AND sj.produit_id = ld.produit_id
 AND sj.date_jour = ld.date_jour  -- ❌ Ne prend que les lignes de cette date
GROUP BY citerne_id, produit_id;
```

**Problème identifié** :

- Si MONALUXE a un mouvement le 2025-12-10 et PARTENAIRE le 2025-12-12
- La vue sélectionne uniquement la date 2025-12-12 (la plus récente)
- Seules les lignes PARTENAIRE du 2025-12-12 sont incluses
- Les lignes MONALUXE du 2025-12-10 sont **totalement exclues**
- Résultat : stock sous-estimé

**Requête SQL de validation** :

```sql
-- Vérifier les stocks par propriétaire dans stocks_journaliers
SELECT
  citerne_id,
  produit_id,
  proprietaire_type,
  date_jour,
  stock_ambiant,
  stock_15c
FROM stocks_journaliers
WHERE citerne_id = '57da330a-1305-4582-be45-ceab0f1aa795'  -- TANK1
ORDER BY proprietaire_type, date_jour DESC;
```

**Résultat** : La table contient bien les deux lignes (MONALUXE et PARTENAIRE), mais la vue ne les agrège pas correctement.

---

## Cause racine

### ❌ Erreur conceptuelle dans la vue SQL

**Hypothèse fausse** : "Tous les propriétaires bougent le même jour"

**Réalité métier** :
- Chaque propriétaire a sa propre date de dernier mouvement
- Un propriétaire peut ne pas avoir de mouvement récent tout en conservant son stock
- Le stock physique réel = somme de tous les stocks, indépendamment des dates

**Impact** :
- Bug structurel, pas un bug de données
- Les données en base sont correctes
- La logique d'agrégation de la vue est incorrecte

---

## Analyse technique du problème

### Mauvaise logique (avant correction)

```
1. Dernière date globale par citerne/produit
   → MAX(date_jour) GROUP BY citerne_id, produit_id
   
2. Filtrer les lignes de cette date
   → WHERE date_jour = MAX(date_jour)
   
3. Agréger
   → SUM(stock_ambiant)
```

**❌ Hypothèse fausse en multi-propriétaire** :
- "Tous les propriétaires bougent le même jour"
- Si un seul propriétaire a un mouvement récent, l'autre est exclu

---

## Solution apportée (corrigée)

### ✅ Nouvelle logique correcte

```
1. Dernière date PAR PROPRIÉTAIRE
   → MAX(date_jour) GROUP BY citerne_id, produit_id, proprietaire_type
   
2. Récupérer le stock courant de chaque propriétaire
   → Une ligne par (citerne, produit, propriétaire) avec sa dernière date
   
3. Agréger au niveau citerne
   → SUM(stock_ambiant) GROUP BY citerne_id, produit_id
```

**Principe clé** :
> Chaque propriétaire a sa propre "date courante de stock"

### Implémentation SQL (résumé conceptuel)

**Étape 1** : Déterminer la dernière date de stock par :
- citerne
- produit
- **propriétaire** (clé ajoutée)

**Étape 2** : Récupérer les stocks correspondants (une ligne par propriétaire)

**Étape 3** : Agréger au niveau :
- citerne
- dépôt
- dashboard

**Ce correctif a été appliqué sur** :
- `v_stocks_citerne_global` (legacy, conservée en DB)
- `v_stocks_citerne_global_daily` (canonique Flutter, corrigée également)
- Vues dérivées KPI et dashboard

---

## Correctif appliqué

### Vue SQL corrigée : `v_stocks_citerne_global` (legacy) et `v_stocks_citerne_global_daily` (canonique)

> **Note** : L'app Flutter utilise désormais `v_stocks_citerne_global_daily` comme vue canonique. `v_stocks_citerne_global` est legacy conservée en DB, l'app n'y touche plus.

**Code APRÈS correction** (logique conceptuelle) :

```sql
-- ✅ BONNE LOGIQUE
WITH last_date_per_owner AS (
  SELECT
    citerne_id,
    produit_id,
    proprietaire_type,  -- ✅ Clé ajoutée
    MAX(date_jour) AS date_jour  -- ✅ Dernière date PAR PROPRIÉTAIRE
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id, proprietaire_type
)
SELECT
  sj.citerne_id,
  sj.produit_id,
  SUM(sj.stock_ambiant) AS stock_ambiant_total,
  SUM(sj.stock_15c) AS stock_15c_total
FROM stocks_journaliers sj
JOIN last_date_per_owner ld
  ON sj.citerne_id = ld.citerne_id
 AND sj.produit_id = ld.produit_id
 AND sj.proprietaire_type = ld.proprietaire_type  -- ✅ Filtre par propriétaire
 AND sj.date_jour = ld.date_jour  -- ✅ Date courante de ce propriétaire
GROUP BY sj.citerne_id, sj.produit_id;
```

**Changements appliqués** :

1. **Ajout de `proprietaire_type` dans le GROUP BY** de `last_date`
   - Permet de déterminer la dernière date **par propriétaire**
   - Chaque propriétaire a sa propre "date courante"

2. **Ajout du filtre `proprietaire_type` dans le JOIN**
   - Assure que chaque propriétaire récupère son stock de sa propre dernière date
   - Évite les mélanges entre propriétaires

3. **Agrégation finale au niveau citerne/produit**
   - Somme tous les stocks de tous les propriétaires
   - Reflète le stock physique réel de la citerne

**Résultat** :
- ✅ Chaque propriétaire contribue avec son stock courant
- ✅ Le stock total = somme de tous les propriétaires
- ✅ Indépendant de la date du dernier mouvement global

---

## Validation

### Tests de validation

**Scénario 1 : Propriétaires avec dates différentes**
- MONALUXE : mouvement le 2025-12-10 → stock 5 500 L
- PARTENAIRE : mouvement le 2025-12-12 → stock 1 277 L
- **Résultat attendu** : TANK1 affiche **6 777 L** ✅

**Scénario 2 : Propriétaires avec même date**
- MONALUXE : mouvement le 2025-12-12 → stock 5 500 L
- PARTENAIRE : mouvement le 2025-12-12 → stock 1 277 L
- **Résultat attendu** : TANK1 affiche **6 777 L** ✅

**Scénario 3 : Un seul propriétaire**
- MONALUXE : mouvement le 2025-12-12 → stock 5 500 L
- PARTENAIRE : aucun mouvement
- **Résultat attendu** : TANK1 affiche **5 500 L** ✅

### Validation fonctionnelle

**Module Citernes** :
- ✅ Chaque citerne affiche le stock ambiant total réel
- ✅ Incluant tous les propriétaires

**Module Stocks** :
- ✅ Totaux ambiant et 15°C cohérents
- ✅ Ligne TOTAL = somme exacte des citernes

**Dashboard** :
- ✅ Stock total = 13 000 L ambiant (au lieu de 7 500 L)
- ✅ MONALUXE : 9 000 L
- ✅ PARTENAIRE : 4 000 L
- ✅ Plus aucune divergence visuelle ou métier

---

## Invariant métier désormais respecté

> **Le stock physique affiché ne dépend plus de la date du dernier mouvement global, mais de l'existence réelle du produit dans la citerne.**

**Avant** :
- ❌ Stock dépendait de la date du dernier mouvement global
- ❌ Propriétaires sans mouvement récent étaient exclus

**Après** :
- ✅ Stock dépend de la date du dernier mouvement **par propriétaire**
- ✅ Tous les propriétaires contribuent au stock total
- ✅ Reflète la réalité physique de la citerne

---

## Leçon clé (à conserver dans la documentation)

### ⚠️ En gestion de stock multi-propriétaire

**❌ Anti-pattern** : "Dernière date globale"
```sql
-- ❌ MAUVAIS
SELECT MAX(date_jour) 
FROM stocks_journaliers
GROUP BY citerne_id, produit_id;
-- Hypothèse fausse : tous les propriétaires bougent le même jour
```

**✅ Pattern correct** : "Dernière date par propriétaire"
```sql
-- ✅ BON
SELECT MAX(date_jour) 
FROM stocks_journaliers
GROUP BY citerne_id, produit_id, proprietaire_type;
-- Chaque propriétaire a sa propre date courante
```

**Règle à appliquer** :
- Toujours inclure `proprietaire_type` dans les GROUP BY pour les stocks
- Toujours filtrer par `proprietaire_type` dans les JOINs
- Agréger uniquement après avoir récupéré les stocks de tous les propriétaires

---

## Prévention / Règles à appliquer à l'avenir

### Règle 1 : Toujours considérer le multi-propriétaire dans les agrégations

**Contexte** : Toute vue ou requête qui agrège des stocks par citerne

**Règle** :
- ✅ Toujours inclure `proprietaire_type` dans les GROUP BY pour déterminer les dates
- ✅ Toujours filtrer par `proprietaire_type` dans les JOINs
- ✅ Agréger uniquement après avoir récupéré les stocks de tous les propriétaires

**Exemple** :
```sql
-- ✅ BON : Dernière date par propriétaire
WITH last_date_per_owner AS (
  SELECT
    citerne_id,
    produit_id,
    proprietaire_type,  -- ✅ Inclus
    MAX(date_jour) AS date_jour
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id, proprietaire_type
)

-- ❌ MAUVAIS : Dernière date globale
WITH last_date AS (
  SELECT
    citerne_id,
    produit_id,
    MAX(date_jour) AS date_jour  -- ❌ proprietaire_type manquant
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id
)
```

### Règle 2 : Tester avec des dates différentes par propriétaire

**Contexte** : Tests de validation pour les vues SQL de stocks

**Règle** :
- ✅ Toujours tester avec des mouvements à des dates différentes
- ✅ Vérifier que tous les propriétaires contribuent au stock total
- ✅ Vérifier que le stock total = somme de tous les propriétaires

**Exemple de test** :
```sql
-- Scénario de test
-- MONALUXE : mouvement le 2025-12-10
-- PARTENAIRE : mouvement le 2025-12-12
-- Vérifier que le stock total = MONALUXE + PARTENAIRE
```

### Règle 3 : Documenter les hypothèses métier dans les vues SQL

**Contexte** : Création ou modification de vues SQL de stocks

**Règle** :
- ✅ Ajouter un commentaire expliquant la logique multi-propriétaire
- ✅ Documenter pourquoi `proprietaire_type` est inclus dans le GROUP BY
- ✅ Préciser que chaque propriétaire a sa propre date courante

**Exemple** :
```sql
-- RÈGLE MÉTIER : Chaque propriétaire a sa propre date courante de stock
-- Un propriétaire peut ne pas avoir de mouvement récent tout en conservant son stock
-- Le stock physique réel = somme de tous les stocks, indépendamment des dates
WITH last_date_per_owner AS (
  SELECT
    citerne_id,
    produit_id,
    proprietaire_type,  -- Clé pour déterminer la date courante par propriétaire
    MAX(date_jour) AS date_jour
  FROM stocks_journaliers
  GROUP BY citerne_id, produit_id, proprietaire_type
)
```

---

## Impact métier

### Avant correction

- ❌ **Décisions opérationnelles basées sur des données incorrectes**
  - Stock sous-estimé → risque de sur-commande ou de rupture
  - Incohérence entre modules → confusion des opérateurs

- ❌ **Perte de confiance**
  - Les utilisateurs ne peuvent pas se fier aux chiffres affichés
  - Risque de décisions métier erronées

### Après correction

- ✅ **Données fiables**
  - Stock reflète la réalité physique de la citerne
  - Cohérence totale entre modules

- ✅ **Décisions opérationnelles correctes**
  - Les opérateurs peuvent se fier aux chiffres affichés
  - Pas de risque de sur-commande ou de rupture

---

## Statut final

| Critère | Statut |
|---------|--------|
| Bug corrigé | ✅ Oui |
| Régression | ❌ Aucune |
| Alignement métier | ✅ Total |
| Exploitabilité dépôt réel | ✅ Validée |
| Tests de non-régression | ✅ À ajouter |

---

## Références

- **Règle métier officielle** : `docs/db/REGLE_METIER_STOCKS_AMBIANT_15C.md`
- **Vue SQL** : `v_stocks_citerne_global_daily` (canonique Flutter), `v_stocks_citerne_global` (legacy conservée en DB, l'app n'y touche plus)
- **Module Citernes** : `lib/features/citernes/screens/citerne_list_screen.dart`
- **Module Stocks** : `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`
- **Dashboard** : `lib/features/dashboard/widgets/role_dashboard.dart`

---

## Historique des modifications

| Date | Version | Auteur | Modification |
|------|---------|--------|--------------|
| 2025-12-13 | 1.0 | Équipe ML_PP MVP | Création du rapport d'incident et documentation du correctif |

---

**Document officiel d'incident – Bug critique résolu**







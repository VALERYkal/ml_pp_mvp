# Tests manuels - Vues Stocks (Phase 3)

## Contexte

Ce document sert à documenter les tests manuels effectués lors de la phase 3 de la migration Stocks Engine, concernant les vues SQL créées pour le frontend.

## Vues créées

1. **v_stocks_citernes** : Stocks journaliers par citerne avec détails
2. **v_dashboard_kpi** : KPIs agrégés pour le dashboard
3. **v_citernes_state** : État actuel de chaque citerne (dernier stock connu)

---

## Test 1 : Vue v_stocks_citernes

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

### Objectif

Valider que la vue `v_stocks_citernes` retourne les données attendues pour l'écran "Stocks".

### Requête de test

```sql
SELECT 
  date_jour,
  citerne_nom,
  produit_nom,
  stock_ambiant,
  stock_15c,
  capacite_totale,
  capacite_securite,
  ratio_utilisation
FROM public.v_stocks_citernes
WHERE date_jour = CURRENT_DATE
ORDER BY citerne_nom, produit_nom;
```

### Résultats attendus

- Une ligne par combinaison (date_jour, citerne, produit, proprietaire_type)
- Les colonnes sont présentes et correctement typées
- Les valeurs correspondent aux données de `stocks_journaliers`

### Résultats observés

[À compléter]

```
[Exemple]
date_jour    | citerne_nom | produit_nom | stock_ambiant | stock_15c | capacite_totale
2025-12-06   | TANK1       | Gasoil      | 1600.0       | 1580.0   | 500000.0
2025-12-06   | TANK2       | Gasoil      | 500.0        | 495.0    | 500000.0
```

### Vérifications

- [ ] Les noms de citernes sont corrects
- [ ] Les noms de produits sont corrects
- [ ] Les stocks correspondent aux calculs manuels
- [ ] Les capacités sont correctes
- [ ] Les ratios de utilisation sont calculés correctement

### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

## Test 2 : Vue v_dashboard_kpi

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

### Objectif

Valider que la vue `v_dashboard_kpi` retourne les KPIs agrégés pour le dashboard.

### Requête de test

```sql
SELECT 
  stock_total_15c,
  stock_total_ambiant,
  receptions_jour_15c,
  receptions_jour_ambiant,
  sorties_jour_15c,
  sorties_jour_ambiant,
  balance_jour_15c,
  balance_jour_ambiant,
  tendance_7j_15c,
  tendance_7j_ambiant
FROM public.v_dashboard_kpi
WHERE date_jour = CURRENT_DATE;
```

### Résultats attendus

- Une ligne par date_jour (ou agrégation globale selon design)
- Les totaux correspondent aux sommes manuelles
- Les balances = réceptions - sorties
- Les tendances 7j = somme nette sur 7 jours

### Résultats observés

[À compléter]

### Vérifications

- [ ] stock_total_15c = somme de tous les stocks_15c
- [ ] stock_total_ambiant = somme de tous les stocks_ambiant
- [ ] receptions_jour = somme des volumes des réceptions du jour
- [ ] sorties_jour = somme des volumes des sorties du jour
- [ ] balance_jour = receptions_jour - sorties_jour
- [ ] tendance_7j = somme nette (réceptions - sorties) sur 7 jours

### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

## Test 3 : Vue v_citernes_state

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

### Objectif

Valider que la vue `v_citernes_state` retourne l'état actuel de chaque citerne.

### Requête de test

```sql
SELECT 
  citerne_id,
  citerne_nom,
  produit_id,
  produit_nom,
  stock_ambiant_actuel,
  stock_15c_actuel,
  date_dernier_mouvement,
  capacite_totale,
  capacite_securite,
  ratio_utilisation
FROM public.v_citernes_state
ORDER BY citerne_nom;
```

### Résultats attendus

- Une ligne par citerne
- Le stock actuel = dernier stock connu (dernière date_jour)
- La date_dernier_mouvement = dernière date avec mouvement

### Résultats observés

[À compléter]

### Vérifications

- [ ] Une ligne par citerne (pas de doublons)
- [ ] stock_ambiant_actuel = dernier stock_ambiant de stocks_journaliers
- [ ] stock_15c_actuel = dernier stock_15c de stocks_journaliers
- [ ] date_dernier_mouvement = dernière date_jour avec mouvement
- [ ] Les capacités sont correctes

### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

## Test 4 : Performance des vues

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

### Objectif

Valider que les vues sont performantes même avec beaucoup de données.

### Requête de test

```sql
-- Test v_stocks_citernes
EXPLAIN ANALYZE
SELECT * FROM public.v_stocks_citernes
WHERE date_jour BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE;

-- Test v_dashboard_kpi
EXPLAIN ANALYZE
SELECT * FROM public.v_dashboard_kpi
WHERE date_jour = CURRENT_DATE;

-- Test v_citernes_state
EXPLAIN ANALYZE
SELECT * FROM public.v_citernes_state;
```

### Résultats attendus

- Temps d'exécution < 1 seconde pour chaque vue
- Utilisation d'index appropriés
- Pas de scans séquentiels sur de grandes tables

### Résultats observés

[À compléter]

### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

## Test 5 : Cohérence avec stocks_journaliers

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

### Objectif

Valider que les vues reflètent fidèlement les données de `stocks_journaliers`.

### Requête de test

```sql
-- Comparer v_stocks_citernes avec stocks_journaliers
SELECT 
  'vue' as source,
  date_jour,
  citerne_id,
  produit_id,
  stock_ambiant,
  stock_15c
FROM public.v_stocks_citernes
WHERE date_jour = CURRENT_DATE

UNION ALL

SELECT 
  'table' as source,
  date_jour,
  citerne_id,
  produit_id,
  stock_ambiant,
  stock_15c
FROM public.stocks_journaliers
WHERE date_jour = CURRENT_DATE
ORDER BY citerne_id, produit_id, source;
```

### Résultats attendus

- Les valeurs de la vue correspondent exactement à celles de la table
- Pas de différences

### Résultats observés

[À compléter]

### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

## Notes générales

- Tous les tests doivent être exécutés sur un environnement de **test**
- Documenter toute anomalie ou comportement inattendu
- Si un test échoue, ne pas passer à la phase 4 avant correction

## Historique des tests

| Date | Test | Statut | Notes |
|------|------|--------|-------|
| [À compléter] | Test 1 | [ ] | [À compléter] |
| [À compléter] | Test 2 | [ ] | [À compléter] |
| [À compléter] | Test 3 | [ ] | [À compléter] |
| [À compléter] | Test 4 | [ ] | [À compléter] |
| [À compléter] | Test 5 | [ ] | [À compléter] |


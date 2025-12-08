# Tests manuels - Stocks Engine (Phase 1 & 2)

## Contexte

Ce document sert à documenter les tests manuels effectués lors des phases 1 et 2 de la migration Stocks Engine.

## Phase 1 - Tests de recompute

### Objectif

Valider que la fonction `rebuild_stocks_journaliers()` calcule correctement les stocks journaliers à partir de `v_mouvements_stock` en utilisant des window functions.

### Prérequis

- Environnement de test avec données de test
- Accès SQL à la base de données
- Connaissance des données de test (réceptions et sorties existantes)

### Test 1 : Recompute complet global

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Vérifier l'état actuel de `stocks_journaliers` :
   ```sql
   SELECT 
     date_jour,
     citerne_id,
     produit_id,
     proprietaire_type,
     source,
     stock_ambiant,
     stock_15c
   FROM public.stocks_journaliers 
   ORDER BY date_jour, citerne_id, produit_id, proprietaire_type;
   ```

2. Vérifier la vue `v_mouvements_stock` :
   ```sql
   SELECT 
     date_jour,
     citerne_id,
     produit_id,
     depot_id,
     proprietaire_type,
     delta_ambiant,
     delta_15c
   FROM public.v_mouvements_stock
   ORDER BY date_jour, citerne_id
   LIMIT 20;
   ```

3. Exécuter la fonction de recompute globale :
   ```sql
   SELECT public.rebuild_stocks_journaliers();
   ```

4. Inspecter le contenu recalculé :
   ```sql
   SELECT
     date_jour,
     citerne_id,
     produit_id,
     proprietaire_type,
     stock_ambiant,
     stock_15c,
     source
   FROM public.stocks_journaliers
   ORDER BY date_jour, citerne_id;
   ```

5. Vérifier la cohérence avec les mouvements bruts :
   ```sql
   -- Somme des mouvements
   SELECT
     SUM(delta_ambiant) AS total_delta_amb,
     SUM(delta_15c)     AS total_delta_15c
   FROM public.v_mouvements_stock;
   
   -- Stock au dernier jour (doit matcher les deltas cumulés)
   SELECT
     MAX(date_jour) AS last_day,
     SUM(stock_ambiant) AS total_stock_amb,
     SUM(stock_15c)     AS total_stock_15c
   FROM public.stocks_journaliers
   WHERE source = 'SYSTEM';
   ```

#### Résultats attendus

- Les stocks calculés correspondent aux calculs manuels
- Pas d'erreurs SQL
- Les contraintes UNIQUE sont respectées
- Tous les stocks recalculés ont `source = 'SYSTEM'`
- Les totaux des mouvements correspondent aux stocks cumulés (à la précision du double)

#### Résultats observés

[À compléter après exécution]

```
[Exemple]
- total_delta_amb : 10000.0 L
- total_stock_amb (dernier jour) : 10000.0 L ✓
- total_delta_15c : 9950.0 L
- total_stock_15c (dernier jour) : 9950.0 L ✓
```

#### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

### Test 1b : Recompute partiel (filtres)

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Exécuter un rebuild partiel pour un dépôt spécifique :
   ```sql
   SELECT public.rebuild_stocks_journaliers(
     p_depot_id := '[ID_DEPOT_TEST]'
   );
   ```

2. Exécuter un rebuild partiel pour une période :
   ```sql
   SELECT public.rebuild_stocks_journaliers(
     p_start_date := '2025-12-01',
     p_end_date := '2025-12-31'
   );
   ```

3. Vérifier que seules les lignes SYSTEM dans le périmètre ont été recalculées

#### Résultats attendus

- Seules les lignes `source = 'SYSTEM'` dans le périmètre sont supprimées et recalculées
- Les lignes hors périmètre restent intactes
- Les ajustements manuels (`source ≠ 'SYSTEM'`) sont préservés

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

### Test 2 : Validation préservation ajustements manuels

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Créer un ajustement manuel :
   ```sql
   INSERT INTO public.stocks_journaliers (
     citerne_id,
     produit_id,
     date_jour,
     stock_ambiant,
     stock_15c,
     proprietaire_type,
     depot_id,
     source,
     created_at,
     updated_at
   ) VALUES (
     '[ID_CITERNE]',
     '[ID_PRODUIT]',
     CURRENT_DATE,
     1000.0,
     995.0,
     'MONALUXE',
     '[ID_DEPOT]',
     'MANUAL',  -- Ajustement manuel
     now(),
     now()
   );
   ```

2. Exécuter le rebuild :
   ```sql
   SELECT public.rebuild_stocks_journaliers();
   ```

3. Vérifier que l'ajustement manuel est préservé :
   ```sql
   SELECT * FROM public.stocks_journaliers
   WHERE source = 'MANUAL';
   ```

#### Résultats attendus

- L'ajustement manuel (`source = 'MANUAL'`) est préservé
- Les stocks SYSTEM sont recalculés normalement
- Pas de conflit entre les deux

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

### Test 3 : Validation séparation propriétaires

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Vérifier qu'une même citerne peut avoir des stocks séparés par propriétaire :
   ```sql
   SELECT 
     citerne_id,
     produit_id,
     proprietaire_type,
     depot_id,
     SUM(stock_ambiant) as total_ambiant,
     SUM(stock_15c) as total_15c
   FROM public.stocks_journaliers
   WHERE citerne_id = '[ID_CITERNE_TEST]'
   GROUP BY citerne_id, produit_id, proprietaire_type, depot_id;
   ```

#### Résultats attendus

- Deux lignes distinctes pour MONALUXE et PARTENAIRE
- Les totaux sont indépendants

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec

---

## Phase 2 - Tests des triggers v2

### Objectif

Valider que les nouveaux triggers v2 maintiennent correctement les stocks en temps réel.

### Prérequis

- Phase 1 validée
- Nouveaux triggers v2 déployés
- Anciens triggers désactivés (suffixe `_old`)

### Test 4 : Validation vue v_mouvements_stock

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Vérifier que la vue agrège correctement les mouvements :
   ```sql
   SELECT 
     date_jour,
     citerne_id,
     produit_id,
     depot_id,
     proprietaire_type,
     SUM(delta_ambiant) as delta_ambiant_jour,
     SUM(delta_15c) as delta_15c_jour
   FROM public.v_mouvements_stock
   WHERE date_jour = CURRENT_DATE
   GROUP BY date_jour, citerne_id, produit_id, depot_id, proprietaire_type;
   ```

2. Vérifier que les réceptions sont positives et les sorties négatives :
   ```sql
   SELECT 
     CASE 
       WHEN delta_ambiant > 0 THEN 'RECEPTION'
       WHEN delta_ambiant < 0 THEN 'SORTIE'
       ELSE 'ZERO'
     END as type_mouvement,
     COUNT(*) as nb_mouvements,
     SUM(delta_ambiant) as total_delta_ambiant
   FROM public.v_mouvements_stock
   GROUP BY type_mouvement;
   ```

#### Résultats attendus

- Les réceptions ont des deltas positifs
- Les sorties ont des deltas négatifs
- L'agrégation journalière fonctionne correctement

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec (détails : [À compléter])

---

### Test 5 : Réception avec trigger v2

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Noter le stock actuel :
   ```sql
   SELECT * FROM public.stocks_journaliers 
   WHERE citerne_id = '[ID_CITERNE]' 
     AND produit_id = '[ID_PRODUIT]'
     AND date_jour = CURRENT_DATE
     AND proprietaire_type = 'MONALUXE';
   ```

2. Créer une réception de test :
   ```sql
   INSERT INTO public.receptions (
     citerne_id,
     produit_id,
     date_reception,
     volume_ambiant,
     volume_corrige_15c,
     proprietaire_type,
     index_avant,
     index_apres,
     statut
   ) VALUES (
     '[ID_CITERNE]',
     '[ID_PRODUIT]',
     CURRENT_DATE,
     100.0,
     98.0,
     'MONALUXE',
     0,
     100,
     'validee'
   );
   ```

3. Vérifier le stock mis à jour :
   ```sql
   SELECT * FROM public.stocks_journaliers 
   WHERE citerne_id = '[ID_CITERNE]' 
     AND produit_id = '[ID_PRODUIT]'
     AND date_jour = CURRENT_DATE
     AND proprietaire_type = 'MONALUXE';
   ```

#### Résultats attendus

- Le stock_ambiant a augmenté de +100.0
- Le stock_15c a augmenté de +98.0
- Pas d'erreurs SQL

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec

---

### Test 6 : Sortie avec trigger v2

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Noter le stock actuel (même requête que Test 3)

2. Créer une sortie de test :
   ```sql
   INSERT INTO public.sorties_produit (
     citerne_id,
     produit_id,
     date_sortie,
     volume_ambiant,
     volume_corrige_15c,
     proprietaire_type,
     client_id,
     index_avant,
     index_apres,
     statut
   ) VALUES (
     '[ID_CITERNE]',
     '[ID_PRODUIT]',
     CURRENT_DATE,
     50.0,
     49.0,
     'MONALUXE',
     '[ID_CLIENT]',
     100,
     150,
     'validee'
   );
   ```

3. Vérifier le stock mis à jour (même requête que Test 3)

#### Résultats attendus

- Le stock_ambiant a diminué de -50.0
- Le stock_15c a diminué de -49.0
- Pas d'erreurs SQL

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec

---

### Test 7 : Validation séparation propriétaires en temps réel

**Date** : [À compléter]  
**Exécuté par** : [À compléter]

#### Étapes

1. Créer une réception MONALUXE
2. Créer une réception PARTENAIRE (même citerne, même produit, même date)
3. Vérifier que les deux stocks sont séparés :
   ```sql
   SELECT 
     proprietaire_type,
     stock_ambiant,
     stock_15c
   FROM public.stocks_journaliers
   WHERE citerne_id = '[ID_CITERNE]'
     AND produit_id = '[ID_PRODUIT]'
     AND date_jour = CURRENT_DATE;
   ```

#### Résultats attendus

- Deux lignes distinctes (une MONALUXE, une PARTENAIRE)
- Les volumes ne se mélangent pas

#### Résultats observés

[À compléter]

#### Statut

- [ ] Réussi
- [ ] Échec

---

## Notes générales

- Tous les tests doivent être exécutés sur un environnement de **test**, jamais en production
- Documenter toute anomalie ou comportement inattendu
- Si un test échoue, ne pas passer à la phase suivante avant correction

## Historique des tests

| Date | Test | Statut | Notes |
|------|------|--------|-------|
| [À compléter] | Test 1 | [ ] | [À compléter] |
| [À compléter] | Test 1b | [ ] | [À compléter] |
| [À compléter] | Test 2 | [ ] | [À compléter] |
| [À compléter] | Test 3 | [ ] | [À compléter] |
| [À compléter] | Test 4 | [ ] | [À compléter] |
| [À compléter] | Test 5 | [ ] | [À compléter] |
| [À compléter] | Test 6 | [ ] | [À compléter] |
| [À compléter] | Test 7 | [ ] | [À compléter] |


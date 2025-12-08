# Règles métier officielles - Stocks journaliers

## Contexte

Ce document définit les règles métier officielles pour le calcul et la gestion des stocks journaliers dans ML_PP MVP.

## Clé composite

Le stock journalier est identifié par une clé composite unique :

```
(date_jour, citerne_id, produit_id, proprietaire_type, depot_id)
```

- `date_jour` : Date du jour (type `date`)
- `citerne_id` : UUID de la citerne
- `produit_id` : UUID du produit
- `proprietaire_type` : `'MONALUXE'` ou `'PARTENAIRE'`
- `depot_id` : UUID du dépôt (récupéré depuis la citerne)

## Règle fondamentale : Cumul depuis le début

**Les colonnes `stock_ambiant` et `stock_15c` représentent le cumul depuis le début de l'historique, pas un delta journalier.**

### Calcul du stock

Pour une date donnée, le stock est calculé comme suit :

```
stock = somme(entrées) – somme(sorties) depuis le début de l'historique
```

Le stock est calculé en cumulant tous les mouvements depuis le début, ordonnés par date :
- **Réceptions** : addition des volumes (crédit positif)
- **Sorties** : soustraction des volumes (débit négatif)

La fonction `rebuild_stocks_journaliers()` utilise des **window functions** pour calculer les cumuls :
- Agrégation journalière des mouvements par `(date_jour, citerne_id, produit_id, depot_id, proprietaire_type)`
- Calcul du cumul avec `SUM(...) OVER (PARTITION BY ... ORDER BY date_jour)`

### Exemple

Pour la citerne TANK1, produit Gasoil, propriétaire MONALUXE, date 2025-12-06 :

- Stock initial (2025-12-05) : 1000 L
- Réception 1 (2025-12-06) : +500 L
- Réception 2 (2025-12-06) : +300 L
- Sortie 1 (2025-12-06) : -200 L

**Stock fin de journée (2025-12-06) : 1000 + 500 + 300 - 200 = 1600 L**

## Signes des volumes

### Réceptions

Les réceptions **créditent** le stock (valeur positive) :

```sql
-- Dans le trigger receptions_apply_effects()
PERFORM stock_upsert_journalier(
  citerne_id,
  produit_id,
  date_jour,
  +volume_ambiant,  -- Positif (crédit)
  +volume_15c       -- Positif (crédit)
);
```

### Sorties

Les sorties **débitent** le stock (valeur négative) :

```sql
-- Dans le trigger sorties_apply_effects() ou fn_sorties_after_insert()
PERFORM stock_upsert_journalier(
  citerne_id,
  produit_id,
  date_jour,
  -volume_ambiant,  -- Négatif (débit)
  -volume_15c      -- Négatif (débit)
);
```

## Séparation par propriétaire

Les stocks MONALUXE et PARTENAIRE sont **séparés** dans `stocks_journaliers`.

Une même citerne peut avoir :
- Un stock MONALUXE (ex: 1000 L)
- Un stock PARTENAIRE (ex: 500 L)

Ces deux stocks sont indépendants et ne se mélangent pas.

## Volumes ambiant vs 15°C

Chaque mouvement enregistre deux volumes :

- `volume_ambiant` : Volume mesuré à la température ambiante
- `volume_corrige_15c` : Volume corrigé à 15°C (calculé ou mesuré)

Les stocks journaliers maintiennent les deux valeurs séparément :
- `stock_ambiant` : Cumul des volumes ambiants
- `stock_15c` : Cumul des volumes corrigés à 15°C

## Vue v_mouvements_stock

La vue `v_mouvements_stock` agrège tous les mouvements (réceptions et sorties) avec leurs deltas :

- **Réceptions** : `delta_ambiant` et `delta_15c` positifs (crédit)
- **Sorties** : `delta_ambiant` et `delta_15c` négatifs (débit)

La vue est utilisée par `rebuild_stocks_journaliers()` pour recalculer les stocks.

## Source SYSTEM vs ajustements manuels

Les stocks journaliers peuvent avoir deux types de sources :

- **`source = 'SYSTEM'`** : Stocks calculés automatiquement par `rebuild_stocks_journaliers()`
- **`source ≠ 'SYSTEM'`** : Ajustements manuels (ex: `'MANUAL'`, `'CORRECTION'`)

La fonction `rebuild_stocks_journaliers()` :
1. Supprime uniquement les lignes `source = 'SYSTEM'` dans le périmètre spécifié
2. Recalcule les stocks à partir de `v_mouvements_stock`
3. Laisse intact les ajustements manuels (`source ≠ 'SYSTEM'`)

## Ordre chronologique

Lors du recompute, les mouvements sont traités **dans l'ordre chronologique strict** via la vue `v_mouvements_stock` :

1. Agrégation journalière des mouvements par date
2. Calcul des cumuls avec window functions ordonnées par `date_jour`
3. Insertion des stocks cumulés dans `stocks_journaliers`

## Contraintes

### Contrainte UNIQUE

```sql
UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type)
```

Cette contrainte garantit qu'il ne peut y avoir qu'une seule ligne de stock par combinaison (citerne, produit, date, propriétaire).

**Note** : `depot_id` n'est pas dans la clé UNIQUE car il est dérivé de `citerne_id` (une citerne appartient à un seul dépôt).

### Contrainte CHECK

```sql
CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE'))
```

## Cas limites

### Stock initial inexistant

Si aucune ligne de stock n'existe pour une date antérieure, le stock initial est considéré comme **0**.

### Date future

Les mouvements avec une date future ne doivent pas être traités lors du recompute (ou être traités avec une date = date actuelle).

### Volumes NULL

Si `volume_ambiant` ou `volume_corrige_15c` est NULL dans un mouvement :
- Pour les réceptions : utiliser 0 (pas de crédit)
- Pour les sorties : utiliser 0 (pas de débit)

## Validation

Pour valider que les stocks sont corrects :

1. Calculer manuellement le stock pour une citerne/produit/propriétaire sur une période
2. Comparer avec le résultat de `rebuild_stocks_journaliers()`
3. Vérifier la cohérence avec les mouvements bruts :
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
   FROM public.stocks_journaliers;
   ```
4. Les deux totaux doivent être égaux (à la précision du double)

## Références

- Table : `public.stocks_journaliers`
- Vue : `public.v_mouvements_stock` (agrégation des mouvements)
- Fonction rebuild : `public.rebuild_stocks_journaliers(p_depot_id, p_start_date, p_end_date)`
- Fonction upsert : `public.stock_upsert_journalier()` (utilisée par les triggers)
- Triggers réceptions : `public.receptions_apply_effects()`
- Triggers sorties : `public.fn_sorties_after_insert()`


# Analyse en profondeur - Problème de stock total incorrect

## Date : 2025-12-11

## Problème identifié

Le stock total affiché dans les modules **Stocks** et **Citernes** est incorrect :
- **Attendu** : 38 500 L ambiant / 38 318.3 L 15°C
- **Affiché** : 23 500 L ambiant / 23 386.57 L 15°C
- **Manquant** : ~15 000 L (stock MONALUXE de TANK1)

## Analyse des sources de données

### 1. Dashboard (✅ CORRECT)

**Provider utilisé** : `stocksDashboardKpisProvider` → `loadDashboardKpis()`

**Méthode** : `fetchCiterneGlobalSnapshots(depotId)` **SANS filtre date**

**Vue SQL** : `v_stocks_citerne_global`

**Résultat** : Affiche correctement 38 318.3 L (15°C)

### 2. Module Stocks - Vue d'ensemble (❌ INCORRECT)

**Provider utilisé** : `depotStocksSnapshotProvider`

**Méthode** : `fetchCiterneGlobalSnapshots(depotId)` **SANS filtre date** (corrigé)

**Vue SQL** : `v_stocks_citerne_global`

**Problème** : Affiche 23 500 L au lieu de 38 500 L

### 3. Module Citernes (❌ INCORRECT)

**Provider utilisé** : `citernesWithStockProvider`

**Vue SQL** : `v_citerne_stock_actuel` (via `stock_actuel`)

**Problème** : La vue `v_citerne_stock_actuel` utilise `PARTITION BY citerne_id` **SANS** `proprietaire_type`, donc elle ne retourne qu'une seule ligne par citerne (la dernière date), perdant ainsi le stock d'un des propriétaires.

## Analyse de la vue SQL `v_stocks_citerne_global`

### Structure de la vue

```sql
CREATE OR REPLACE VIEW public.v_stocks_citerne_global AS
WITH dernier_stock AS (
  SELECT DISTINCT ON (citerne_id, produit_id, proprietaire_type)
    citerne_id, produit_id, proprietaire_type, stock_ambiant, stock_15c, date_jour, depot_id
  FROM public.stocks_journaliers
  ORDER BY citerne_id, produit_id, proprietaire_type, date_jour DESC
),
stocks_agreges AS (
  SELECT
    citerne_id, produit_id, depot_id,
    SUM(CASE WHEN proprietaire_type = 'MONALUXE' THEN stock_ambiant ELSE 0 END) AS stock_ambiant_monaluxe,
    SUM(CASE WHEN proprietaire_type = 'MONALUXE' THEN stock_15c ELSE 0 END) AS stock_15c_monaluxe,
    SUM(CASE WHEN proprietaire_type = 'PARTENAIRE' THEN stock_ambiant ELSE 0 END) AS stock_ambiant_partenaire,
    SUM(CASE WHEN proprietaire_type = 'PARTENAIRE' THEN stock_15c ELSE 0 END) AS stock_15c_partenaire,
    MAX(date_jour) AS date_dernier_mouvement
  FROM dernier_stock
  GROUP BY citerne_id, produit_id, depot_id
)
SELECT
  c.id AS citerne_id,
  c.nom AS citerne_nom,
  c.produit_id,
  p.nom AS produit_nom,
  sa.stock_ambiant_monaluxe + sa.stock_ambiant_partenaire AS stock_ambiant_total,
  sa.stock_15c_monaluxe + sa.stock_15c_partenaire AS stock_15c_total,
  ...
FROM public.citernes c
LEFT JOIN public.produits p ON p.id = c.produit_id
LEFT JOIN stocks_agreges sa ON sa.citerne_id = c.id AND sa.produit_id = c.produit_id
LEFT JOIN public.depots d ON d.id = COALESCE(sa.depot_id, c.depot_id);
```

### Points clés

1. ✅ La vue agrège correctement MONALUXE + PARTENAIRE dans `stocks_agreges`
2. ✅ Elle calcule `stock_ambiant_total = stock_ambiant_monaluxe + stock_ambiant_partenaire`
3. ⚠️ Elle fait un **LEFT JOIN** avec `citernes`, donc elle retourne **TOUTES les citernes**, même celles sans stock (valeurs NULL)
4. ⚠️ Elle expose `date_dernier_mouvement` (pas `date_jour`), donc un filtre sur `date_jour` ne fonctionne pas

## Analyse de la vue SQL `v_citerne_stock_actuel`

### Structure de la vue

```sql
CREATE OR REPLACE VIEW public.v_citerne_stock_actuel AS
WITH ranked AS (
  SELECT s.*,
    row_number() OVER (PARTITION BY s.citerne_id ORDER BY s.date_jour DESC) AS rn
  FROM public.stocks_journaliers s
)
SELECT r.citerne_id, r.produit_id, r.stock_ambiant, r.stock_15c, r.date_jour
FROM ranked r
WHERE r.rn = 1;
```

### Problème identifié

❌ **PARTITION BY citerne_id seulement** - ne prend pas en compte `proprietaire_type`

**Conséquence** : Si une citerne a du stock MONALUXE et PARTENAIRE, la vue ne retourne que **l'une des deux lignes** (celle avec la date la plus récente), perdant ainsi le stock de l'autre propriétaire.

## Hypothèses sur la cause du problème

### Hypothèse 1 : Vue SQL non à jour dans la base de données

La migration `2025-12-XX_views_stocks.sql` qui définit `v_stocks_citerne_global` n'a peut-être pas été exécutée dans la base de données de production.

**Vérification nécessaire** : Exécuter la migration ou vérifier que la vue existe et a la bonne structure.

### Hypothèse 2 : La vue retourne des lignes avec valeurs NULL

Le LEFT JOIN avec `citernes` peut retourner des citernes sans stock, avec `stock_ambiant_total = NULL`. Ces valeurs NULL ne sont pas sommées correctement.

**Vérification nécessaire** : Vérifier que les valeurs NULL sont bien gérées dans le mapping Dart.

### Hypothèse 3 : La vue retourne plusieurs lignes par citerne

Si la vue retourne des lignes séparées par propriétaire au lieu de lignes agrégées, l'agrégation Dart devrait fonctionner, mais peut-être qu'elle ne fonctionne pas correctement.

**Vérification nécessaire** : Ajouter des logs pour voir ce que retourne réellement la vue SQL.

## Solutions proposées

### Solution 1 : Vérifier et mettre à jour la vue SQL

1. Vérifier que la migration `2025-12-XX_views_stocks.sql` a été exécutée
2. Vérifier que la vue `v_stocks_citerne_global` existe et a la bonne structure
3. Si nécessaire, recréer la vue avec la bonne structure

### Solution 2 : Corriger le mapping Dart pour gérer les valeurs NULL

Dans `CiterneGlobalStockSnapshot.fromMap`, s'assurer que les valeurs NULL sont bien converties en 0.0 :

```dart
stockAmbiantTotal: _toDouble(map['stock_ambiant_total'] ?? 0),
stock15cTotal: _toDouble(map['stock_15c_total'] ?? 0),
```

### Solution 3 : Améliorer l'agrégation Dart

L'agrégation Dart actuelle devrait fonctionner, mais on peut l'améliorer pour gérer les cas où la vue retourne des lignes séparées par propriétaire.

### Solution 4 : Remplacer `v_citerne_stock_actuel` par `v_stocks_citerne_global` dans le module Citernes

Le module Citernes utilise `v_citerne_stock_actuel` qui ne prend pas en compte `proprietaire_type`. Il faudrait le remplacer par `v_stocks_citerne_global` pour avoir les totaux agrégés.

## Actions immédiates

1. ✅ Ajouter des logs de diagnostic pour voir ce que retourne réellement la vue SQL
2. ⏳ Vérifier que la vue `v_stocks_citerne_global` est à jour dans la base de données
3. ⏳ Tester avec les données réelles pour confirmer le problème
4. ⏳ Corriger le module Citernes pour utiliser `v_stocks_citerne_global` au lieu de `v_citerne_stock_actuel`

## Logs de diagnostic ajoutés

Des logs ont été ajoutés dans :
- `lib/data/repositories/stocks_kpi_repository.dart` : Log des données brutes retournées par la vue SQL
- `lib/features/stocks/data/stocks_kpi_providers.dart` : Log détaillé de chaque citerne après agrégation

Ces logs permettront de voir exactement ce que retourne la vue SQL et comment les données sont agrégées.


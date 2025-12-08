# Contrat SQL - Vues Stocks (Interface stable pour Flutter)

**Date** : 06/12/2025  
**Version** : 1.0  
**Objectif** : Définir l'interface SQL stable que Flutter consommera pour les stocks

---

## 🎯 Principe

Ces vues sont la **source unique de vérité** pour tous les modules Flutter qui affichent des stocks.  
**Toute modification de ces vues doit être documentée et communiquée au frontend.**

---

## 📊 Vue principale : `v_stocks_citerne_global`

### Description

Vue principale de stock instantané par citerne / produit avec totaux MONALUXE + PARTENAIRE.  
**Source unique de vérité pour les écrans Citernes, Dashboard et KPI.**

### Colonnes

| Colonne | Type | Description | Garanti stable |
|---------|------|-------------|----------------|
| `citerne_id` | `uuid` | ID de la citerne | ✅ Oui |
| `citerne_nom` | `text` | Nom de la citerne | ✅ Oui |
| `produit_id` | `uuid` | ID du produit | ✅ Oui |
| `produit_nom` | `text` | Nom du produit | ✅ Oui |
| `produit_code` | `text` | Code du produit | ✅ Oui |
| `stock_ambiant_total` | `double precision` | Stock ambiant total (Monaluxe + Partenaire) | ✅ Oui |
| `stock_15c_total` | `double precision` | Stock 15°C total (Monaluxe + Partenaire) | ✅ Oui |
| `stock_ambiant_monaluxe` | `double precision` | Stock ambiant MONALUXE uniquement | ✅ Oui |
| `stock_15c_monaluxe` | `double precision` | Stock 15°C MONALUXE uniquement | ✅ Oui |
| `stock_ambiant_partenaire` | `double precision` | Stock ambiant PARTENAIRE uniquement | ✅ Oui |
| `stock_15c_partenaire` | `double precision` | Stock 15°C PARTENAIRE uniquement | ✅ Oui |
| `capacite_totale` | `double precision` | Capacité totale de la citerne | ✅ Oui |
| `capacite_securite` | `double precision` | Capacité de sécurité de la citerne | ✅ Oui |
| `ratio_utilisation` | `double precision` | Ratio d'utilisation (stock_ambiant_total / capacite_totale) en % | ✅ Oui |
| `depot_id` | `uuid` | ID du dépôt | ✅ Oui |
| `depot_nom` | `text` | Nom du dépôt | ✅ Oui |
| `date_dernier_mouvement` | `date` | Date du dernier mouvement | ✅ Oui |

### Clé de regroupement

**Une ligne par combinaison `(citerne_id, produit_id)`** avec les totaux agrégés MONALUXE + PARTENAIRE.

**Note** : Cette vue ne sépare pas par `proprietaire_type` dans les lignes, mais fournit les totaux séparés dans des colonnes distinctes.

### Exemple d'usage

```sql
-- Récupérer tous les stocks par citerne
SELECT * FROM public.v_stocks_citerne_global
ORDER BY citerne_nom, produit_nom;

-- Récupérer le stock d'une citerne spécifique
SELECT * FROM public.v_stocks_citerne_global
WHERE citerne_id = '57da330a-1305-4582-be45-ceab0f1aa795';

-- Filtrer par dépôt
SELECT * FROM public.v_stocks_citerne_global
WHERE depot_id = '[ID_DEPOT]';
```

### Garanties

- ✅ Les valeurs `stock_ambiant_total` et `stock_15c_total` sont toujours cohérentes avec `stocks_journaliers`
- ✅ Les valeurs sont calculées depuis le dernier mouvement connu (dernière date_jour)
- ✅ Les totaux incluent MONALUXE + PARTENAIRE
- ✅ Les valeurs individuelles (monaluxe, partenaire) sont séparées

---

## 📊 Vue KPI : `v_kpi_stock_depot` (à créer si nécessaire)

### Description

Agrégation des stocks par dépôt / produit / propriétaire pour les KPIs Dashboard.

### Colonnes (proposition)

| Colonne | Type | Description |
|---------|------|-------------|
| `depot_id` | `uuid` | ID du dépôt |
| `depot_nom` | `text` | Nom du dépôt |
| `produit_id` | `uuid` | ID du produit |
| `produit_nom` | `text` | Nom du produit |
| `proprietaire_type` | `text` | 'MONALUXE' ou 'PARTENAIRE' |
| `stock_total_ambiant` | `double precision` | Stock total ambiant (toutes citernes) |
| `stock_total_15c` | `double precision` | Stock total 15°C (toutes citernes) |
| `nb_citernes` | `integer` | Nombre de citernes concernées |
| `date_jour` | `date` | Date de référence |

### Usage

Pour les KPIs Dashboard qui affichent des totaux par dépôt.

---

## 📊 Vue KPI : `v_kpi_stock_proprietaire_global` (à créer si nécessaire)

### Description

Agrégation globale Monaluxe vs Partenaire, tout dépôt confondu.

### Colonnes (proposition)

| Colonne | Type | Description |
|---------|------|-------------|
| `proprietaire_type` | `text` | 'MONALUXE' ou 'PARTENAIRE' |
| `stock_total_ambiant` | `double precision` | Stock total ambiant (tous dépôts) |
| `stock_total_15c` | `double precision` | Stock total 15°C (tous dépôts) |
| `nb_citernes` | `integer` | Nombre de citernes concernées |
| `nb_depots` | `integer` | Nombre de dépôts concernés |
| `date_jour` | `date` | Date de référence |

### Usage

Pour les KPIs Dashboard qui comparent Monaluxe vs Partenaire globalement.

---

## 📊 Vue historique : `v_mouvements_stock`

### Description

Historique de tous les mouvements (réceptions et sorties) avec deltas.

### Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `date_jour` | `date` | Date du mouvement |
| `citerne_id` | `uuid` | ID de la citerne |
| `produit_id` | `uuid` | ID du produit |
| `depot_id` | `uuid` | ID du dépôt |
| `proprietaire_type` | `text` | 'MONALUXE' ou 'PARTENAIRE' |
| `delta_ambiant` | `double precision` | Delta ambiant (positif pour réceptions, négatif pour sorties) |
| `delta_15c` | `double precision` | Delta 15°C (positif pour réceptions, négatif pour sorties) |

### Usage

Pour les audits, analyses, et reconstruction des stocks.

---

## 📋 Table de base : `stocks_journaliers`

### Description

Table persistée jour par jour avec les stocks cumulés.

### Colonnes principales

| Colonne | Type | Description |
|---------|------|-------------|
| `citerne_id` | `uuid` | ID de la citerne |
| `produit_id` | `uuid` | ID du produit |
| `date_jour` | `date` | Date du jour |
| `proprietaire_type` | `text` | 'MONALUXE' ou 'PARTENAIRE' |
| `stock_ambiant` | `double precision` | Stock ambiant cumulé |
| `stock_15c` | `double precision` | Stock 15°C cumulé |
| `depot_id` | `uuid` | ID du dépôt |
| `source` | `text` | 'SYSTEM' ou ajustement manuel |

### Clé unique

`UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type)`

### Usage

Pour les écrans "Stock journalier" qui affichent l'historique jour par jour.

---

## 🔄 Flux de données recommandé

### Pour les écrans Citernes

```
v_stocks_citerne_global → StockService.getStocksParCiterne() → stocksParCiterneProvider → UI
```

### Pour les KPIs Dashboard

```
v_kpi_stock_depot (ou v_stocks_citerne_global) → StockService.getKpiStock() → kpiStockProvider → Dashboard
```

### Pour l'écran Stock Journalier

```
stocks_journaliers → StockService.getStocksParDate(date) → stocksParDateProvider → UI
```

### Pour les audits/analyses

```
v_mouvements_stock → StockService.getMouvements(...) → mouvementsProvider → UI
```

---

## ⚠️ Règles de stabilité

### Colonnes garanties stables

Les colonnes marquées "✅ Oui" dans `v_stocks_citerne_global` ne seront **jamais supprimées** sans :
1. Communication préalable au frontend
2. Migration planifiée
3. Mise à jour de cette documentation

### Ajout de colonnes

Les nouvelles colonnes peuvent être ajoutées sans casser l'existant (backward compatible).

### Modification de colonnes

Toute modification de type ou de signification d'une colonne existante doit être :
1. Documentée dans ce fichier
2. Communiquée au frontend
3. Testée en intégration

---

## 📝 Exemples de requêtes Flutter

### Exemple 1 : Récupérer tous les stocks par citerne

```dart
final stocks = await supabase
    .from('v_stocks_citerne_global')
    .select('*')
    .order('citerne_nom');
```

### Exemple 2 : Récupérer le stock d'une citerne spécifique

```dart
final stock = await supabase
    .from('v_stocks_citerne_global')
    .select('*')
    .eq('citerne_id', citerneId)
    .maybeSingle();
```

### Exemple 3 : Filtrer par dépôt

```dart
final stocks = await supabase
    .from('v_stocks_citerne_global')
    .select('*')
    .eq('depot_id', depotId);
```

### Exemple 4 : Récupérer uniquement les stocks MONALUXE (agrégation côté Flutter)

```dart
final stocks = await supabase
    .from('v_stocks_citerne_global')
    .select('*')
    .eq('depot_id', depotId);
// Puis filtrer côté Dart : stocks.where((s) => s['stock_ambiant_monaluxe'] > 0)
```

### Exemple 4 : Récupérer les stocks journaliers pour une date

```dart
final stocks = await supabase
    .from('stocks_journaliers')
    .select('*')
    .eq('date_jour', dateStr)
    .order('citerne_id');
```

---

## 🔗 Références

- Vue `v_mouvements_stock` : `supabase/migrations/2025-12-06_rebuild_stocks_offline.sql`
- Vue `v_stocks_citerne_global` : `supabase/migrations/2025-12-XX_views_stocks.sql` (à créer)
- Règles métier : `docs/db/stocks_rules.md`
- Phase 2 : `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md`


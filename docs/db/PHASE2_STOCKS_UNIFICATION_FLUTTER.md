# Phase 2 - Unification Flutter sur la vérité unique Stock

**Projet** : ML_PP MVP — Module Stock / Sorties / Réceptions  
**Date** : 06/12/2025  
**Prérequis** : Phase 1 complétée ✅

---

## 🎯 Objectifs de la Phase 2

### Objectif global

👉 Faire en sorte que toute l'app (écrans + KPI) lise les stocks à partir de la même vérité unique :

```
stocks_journaliers → v_stocks_citerne_global → services Dart → UI / KPI
```

### Objectifs détaillés

Phase 2 doit garantir que :

1. **Tous les écrans qui affichent du stock** (Citernes, Stock, Dashboard, éventuellement Réception/Sortie détail)
   - lisent leurs données à partir de `v_stocks_citerne_global` (ou vues dérivées).

2. **Les KPIs de stock** (par citerne, par propriétaire, par produit, par dépôt)
   - soient exactement cohérents avec :
     - les mouvements `receptions` / `sorties_produit`
     - les données de `stocks_journaliers`.

3. **Le code Flutter ait** :
   - une couche de service unique pour le stock (ex: `StockRepository`/`StockService`)
   - aucune requête "custom" dispersée qui recalcule le stock à la main côté app.

4. **La solution reste maintenable et scalable** :
   - demain on ajoute un autre dépôt, d'autres produits, d'autres KPIs → rien à réécrire côté logique, juste consommer les vues.

---

## 🧭 Plan détaillé Phase 2 (ordre suggéré)

### 🔹 Étape 2.1 — Figer le contrat SQL "vérité unique stock"

**But** : Définir une interface SQL stable que l'app pourra consommer longtemps.

#### Actions

1. **Valider officiellement que la base de travail pour l'app est** :
   - `v_mouvements_stock` = historique des mouvements (pour audits / analyse)
   - `stocks_journaliers` = base persistée jour par jour
   - `v_stocks_citerne_global` = vue principale de stock instantané par citerne / produit / propriétaire + total

2. **Si besoin, créer une vue supplémentaire dédiée KPIs**, par exemple :
   - `v_kpi_stock_depot` (agrégation par dépôt / produit / propriétaire)
   - `v_kpi_stock_proprietaire_global` (Monaluxe vs Partenaire, tout dépôt confondu)

3. **Documenter ces vues** (dans `docs/db/`) :
   - colonnes, signification, exemples d'usage
   - ce qui est garanti stable (contrat pour le frontend).

#### Livrables

- [ ] Vue `v_stocks_citerne_global` créée et documentée
- [ ] Vues KPI créées si nécessaire (`v_kpi_stock_depot`, `v_kpi_stock_proprietaire_global`)
- [ ] Documentation des vues dans `docs/db/stocks_views_contract.md`

#### Fichiers à créer/modifier

- `supabase/migrations/2025-12-XX_views_stocks.sql` (mise à jour avec vues KPI si nécessaire)
- `docs/db/stocks_views_contract.md` (nouveau)

---

### 🔹 Étape 2.2 — Créer un service Flutter unique de lecture du stock

**But** : Arrêter les requêtes "sauvages" dans les widgets.

#### Actions

1. **Créer un `StockService` / `StockRepository` dans Flutter** (dans `features/stocks/` ou équivalent) :
   - méthode `getStocksParCiterne(...)` → lit `v_stocks_citerne_global`
   - méthodes dérivées :
     - `getStockDepotGlobal(depotId, date)`
     - `getStockParProprietaire(depotId, proprietaireType, date)`
     - `getStockParProduit(...)` si nécessaire

2. **Créer les providers Riverpod associés** :
   - `stocksParCiterneProvider`
   - `stockDepotGlobalProvider`
   - `kpiStockProvider` (si on veut un provider dédié KPI)

3. **Décision importante** :
   - On garde toute la logique de calcul côté SQL
   - Côté Flutter, on ne fait que de l'agrégation/simple mapping, pas de recalcul de stock.

#### Livrables

- [ ] `StockService` créé avec toutes les méthodes nécessaires
- [ ] Providers Riverpod créés
- [ ] Tests unitaires pour `StockService` (mocks Supabase)

#### Fichiers à créer/modifier

- `lib/features/stocks/data/stock_service.dart` (nouveau ou refactor)
- `lib/features/stocks/providers/stock_providers.dart` (nouveau)
- `test/features/stocks/data/stock_service_test.dart` (nouveau)

---

### 🔹 Étape 2.3 — Rebrancher le module Citernes sur le nouveau service

**But** : L'écran Citernes doit refléter exactement `v_stocks_citerne_global`.

#### Actions

1. **Identifier les écrans concernés** :
   - `CiterneListScreen`
   - `CiterneDetailScreen`
   - widget du dashboard citernes

2. **Remplacer l'ancienne source de données par** :
   - `stocksParCiterneProvider` → qui interroge `v_stocks_citerne_global`.

3. **Normaliser ce qu'on affiche** :
   - Stock ambiant total
   - Stock à 15°C total
   - Possiblement séparation Monaluxe / Partenaire si l'UI le demande.

4. **Vérifier manuellement que pour** :
   - TANK1 / Gasoil
   - TANK2 / Gasoil
   - les chiffres affichés = ceux de la vue SQL.

#### Livrables

- [ ] `CiterneListScreen` utilise `stocksParCiterneProvider`
- [ ] `CiterneDetailScreen` utilise `stocksParCiterneProvider`
- [ ] Widget dashboard citernes utilise `stocksParCiterneProvider`
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

#### Fichiers à modifier

- `lib/features/citernes/providers/citerne_providers.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/citernes/screens/citerne_detail_screen.dart` (si existe)
- `lib/features/dashboard/widgets/citernes_alertes.dart` (si existe)

---

### 🔹 Étape 2.4 — Rebrancher le module "Stocks / Inventaire" sur la vérité unique

**But** : Que le module Stock (ou écran "Stock journalier") consomme `stocks_journaliers` / `v_stocks_citerne_global`.

#### Actions

1. **Si tu as un écran "Stock du jour / par date"** :
   - Ajouter un provider `stocksParDateProvider(date)` basé sur `stocks_journaliers`
   - Ou une vue SQL `v_stocks_journaliers_det` si besoin.

2. **Remplacer toute logique type** :
   - `sum(receptions) - sum(sorties)` côté Dart
   - par un simple `SELECT` sur `stocks_journaliers` / vues dérivées.

3. **Ajouter une possibilité de filtre** :
   - par dépôt
   - par produit
   - par propriétaire.

#### Livrables

- [ ] `StocksListScreen` utilise `stocks_journaliers` directement
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres (dépôt, produit, propriétaire) fonctionnels

#### Fichiers à modifier

- `lib/features/stocks_journaliers/providers/stocks_providers.dart`
- `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`

---

### 🔹 Étape 2.5 — Rebrancher les KPIs Dashboard sur les vues

**But** : Les cartes KPI ne doivent plus recoder de la logique métier.

#### Actions

1. **Lister les KPI stock existants** (d'après tes captures) :
   - Exemple :
     - Stock total dépôt
     - Stock Monaluxe
     - Stock Partenaires
     - Stock par citerne
     - Variation vs J-1 (si déjà prévu)

2. **Pour chaque KPI, définir exactement** :
   - de quelle vue SQL il dépend (`v_stocks_citerne_global` / `v_kpi_stock_depot`)
   - quelle période (date du jour, date max, J-1, etc.)

3. **Côté Flutter** :
   - créer un `kpiStockProvider` qui:
     - fait 1 ou 2 requêtes SQL ciblées
     - retourne un DTO `StockKpiModel` avec toutes les valeurs nécessaires.

4. **Rebrancher chaque carte du Dashboard sur `kpiStockProvider`**
   - → plus aucun calcul manuel dans les widgets.

#### Livrables

- [ ] `kpiStockProvider` créé avec DTO `StockKpiModel`
- [ ] Toutes les cartes Dashboard utilisent `kpiStockProvider`
- [ ] Suppression de toute logique de calcul dans les widgets Dashboard

#### Fichiers à créer/modifier

- `lib/features/kpi/providers/stock_kpi_provider.dart` (nouveau ou refactor)
- `lib/features/kpi/models/stock_kpi_model.dart` (nouveau)
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- `lib/features/dashboard/widgets/kpi_card.dart`

---

### 🔹 Étape 2.6 — Harmonisation de l'affichage dans Réceptions / Sorties

**But** : Quand on affiche un stock ou un effet sur stock dans ces écrans, ce doit être cohérent avec le reste.

#### Actions

1. **Sur les écrans** :
   - Détail Réception
   - Détail Sortie
   - éventuellement formulaire (stock avant / après)

2. **Vérifier que lorsqu'on montre un "stock actuel"** :
   - on lit bien depuis le même provider de stock,
   - et pas depuis `sum(...)` local sur la liste.

3. **Option à discuter (peut être Phase 3)** :
   - montrer l'impact théorique d'une nouvelle sortie sur le stock en temps réel
   - via `stock_actuel - volume_sortie`.

#### Livrables

- [ ] Écrans Réception/Sortie utilisent `stocksParCiterneProvider` pour afficher le stock
- [ ] Cohérence vérifiée avec les autres écrans

#### Fichiers à modifier

- `lib/features/receptions/screens/reception_screen.dart` (si affiche stock)
- `lib/features/sorties/screens/sortie_detail_screen.dart` (si affiche stock)

---

### 🔹 Étape 2.7 — Tests et garde-fous

**But** : Ne plus jamais retomber dans le bazar qu'on vient de régler.

#### Actions

1. **Ajouter des tests SQL ou scripts de contrôle** :
   - Comparer `sum(delta)` de `v_mouvements_stock` vs `v_stocks_citerne_global` (ce qu'on a déjà fait)
   - Script simple à relancer à chaque grosse migration.

2. **Ajouter des tests Dart (unit + integration)** :
   - `StockService` → mock Supabase, vérifier qu'un JSON donné produit les bons KPIs
   - Tests widget du Dashboard pour vérifier que les valeurs sont bien rendues.

3. **Ajouter une petite page "debug stock" (interne admin uniquement)** :
   - affiche les valeurs brutes de `v_stocks_citerne_global`
   - permet de voir en live si l'app lit bien les mêmes chiffres que Supabase Dashboard.

#### Livrables

- [ ] Script SQL de validation créé
- [ ] Tests unitaires `StockService` créés
- [ ] Tests widget Dashboard créés
- [ ] Page debug stock créée (optionnel)

#### Fichiers à créer

- `scripts/validate_stocks.sql` (nouveau)
- `test/features/stocks/data/stock_service_test.dart` (nouveau)
- `test/features/dashboard/widgets/dashboard_stocks_test.dart` (nouveau)
- `lib/features/stocks/screens/stocks_debug_screen.dart` (optionnel)

---

## ✅ Résumé Phase 2 en une phrase

**Phase 2 = tout brancher (UI + KPI) sur la même "vérité stock" basée sur `stocks_journaliers` et `v_stocks_citerne_global`, via un service unique dans Flutter.**

---

## 📋 Checklist Phase 2

### Étape 2.1 - Contrat SQL
- [ ] Vue `v_stocks_citerne_global` créée et documentée
- [ ] Vues KPI créées si nécessaire
- [ ] Documentation des vues dans `docs/db/stocks_views_contract.md`

### Étape 2.2 - Service Flutter unique
- [ ] `StockService` créé avec toutes les méthodes nécessaires
- [ ] Providers Riverpod créés
- [ ] Tests unitaires pour `StockService`

### Étape 2.3 - Module Citernes
- [ ] `CiterneListScreen` utilise `stocksParCiterneProvider`
- [ ] `CiterneDetailScreen` utilise `stocksParCiterneProvider`
- [ ] Widget dashboard citernes utilise `stocksParCiterneProvider`
- [ ] Vérification manuelle : valeurs affichées = valeurs SQL

### Étape 2.4 - Module Stocks
- [ ] `StocksListScreen` utilise `stocks_journaliers` directement
- [ ] Suppression de toute logique de calcul côté Dart
- [ ] Filtres (dépôt, produit, propriétaire) fonctionnels

### Étape 2.5 - KPIs Dashboard
- [ ] `kpiStockProvider` créé avec DTO `StockKpiModel`
- [ ] Toutes les cartes Dashboard utilisent `kpiStockProvider`
- [ ] Suppression de toute logique de calcul dans les widgets Dashboard

### Étape 2.6 - Harmonisation Réceptions/Sorties
- [ ] Écrans Réception/Sortie utilisent `stocksParCiterneProvider` pour afficher le stock
- [ ] Cohérence vérifiée avec les autres écrans

### Étape 2.7 - Tests et garde-fous
- [ ] Script SQL de validation créé
- [ ] Tests unitaires `StockService` créés
- [ ] Tests widget Dashboard créés
- [ ] Page debug stock créée (optionnel)

---

## 📁 Fichiers à créer/modifier

### Migrations SQL
- `supabase/migrations/2025-12-XX_views_stocks.sql` (mise à jour avec vues KPI si nécessaire)

### Documentation
- `docs/db/stocks_views_contract.md` (nouveau - contrat des vues SQL)
- `docs/db/PHASE2_STOCKS_UNIFICATION_FLUTTER.md` (ce fichier)

### Code Flutter - Services
- `lib/features/stocks/data/stock_service.dart` (nouveau ou refactor)
- `lib/features/stocks/providers/stock_providers.dart` (nouveau)

### Code Flutter - Modules à refactorer
- `lib/features/citernes/providers/citerne_providers.dart`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/stocks_journaliers/providers/stocks_providers.dart`
- `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`
- `lib/features/kpi/providers/stock_kpi_provider.dart` (nouveau ou refactor)
- `lib/features/kpi/models/stock_kpi_model.dart` (nouveau)
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- `lib/features/dashboard/widgets/kpi_card.dart`

### Tests
- `test/features/stocks/data/stock_service_test.dart` (nouveau)
- `test/features/dashboard/widgets/dashboard_stocks_test.dart` (nouveau)
- `scripts/validate_stocks.sql` (nouveau)

---

## 🔗 Références

- Phase 1 : `docs/rapports/PHASE1_STOCKS_STABILISATION_2025-12-06.md`
- Règles métier : `docs/db/stocks_rules.md`
- Plan global : `docs/db/stocks_engine_migration_plan.md`
- Vue `v_mouvements_stock` : `supabase/migrations/2025-12-06_rebuild_stocks_offline.sql`


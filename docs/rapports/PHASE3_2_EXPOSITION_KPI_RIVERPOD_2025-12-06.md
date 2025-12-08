# Rapport - Phase 3.2 : Exposition des KPIs via Riverpod

**Projet** : ML_PP MVP — Module Stock / Sorties / Réceptions  
**Date** : 06/12/2025  
**Prérequis** : Phase 3.1 complétée ✅ (StocksKpiRepository créé)

---

## 🎯 Objectif

Isoler toute la logique d'accès aux vues KPI (SQL) derrière des providers Riverpod, afin que le Dashboard et les écrans ne parlent plus directement à Supabase.

---

## 1️⃣ Fichier créé

### `lib/features/stocks/data/stocks_kpi_providers.dart`

**But** : Centraliser tous les providers Riverpod pour les KPI de stock basés sur les vues SQL.

**Contenu** :
- Provider du repository
- 4 providers principaux pour les KPIs et snapshots
- 2 providers `.family` pour le filtrage

---

## 2️⃣ Providers mis en place

### 2.1. Provider du repository

#### `stocksKpiRepositoryProvider`

- **Type** : `Provider<StocksKpiRepository>`
- **Injection** : Utilise `supabaseClientProvider` (depuis `lib/data/repositories/repositories.dart`)
- **Avantages** :
  - Injection propre et testable
  - Override facile dans les tests
  - Source unique du client Supabase

---

### 2.2. Providers pour KPIs globaux (niveau dépôt)

#### `kpiGlobalStockProvider`

- **Type** : `FutureProvider<List<DepotGlobalStockKpi>>`
- **Source SQL** : `v_kpi_stock_global`
- **Méthode repository** : `fetchDepotProductTotals()`
- **Usage** : Fournit la liste des KPI de stock par dépôt/produit (tous propriétaires confondus)

#### `kpiStockByOwnerProvider`

- **Type** : `FutureProvider<List<DepotOwnerStockKpi>>`
- **Source SQL** : `v_kpi_stock_owner`
- **Méthode repository** : `fetchDepotOwnerTotals()`
- **Usage** : Fournit les KPI de stock par dépôt + `proprietaire_type` (MONALUXE / PARTENAIRE)

---

### 2.3. Providers pour snapshots par citerne

#### `kpiStocksByCiterneOwnerProvider`

- **Type** : `FutureProvider<List<CiterneOwnerStockSnapshot>>`
- **Source SQL** : `v_stocks_citerne_owner`
- **Méthode repository** : `fetchCiterneOwnerSnapshots()`
- **Usage** : Retourne les snapshots par citerne + `proprietaire_type` (Monaluxe vs Partenaire par tank)

#### `kpiStocksByCiterneGlobalProvider`

- **Type** : `FutureProvider<List<CiterneGlobalStockSnapshot>>`
- **Source SQL** : `v_stocks_citerne_global`
- **Méthode repository** : `fetchCiterneGlobalSnapshots()`
- **Usage** : Retourne les snapshots globaux par citerne (tous propriétaires confondus)

---

## 3️⃣ Providers `.family` pour filtrage

### 3.1. `kpiGlobalStockByDepotProvider`

- **Type** : `FutureProvider.family<DepotGlobalStockKpi?, String>`
- **Filtrage** : Côté Dart (s'appuie sur `kpiGlobalStockProvider`)
- **Usage** : Utile pour les écrans Dashboard filtrés par dépôt

### 3.2. `kpiCiterneOwnerByDepotProvider`

- **Type** : `FutureProvider.family<List<CiterneOwnerStockSnapshot>, String>`
- **Filtrage** : Côté SQL (via le repository avec paramètre `depotId`)
- **Usage** : Permet d'afficher les stocks par citerne/propriétaire dans un dépôt donné, sans logique SQL côté UI

---

## 4️⃣ Corrections & ajustements techniques

### 4.1. Résolution des conflits d'import

- **Problème** : Conflit de nom entre `Provider` de Riverpod et `Provider` de Supabase
- **Solution** : Utilisation de l'alias `riverpod` pour `flutter_riverpod`
- **Code** : `import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;`

### 4.2. Nettoyage des imports

- **Suppression** : Import inutile `supabase_flutter` (non utilisé directement)

### 4.3. Alignement sur les méthodes du repository

Les providers utilisent les méthodes correctes de `StocksKpiRepository` :
- `fetchDepotProductTotals()` (pas `fetchGlobalStockByDepot()`)
- `fetchDepotOwnerTotals()` (pas `fetchStockByOwner()`)
- `fetchCiterneOwnerSnapshots()` (pas `fetchStockByCiterneAndOwner()`)
- `fetchCiterneGlobalSnapshots()` (pas `fetchGlobalStockByCiterne()`)

### 4.4. Source unique du client Supabase

- **Utilisation** : `supabaseClientProvider` depuis `lib/data/repositories/repositories.dart`
- **Avantage** : Cohérence avec le reste de l'architecture

---

## 5️⃣ Validation

### 5.1. Analyse Flutter

- ✅ **Résultat** : Aucune erreur détectée
- ✅ **Commande** : `flutter analyze lib/features/stocks/data/stocks_kpi_providers.dart`

### 5.2. Vérifications structurelles

- ✅ Tous les providers pointent vers les méthodes correctes du repository
- ✅ Structure cohérente avec le reste de l'architecture (pattern repository + providers Riverpod)
- ✅ Pas de dépendance directe à Supabase dans les écrans (via ces providers)

---

## 6️⃣ Impact et bénéfices

### 6.1. Séparation des responsabilités

- **Avant** : Les écrans interrogeaient directement Supabase
- **Après** : Les écrans consomment uniquement les providers Riverpod

### 6.2. Testabilité

- **Avant** : Difficile de mocker les appels Supabase dans les tests
- **Après** : Override facile des providers dans les tests

### 6.3. Maintenabilité

- **Avant** : Logique SQL dispersée dans les écrans
- **Après** : Logique centralisée dans le repository, exposée via providers

### 6.4. Scalabilité

- **Avant** : Chaque écran devait gérer ses propres requêtes
- **Après** : Réutilisation des providers dans tous les écrans

---

## 7️⃣ Prochaines étapes (Phase 3.3)

Le Dashboard et les autres écrans peuvent désormais consommer ces providers sans requête SQL directe ni dépendance à Supabase.

**Phase 3.3** : Rebrancher le Dashboard Admin sur ces nouveaux providers.

---

## 📁 Fichiers créés/modifiés

### Fichiers créés

- ✅ `lib/features/stocks/data/stocks_kpi_providers.dart` - Tous les providers Riverpod pour les KPI de stock

### Fichiers utilisés (non modifiés)

- `lib/data/repositories/stocks_kpi_repository.dart` - Repository utilisé par les providers
- `lib/data/repositories/repositories.dart` - Source de `supabaseClientProvider`

---

## 🔗 Références

- Phase 3.1 : `lib/data/repositories/stocks_kpi_repository.dart`
- Plan Phase 3 : `docs/db/PHASE3_FLUTTER_RECONNEXION_STOCKS.md`
- Contrat SQL : `docs/db/stocks_views_contract.md`

---

**Fin du rapport Phase 3.2**


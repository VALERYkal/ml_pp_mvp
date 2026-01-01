# Inventaire des Usages Legacy Stock

**Date** : 2025-12-27  
**Version** : 2.0 (Mise à jour 01/01/2026)  
**Objectif** : Inventaire exhaustif des usages des vues legacy stock pour planifier la migration vers `v_stock_actuel` (source de vérité unique)

---

## 📋 Résumé exécutif

| Vue SQL | Type | Occurrences | Statut |
|---------|------|-------------|--------|
| `v_stock_actuel` | 🟢 CANONIQUE | Tous modules | ✅ **SOURCE DE VÉRITÉ UNIQUE** (01/01/2026) |
| `v_citerne_stock_snapshot_agg` | 🔶 LEGACY | 0 | ✅ **MIGRÉ** vers `v_stock_actuel` (01/01/2026) |
| `v_stock_actuel_snapshot` | 🔶 LEGACY | 0 | ✅ **MIGRÉ** vers `v_stock_actuel` (01/01/2026) |
| `v_stock_actuel_owner_snapshot` | 🔶 LEGACY | 0 | ✅ **MIGRÉ** vers `v_stock_actuel` (01/01/2026) |
| `stock_actuel` | 🔶 LEGACY | 0 | ✅ **MIGRÉ** vers `v_stock_actuel` (01/01/2026) |
| `v_citerne_stock_actuel` | 🔶 LEGACY | 0 | ✅ **MIGRÉ** vers `v_stock_actuel` (01/01/2026) |

**État** : ✅ **MIGRATION COMPLÈTE TERMINÉE** (01/01/2026)

Tous les modules utilisent désormais `v_stock_actuel` comme source de vérité unique :
- ✅ Dashboard : `depotGlobalStockFromSnapshotProvider`, `depotOwnerStockFromSnapshotProvider`
- ✅ Citernes : `CiterneRepository.fetchCiterneStockSnapshots()`
- ✅ Module Stock : `StocksRepository.totauxActuels()`
- ✅ Méthode canonique : `StocksKpiRepository.fetchStockActuelRows()`

---

## 📊 Inventaire détaillé

### 1. stock_actuel (LEGACY)

**Statut** : 🔶 LEGACY (journalier)  
**Remplacement cible** : `v_stock_actuel_snapshot` ou `v_citerne_stock_snapshot_agg`

| Fichier Dart | Ligne | Méthode/Provider | Module | Usage | Priorité migration |
|--------------|-------|------------------|--------|-------|-------------------|
| `lib/features/sorties/providers/sortie_providers.dart` | ~205 | `_loadStockActuel()` (helper privée) | Sorties | Stock affiché dans formulaire sortie | 🔴 Haute |
| `lib/features/citernes/providers/citerne_providers.dart` | ~319 | `citernesWithStockProvider` (legacy) | Citernes | Provider legacy @Deprecated | 🟡 Moyenne |
| `lib/features/citernes/data/citerne_service.dart` | ~61 | `getStockActuel()` (@Deprecated) | Citernes | Service legacy, utilisé par ReceptionService | 🟡 Moyenne |

**Détails** :
- **Sorties** : Utilisé pour afficher le "dernier stock" dans le formulaire de création de sortie
  - ⚠️ **Impact utilisateur** : Le stock affiché peut être obsolète si aucune écriture journalière n'a eu lieu aujourd'hui
  - 🔄 **Migration** : Remplacer par `v_stock_actuel_snapshot` pour afficher le stock réel temps présent

- **Citernes (legacy)** : Providers/services déjà marqués @Deprecated
  - ✅ **Impact** : Faible, déjà remplacés par `v_citerne_stock_snapshot_agg` dans l'UI
  - 🔄 **Migration** : Supprimer après vérification que ReceptionService n'en dépend plus

---

### 2. v_citerne_stock_actuel (LEGACY)

**Statut** : 🔶 LEGACY (journalier)  
**Remplacement cible** : `v_citerne_stock_snapshot_agg` ou `v_kpi_stock_global`

| Fichier Dart | Ligne | Méthode/Provider | Module | Usage | Statut |
|--------------|-------|------------------|--------|-------|--------|
| `lib/data/repositories/stocks_repository.dart` | ~40 | `fetchTotauxStocks()` | Stocks | Totaux stocks par dépôt | 🔴 À migrer |
| `lib/features/dashboard/providers/admin_kpi_provider.dart` | ~65 | `citernesSousSeuilProvider` | Dashboard | Citernes sous seuil (KPI) | ✅ Migré (A-FLT-02) |
| `lib/features/dashboard/providers/directeur_kpi_provider.dart` | ~76 | `directeurKpisProvider` | Dashboard | Citernes sous seuil (KPI) | ✅ Migré (A-FLT-02) |
| `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart` | ~15 | `citernesSousSeuilProvider` | Dashboard | Citernes sous seuil (widget) | ✅ Migré (A-FLT-02) |

**Détails** :
- **Dashboard KPI** : Tous les providers "citernes sous seuil" utilisent cette vue legacy
  - ⚠️ **Impact utilisateur** : KPI Dashboard peut afficher des valeurs incorrectes si le journalier n'est pas à jour
  - 🔄 **Migration** : Remplacer par `v_citerne_stock_snapshot_agg` pour avoir le stock réel temps présent

- **Stocks Repository** : Méthode `fetchTotauxStocks()` utilisée pour les totaux par dépôt
  - 🔄 **Migration** : Remplacer par agrégation depuis `v_stock_actuel_snapshot` ou utiliser `v_kpi_stock_global`

---

### 3. v_stock_actuel_owner_snapshot (LEGACY "pseudo snapshot")

**Statut** : 🟡 LEGACY (journalier mais nommé "snapshot")  
**Remplacement cible** : Vue owner snapshot-based à créer (basée sur `v_stock_actuel_snapshot`)

| Fichier Dart | Ligne | Méthode/Provider | Module | Usage | Priorité migration |
|--------------|-------|------------------|--------|-------|-------------------|
| `lib/data/repositories/stocks_kpi_repository.dart` | ~247 | `fetchDepotOwnerTotals()` | Stocks | Breakdown stock par propriétaire | 🟡 Moyenne |
| `lib/data/repositories/stocks_kpi_repository.dart` | ~366 | `fetchDepotOwnerStocksFromSnapshot()` (deprecated alias) | Stocks | Alias deprecated | 🟢 Basse |

**Détails** :
- **Stocks Repository** : Utilisé pour le breakdown MONALUXE vs PARTENAIRE
  - ⚠️ **Impact** : Vue basée sur journalier, peut avoir un décalage si pas de ligne journalière récente
  - 🔄 **Migration** : Créer une vue owner snapshot-based ou agréger depuis `v_stock_actuel_snapshot`
  - 📝 **Note** : Une méthode est déjà deprecated (`fetchDepotOwnerStocksFromSnapshot`), migration en cours

---

### 4. v_kpi_stock_global (CANONIQUE - snapshot-based)

**Statut** : 🟢 CANONIQUE (snapshot-based, OK)  
**Remplacement** : Aucun, c'est déjà la bonne vue

| Fichier Dart | Ligne | Méthode/Provider | Module | Usage | Statut |
|--------------|-------|------------------|--------|-------|--------|
| `lib/data/repositories/stocks_kpi_repository.dart` | ~213 | `fetchDepotGlobalStocks()` | Stocks | KPI stock global par dépôt | ✅ OK |

**Détails** :
- ✅ **Statut** : Vue canonique, snapshot-based
- ✅ **Usage** : Correct, pas de migration nécessaire
- ℹ️ **Note** : Vérifier que la vue est bien snapshot-based (basée sur `v_stock_actuel_snapshot`)

---

## 🎯 Plan de migration priorisé

### ✅ **MIGRATION COMPLÈTE TERMINÉE** (01/01/2026)

Tous les modules utilisent désormais `v_stock_actuel` comme source de vérité unique :

1. ✅ **Dashboard** : `depotGlobalStockFromSnapshotProvider`, `depotOwnerStockFromSnapshotProvider`
   - **Fichier** : `lib/features/stocks/data/stocks_kpi_providers.dart`
   - **Méthode** : Utilisent `StocksKpiRepository.fetchStockActuelRows()` avec agrégation Dart
   - **Impact** : Stock réel incluant ajustements visible immédiatement

2. ✅ **Module Citernes** : `CiterneRepository.fetchCiterneStockSnapshots()`
   - **Fichier** : `lib/features/citernes/data/citerne_repository.dart`
   - **Méthode** : Lit depuis `v_stock_actuel` et agrège par `citerne_id` (tous propriétaires confondus)
   - **Impact** : Affichage correct du stock réel (31 253 L au lieu de 30 400 L)

3. ✅ **Module Stock** : `StocksRepository.totauxActuels()`
   - **Fichier** : `lib/data/repositories/stocks_repository.dart`
   - **Méthode** : Lit depuis `v_stock_actuel` avec agrégation Dart
   - **Impact** : Totaux cohérents avec Dashboard et Citernes

4. ✅ **Méthode canonique** : `StocksKpiRepository.fetchStockActuelRows()`
   - **Fichier** : `lib/data/repositories/stocks_kpi_repository.dart`
   - **Usage** : Méthode centrale utilisée par tous les modules
   - **Impact** : Source unique garantissant la cohérence

### 📝 **Nettoyage restant** (non bloquant)

- ⏳ Commentaires et documentation à mettre à jour (références legacy)
- ⏳ Providers legacy @Deprecated à supprimer après vérification (non utilisés)
   - **Action** : Supprimer après migration des callers
   - **Impact** : Aucun (déjà deprecated)

---

## 🧪 Baseline Tests

### Commande d'inventaire

**Script automatique** :
```bash
./tools/stock_inventory.sh
```

**Commande ripgrep manuelle** :
```bash
# Recherche toutes les occurrences
rg "\.from\(['\"]stock_actuel|\.from\(['\"]v_citerne_stock_actuel|\.from\(['\"]v_stock_actuel_owner_snapshot|\.from\(['\"]v_kpi_stock_global" lib/
```

**Résultats** : 10 occurrences trouvées (détail ci-dessus)

**Date inventaire** : 2025-12-27

---

## 🧪 Baseline Tests Flutter

### Commande à exécuter

```bash
cd /Users/val/Documents/ml_pp_mvp
flutter test > tests_baseline_2025-12-27.txt 2>&1
```

### Résultat

⚠️ **À exécuter manuellement** : La baseline de tests doit être exécutée localement et le résultat collé ici.

**Date baseline** : À compléter  
**Commande** : `flutter test`  
**Résultat** : Voir fichier `tests_baseline_2025-12-27.txt` ou coller ci-dessous

```bash
# Résultat à coller ici après exécution
# 
# Exemple format attendu :
# +[X tests passed, Y failed]
# [liste des tests avec résultats]
```

### 📌 Instructions

1. **Exécuter les tests** : `flutter test > tests_baseline_2025-12-27.txt 2>&1`
2. **Vérifier le résultat** : Lire `tests_baseline_2025-12-27.txt`
3. **Mettre à jour ce document** : Copier le contenu pertinent dans la section ci-dessus
4. **Conserver le fichier** : Garder `tests_baseline_2025-12-27.txt` comme référence

**Note** : Cette baseline servira à détecter toute régression lors des migrations futures.

---

## 📝 Notes de migration

### Règles à respecter

1. **Ne jamais filtrer `v_stock_actuel_snapshot` par date** (représente l'état actuel)
2. **Colonnes différentes** : `stock_ambiant` vs `stock_ambiant_total` (voir `_safeDouble()` pour compatibilité)
3. **Migration progressive** : Migrer un module à la fois, tester après chaque migration
4. **Vérifier les tests** : S'assurer que les tests passent après chaque migration

### Checklist de migration

Avant de migrer :
- [ ] Identifier tous les usages du fichier (grep local)
- [ ] Comprendre les colonnes consommées
- [ ] Choisir la vue canonique de remplacement
- [ ] Tester l'affichage reste cohérent

Après migration :
- [ ] Vérifier `flutter analyze` = 0 erreur
- [ ] Vérifier `flutter test` = pas de régression
- [ ] Tester manuellement l'écran/module concerné
- [ ] Mettre à jour cet inventaire

---

## 🔗 Références

- **Documentation vues SQL** : `docs/db/vues_sql_reference.md`
- **Cartographie par modules** : `docs/db/modules_flutter_db_map.md`
- **Documentation centralisée** : `docs/db/vues_sql_reference_central.md`

---

**Dernière mise à jour** : 2025-12-27


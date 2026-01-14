# 📦 Contrat de Vérité — Stock Actuel & KPI (AXE A)

**Statut** : 🟢 VALIDÉ & STABLE  
**Date de création** : 2026-01-13  
**Version** : 1.0  
**NE PAS MODIFIER SANS VALIDATION ARCHITECTURE**

---

## 1. Objectif du contrat

Ce document définit la **source de vérité officielle** pour :

- Le stock actuel (état temps réel)
- L'affichage des citernes dans l'UI
- Les KPI (global, par propriétaire, par citerne)
- Le routing actuel vs historique (journalier)

**Toute nouvelle implémentation DOIT respecter ce contrat.**

Ce contrat a été **validé avec des données réelles** (réceptions + sorties) et est considéré comme **stable** pour le MVP.

---

## 2. Source de vérité — v_stock_actuel

### Principe fondamental

> **Toute lecture de stock "actuel" dans l'application DOIT passer par `v_stock_actuel`.**

### Caractéristiques

- **`v_stock_actuel`** = état temps réel du stock (pas de snapshot, pas de filtrage par date)
- **1 ligne** = `(depot_id, citerne_id, produit_id, proprietaire_type)`
- **Mis à jour automatiquement** par :
  - Réception validée → mise à jour immédiate
  - Sortie validée → mise à jour immédiate
  - Ajustement validé → mise à jour immédiate
- **Aucun filtrage par date** : snapshot live, toujours à jour

### Structure de données

Chaque ligne de `v_stock_actuel` expose :
- `citerne_id` (UUID) — Identifiant de la citerne
- `citerne_nom` (TEXT) — **⚠️ Peut être incohérent** (utiliser table `citernes.nom` comme source de vérité)
- `produit_id` (UUID) — Identifiant du produit
- `produit_nom` (TEXT) — Nom du produit
- `depot_id` (UUID) — Identifiant du dépôt
- `depot_nom` (TEXT) — Nom du dépôt
- `proprietaire_type` (TEXT) — Type de propriétaire (MONALUXE, PARTENAIRE)
- `stock_ambiant` (NUMERIC) — Stock à température ambiante
- `stock_15c` (NUMERIC) — Stock corrigé à 15°C
- `updated_at` (TIMESTAMP) — Date de dernière mise à jour

### Agrégation côté application

Le stock total d'une citerne = **somme de TOUTES les lignes** de `v_stock_actuel` ayant le même `citerne_id`, **tous propriétaires confondus**.

**Exemple** :
- TANK1 MONALUXE : 3000 L
- TANK1 PARTENAIRE : 1850 L
- **Stock total TANK1** : 4850 L (agrégation Dart)

---

## 3. UI Citernes — Mapping validé

### Comportement actuel

L'écran "Citernes" consomme `v_stock_actuel` via agrégation Dart dans `CiterneRepository.fetchCiterneStockSnapshots()`.

### Mapping citerne_id → nom

**Source de vérité pour le nom** : Table `citernes.nom` (jamais `v_stock_actuel.citerne_nom`)

**Implémentation** :
1. Agrégation des stocks par `citerne_id` depuis `v_stock_actuel`
2. Récupération des métadonnées (nom, capacités) depuis table `citernes`
3. Construction des snapshots avec `citerneNom` provenant de `citernes.nom`
4. Log debug si mismatch entre `v_stock_actuel.citerne_nom` et `citernes.nom`

### Volumes affichés

Les volumes affichés sont la **somme de TOUS les propriétaires** pour chaque citerne.

**Exemple** :
- CITERNE 1 (TANK1) : 4850 L / 4828.03 L (MONALUXE + PARTENAIRE)
- CITERNE 6 (TANK6) : 1000 L / 996.1 L (MONALUXE + PARTENAIRE)

### Libellé "CITERNE X"

Le numéro affiché correspond au **numéro réel extrait du nom de la citerne** (pas l'index dans la liste).

**Exemple** :
- "TANK1" → affiche "CITERNE 1"
- "TANK6" → affiche "CITERNE 6"

✅ **VALIDÉ** : Les volumes affichés correspondent à la bonne citerne après mouvements réels (réception + sorties).

---

## 4. Contrat KPI — Actuel vs Journalier

### Routing selon dateJour

Le paramètre `dateJour` détermine la source de données utilisée :

| Méthode | `dateJour == null` | `dateJour != null` |
|---------|-------------------|-------------------|
| `fetchDepotProductTotals` | `v_stock_actuel` | `stocks_journaliers` |
| `fetchDepotOwnerTotals` | `v_stock_actuel` | `stocks_journaliers` |
| `fetchCiterneGlobalSnapshots` | `v_stock_actuel` | `v_stocks_citerne_global_daily` |
| `fetchCiterneOwnerSnapshots` | `v_stock_actuel` (toujours) | **IGNORÉ** (warning debug) |

### Comportement détaillé

#### Mode actuel (`dateJour == null`)

- **Source** : `v_stock_actuel`
- **Agrégation** : Côté Dart par `(depot_id, produit_id)` ou `(depot_id, produit_id, proprietaire_type)`
- **Temps réel** : Toujours à jour, inclut les ajustements récents

#### Mode historique (`dateJour != null`)

- **Source** : `stocks_journaliers` ou `v_stocks_citerne_global_daily`
- **Fallback automatique** : Si aucun snapshot pour `dateJour`, utilisation du dernier `date_jour` disponible
- **Logs debug** : Affichage des tentatives de fallback

#### Exception : fetchCiterneOwnerSnapshots

**Cette méthode ne supporte PAS l'historique** (par design MVP).

- **Comportement** : Retourne toujours l'état actuel depuis `v_stock_actuel`
- **Warning** : Si `dateJour != null` est passé, un warning debug est affiché
- **Annotation** : Le paramètre `dateJour` est marqué `@Deprecated`

**Pour obtenir des snapshots historiques par citerne** : Utiliser `fetchCiterneGlobalSnapshots(dateJour: ...)`.

---

## 5. API claire — Wrappers explicites

Pour éviter toute ambiguïté future, des wrappers explicites ont été créés dans `StocksKpiRepository` :

### Wrappers "Actuel"

- `fetchDepotProductTotalsActuel({required depotId, produitId?})`
  - Appelle `fetchDepotProductTotals(dateJour: null)`
  - Utilise `v_stock_actuel`

- `fetchDepotOwnerTotalsActuel({required depotId, produitId?, proprietaireType?})`
  - Appelle `fetchDepotOwnerTotals(dateJour: null)`
  - Utilise `v_stock_actuel`

- `fetchCiterneGlobalSnapshotsActuel({required depotId, citerneId?, produitId?})`
  - Appelle `fetchCiterneGlobalSnapshots(dateJour: null)`
  - Utilise `v_stock_actuel`

### Wrappers "Journalier"

- `fetchDepotProductTotalsJournalier({required depotId, required DateTime dateJour, produitId?})`
  - Appelle `fetchDepotProductTotals(dateJour: dateJour)`
  - Utilise `stocks_journaliers` avec fallback

- `fetchDepotOwnerTotalsJournalier({required depotId, required DateTime dateJour, produitId?, proprietaireType?})`
  - Appelle `fetchDepotOwnerTotals(dateJour: dateJour)`
  - Utilise `stocks_journaliers` avec fallback

- `fetchCiterneGlobalSnapshotsJournalier({required depotId, required DateTime dateJour, citerneId?, produitId?})`
  - Appelle `fetchCiterneGlobalSnapshots(dateJour: dateJour)`
  - Utilise `v_stocks_citerne_global_daily` avec fallback

**Ces wrappers ne modifient pas le comportement**, ils clarifient l'intention du code.

---

## 6. Statut

🟢 **STATUT : VALIDÉ & STABLE**

- ✅ **DB contract vérifié** avec données réelles (réceptions + sorties)
- ✅ **UI conforme** : Les volumes s'affichent sous les bonnes citernes
- ✅ **KPI contract documenté** : Routing actuel vs historique explicite
- ✅ **Mapping validé** : Nom de citerne depuis table `citernes` (source de vérité)
- ✅ **Aucun refactor requis** : Architecture stable et maintenable
- ✅ **Prêt pour évolution post-MVP** : Contrat clair pour extensions futures

**Date de validation** : 2026-01-13  
**Validé par** : Tests avec mouvements réels (réception + sorties)

---

## 7. Règles pour le futur

### Obligations

1. **Ne jamais bypasser `v_stock_actuel` pour le stock actuel**
   - Toute lecture de stock actuel DOIT passer par `v_stock_actuel`
   - Aucune exception, aucun cache intermédiaire

2. **Toute nouvelle vue "daily" doit être explicitement nommée**
   - Pattern : `v_*_daily` ou `*_journaliers`
   - Documentation obligatoire du routing dans `StocksKpiRepository`

3. **Toute ambiguïté doit être documentée avant implémentation**
   - Si une méthode supporte `dateJour`, la docstring DOIT l'indiquer clairement
   - Si une méthode ignore `dateJour`, warning debug obligatoire

### Recommandations

- **Utiliser les wrappers explicites** pour le nouveau code (Actuel/Journalier)
- **Respecter le contrat de mapping** : nom depuis table `citernes`, jamais depuis vue
- **Tester avec données réelles** avant de valider un changement de contrat

---

## 8. Références

### Code source

- **Repository principal** : `lib/data/repositories/stocks_kpi_repository.dart`
  - `fetchStockActuelRows()` — Source de vérité unique pour stock actuel
  - `fetchDepotProductTotals()` — Totaux globaux (actuel/historique)
  - `fetchDepotOwnerTotals()` — Totaux par propriétaire (actuel/historique)
  - `fetchCiterneGlobalSnapshots()` — Snapshots par citerne (actuel/historique)
  - `fetchCiterneOwnerSnapshots()` — Snapshots par citerne/propriétaire (actuel uniquement)

- **Repository Citernes** : `lib/features/citernes/data/citerne_repository.dart`
  - `fetchCiterneStockSnapshots()` — Agrégation depuis `v_stock_actuel` avec nom depuis table `citernes`

- **Providers** : `lib/features/stocks/data/stocks_kpi_providers.dart`
  - `depotStocksSnapshotProvider` — Provider principal pour snapshots
  - `depotGlobalStockFromSnapshotProvider` — KPI global
  - `depotOwnerStockFromSnapshotProvider` — KPI par propriétaire

### Documentation associée

- **Contrat SQL** : `docs/db/stocks_views_contract.md`
- **Contrat transactionnel** : `docs/TRANSACTION_CONTRACT.md`
- **Changelog** : `CHANGELOG.md` (entrées 2026-01-13)

---

## 9. Historique des validations

### 2026-01-13 — Validation initiale

- ✅ Mapping citerne_id → nom corrigé (nom depuis table `citernes`)
- ✅ Libellé "CITERNE X" corrigé (numéro réel extrait du nom)
- ✅ Contrat KPI documenté et verrouillé (routing actuel vs historique)
- ✅ Wrappers explicites créés (API claire pour le futur)
- ✅ Tests avec données réelles (réception + sorties) validés

**Résultat** : Architecture stable, prête pour production MVP.

---

**Fin du document**

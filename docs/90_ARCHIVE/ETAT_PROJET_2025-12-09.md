# 📊 État du Projet ML_PP MVP - 09/12/2025

## 🎯 Vue d'ensemble

Ce document présente l'état actuel du projet **ML_PP MVP** (Monaluxe), un système de gestion de stocks de produits pétroliers avec suivi des mouvements (réceptions, sorties), gestion des cours de route, et tableaux de bord KPI.

---

## 1️⃣ 🔐 Auth & Profils

### ✅ Statut : **Stable et en production interne**

### Composants principaux

- **Auth Supabase + GoRouter + Riverpod** : Architecture stable et testée
- **ProfilService + profilProvider** : Gestion des profils utilisateurs opérationnelle
- **userRoleProvider** : Provider réactif pour les rôles utilisateurs
- **Redirections par rôle** : 
  - Admin → `/dashboard/admin`
  - Opérateur → `/dashboard/operateur`
  - Gérant → `/dashboard/gerant`
  - Directeur → `/dashboard/directeur`

### Tests

- ✅ Tests d'intégration Auth complets (`test/integration/auth/auth_integration_test.dart`)
- ✅ 14 tests PASS, 3 tests SKIP
- ✅ Navigation guards testés et validés

### Fichiers clés

- `lib/shared/providers/auth_service_provider.dart`
- `lib/features/profil/providers/profil_provider.dart`
- `lib/shared/navigation/app_router.dart`

---

## 2️⃣ 🚚 Cours de Route (CDR)

### ✅ Statut : **En place et fonctionnel**

### Composants principaux

- **Modèle CDR** : `CoursDeRoute` avec statuts métier
- **Service CDR** : `CoursDeRouteService` opérationnel
- **Providers Riverpod** : `cdrListProvider`, `cdrKpiProvider`
- **Statuts métier** :
  - `CHARGEMENT` : Camion chez le fournisseur
  - `TRANSIT` : Camion en transit
  - `FRONTIERE` : Camion à la frontière
  - `ARRIVE` : Camion arrivé au dépôt (non déchargé)
  - `DECHARGE` : Cours terminé (déchargé)

### Tests

- ✅ Tests CDR complets (transitions, KPI provider, écran de décharge)
- ✅ Checkpoint vert mémorisé
- ✅ Test E2E CDR (`test/features/cours_route/e2e/cdr_flow_e2e_test.dart`)

### Fichiers clés

- `lib/features/cours_route/`
- `lib/data/repositories/cours_de_route_repository.dart`

---

## 3️⃣ 🧾 Réceptions

### ✅ Statut : **Flow métier complet et validé**

### Flow métier

1. **CDR ARRIVE** → Création d'une réception
2. **Réception validée** → Mise à jour des stocks + CDR → `DECHARGE`
3. **Triggers DB** :
   - Crédit des stocks via `stock_upsert_journalier()`
   - Logs automatiques (`RECEPTION_CREEE` / `RECEPTION_VALIDE`)

### Composants UI

- ✅ Formulaire moderne de réception
- ✅ Listing des réceptions avec filtres
- ✅ Intégration avec les référentiels (produits, citernes, clients, partenaires)

### Tests

- ✅ Checkpoint Réceptions AXE A+B validé
- ✅ Test E2E Réceptions (`test/features/receptions/e2e/reception_flow_e2e_test.dart`)
- ✅ Tests d'intégration complets

### Fichiers clés

- `lib/features/receptions/`
- `lib/data/repositories/receptions_repository.dart`
- `supabase/migrations/*_receptions_*.sql`

---

## 4️⃣ ⛽ Sorties Produit

### ✅ Statut : **Opérationnel avec tests complets**

### Composants principaux

- **SortieService.createValidated** : Service métier opérationnel
- **Formulaire UI** :
  - Sélection produit / citerne
  - Saisie mesures (avant/après, température, densité)
  - Validation métier complète
  - Support MONALUXE et PARTENAIRE

### Tests

- ✅ `sorties_submission_test.dart` : Vérifie que le formulaire appelle le service avec les bonnes valeurs
- ✅ `sorties_e2e_test.dart` : Test E2E complet
  - Opérateur se connecte
  - Navigue vers Sorties
  - Crée une sortie MONALUXE
  - Vérifie l'apparition dans la liste

### Fichiers clés

- `lib/features/sorties/`
- `lib/features/sorties/data/sortie_service.dart`
- `test/features/sorties/sorties_e2e_test.dart`

---

## 5️⃣ 📊 Stocks & KPI (Bloc 3)

### ✅ Statut : **Bloc complet verrouillé (repo + providers + UI + tests)**

### Backend KPI

#### Vues SQL Supabase

- ✅ `v_kpi_stock_global` : Totaux globaux par dépôt/produit
- ✅ `v_kpi_stock_owner` : Breakdown par propriétaire (MONALUXE / PARTENAIRE)
- ✅ `v_stocks_citerne_owner` : Snapshots par citerne + propriétaire
- ✅ `v_stocks_citerne_global` : Snapshots globaux par citerne

#### Repository

- ✅ `StocksKpiRepository` : Entièrement testé
- ✅ `test/features/stocks/stocks_kpi_repository_test.dart` : **24/24 tests PASS** ✅
- ✅ Support du filtrage par date (`dateJour` optionnel)

### Providers KPI

- ✅ `stocks_kpi_providers.dart` : Repository + providers globaux et filtrés
- ✅ `depotStocksSnapshotProvider` : Provider agrégé pour un dépôt
  - Combine : totaux globaux + breakdown par propriétaire + snapshots par citerne
- ✅ `stocksDashboardKpisProvider` : Provider pour le dashboard
- ✅ Tests complets : `depot_stocks_snapshot_provider_test.dart` (3/3 PASS)

### UI KPI

#### Dashboard

- ✅ Carte "Stock par propriétaire" (MONALUXE / PARTENAIRE)
- ✅ Widget `OwnerStockBreakdownCard` réutilisable
- ✅ Affichage conditionnel selon `depotId` du profil

#### Écran Stocks journaliers

- ✅ Section "Vue d'ensemble" en haut de l'écran
- ✅ Affichage des KPI avec la date sélectionnée
- ✅ Tableau détaillé des stocks par citerne

#### Tests UI

- ✅ `stocks_kpi_cards_test.dart` : Test du widget `OwnerStockBreakdownCard`
- ✅ Gestion des états : `loading`, `error`, `data`

### Compilation & Run

- ✅ `flutter run -d chrome` : OK
- ✅ Dashboard admin et opérateur fonctionnent
- ✅ Tous les tests passent (28/28 pour le module Stocks)

### Fichiers clés

- `lib/data/repositories/stocks_kpi_repository.dart`
- `lib/features/stocks/data/stocks_kpi_providers.dart`
- `lib/features/stocks/widgets/stocks_kpi_cards.dart`
- `lib/features/stocks/domain/depot_stocks_snapshot.dart`
- `test/features/stocks/`

---

## 6️⃣ 📦 Stocks Journaliers (Focus actuel)

### 🎯 Objectif

S'assurer que chaque mouvement (Réception / Sortie) met à jour `stocks_journaliers` correctement, et que les KPI Stocks reflètent la réalité.

### 🔧 Rôle de `stocks_journaliers`

#### Table "gélifiée" par citerne / produit / date / propriétaire

**Colonnes principales** :
- `citerne_id`
- `produit_id`
- `date_jour`
- `proprietaire_type` (MONALUXE / PARTENAIRE)
- `stock_ambiant`, `stock_15c`
- `depot_id`, `source`, `timestamps`

#### Fonction `stock_upsert_journalier(...)`

- Appelée par les triggers Réception / Sortie
- Si la ligne existe → **UPDATE** avec +Δ ou −Δ
- Sinon → **INSERT** initial

#### Triggers

- **Réception** : Crédite `stocks_journaliers` (volumes positifs)
- **Sortie** : Débite `stocks_journaliers` (volumes négatifs)

#### KPI

Les KPI (Bloc 3) sont une **lecture** de ces données via les vues SQL.

---

## 7️⃣ 🧪 Prochaines étapes - Stocks Journaliers

### A. Vérification fonctionnelle "manuelle" (via l'app et Supabase)

#### Scénario minimal MONALUXE

1. **Choisir une citerne de test** (ex : TANK1, MONALUXE)
2. **Vérifier dans Supabase** (table `stocks_journaliers`) :
   ```sql
   SELECT * FROM stocks_journaliers 
   WHERE citerne_id = '...' 
     AND produit_id = '...' 
     AND proprietaire_type = 'MONALUXE'
     AND date_jour = CURRENT_DATE;
   ```
3. **Depuis l'app** :
   - Faire **UNE réception** sur cette citerne
   - Puis **UNE sortie** depuis cette citerne
   - Revenir sur :
     - Écran Stocks journaliers (section "Vue d'ensemble" + tableau)
     - Dashboard (KPI "Stock par propriétaire")
4. **Vérifier dans Supabase** :
   - `stock_ambiant` et `stock_15c` ont bien bougé dans le sens attendu
   - La vue `v_kpi_stock_owner` reflète bien ces changements

#### Scénario PARTENAIRE

- Même logique mais avec une citerne PARTENAIRE
- Vérifier que les volumes sont bien **séparés** par `proprietaire_type`

### B. Durcissement par tests automatisés (prochaine étape)

#### Option 1 : Tests SQL

- Fichier : `docs/db/stocks_journaliers_tests.md` ou migration de test
- Vérifier les triggers et la fonction `stock_upsert_journalier()`

#### Option 2 : Tests d'intégration Flutter

- Créer une réception puis une sortie
- Vérifier que les KPI de stock (lecture via providers) ont bougé comme prévu
- Construire ces tests par-dessus tout ce qui est sécurisé (Sorties + KPI)

---

## 8️⃣ 📈 Résumé des Checkpoints

| Module | Statut | Tests | Notes |
|--------|--------|-------|-------|
| 🔐 Auth & Profils | ✅ Stable | 14 PASS, 3 SKIP | Production interne |
| 🚚 Cours de Route | ✅ En place | Checkpoint vert | Statuts métier intégrés |
| 🧾 Réceptions | ✅ Flow complet | Checkpoint AXE A+B | Triggers DB OK |
| ⛽ Sorties | ✅ Opérationnel | E2E + Submission | Formulaire + Service testés |
| 📊 Stocks & KPI | ✅ Bloc complet | 28/28 PASS | Repo + Providers + UI |
| 📦 Stocks Journaliers | 🔄 En cours | À venir | Vérification fonctionnelle |

---

## 9️⃣ 🛠️ Architecture technique

### Stack

- **Flutter** : Framework UI
- **Riverpod** : Gestion d'état
- **GoRouter** : Navigation et routing
- **Supabase** : Backend (PostgreSQL + Auth + Realtime)

### Patterns

- **Repository Pattern** : Abstraction de l'accès aux données
- **Provider Pattern** : Gestion d'état réactive avec Riverpod
- **Service Layer** : Logique métier encapsulée
- **Domain Models** : Modèles métier purs (sans dépendances)

### Tests

- **Unit Tests** : Services, repositories, providers
- **Widget Tests** : Composants UI isolés
- **Integration Tests** : Flux complets (Auth, navigation)
- **E2E Tests** : Scénarios utilisateur complets

---

## 🔟 📝 Documentation existante

- `CHANGELOG.md` : Historique des changements
- `docs/rapports/` : Rapports de phases
- `docs/db/` : Documentation SQL et migrations
- `docs/prompts/` : Prompts d'implémentation

---

**Dernière mise à jour** : 09/12/2025  
**Version** : MVP Phase 3.4 (Stocks & KPI UI intégrés)


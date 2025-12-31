# Cartographie Modules Flutter → DB

**Date** : 2025-12-27  
**Version** : 1.0  
**Objectif** : Documenter l'utilisation des tables/vues/RPC par module fonctionnel Flutter

---

## 📋 Sommaire

1. [Module Dashboard](#module-dashboard)
2. [Module Stocks](#module-stocks)
3. [Module Citernes](#module-citernes)
4. [Module Sorties](#module-sorties)
5. [Module Réceptions](#module-réceptions)
6. [Module KPI](#module-kpi-générique)
7. [Module Logs](#module-logs)
8. [Module Cours de route](#module-cours-de-route)
9. [Points critiques](#-points-critiques)

---

## Module Dashboard

### Stock (KPI)

#### v_stock_actuel_snapshot (canonique snapshot)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/dashboard/widgets/role_dashboard.dart` (commenté "source de vérité" via providers)
  - (Indirectement via `stocks_kpi_providers.dart` / `stocks_kpi_repository.dart`)

#### v_stock_actuel_owner_snapshot (owner totals – basé journalier, legacy naming)
- **Statut** : 🟡 LEGACY
- **Usage** : Affichage "stock par propriétaire" via providers

#### v_kpi_stock_global (canonique KPI global DB)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/kpi/providers/kpi_provider.dart`
  - `lib/data/repositories/stocks_kpi_repository.dart`

### Citernes sous seuil

#### v_citerne_stock_snapshot_agg (canonique)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart` (migré depuis `v_citerne_stock_actuel` - A-FLT-02)
  - `lib/features/dashboard/providers/admin_kpi_provider.dart` (migré depuis `v_citerne_stock_actuel` - A-FLT-02)
  - `lib/features/dashboard/providers/directeur_kpi_provider.dart` (migré depuis `v_citerne_stock_actuel` - A-FLT-02)

### Activités récentes

#### logs (vue compat log_actions)
- **Statut** : 🟡 COMPAT
- **Fichiers** :
  - `lib/features/dashboard/providers/activites_recentes_provider.dart`
  - `lib/features/dashboard/providers/admin_kpi_provider.dart`

### KPI Réceptions / Sorties

#### receptions (table)
- **Statut** : 📊 TABLE
- **Usage** : KPI réceptions dashboard

#### sorties_produit (table)
- **Statut** : 📊 TABLE
- **Usage** : KPI sorties dashboard

---

## Module Stocks

### Stock total dépôt

#### v_stock_actuel_snapshot (canonique snapshot)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/stocks/data/stocks_kpi_providers.dart`
  - `lib/data/repositories/stocks_kpi_repository.dart`

### Stock par propriétaire (breakdown)

#### v_stock_actuel_owner_snapshot (legacy naming — basé stocks_journaliers)
- **Statut** : 🟡 LEGACY
- **Fichiers** :
  - `lib/features/stocks/data/stocks_kpi_providers.dart`
  - `lib/features/stocks/widgets/stocks_kpi_cards.dart`

### Historique / par date

#### stocks_journaliers (table)
- **Statut** : 📊 TABLE (historique)
- **Fichiers** :
  - `lib/data/repositories/stocks_kpi_repository.dart`
- **Usage** : Historique stock par date

---

## Module Citernes

### Liste citernes + stock visible maintenant

#### v_citerne_stock_snapshot_agg (canonique Citernes)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/citernes/data/citerne_repository.dart`
  - `lib/features/citernes/screens/citerne_list_screen.dart`

### Legacy / compat

#### stock_actuel (legacy journalier)
- **Statut** : 🔶 LEGACY
- **Fichiers** :
  - `lib/features/citernes/providers/citerne_providers.dart`
  - `lib/features/citernes/data/citerne_service.dart`

#### v_stock_actuel_snapshot (legacy provider conservé pour compat/refresh)
- **Statut** : 🟡 LEGACY (provider deprecated)
- **Fichiers** :
  - `lib/features/citernes/providers/citerne_providers.dart` (annoté `@Deprecated`)

---

## Module Sorties

### CRUD / écran création / table sorties

#### sorties_produit (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/sorties/data/sortie_service.dart`
  - `lib/features/sorties/providers/sortie_providers.dart`
  - `lib/features/sorties/providers/sorties_table_provider.dart`

### Référentiels

#### clients, partenaires, produits, citernes (tables)
- **Statut** : 📊 TABLE
- **Usage** : Référentiels pour formulaire sortie

### Stock "dernier stock" affiché dans formulaire

#### stock_actuel (legacy journalier)
- **Statut** : 🔶 LEGACY
- **Fichiers** :
  - `lib/features/sorties/providers/sortie_providers.dart`

⚠️ **Point critique** : Le module Sorties est encore sur "journalier" pour l'UI stock, pas snapshot

---

## Module Réceptions

### CRUD / table / liste

#### receptions (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/receptions/data/reception_service.dart`
  - `lib/features/receptions/providers/receptions_table_provider.dart`
  - `lib/features/receptions/providers/receptions_list_provider.dart`

### Cours de route "arrivés"

#### cours_de_route (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/receptions/data/cours_arrives_provider.dart`

### RPC validation

#### validate_reception (function RPC)
- **Statut** : 🔧 RPC
- **Fichiers** :
  - `lib/shared/db/db_port.dart`

### Stock affiché dans écran réception

#### RPC get_last_stock_ambiant (function)
- **Statut** : 🔧 RPC
- **Fichiers** :
  - `lib/features/receptions/data/citerne_info_provider.dart`

#### legacy stock_actuel via CiterneService (compat)
- **Statut** : 🔶 LEGACY
- **Usage** : Compatibilité pour affichage stock dans formulaire réception

---

## Module KPI (générique)

### KPI Stock global

#### v_kpi_stock_global (canonique DB)
- **Statut** : 🟢 CANONIQUE
- **Fichiers** :
  - `lib/features/kpi/providers/kpi_provider.dart`

### KPI Réceptions / Sorties / Cours de route

#### receptions, sorties_produit, cours_de_route (tables)
- **Statut** : 📊 TABLE
- **Usage** : KPI volumes / camions à suivre

---

## Module Logs

### logs (vue compat)
- **Statut** : 🟡 COMPAT
- **Fichiers** :
  - `lib/features/logs/services/logs_service.dart`

### log_actions (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/logs/providers/logs_providers.dart`

---

## Module Cours de route

### cours_de_route (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/cours_route/data/cours_de_route_service.dart`
  - `lib/data/repositories/cours_de_route_repository.dart`

### cdr_logs (table)
- **Statut** : 📊 TABLE
- **Fichiers** :
  - `lib/features/cours_route/data/cdr_logs_service.dart`

---

## ⚠️ Points critiques

### Coexistence de 3 sources "stock" côté Flutter

**Aujourd'hui, 3 sources "stock" coexistent côté Flutter** :

1. **Snapshot canonique** : 
   - `v_stock_actuel_snapshot` (+ `v_citerne_stock_snapshot_agg`)
   - **Usage** : Stock réel temps présent

2. **Journalier legacy** : 
   - `v_citerne_stock_actuel` / `stock_actuel`
   - **Usage** : Anciennes UI, formulaire Sorties, Citernes legacy

3. **Owner totals "snapshot" mais en réalité journalier** : 
   - `v_stock_actuel_owner_snapshot`
   - **Usage** : Breakdown par propriétaire (mais basé sur journalier, pas snapshot réel)

**Impact** :
- Risque d'incohérences entre modules utilisant snapshot vs journalier
- Le module Sorties affiche encore "dernier stock journalier" au lieu de "stock actuel snapshot"
- Le breakdown par propriétaire peut avoir un décalage si le journalier n'est pas à jour

**Actions recommandées** :
1. Migrer progressivement tous les widgets "stock présent maintenant" vers `v_stock_actuel_snapshot`
2. Créer une vraie vue owner snapshot-based pour remplacer `v_stock_actuel_owner_snapshot`
3. Aligner le module Sorties sur le snapshot pour l'affichage du stock dans le formulaire

---

## 📊 Récapitulatif par statut

### 🟢 Canoniques (à utiliser)
- `v_stock_actuel_snapshot` : Dashboard, Stocks, Citernes (principal)
- `v_citerne_stock_snapshot_agg` : Module Citernes
- `v_kpi_stock_global` : Dashboard, Module KPI

### 🟡 Legacy/Compat (transition)
- `v_stock_actuel_owner_snapshot` : Dashboard, Stocks (à migrer vers snapshot)
- `logs` : Dashboard, Module Logs (stable, à garder)

### 🔶 Deprecated (à remplacer)
- `stock_actuel` : Sorties, Citernes (legacy)
- `v_citerne_stock_actuel` : `stocks_repository.dart` uniquement (legacy)

**Migration effectuée (A-FLT-02)** :
- ✅ Dashboard providers migrés vers `v_citerne_stock_snapshot_agg`

### 📊 Tables (sources de données)
- `stocks_journaliers` : Historique (module Stocks)
- `sorties_produit` : Module Sorties, Dashboard
- `receptions` : Module Réceptions, Dashboard
- `cours_de_route` : Module Cours de route, Réceptions
- `log_actions` : Module Logs
- Référentiels : `citernes`, `produits`, `depots`, `clients`, `partenaires`, `profils`

---

## 🔗 Références

- **Documentation vues SQL** : `docs/db/vues_sql_reference.md`
- **Cartographie Flutter → DB** : `docs/db/flutter_db_usage_map.md`
- **Documentation centralisée** : `docs/db/vues_sql_reference_central.md`

---

**Dernière mise à jour** : 2025-12-31 (Migration A-FLT-02 : Dashboard providers vers v_citerne_stock_snapshot_agg)


# Référence Centralisée des Vues SQL

**Date** : 2025-12-27  
**Version** : 1.0  
**Objectif** : Documentation exhaustive de toutes les vues SQL du projet ML_PP_MVP

---

## 📋 Sommaire

1. [Table de résumé](#-table-de-résumé)
2. [Vues canoniques](#-vues-canoniques)
3. [Vues legacy / deprecated](#-vues-legacy--deprecated)
4. [Vues compat](#-vues-compat)
5. [Vues non utilisées](#-vues-non-utilisées)
6. [Règles de choix](#-règles-de-choix)
7. [Plan de dépréciation](#-plan-de-dépréciation)

---

## 📊 Table de résumé

| Vue SQL | Statut | Rôle principal | Remplacement cible |
|---------|--------|----------------|-------------------|
| **CANONIQUES** | | | |
| `v_stock_actuel_snapshot` | 🟢 CANONIQUE | Stock actuel réel (snapshot) | - |
| `v_citerne_stock_snapshot_agg` | 🟢 CANONIQUE | Affichage Citernes (agrégé) | - |
| `v_kpi_stock_global` | 🟢 CANONIQUE | KPI stock dashboard | - |
| `v_mouvements_stock` | 🟢 CANONIQUE | Journal mouvements (deltas) | - |
| **LEGACY / DEPRECATED** | | | |
| `stock_actuel` | 🔶 DEPRECATED | Dernier stock journalier | `v_stock_actuel_snapshot` |
| `v_citerne_stock_actuel` | 🔶 DEPRECATED | Stock citerne journalier | `v_citerne_stock_snapshot_agg` |
| `v_stock_actuel_owner_snapshot` | 🟡 LEGACY/COMPAT | Stock par propriétaire (journal) | À créer (snapshot-based) |
| **COMPAT** | | | |
| `logs` | 🟡 COMPAT | Vue compatibilité log_actions | - |
| `cours_route` | 🟡 COMPAT | Vue présentation cours_de_route | - |
| **NON UTILISÉES** | | | |
| `current_user_profile` | ⚪ NON UTILISÉ | Profil utilisateur | - |

---

## 🟢 Vues canoniques

Les vues canoniques sont les **contrats stables** entre la base de données et Flutter. Elles doivent être utilisées pour tous les nouveaux développements.

---

### 1. v_stock_actuel_snapshot

**Statut** : 🟢 CANONIQUE

#### Rôle
Source de vérité absolue pour le stock actuel réel à l'instant T. Représente l'état physique présent dans chaque citerne, par produit et par propriétaire (MONALUXE / PARTENAIRE).

#### Source
- **Table** : `stocks_snapshot`
- Alimentée exclusivement par :
  - Fonction `stock_snapshot_apply_delta()` appelée depuis :
    - Triggers de réceptions validées
    - Triggers de sorties validées
- ⚠️ Aucun calcul à la volée, aucun agrégat temporel

#### Colonnes exposées
- `citerne_id` (uuid)
- `citerne_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `depot_id` (uuid)
- `depot_nom` (text)
- `proprietaire_type` (MONALUXE | PARTENAIRE)
- `stock_ambiant` (double precision)
- `stock_15c` (double precision)
- `updated_at` (timestamptz)
- `capacite_totale` (double precision)
- `capacite_securite` (double precision)

#### Usages Flutter
- `lib/data/repositories/stocks_kpi_repository.dart`
  - `.from('v_stock_actuel_snapshot')` (lignes ~312, ~326, ~415)
  - Utilisé pour : snapshots citernes + agrégations dashboard/stocks
- `lib/features/stocks/data/stocks_kpi_providers.dart`
  - Totaux stock dépôt (accepte `stock_ambiant_total` fallback sur `stock_ambiant`)
- `lib/features/dashboard/widgets/role_dashboard.dart`
  - Stock total via providers snapshot

#### Notes / Risques
- ❌ **NE DOIT JAMAIS être filtrée par date**
- ❌ `updated_at` ≠ `date_jour` (updated_at est informatif uniquement)
- ✅ Représente **un état**, pas une série temporelle
- ✅ Toute incohérence ici est **un bug DB**, jamais UI

---

### 2. v_citerne_stock_snapshot_agg

**Statut** : 🟢 CANONIQUE

#### Rôle
Vue dédiée à l'écran Citernes. Agrège le stock actuel par citerne, tous propriétaires confondus, depuis `v_stock_actuel_snapshot`.

#### Source
- **Vue** : `v_stock_actuel_snapshot`
- Agrégation par citerne (somme des propriétaires)

#### Colonnes exposées
- `citerne_id` (uuid)
- `citerne_nom` (text)
- `depot_id` (uuid)
- `produit_id` (uuid)
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)
- `last_snapshot_at` (timestamptz)

#### Usages Flutter
- `lib/features/citernes/data/citerne_repository.dart`
  - `.from('v_citerne_stock_snapshot_agg')`
- `lib/features/citernes/screens/citerne_list_screen.dart`
- `lib/features/citernes/domain/citerne_stock_snapshot.dart`

#### Notes / Risques
- ✅ Affichage OK
- ❌ Pas de logique métier (pas de validation)
- ✅ Vue strictement UI
- ✅ Remplace définitivement `v_citerne_stock_actuel`

---

### 3. v_kpi_stock_global

**Statut** : 🟢 CANONIQUE

#### Rôle
Vue KPI consolidée pour le pilotage global. Expose le stock total, stock MONALUXE et stock PARTENAIRE par dépôt et par produit, basée sur `v_stock_actuel_snapshot`.

#### Source
- **Vue** : `v_stock_actuel_snapshot`
- Agrégation par : dépôt, produit, propriétaire

#### Colonnes exposées
- `depot_id` (uuid)
- `depot_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `date_jour` (date) - CAST de `updated_at`
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)
- `stock_ambiant_monaluxe` (double precision)
- `stock_15c_monaluxe` (double precision)
- `stock_ambiant_partenaire` (double precision)
- `stock_15c_partenaire` (double precision)

#### Usages Flutter
- `lib/data/repositories/stocks_kpi_repository.dart`
  - `.from('v_kpi_stock_global')` (~ligne 213)
- `lib/features/kpi/providers/kpi_provider.dart`
  - Stocks dashboard KPIs (commentaire: "agrégé DB via v_kpi_stock_global")
- `lib/features/dashboard/widgets/role_dashboard.dart`
  - KPI stocks

#### Notes / Risques
- ⚠️ `date_jour` = **date d'update**, pas date métier
- ✅ Vue **strictement visuelle** (KPI uniquement)
- ❌ Ne jamais utiliser pour contrôles métier
- ✅ Vue 100% lecture

---

### 4. v_mouvements_stock

**Statut** : 🟢 CANONIQUE

#### Rôle
Journal normalisé des mouvements de stock (deltas). Union standardisée des réceptions (delta positif) et sorties (delta négatif) pour produire une timeline des mouvements journaliers.

#### Source
- **Tables** : `receptions`, `sorties_produit`
- UNION ALL avec deltas positifs (réceptions) / négatifs (sorties)

#### Colonnes exposées
- `date_jour` (date)
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `depot_id` (uuid)
- `proprietaire_type` (MONALUXE | PARTENAIRE)
- `delta_ambiant` (double precision)
- `delta_15c` (double precision)

#### Usages Flutter
- ➡️ **Vue disponible côté DB, non consommée actuellement par Flutter**
- Aucun appel direct `.from('v_mouvements_stock')` repéré
- Utilisation prévue pour : module "Mouvements du jour", audit, timeline

#### Notes / Risques
- ✅ `date_jour` = date métier
- ✅ Utile pour "aujourd'hui", "semaine", "période"
- ❌ Pas une vue de stock "actuel" (c'est des deltas)
- ⚠️ Ne jamais utiliser pour afficher un stock actuel

---

## 🔶 Vues legacy / deprecated

Ces vues fonctionnent encore mais ne sont plus la source de vérité. Elles doivent être progressivement retirées du code Flutter.

---

### 5. stock_actuel

**Statut** : 🔶 DEPRECATED (toléré uniquement en compat/transition)

#### Rôle
Retourne le dernier stock par (citerne, produit) depuis `stocks_journaliers` en utilisant DISTINCT ON sur la date la plus récente.

#### Source
- **Table** : `stocks_journaliers`
- Sélection `DISTINCT ON` sur `date_jour DESC`

#### Colonnes exposées
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `date_jour` (date)
- `stock_ambiant` (double precision)
- `stock_15c` (double precision)

#### Usages Flutter
- `lib/features/sorties/providers/sortie_providers.dart`
  - `.from('stock_actuel')` (~ligne 205)
- `lib/features/citernes/providers/citerne_providers.dart`
  - Legacy provider
- `lib/features/citernes/data/citerne_service.dart`
  - Legacy method

#### Notes / Risques
- ⚠️ C'est basé sur `stocks_journaliers` → donc "dernier jour disponible", pas forcément "stock réel maintenant"
- ⚠️ Mélange "historique/journal" avec "stock actuel", ce qui a causé des incohérences
- ❌ Ne gère pas les propriétaires
- ❌ Peut afficher un stock obsolète intra-journée

#### Remplacement cible
➡️ `v_stock_actuel_snapshot` (ou `v_citerne_stock_snapshot_agg` pour Citernes UI)

---

### 6. v_citerne_stock_actuel

**Statut** : 🔶 DEPRECATED (doit être remplacé partout par snapshot)

#### Rôle
Agrège `stocks_journaliers` en prenant la dernière date par (citerne, produit, propriétaire) puis somme. Renvoie un stock "actuel" mais en réalité "dernier journal".

#### Source
- **Table** : `stocks_journaliers`
- Agrégation sur la dernière date disponible par (citerne, produit, propriétaire)

#### Colonnes exposées
- `citerne_id` (uuid)
- `produit_id` (uuid)
- `date_jour` (date)
- `stock_ambiant` (double precision)
- `stock_15c` (double precision)

#### Usages Flutter
- `lib/data/repositories/stocks_repository.dart`
  - `.from('v_citerne_stock_actuel')`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart`

#### Notes / Risques
- ⚠️ Même problème : c'est du journalier, pas du snapshot réel
- ⚠️ Incohérences possibles si plusieurs dates existent
- ❌ Ignore totalement MONALUXE / PARTENAIRE (agrégation incorrecte)
- ❌ Non alignée avec le moteur snapshot

#### Remplacement cible
- Citernes sous seuil → `v_citerne_stock_snapshot_agg` (`stock_ambiant_total`)
- KPI dashboard → `v_kpi_stock_global` (déjà snapshot-based) ou agrégation depuis `v_stock_actuel_snapshot`

---

### 7. v_stock_actuel_owner_snapshot

**Statut** : 🟡 LEGACY/COMPAT → à migrer vers une vue owner "snapshot-based"

#### Rôle
Donne stock par dépôt+produit+propriétaire, mais basé sur `stocks_journaliers` (last_date) et pas sur `stocks_snapshot`.

#### Source
- **Table** : `stocks_journaliers`
- Sélection de la dernière date par couple (citerne, produit, propriétaire)
- Agrégation finale par dépôt

#### Colonnes exposées
- `depot_id` (uuid)
- `depot_nom` (text)
- `produit_id` (uuid)
- `produit_nom` (text)
- `proprietaire_type` (MONALUXE | PARTENAIRE)
- `date_jour` (date)
- `stock_ambiant_total` (double precision)
- `stock_15c_total` (double precision)

#### Usages Flutter
- `lib/data/repositories/stocks_kpi_repository.dart`
  - `.from('v_stock_actuel_owner_snapshot')` (~lignes 247, 366)
- `lib/features/stocks/data/stocks_kpi_providers.dart`
  - Stock by owner
- `lib/features/dashboard/widgets/role_dashboard.dart`
  - Owner breakdown

#### Notes / Risques
- ⚠️ Le mot **snapshot** est trompeur
- ⚠️ Ce n'est PAS le moteur snapshot
- ⚠️ C'est une **reconstruction depuis le journal**
- ⚠️ Vue **snapshot logique**, pas historique
- ⚠️ Le champ `date_jour` est informatif, jamais filtrant

#### Remplacement cible
➡️ Une vue du type `v_kpi_stock_owner` (à créer) basée sur `stocks_snapshot` (ou dérivée de `v_stock_actuel_snapshot`)

**TODO** : Créer une vue owner snapshot-based pour remplacer cette vue legacy.

---

## 🟡 Vues compat

Ces vues sont maintenues pour compatibilité et ne sont pas liées à la logique de stock.

---

### 8. logs

**Statut** : 🟡 COMPAT / OK (pas critique, mais utile)

#### Rôle
Vue de compatibilité exposant la table `log_actions` pour le module Logs et les activités récentes du dashboard.

#### Source
- **Table** : `log_actions`
- Vue de compatibilité simple

#### Colonnes exposées
- `id` (uuid)
- `created_at` (timestamptz)
- `module` (text)
- `action` (text)
- `niveau` (text)
- `user_id` (uuid)
- `details` (jsonb)

#### Usages Flutter
- `lib/features/logs/services/logs_service.dart`
  - `.from('logs')`
- `lib/features/dashboard/providers/activites_recentes_provider.dart`
  - `.from('logs')`

#### Notes / Risques
- ✅ Vue stable et utile
- ✅ Pas concernée par la logique stock
- ✅ À conserver

---

### 9. cours_route

**Statut** : 🟡 COMPAT (pas lié aux stocks)

#### Rôle
Vue "présentation" de `cours_de_route` avec concaténation des plaques et nettoyage des champs pour l'affichage UI.

#### Source
- **Table** : `cours_de_route`
- Vue de présentation avec formatage

#### Colonnes exposées
- (Dépend de la structure de `cours_de_route`, colonnes formatées pour UI)

#### Usages Flutter
- ➡️ **Non utilisé directement par Flutter à ce stade**
- Utilisation prévue pour : UI cours de route "liste simple"

#### Notes / Risques
- ✅ Vue UI de présentation
- ✅ Pas liée aux stocks
- ✅ À conserver pour usage futur

---

## ⚪ Vues non utilisées

---

### 10. current_user_profile

**Statut** : ⚪ NON UTILISÉ

#### Rôle
Vue théorique pour exposer le profil utilisateur courant (si elle existe).

#### Source
- (Structure non définie / non utilisée)

#### Colonnes exposées
- (Non définies)

#### Usages Flutter
- ➡️ **Non utilisé directement par Flutter**
- `rg` montre que Flutter lit les profils directement (`role_provider.dart`, `profil_service.dart`)
- Pas d'usage direct `.from('current_user_profile')` repéré

#### Notes / Risques
- ⚪ Vue non utilisée actuellement
- Le code Flutter accède aux profils via d'autres mécanismes

---

## 📋 Règles de choix

### Quelle vue utiliser selon le besoin UI ?

| Besoin UI | Vue canonique à utiliser | Notes |
|-----------|-------------------------|-------|
| **Stock actuel réel** | `v_stock_actuel_snapshot` | Source de vérité absolue, jamais filtrer par date |
| **Affichage Citernes (liste/tank)** | `v_citerne_stock_snapshot_agg` | Agrégation par citerne, tous propriétaires |
| **KPI Dashboard (stock global)** | `v_kpi_stock_global` | Déjà agrégé par dépôt/produit/propriétaire |
| **Stock par propriétaire** | `v_stock_actuel_owner_snapshot` (legacy) | ⚠️ À migrer vers vue snapshot-based future |
| **Mouvements du jour/historique** | `v_mouvements_stock` | ⚠️ Non connectée UI actuellement, à utiliser pour timeline |
| **Logs / Activités** | `logs` | Vue compat, stable |
| **Cours de route (liste)** | `cours_route` | Vue UI, non liée stocks |

### ❌ À éviter absolument

- ❌ **`stock_actuel`** → Remplacer par `v_stock_actuel_snapshot`
- ❌ **`v_citerne_stock_actuel`** → Remplacer par `v_citerne_stock_snapshot_agg`
- ❌ Filtrer `v_stock_actuel_snapshot` par date (utiliser `v_mouvements_stock` pour historique)
- ❌ Utiliser une vue KPI pour validation métier (ex: contrôles de stock avant sortie)

### ✅ Bonnes pratiques

- ✅ Toujours partir d'une vue canonique pour nouveaux développements
- ✅ Comprendre la différence `updated_at` (info) vs `date_jour` (métier)
- ✅ Distinguer vues transactionnelles (stock actuel) vs vues analytiques (KPI/historique)
- ✅ Utiliser `v_stock_actuel_snapshot` pour tout affichage "stock maintenant"

---

## 🔄 Plan de dépréciation

### Phase 1 : Vues deprecated à retirer immédiatement

#### `stock_actuel` → `v_stock_actuel_snapshot`

**Fichiers à migrer** :
- `lib/features/sorties/providers/sortie_providers.dart` (ligne ~205)
- `lib/features/citernes/providers/citerne_providers.dart` (legacy provider)
- `lib/features/citernes/data/citerne_service.dart` (legacy method)

**Action** : Remplacer tous les `.from('stock_actuel')` par `.from('v_stock_actuel_snapshot')` et adapter les colonnes consommées.

#### `v_citerne_stock_actuel` → `v_citerne_stock_snapshot_agg`

**Fichiers à migrer** :
- `lib/data/repositories/stocks_repository.dart`
- `lib/features/dashboard/providers/admin_kpi_provider.dart`
- `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- `lib/features/dashboard/providers/citernes_sous_seuil_provider.dart`

**Action** : 
- Pour citernes sous seuil : utiliser `v_citerne_stock_snapshot_agg` (`stock_ambiant_total`)
- Pour KPI dashboard : utiliser `v_kpi_stock_global` ou agrégation depuis `v_stock_actuel_snapshot`

### Phase 2 : Vues legacy/compat à migrer (moyen terme)

#### `v_stock_actuel_owner_snapshot` → Vue owner snapshot-based (à créer)

**Fichiers concernés** :
- `lib/data/repositories/stocks_kpi_repository.dart` (~lignes 247, 366)
- `lib/features/stocks/data/stocks_kpi_providers.dart`
- `lib/features/dashboard/widgets/role_dashboard.dart`

**Action** :
1. Créer une nouvelle vue `v_kpi_stock_owner` basée sur `v_stock_actuel_snapshot` (agrégation par dépôt+produit+propriétaire)
2. Migrer tous les appels `.from('v_stock_actuel_owner_snapshot')` vers la nouvelle vue
3. Supprimer `v_stock_actuel_owner_snapshot` après migration complète

**TODO** : Créer la vue SQL `v_kpi_stock_owner` dans les migrations Supabase.

### Phase 3 : Vues à connecter (futur)

#### `v_mouvements_stock` → Module UI "Mouvements du jour"

**Action** :
- Créer un module Flutter "Mouvements du jour" consommant `v_mouvements_stock`
- Utiliser pour : timeline, audit, export mouvements

---

## ✅ Checklist de migration

### Avant de migrer une vue legacy

- [ ] Identifier tous les usages Flutter (`rg "vue_name" lib/`)
- [ ] Comprendre les colonnes consommées
- [ ] Choisir la vue canonique de remplacement
- [ ] Adapter le code aux colonnes de la nouvelle vue
- [ ] Tester que l'affichage reste cohérent
- [ ] Vérifier `flutter analyze` = 0 erreur
- [ ] Supprimer les anciens appels `.from('legacy_view')`
- [ ] Mettre à jour ce document

### Après migration

- [ ] Supprimer la vue legacy de la base (optionnel, après vérification production)
- [ ] Mettre à jour ce document (marquer comme supprimée)

---

## 🔗 Références

- **Migrations SQL** : `supabase/migrations/`
- **Repository Flutter principal** : `lib/data/repositories/stocks_kpi_repository.dart`
- **Providers Flutter** : `lib/features/stocks/data/stocks_kpi_providers.dart`
- **Documentation technique** : `docs/db/stocks_views_contract.md`
- **Documentation précédente** : `docs/db/vues_sql_reference.md` (remplacée par ce document)

---

**Dernière mise à jour** : 2025-12-27


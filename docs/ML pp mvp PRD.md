# PRD – ML_PP MVP v5.0 (Janvier 2026)

## 📌 Objectif général
Créer une application de gestion logistique pétrolière pour Monaluxe permettant de suivre les flux de carburant à travers les modules : authentification, cours de route, réception, sorties, citernes, stock journalier, logs et dashboard.

**Architecture technique** : Application Flutter avec backend PostgreSQL/Supabase, logique métier centralisée dans les triggers SQL, séparation claire des responsabilités (DB, service, UI), architecture KPI testable et maintenable.

---

## ✅ Modules Inclus dans le MVP

### 🔐 Authentification
- Connexion sécurisée via Supabase
- Gestion des rôles : admin, directeur, gérant, opérateur, pca, lecture
- Row Level Security (RLS) activée sur toutes les tables sensibles
- Audit trail pour chaque action critique

### 🛣 Cours de Route
- Création dès le chargement chez le fournisseur
- Champs : produit, plaques, transporteur, date, volume, etc.
- Statuts : `CHARGEMENT` → `TRANSIT` → `FRONTIERE` → `ARRIVE` → `DECHARGE`
- Une fois le statut "ARRIVE" atteint, déclenchement du formulaire de réception
- Les cours "DECHARGE" ne sont plus visibles dans la liste principale
- **Trigger automatique** : Passage à `DECHARGE` lors de la création d'une réception liée

### 📥 Réception Produit

#### Architecture Backend (PostgreSQL)
- **Trigger unifié** : `fn_receptions_after_insert()` (via `receptions_apply_effects()`)
- **Fonction de stock** : `stock_upsert_journalier()` avec support `proprietaire_type`, `depot_id`, `source`
- **Validation métier centralisée** :
  - Citerne active et compatible avec le produit
  - Indices cohérents (`index_avant >= 0`, `index_apres > index_avant`)
  - Calcul automatique du volume ambiant si non fourni
  - Calcul du volume corrigé 15°C
- **Mise à jour stocks** : Incrément automatique dans `stocks_journaliers` avec séparation par `proprietaire_type`
- **Journalisation** : Enregistrement automatique dans `log_actions` avec `action = 'RECEPTION_CREEE'`

#### Cas 1 : Propriétaire = MONALUXE
- Liée à un cours de route (optionnel)
- Validation par admin/directeur/gérant
- Vérification des documents, mesure volume, température, densité
- Calcul volume 15°C (OBLIGATOIRE : température et densité requises)
- Affectation à une citerne compatible
- Mise à jour stock MONALUXE (séparé du stock PARTENAIRE)
- Journalisation (log_actions)

#### Cas 2 : Propriétaire = PARTENAIRE
- Sans lien avec un cours de route
- Même processus métier que ci-dessus
- Affectation à une citerne théoriquement partagée
- Stock PARTENAIRE non intégré au stock disponible MONALUXE
- Séparation complète des stocks par `proprietaire_type` dans `stocks_journaliers`

#### Architecture Frontend (Flutter)
- **Service** : `ReceptionService.createValidated()` avec validations métier
- **Formulaire** : Champs obligatoires (produit, citerne, `index_avant`, `index_apres`, température, densité)
- **Calculs** : Volume ambiant = `index_apres - index_avant`, Volume 15°C calculé automatiquement
- **Gestion d'erreurs** : Mapping des erreurs SQL vers messages utilisateur lisibles
- **Ajustements** : Bouton "Corriger (Ajustement)" visible uniquement pour les administrateurs sur l'écran de détail

### 📤 Sortie Produit

#### Architecture Backend (PostgreSQL)
- **Trigger unifié** : `fn_sorties_after_insert()` (remplace les anciens triggers séparés)
- **Validation métier centralisée** :
  - Citerne active et compatible avec le produit
  - Indices cohérents (`index_avant >= 0`, `index_apres > index_avant`)
  - Propriétaire cohérent : `MONALUXE` → `client_id` obligatoire, `PARTENAIRE` → `partenaire_id` obligatoire
  - Vérification stock disponible (stock du jour ≥ volume ambiant)
  - Respect de la capacité de sécurité de la citerne
- **Mise à jour stocks** : Débit automatique dans `stocks_journaliers` avec séparation par `proprietaire_type`
- **Journalisation** : Enregistrement automatique dans `log_actions` avec `action = 'SORTIE_CREEE'`

#### Fonctionnalités
- Déduction du stock MONALUXE ou PARTENAIRE (séparés)
- Sélection produit + citerne + propriétaire
- Mesure volume brut/température/densité
- Calcul du volume à 15°C (OBLIGATOIRE : température et densité requises)
- **Contrainte bénéficiaire** : Au moins un bénéficiaire (`client_id` OU `partenaire_id`)
- **Mono-citerne** : Une sortie ne peut concerner qu'une seule citerne (limitation MVP)

#### Architecture Frontend (Flutter)
- **Service** : `SortieService.createValidated()` avec validations métier
- **Exception dédiée** : `SortieServiceException` pour erreurs SQL/DB
- **Mapping d'erreurs** : Messages utilisateur lisibles pour chaque erreur du trigger
- **Formulaire** : Champs obligatoires (produit, citerne, `index_avant`, `index_apres`, température, densité, bénéficiaire)
- **Gestion d'erreurs** : Affichage des erreurs SQL dans des SnackBars avec messages clairs
- **Ajustements** : Bouton "Corriger (Ajustement)" visible uniquement pour les administrateurs sur l'écran de détail

### 🛢 Citernes
- Champs : nom, capacité, sécurité, produit, statut (active/inactive)
- Lecture seule sauf pour admin
- Gestion théorique des volumes par propriétaire
- Pas de mélange de produits, mais mélange de propriétaires autorisé
- Journalisation : création, modification, désactivation
- **Validation** : Vérification produit/citerne avant insertion sortie/réception
- **Source de données** : Utilise `v_stock_actuel` comme source de vérité unique (migration complète 01/01/2026)
- **Stock par citerne** : Agrégation depuis `v_stock_actuel` par `citerne_id`, inclut réceptions + sorties + ajustements

### 📊 Stocks Journaliers

#### Architecture Backend
- **Table** : `stocks_journaliers` avec colonnes enrichies :
  - `citerne_id`, `produit_id`, `date_jour` (clés primaires)
  - `proprietaire_type` (MONALUXE | PARTENAIRE) - **NOUVEAU**
  - `depot_id` (référence au dépôt) - **NOUVEAU**
  - `source` (RECEPTION | SORTIE | MANUAL | ADJUSTMENT) - **NOUVEAU**
  - `stock_ambiant`, `stock_15c` (volumes)
  - `created_at`, `updated_at` (audit)
- **Contrainte UNIQUE** : `(citerne_id, produit_id, date_jour, proprietaire_type)`
- **Séparation des stocks** : Les stocks MONALUXE et PARTENAIRE sont complètement séparés
- **Génération automatique** : Après chaque réception/sortie validée via triggers
- **Fonction upsert** : `stock_upsert_journalier()` avec support `proprietaire_type`, `depot_id`, `source`

#### Fonctionnalités
- Générés automatiquement après chaque réception/sortie validée
- Lecture seule sauf action manuelle admin
- Affichage brut / 15°C / par citerne / par propriétaire
- Exportables en CSV ou PDF (à venir)
- **Séparation par propriétaire** : Filtrage et agrégation par `proprietaire_type`
- **Source de vérité unique** : `v_stock_actuel` (migration complète 01/01/2026)
  - Toute lecture de stock actuel DOIT utiliser `v_stock_actuel`
  - Inclut automatiquement : réceptions validées + sorties validées + ajustements
  - Utilisée par : Dashboard, Citernes, Module Stock

### 🔧 Ajustements de Stock

#### Architecture Backend (PostgreSQL)
- **Table** : `stocks_adjustments` pour corrections officielles du stock
- **Seule méthode autorisée** : Pour corriger le stock après validation d'une réception ou sortie
- **Champs** :
  - `mouvement_type` (RECEPTION | SORTIE) - Référence au mouvement source
  - `mouvement_id` (UUID) - ID du mouvement à corriger
  - `delta_ambiant` (double precision) - Correction du volume ambiant (≠ 0)
  - `delta_15c` (double precision) - Correction du volume à 15°C
  - `reason` (text) - Raison obligatoire (minimum 10 caractères)
  - `created_by` (UUID) - Utilisateur ayant créé l'ajustement (NOT NULL)
- **Contraintes** :
  - Au moins un delta non nul (`delta_ambiant != 0 OR delta_15c != 0`)
  - Raison minimum 10 caractères
  - `created_by` obligatoire
- **RLS** : INSERT réservé aux administrateurs uniquement
- **Impact immédiat** : Les ajustements sont immédiatement reflétés dans `v_stock_actuel`

#### Types d'ajustements (Frontend)
- **Volume** : Correction uniquement du volume ambiant (température/densité en lecture seule)
- **Température** : Correction de la température (recalcul automatique du 15°C)
- **Densité** : Correction de la densité (recalcul automatique du 15°C)
- **Mixte** : Correction volume + température + densité (recalcul automatique complet)
- **Préfixage automatique** : La raison est automatiquement préfixée avec `[VOLUME]`, `[TEMP]`, `[DENSITE]`, ou `[MIXTE]`

#### Architecture Frontend (Flutter)
- **Service** : `StocksAdjustmentsService.createAdjustment()` avec validations métier
- **Exception dédiée** : `StocksAdjustmentsException` pour erreurs SQL/DB
- **Formulaire** : `StocksAdjustmentCreateSheet` avec sélecteur de type d'ajustement
- **Calculs automatiques** : Utilisation de `calcV15()` pour recalculer les deltas selon le type
- **Validations** :
  - Impact non nul (au moins un delta ≠ 0)
  - Plages valides pour température et densité
  - Raison minimum 10 caractères
- **Accès** : Uniquement depuis les écrans de détail Réception/Sortie, visible uniquement pour les administrateurs
- **Rafraîchissement** : Invalidation automatique des providers Dashboard/Citernes/Stock après création

### 📚 Référentiels (Lecture seule via Supabase)
- Fournisseurs
- Produits
- Dépôts
- Clients
- Citernes
- Partenaires
**⚠️ Alimentation manuelle via Supabase (admin uniquement)**

### 📈 Dashboard

#### Architecture KPI (Production-Ready)
- **Architecture modulaire** :
  - **Providers bruts** : `receptionsRawTodayProvider`, `sortiesRawTodayProvider` (rows brutes depuis Supabase)
  - **Fonctions pures** : `computeKpiReceptions()`, `computeKpiSorties()` (calcul métier isolé, testable)
  - **Providers KPI** : `receptionsKpiTodayProvider`, `sortiesKpiTodayProvider` (orchestration)
  - **Provider global** : `kpiProviderProvider` (agrégation dans `KpiSnapshot`)
- **Modèles enrichis** :
  - `KpiReceptions` : `count`, `volumeAmbient`, `volume15c`, `countMonaluxe`, `countPartenaire`
  - `KpiSorties` : `count`, `volumeAmbient`, `volume15c`, `countMonaluxe`, `countPartenaire`
  - `KpiSnapshot` : Agrégation de tous les KPI (réceptions, sorties, stocks, balance, tendances, alertes)
- **Testabilité** : Architecture 100% testable sans dépendance à Supabase (injection de données mockées)
- **Source de données stocks** : Utilise `v_stock_actuel` via `fetchStockActuelRows()` (migration complète 01/01/2026)
  - Agrégation Dart pour totaux globaux et par propriétaire
  - Inclut automatiquement les ajustements dans les calculs

#### Fonctionnalités
- Récap volumes stockés, reçus, sortis
- **KPI Réceptions du jour** : Count, volumes (ambiant/15°C), répartition MONALUXE/PARTENAIRE
- **KPI Sorties du jour** : Count, volumes (ambiant/15°C), répartition MONALUXE/PARTENAIRE
- **KPI Stocks** : Stocks totaux (global) et stocks par propriétaire (MONALUXE / PARTENAIRE)
- **KPI Balance** : Balance du jour (réceptions - sorties)
- **Camions à suivre** : Cours de route en cours (CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE)
- Filtres : date, produit, citerne, propriétaire (à venir)
- Alertes :
  - ❗ Seuil de sécurité bas
  - 🛢 Citerne vide ou inactive
  - 🚫 Erreur de validation d'une sortie ou réception
  - 🔐 Tentative d'accès non autorisé

### 🧾 Logs
- Toutes actions critiques sont historisées dans `log_actions`
- Exemples : `RECEPTION_CREEE`, `SORTIE_CREEE`, `CITERNE_MODIFIEE`
- Champs : `user_id`, `action`, `module`, `niveau`, `details` (JSONB), `cible_id`, `created_at`
- Visible selon rôle
- **Journalisation automatique** : Via triggers SQL pour réceptions et sorties

---

## 🏗️ Architecture Technique

### Backend (PostgreSQL/Supabase)

#### Triggers et Fonctions SQL
- **Réceptions** :
  - `receptions_apply_effects()` : Calcul volumes, crédit stock, passage cours de route à DECHARGE
  - `receptions_log_created()` : Journalisation
  - `trg_receptions_apply_effects` : AFTER INSERT
  - `trg_receptions_log_created` : AFTER INSERT
- **Sorties** :
  - `fn_sorties_after_insert()` : **Trigger unifié** (validation, débit stock, journalisation)
  - `sorties_check_produit_citerne()` : Validation produit/citerne (BEFORE INSERT)
  - `sortie_before_upd_trg()` : Immutabilité hors brouillon (BEFORE UPDATE)
  - `trg_sorties_after_insert` : AFTER INSERT (unifié)
  - `trg_sorties_check_produit_citerne` : BEFORE INSERT
  - `trg_sortie_before_upd_trg` : BEFORE UPDATE
- **Stocks** :
  - `stock_upsert_journalier()` : Upsert avec support `proprietaire_type`, `depot_id`, `source`
  - Contrainte UNIQUE : `(citerne_id, produit_id, date_jour, proprietaire_type)`
- **Ajustements** :
  - `apply_stock_adjustment()` : Application des ajustements au stock journalier (trigger AFTER INSERT)
  - Journalisation automatique avec niveau CRITICAL dans `log_actions`

#### Migrations SQL
- **Idempotentes** : Toutes les migrations peuvent être rejouées sans erreur
- **Structure** : Sections claires avec commentaires (STEP 1, STEP 2, etc.)
- **Backfill** : Mise à jour des données existantes avec valeurs par défaut
- **Index** : Index composites pour performance

#### Vue canonique : v_stock_actuel
- **Source de vérité unique** : Toute lecture de stock actuel DOIT utiliser `v_stock_actuel`
- **Inclut automatiquement** : Réceptions validées + Sorties validées + Ajustements
- **Utilisée par** : Dashboard, Citernes, Module Stock
- **Migration complète** : Tous les modules alignés sur `v_stock_actuel` (01/01/2026)
- **Voir** : `docs/db/CONTRAT_STOCK_ACTUEL.md` pour le contrat complet

### Frontend (Flutter)

#### Architecture KPI
- **Séparation des responsabilités** :
  - **Accès DB** : Providers bruts (`*RawTodayProvider`)
  - **Calcul métier** : Fonctions pures (`computeKpi*()`)
  - **Orchestration** : Providers KPI (`*KpiTodayProvider`)
- **Testabilité** : Injection de données mockées dans les tests
- **Maintenabilité** : Code clair, documenté, cohérent entre Réceptions et Sorties

#### Gestion d'erreurs
- **Exceptions métier** : `SortieValidationException` (validations côté Flutter)
- **Exceptions service** : `SortieServiceException` (erreurs SQL/DB)
- **Mapping** : Messages utilisateur lisibles pour chaque erreur du trigger
- **Affichage** : SnackBars avec messages clairs et codes d'erreur

#### State Management
- **Riverpod** : Providers pour données, services, état
- **Auto-dispose** : Providers auto-dispose pour performance
- **Invalidation** : Invalidation automatique après création/modification
- **Rafraîchissement après ajustement** : Invalidation automatique des providers Dashboard/Citernes/Stock

#### CI/CD (GitHub Actions)
- **Flutter analyze** : Non-bloquant pour MVP (warnings visibles dans les logs)
- **Dart format** : Non-bloquant pour MVP (formatting issues visibles dans les logs)
- **Tests** : Bloquants (compilation et tests unitaires/widgets)
- **Note** : Lint cleanup prévu en AXE B / post-MVP

---

## 🛡 Sécurité & Permissions (Supabase RLS)
- 🔐 Authentification : via Supabase (JWT)
- 🧾 RLS activées par table
- Tables sécurisées par rôle utilisateur
- Audit trail pour chaque action critique
- **Fonctions SECURITY DEFINER** : Triggers et fonctions avec privilèges élevés pour logique métier

---

## ❗ Gestion des erreurs critiques

### Backend (Triggers SQL)
- ❌ Volume > capacité citerne → erreur bloquante
- ❌ Volume négatif → rejet de l'enregistrement
- ❌ Saisie dans citerne inactive → rejet
- ❌ Produit incompatible avec citerne → rejet
- ❌ Stock insuffisant → rejet
- ❌ Dépassement capacité de sécurité → rejet
- ❌ MONALUXE sans client_id → rejet
- ❌ PARTENAIRE sans partenaire_id → rejet
- ❌ Indices incohérents → rejet
- ❌ Ajustement avec impact nul → rejet
- ❌ Ajustement sans raison (ou raison < 10 caractères) → rejet
- ❌ Ajustement créé par non-admin → rejet (RLS)

### Frontend (Flutter)
- ⚠ Rôle non autorisé → interdiction d'action (lecture seule)
- ⚠ Erreurs SQL → Messages utilisateur lisibles via `SortieServiceException`
- ⚠ Validations métier → Messages clairs via `SortieValidationException`

---

## 🧪 Tests

### Tests Backend (SQL)
- **Documentation de tests manuels** : `docs/db/sorties_trigger_tests.md`
  - 12 cas de test (4 OK, 8 ERREUR)
  - SQL prêt à exécuter dans Supabase SQL Editor
  - Vérifications `stocks_journaliers` et `log_actions`

### Tests Frontend (Flutter)

#### Tests Unitaires
- **Fonctions pures KPI** : `computeKpiReceptions()`, `computeKpiSorties()`
  - Tests isolés sans dépendance à Supabase
  - Gestion formats numériques (virgules, points, espaces)
  - Comptage MONALUXE/PARTENAIRE
- **Services** : `SortieService`, `ReceptionService`
  - Validations métier
  - Gestion d'erreurs
  - Mapping erreurs SQL

#### Tests Providers
- **Providers KPI** : `receptionsKpiTodayProvider`, `sortiesKpiTodayProvider`
  - Injection de données mockées
  - Agrégation correcte
  - Conversion en modèles

#### Tests Widgets
- **Dashboard** : Carte KPI Réceptions, Carte KPI Sorties
- **Formulaires** : Réception, Sortie
- **Listes** : Réceptions, Sorties

#### Tests d'Intégration (SKIP par défaut)
- **Sorties → Stocks** : `sortie_stocks_integration_test.dart`
  - Vérification mise à jour `stocks_journaliers` via trigger
  - Vérification séparation MONALUXE/PARTENAIRE
  - Vérification `log_actions`

### Tests Critiques Recommandés
- ✅ Tester qu'un opérateur ne peut pas valider une réception
- ✅ Valider une sortie sur une citerne partagée (stock partenaire)
- ✅ Vérifier que les volumes à 15°C sont calculés correctement
- ✅ Recalcul des stocks après réception/sortie
- ✅ Vérifier comportement des alertes du dashboard
- ✅ Vérifier séparation des stocks MONALUXE vs PARTENAIRE
- ✅ Vérifier journalisation automatique dans `log_actions`
- ✅ Vérifier que les ajustements sont visibles immédiatement dans Dashboard/Citernes/Stock
- ✅ Vérifier que seuls les admins peuvent créer des ajustements
- ✅ Vérifier que les ajustements sont reflétés dans `v_stock_actuel`

---

## 📖 Glossaire des termes métier
| Terme                  | Définition |
|------------------------|------------|
| Volume à 15°C         | Volume corrigé à température de référence (15°C) |
| BL/CMR                 | Bordereau de Livraison / Convention Marchandise Routière |
| Capacité de sécurité   | Volume réservé pour la sécurité (ex. incendie) |
| Partenaire             | Client ou fournisseur tiers non-Monaluxe |
| Cours de route         | Transport entrant de produits avant réception |
| RLS (Row Level Security)| Mécanisme de filtrage par utilisateur Supabase |
| Propriétaire           | Type de propriétaire du stock (MONALUXE ou PARTENAIRE) |
| Index                  | Mesure de niveau dans une citerne (avant/après) |
| Stock journalier       | Stock calculé par jour, par citerne, par produit, par propriétaire |
| Ajustement de stock    | Correction officielle du stock après validation (uniquement admin) |
| v_stock_actuel         | Vue canonique source de vérité unique pour le stock actuel |
| Delta                  | Variation de volume (positif = ajout, négatif = retrait) |

---

## ⚠ Risques anticipés
- ⚡ Recalculs de stock fréquents → impact performance (mitigé par index composites)
- 📊 Affichage de gros volumes de données (stocks journaliers) → pagination nécessaire
- 🔒 Sécurité des rôles mal définie → exposition des données sensibles (mitigé par RLS)
- 🌐 Connectivité lente → fallback partiel offline requis (à venir)
- 🔄 Synchronisation stocks MONALUXE/PARTENAIRE → validation manuelle recommandée

---

## 📋 SUPPLÉMENT PRD – Version MVP Janvier 2026

### 0) Migration complète sur v_stock_actuel (01/01/2026)

#### Alignement architectural
- **Source de vérité unique** : `v_stock_actuel` est la SEULE source pour le stock actuel
- **Migration complète** : Tous les modules utilisent désormais `v_stock_actuel`
  - ✅ Dashboard : Agrégation depuis `v_stock_actuel` via `fetchStockActuelRows()`
  - ✅ Citernes : Agrégation depuis `v_stock_actuel` par `citerne_id`
  - ✅ Module Stock : Agrégation depuis `v_stock_actuel` pour les totaux
- **Méthode canonique** : `StocksKpiRepository.fetchStockActuelRows()` créée et utilisée partout
- **Impact immédiat** : Les ajustements sont visibles immédiatement dans tous les modules
- **Vues dépréciées** : `v_stock_actuel_snapshot`, `v_citerne_stock_snapshot_agg`, `v_stock_actuel_owner_snapshot` (remplacées par agrégation Dart)

### 1) Système d'ajustements de stock industriel

#### Fonctionnalités
- **Types d'ajustements** : Volume, Température, Densité, Mixte
- **Calculs automatiques** : Utilisation de `calcV15()` pour recalculer les deltas
- **Préfixage automatique** : Raison préfixée avec `[VOLUME]`, `[TEMP]`, `[DENSITE]`, `[MIXTE]`
- **Validations** : Impact non nul, plages valides, raison minimum 10 caractères
- **Accès** : Uniquement depuis écrans de détail Réception/Sortie, visible uniquement pour admins
- **Impact** : Immédiatement reflété dans `v_stock_actuel` et tous les modules

#### Architecture
- **Table** : `stocks_adjustments` avec contraintes strictes
- **Trigger** : `apply_stock_adjustment()` pour application automatique
- **RLS** : INSERT réservé aux administrateurs
- **Journalisation** : Niveau CRITICAL dans `log_actions`

## 📋 SUPPLÉMENT PRD – Version MVP Décembre 2025

### 1) Architecture KPI Production-Ready

#### Réceptions et Sorties
- **Fonctions pures** : `computeKpiReceptions()`, `computeKpiSorties()`
  - 100% testables sans dépendance à Supabase
  - Gestion robuste des formats numériques
  - Comptage séparé MONALUXE/PARTENAIRE
- **Providers bruts** : `receptionsRawTodayProvider`, `sortiesRawTodayProvider`
  - Overridables dans les tests
  - Injection de données mockées
- **Modèles enrichis** : `KpiReceptions`, `KpiSorties`
  - Champs : `count`, `volumeAmbient`, `volume15c`, `countMonaluxe`, `countPartenaire`
  - Méthode `toKpiNumberVolume()` pour compatibilité
- **Tests complets** : Unitaires, providers, widgets

### 2) Backend SQL - Triggers Unifiés

#### Réceptions
- **Trigger unifié** : `receptions_apply_effects()`
  - Calcul volumes (ambiant, 15°C)
  - Crédit stock via `stock_upsert_journalier()`
  - Passage cours de route à DECHARGE
  - Journalisation automatique

#### Sorties
- **Trigger unifié** : `fn_sorties_after_insert()`
  - Validation métier complète (citerne, produit, stock, propriétaire)
  - Débit stock via `stock_upsert_journalier()` avec volumes négatifs
  - Journalisation automatique
  - Remplace les anciens triggers séparés

#### Stocks Journaliers
- **Migration** : Ajout colonnes `proprietaire_type`, `depot_id`, `source`
- **Contrainte UNIQUE** : `(citerne_id, produit_id, date_jour, proprietaire_type)`
- **Séparation complète** : Stocks MONALUXE et PARTENAIRE séparés
- **Fonction upsert** : `stock_upsert_journalier()` avec support nouveaux paramètres

### 3) Gestion d'erreurs robuste

#### Frontend
- **Exception dédiée** : `SortieServiceException` pour erreurs SQL/DB
- **Mapping d'erreurs** : Messages utilisateur lisibles pour chaque erreur du trigger
- **Affichage** : SnackBars avec messages clairs et codes d'erreur

#### Backend
- **Messages d'erreur explicites** : Chaque validation retourne un message clair
- **Codes d'erreur** : Codes PostgreSQL standard (23505 pour unique violation, etc.)

### 4) Documentation et Tests

#### Documentation
- **Tests manuels** : `docs/db/sorties_trigger_tests.md` avec 12 cas de test
- **Migrations** : Commentaires clairs, sections structurées
- **CHANGELOG** : Documentation complète des évolutions

#### Tests
- **Unitaires** : Fonctions pures, services, providers
- **Widgets** : Dashboard, formulaires, listes
- **Intégration** : Tests SKIP par défaut (activation manuelle)

---

## 🎯 Prochaines étapes recommandées

1. **Validation manuelle du trigger SQL** : Exécuter les 12 tests manuels dans Supabase
2. **Activation tests d'intégration** : Configurer SupabaseClient de test et activer les tests SKIP
3. **Améliorations UX** : Badges propriétaire, filtres avancés, indicateurs visuels
4. **Export CSV/PDF** : Stocks journaliers, réceptions, sorties
5. **Offline mode** : Cache local pour fonctionnement hors ligne partiel

---

**Version** : 5.0  
**Date** : Janvier 2026  
**Dernière mise à jour** : 01/01/2026

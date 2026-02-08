# État Production — ML_PP MVP

**Projet** : ML_PP MVP (Monaluxe Petrol Platform)  
**Date d'activation** : 2026-02-05  
**Statut** : 🟢 **PROD EN EXPLOITATION**  
**Responsable** : Valery Kalonga  
**Version** : 1.0

---

## 1. Résumé exécutif

- **Environnement PROD** : Base de données Supabase Postgres + Frontend Flutter Web (Firebase Hosting)
- **Domaine** : `https://monaluxe.app` (HTTPS actif)
- **État des données** : J0 + premières entrées métier (Monaluxe a commencé l'usage — CDR en création)
- **Exploitation** : Monaluxe a la main sur l'environnement PROD
- **Source de vérité stock** : `v_stock_actuel` (vue canonique) — toute lecture de stock actuel DOIT passer par cette vue
- **Règle d'or** : Aucune action destructive sans décision formelle et backup validé

---

## 2. Base de données PROD

### Environnement

- **DB** : Supabase Postgres
- **Schéma** : `public`
- **Source** : `staging/sql/000_prod_schema_public.safe.sql`
- **Date création** : 2026-02-05
- **État des données** : J0 + premières entrées métier (Monaluxe — CDR en création)

### Tables transactionnelles (clés)

- `citernes` : 6 citernes (TANK1 → TANK6) ; des citernes logiques supplémentaires (stock externe dépôt ami) peuvent exister — voir `docs/02_RUNBOOKS/DEPOT_AMI_STOCK_EXTERNE.md`
- `cours_de_route` : Cours de route (CDR) — **en usage réel Monaluxe**
- `receptions` : Réceptions produits
- `sorties_produit` : Sorties produits
- `stocks_snapshot` : Snapshots stock (état actuel)
- `stocks_journaliers` : Logs journaliers stock
- `log_actions` : Logs d'actions utilisateurs
- `profils` : Profils utilisateurs
- `depots` : Dépôts
- `produits` : Produits (Essence, Gasoil/AGO)

### Vues canoniques (clés)

- **`v_stock_actuel`** : **Source unique de vérité pour le stock actuel** — toute lecture de stock actuel DOIT passer par cette vue
- `v_stock_actuel_owner_snapshot` : Snapshots par propriétaire
- `v_stock_actuel_snapshot` : Snapshots globaux
- `v_kpi_stock_global` : KPI stock global

### Seed PROD-like minimal

- **Source** : `staging/sql/seed_staging_prod_like.sql`
- **Dépôts** : 1
- **Produits** : 2 (UUID canoniques alignés avec l'application Flutter)
  - Essence : `640cf7ec-1616-4503-a484-0a61afb20005`
  - Gasoil/AGO : `22222222-2222-2222-2222-222222222222`
- **Citernes** : 6 (TANK1 → TANK6)

---

## 3. Frontend Web PROD

### Déploiement

- **Plateforme** : Firebase Hosting
- **Domaine** : `https://monaluxe.app` (HTTPS actif)
- **Build** : `flutter build web --release` avec `--dart-define SUPABASE_URL` + `--dart-define SUPABASE_ANON_KEY`
- **Déploiement** : `firebase deploy --only hosting`

### Statut navigateurs

- ✅ Chrome : OK
- ✅ Safari : OK (incident écran blanc résolu le 2026-02-05 — voir `docs/02_RUNBOOKS/GO_LIVE_FRONT_CHECKPOINT_2026-02-02.md`)

---

## 4. Backups

### Backups J0 (2026-02-05)

- **Backup schéma seul** : `backups/ml_pp_prod_J0_schema_only.dump`
- **Backup schéma + données** : `backups/ml_pp_prod_J0_seeded_with_data.dump`

### Chemins et noms

- **Répertoire** : `backups/`
- **Convention** : `ml_pp_prod_J{jour}_{description}.dump`
- **J0** : Jour 0 (initialisation PROD — 2026-02-05)

### Règle de gouvernance

- ✅ **Backup préalable obligatoire** : Toute action DB en PROD nécessite un backup validé avant exécution
- ✅ **Traçabilité** : Tous les backups doivent être documentés et datés

---

## 5. Règles et interdictions

### Interdictions absolues

- ❌ **Aucune réinitialisation PROD** : Interdiction de reset/drop `public` en PROD
- ❌ **Aucune modification DB sans backup** : Backup préalable obligatoire pour toute action DB
- ❌ **Aucun seed direct** : Aucun seed appliqué directement en PROD sans validation formelle
- ❌ **Aucune remise en question GO PROD** : La décision GO PROD est assumée et traçable

### Règles de gouvernance

- ✅ **Toute action future** : Doit être classée comme POST-PROD / MAINTENANCE / SCALE / AUDIT
- ✅ **Validation formelle** : Toute modification PROD doit être validée par le responsable technique
- ✅ **Traçabilité** : Toute action PROD doit être documentée et traçable

---

## 6. Source de vérité stock (rappel critique)

### Vue canonique

**`v_stock_actuel`** est la **source unique de vérité** pour le stock actuel.

- ✅ **Toute lecture de stock actuel** DOIT passer par `v_stock_actuel`
- ❌ **Interdiction** : Lecture directe depuis `stocks_journaliers` pour le stock actuel
- ✅ **Historique** : `stocks_journaliers` pour les snapshots historiques (avec `date_jour`)

### Règle de validation sortie

- **Interdiction DB** : Une sortie ne peut pas être validée si `stocks_snapshot` est vide
- **Bootstrap** : Le snapshot est bootstrapé uniquement par une réception validée
- **Documentation** : `docs/db/stocks_views_contract.md`

---

## 7. Exploitation

### Statut

- **Exploitation en cours** : Monaluxe a la main sur l'environnement PROD
- **Création CDR** : En cours d'utilisation réelle
- **Flux opérationnel** : CDR → Réception → Stock → Sortie validé et en production

### Responsable

- **Nom** : Valery Kalonga
- **Rôle** : Responsable technique PROD

---

## 8. Références

### Documents de décision

- `docs/01_DECISIONS/DECISION_GO_PROD_2026_01.md` : Décision GO PROD (2026-01-27) + Avenant activation (2026-02-05)

### Documents opérationnels

- `docs/02_RUNBOOKS/GO_LIVE_FRONT_CHECKPOINT_2026-02-02.md` : Checkpoint GO-LIVE Frontend + Incident Safari
- `docs/02_RUNBOOKS/RESET_STAGING_RUNBOOK.md` : Runbook reset STAGING (⚠️ ne s'applique PAS à PROD)
- `docs/02_RUNBOOKS/DEPOT_AMI_STOCK_EXTERNE.md` : Stock externe dépôt ami (citerne logique) — procédure et garde-fous
- `docs/03_TESTING/END_TO_END_VALIDATION.md` : Validation end-to-end GO PROD

### Documents techniques

- `docs/db/stocks_views_contract.md` : Contrat vues stock (`v_stock_actuel`)
- `docs/00_REFERENCE/TRANSACTION_CONTRACT.md` : Contrat transactionnel DB

### Historique

- `CHANGELOG.md` : Entrée [2026-02-05] — GO-LIVE PROD EFFECTIF

---

## 📦 Module Fournisseurs — Sprint 1 (Lecture seule)

**Statut :** ✅ ACTIF EN PROD  
**Date d'intégration :** 2026-02-08  
**Portée :** Lecture seule (liste + détail)

### Fonctionnalités disponibles
- Liste des fournisseurs
- Recherche (nom, pays, contact)
- Consultation fiche fournisseur

### Sécurité & rôles
- Accès autorisé :
  - Admin
  - Directeur
  - Gérant
  - PCA
- Accès refusé (menu + route) :
  - Opérateur
  - Lecture

### Navigation
- Entrée **Fournisseurs** visible dans le menu principal
- Position : après **Cours de route**
- Source de vérité : `nav_config.dart`

### Qualité & validation
- Tests UI Fournisseurs : ✅
- Tests unitaires navigation (role-gating) : ✅
- CI Flutter : ✅ (PR #56, #57)

### Impact PROD
- ❌ Aucun changement base de données
- ❌ Aucun impact sur flux métier critiques
- ✅ Module isolé

---

## POST-PROD — Chaîne Contractuelle Fournisseur (ERP-grade)

Le module **Chaîne Contractuelle Fournisseur** est une évolution **POST-PROD** strictement **non destructive** et **compatible PROD**.  
Il n'a **aucun impact** sur le flux cœur immuable :

**Cours de Route → Réception → Stock → Sortie**

### Références officielles
- Requirements (normatif) : `docs/05_REQUIREMENTS/REQUIREMENT_FOURNISSEUR_CONTRACT_CHAIN_V2.md`
- User Stories (backlog) : `docs/06_USER_STORIES/USER_STORIES_FOURNISSEUR_V2.md`
- Plan d'exécution (sprints) : `docs/04_PLANS/PLAN_POST_PROD_FOURNISSEURS_V2.md`

### Chaîne couverte
**SBLC → Proforma → Cours de Route → Réceptions → Écarts → Facture Finale → Paiements → Compte & Relevé Fournisseur**

### Contraintes de sécurité
- Interdiction d'automatisation bancaire (paiements déclaratifs)
- Dette créée uniquement à la validation de la facture finale
- Traçabilité & audit obligatoires (logs + snapshots)
- RLS obligatoire par rôle (PCA lecture globale)

---

**Document créé le** : 2026-02-05  
**Dernière mise à jour** : 2026-02-08  
**Version** : 1.0  
**Responsable** : Valery Kalonga

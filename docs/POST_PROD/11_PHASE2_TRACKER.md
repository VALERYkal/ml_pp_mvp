# POST-PROD — Phase 2 : Tracker

**Référence** : [09_PHASE2_STRATEGIE.md](09_PHASE2_STRATEGIE.md) | [10_PHASE2_PLAN_10_ACTIONS.md](10_PHASE2_PLAN_10_ACTIONS.md)

---

## Tableau de suivi

| ID | Action | Axe | Priorité | Statut | Owner | PR/Commit | Date début | Date fin | Notes |
|----|--------|-----|----------|--------|-------|-----------|------------|----------|-------|
| 1 | Vue SQL v_integrity_checks | 1 | P1 | DONE (STAGING + PROD) | — | — | — | — | voir Evidence ci-dessous |
| 2 | Table system_alerts (persistence + workflow) | 1 | P1 | DONE (PROD) | — | — | — | — | Patch 2.1→2.4 déployés. Dette technique documentée (PHASE2_TECH_DEBT.md). |
| 3 | Job périodique d'évaluation (DOC) | 1 | P1 | TODO | — | — | — | — | |
| 4 | Écran intégrité système | 1 | P2 | DONE (DOC + IMPLEMENTATION) | — | PR #71 / 9a80413 | 2026-02-19 | 2026-02-19 | UI livrée, tests OK |
| 5 | Standardiser APP_ENV & APP_RELEASE (DOC) | 2 | P1 | TODO | — | — | — | — | |
| 6 | Endpoint /health + 2e monitor uptime (DOC) | 2 | P2 | TODO | — | — | — | — | |
| 7 | Audit RLS complet + hardening (0 public policies) | 3 | P1 | DONE | — | docs(post-prod) | 2026-02-21 | 2026-02-21 | Runbook + deploy log Entry 2 |
| 8 | Journal accès suspect (DOC) | 3 | P2 | TODO | — | — | — | — | |
| 9 | Hash release visible UI (DOC) | 4 | P2 | TODO | — | — | — | — | |
| 10 | Runbook rollback web (DOC) | 4 | P1 | TODO | — | — | — | — | |

**Légende Statut** : TODO | IN_PROGRESS | DONE | BLOCKED

### Action 1 — Evidence (DONE STAGING + PROD)
- **Script** : `staging/sql/phase2/phase2_01_v_integrity_checks.sql`
- **Contrat** : `docs/db/v_integrity_checks_contract.md`
- **Vue** : `public.v_integrity_checks`
- **Risk** : Low
- **Rollback** : `DROP VIEW public.v_integrity_checks`
- **Validation STAGING** : 1 alerte CDR_ARRIVE_STALE pertinente, 0 bruit sur STOCK_NEGATIF / STOCK_OVER_CAPACITY / RECEPTION_ECART_15C / SORTIE_ECART_15C.
### Action 2 — Découpage (persistence + workflow)

| Patch | Description | Artifacts | Statut |
|-------|-------------|-----------|--------|
| 2.1 | DOC + SQL STAGING | `docs/db/spec_system_alerts.md`, `staging/sql/phase2/phase2_02_system_alerts.sql` | DONE (PROD) |
| 2.2 | Job de sync (v_integrity_checks → system_alerts) | `staging/sql/phase2/phase2_03_system_alerts_sync.sql` | MERGED (PR #73) |
| 2.3 | STAGING execution proof | — | DONE |
| 2.4 | UI workflow ACK/RESOLVE | Flutter (IntegrityChecksScreen, repository) | DONE (PROD) |

**Proof (STAGING)** :
- system_alerts créée après sync (OPEN count = 1)
- Idempotence confirmée (first_detected_at stable, last_detected_at mis à jour)
- Auto-resolve confirmé via FAKE_CHECK → RESOLVED (resolved_by NULL)

**PR** : 2.2 merged via PR #73.

**Evidence PROD (Action 2.4 — Feb 2026)** :
- Table `public.system_alerts` + trigger `trg_system_alerts_set_actor`
- Policies : `system_alerts_select_authenticated`, `system_alerts_update_admin_directeur`
- Web déployé sur https://monaluxe.app (Firebase Hosting ml-pp-mvp-web)
- Dette technique : `docs/POST_PROD/PHASE2_TECH_DEBT.md`

### PROD Validation Snapshot
- CDR_ARRIVE_STALE: 5
- No critical alerts
- Backup validated

---

## PROD Operation — ASTM 53B Volumetric Migration

**Statut** : IN PROGRESS — PRE-BACKUP DOC

**Runbook** : [RUNBOOK_VOLUMETRICS_ASTM_53B_MIGRATION.md](RUNBOOK_VOLUMETRICS_ASTM_53B_MIGRATION.md)

**Checklist** :
- [ ] Doc package créé (ce PR)
- [x] Backup PROD effectué : `backups/prod_pre_astm53b_20260221_2253_data.dump` (pré-requis avant BLOC 2 — moteur ASTM 53B)
- [ ] Golden dataset capturé (20–30 cas) + suite de tests verte
- [ ] Rapport de simulation approuvé (8 réceptions)
- [ ] Migration exécutée + rebuild stock fait
- [ ] Sorties dégelées
- [ ] Vérification post-migration (spot checks vs app ASTM)

**BLOC 2 — Progression ASTM 53B** :

| Étape | Description | Statut |
|-------|--------------|--------|
| A | Squelette moteur ASTM 53B (astm53b_engine.dart) | [x] Fait |
| B | Dataset golden ASTM 53B (structure + tests) | [x] Fait |
| C | Calibration moteur + formule ASTM 53B | [ ] À faire |

**Notes Étape B** :
- Fichier : `lib/core/volumetrics/astm53b_golden_cases.dart`
- Test : `test/core/volumetrics/astm53b_golden_test.dart`
- Valeurs encore placeholders ; calibration prévue Étape C.

**Risk / Notes** :
- Ne pas valider de sorties pendant l'opération.
- Aucune mise à jour silencieuse ; logger l'événement global.
- Sémantique : `densite_a_15` est un misnomer actuel (stocke la densité observée, pas la densité@15).

---

### Action 7 — Evidence (DONE — RLS Hardening Feb 2026)
- **Objectif** : Audit RLS + élimination des policies `{public}` (exposition ANON).
- **STAGING** : DROP/migration policies `{public}` (log_actions, stocks_journaliers, citernes, puis 14 policies conditionnelles → `authenticated`). Vérif : count(public) = 0.
- **PROD** : Correction fuites critiques (DROP `read stocks_journaliers`, DROP `read citernes`). Migration `{public}` → `{authenticated}` sur profils, cours_de_route, prises_de_hauteur, sorties_produit, stocks_journaliers. Vérif : count(public) = 0 ; curl ANON → `[]` sur tables sensibles.
- **Docs** : `docs/POST_PROD/RUNBOOK_RLS_HARDENING.md`, `12_PHASE2_PROD_DEPLOY_LOG.md` (Entry 2), stratégie/plan mis à jour (standard "0 public policies").
- **Rollback** : Recreate policy if needed (see runbook). No data mutation.

### Action 4 — Evidence (DONE DOC + IMPLEMENTATION)
- Route: `/governance/integrity`
- Rôles: admin, directeur, pca
- Repository: `lib/features/governance/data/integrity_repository.dart`
- Provider: `integrityChecksProvider`
- Screen: `IntegrityChecksScreen`
- Tests:
  - integrity_check_test.dart
  - integrity_checks_screen_test.dart
- PR: #71
- Tag: checkpoint-phase2-integrity-ui-2026-02-19
- No DB mutation
- No contract modification

---

## Checkpoint actuel

Phase 2 : Action 1 (v_integrity_checks) DONE ; Action 2 (system_alerts + workflow ACK/RESOLVE) **DONE (PROD)** ; Action 4 (Écran intégrité système) DONE ; Action 7 (Audit RLS + hardening) DONE. Table `public.system_alerts` déployée avec trigger actor. UI Integrity Checks avec boutons ACK/RESOLVE en exploitation sur https://monaluxe.app. Dette technique documentée dans `docs/POST_PROD/PHASE2_TECH_DEBT.md`.

---

## Note — Statut README (Feb 2026)

Le README racine a été mis à jour : reclassification "Industriel NO-GO" → "Industriel opérationnel" suite au RLS hardening (0 policy `{public}`). Références : [RUNBOOK_RLS_HARDENING.md](RUNBOOK_RLS_HARDENING.md), [PHASE2_TECH_DEBT.md](PHASE2_TECH_DEBT.md).

---

## Règles d'update

À chaque PR ou commit lié à la Phase 2 :

1. Mettre à jour la colonne **Statut** de l'action concernée (TODO → IN_PROGRESS → DONE).
2. Renseigner **PR/Commit** (lien ou hash).
3. Renseigner **Date début** et **Date fin** si applicable.
4. Ajouter une ligne en **Notes** en cas de blocage ou décision importante.
5. Mettre à jour la section **Checkpoint actuel** si le résumé global change.

# POST-PROD — Phase 2 : Tracker

**Référence** : [09_PHASE2_STRATEGIE.md](09_PHASE2_STRATEGIE.md) | [10_PHASE2_PLAN_10_ACTIONS.md](10_PHASE2_PLAN_10_ACTIONS.md)

---

## Tableau de suivi

| ID | Action | Axe | Priorité | Statut | Owner | PR/Commit | Date début | Date fin | Notes |
|----|--------|-----|----------|--------|-------|-----------|------------|----------|-------|
| 1 | Vue SQL v_integrity_checks | 1 | P1 | DONE (STAGING + PROD) | — | — | — | — | voir Evidence ci-dessous |
| 2 | Table system_alerts (persistence + workflow) | 1 | P1 | TODO | — | — | — | — | Patch 2.1 (DOC+SQL STAGING) → 2.2 (sync job) → 2.3 (UI workflow) |
| 3 | Job périodique d'évaluation (DOC) | 1 | P1 | TODO | — | — | — | — | |
| 4 | Écran intégrité système | 1 | P2 | DONE (DOC + IMPLEMENTATION) | — | PR #71 / 9a80413 | 2026-02-19 | 2026-02-19 | UI livrée, tests OK |
| 5 | Standardiser APP_ENV & APP_RELEASE (DOC) | 2 | P1 | TODO | — | — | — | — | |
| 6 | Endpoint /health + 2e monitor uptime (DOC) | 2 | P2 | TODO | — | — | — | — | |
| 7 | Audit RLS complet (DOC) | 3 | P1 | TODO | — | — | — | — | |
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
- **Next** : Action 2 (system_alerts persistence) reste TODO.

### Action 2 — Découpage (persistence + workflow)

| Patch | Description | Artifacts | Statut |
|-------|-------------|-----------|--------|
| 2.1 | DOC + SQL STAGING | `docs/db/spec_system_alerts.md`, `staging/sql/phase2/phase2_02_system_alerts.sql` | TODO |
| 2.2 | Job de sync (v_integrity_checks → system_alerts) | `spec_job_integrity_evaluation.md`, migration SQL | TODO |
| 2.3 | UI workflow ACK/RESOLVE | Flutter (IntegrityChecksScreen, repository) | TODO |

**PR** : placeholder (à créer pour 2.1 après validation STAGING).

### PROD Validation Snapshot
- CDR_ARRIVE_STALE: 5
- No critical alerts
- Backup validated

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

Phase 2 : Action 1 (v_integrity_checks) DONE ; Action 4 (Écran intégrité système) DONE (DOC + IMPLEMENTATION). Vue `public.v_integrity_checks` déployée. UI Integrity Checks exploitable en PROD. Backup PROD validé. Prochaine étape : Action 2 (system_alerts).

---

## Règles d'update

À chaque PR ou commit lié à la Phase 2 :

1. Mettre à jour la colonne **Statut** de l'action concernée (TODO → IN_PROGRESS → DONE).
2. Renseigner **PR/Commit** (lien ou hash).
3. Renseigner **Date début** et **Date fin** si applicable.
4. Ajouter une ligne en **Notes** en cas de blocage ou décision importante.
5. Mettre à jour la section **Checkpoint actuel** si le résumé global change.

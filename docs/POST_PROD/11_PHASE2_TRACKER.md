# POST-PROD — Phase 2 : Tracker

**Référence** : [09_PHASE2_STRATEGIE.md](09_PHASE2_STRATEGIE.md) | [10_PHASE2_PLAN_10_ACTIONS.md](10_PHASE2_PLAN_10_ACTIONS.md)

---

## Tableau de suivi

| ID | Action | Axe | Priorité | Statut | Owner | PR/Commit | Date début | Date fin | Notes |
|----|--------|-----|----------|--------|-------|-----------|------------|----------|-------|
| 1 | Vue SQL v_integrity_checks | 1 | P1 | DONE (STAGING) | — | — | — | — | voir Evidence ci-dessous |
| 2 | Table system_alerts (DOC) | 1 | P1 | TODO | — | — | — | — | |
| 3 | Job périodique d'évaluation (DOC) | 1 | P1 | TODO | — | — | — | — | |
| 4 | Écran intégrité système (DOC) | 1 | P2 | TODO | — | — | — | — | |
| 5 | Standardiser APP_ENV & APP_RELEASE (DOC) | 2 | P1 | TODO | — | — | — | — | |
| 6 | Endpoint /health + 2e monitor uptime (DOC) | 2 | P2 | TODO | — | — | — | — | |
| 7 | Audit RLS complet (DOC) | 3 | P1 | TODO | — | — | — | — | |
| 8 | Journal accès suspect (DOC) | 3 | P2 | TODO | — | — | — | — | |
| 9 | Hash release visible UI (DOC) | 4 | P2 | TODO | — | — | — | — | |
| 10 | Runbook rollback web (DOC) | 4 | P1 | TODO | — | — | — | — | |

**Légende Statut** : TODO | IN_PROGRESS | DONE | BLOCKED

### Action 1 — Evidence (DONE STAGING)
- **Script** : `staging/sql/phase2/phase2_01_v_integrity_checks.sql`
- **Contrat** : `docs/db/v_integrity_checks_contract.md`
- **Vue** : `public.v_integrity_checks`
- **Validation** : `select check_code, count(*) from public.v_integrity_checks group by check_code` — 1 alerte CDR_ARRIVE_STALE pertinente, 0 bruit sur STOCK_NEGATIF / STOCK_OVER_CAPACITY / RECEPTION_ECART_15C / SORTIE_ECART_15C.
- **Next** : Action 2 (system_alerts persistence) reste TODO.

---

## Checkpoint actuel

Phase 2 : Action 1 (v_integrity_checks) DONE en STAGING. Script `staging/sql/phase2/phase2_01_v_integrity_checks.sql`, contrat `docs/db/v_integrity_checks_contract.md`. Prochaine étape : Action 2 (system_alerts). Promotion PROD uniquement après PR + validation formelle.

---

## Règles d'update

À chaque PR ou commit lié à la Phase 2 :

1. Mettre à jour la colonne **Statut** de l'action concernée (TODO → IN_PROGRESS → DONE).
2. Renseigner **PR/Commit** (lien ou hash).
3. Renseigner **Date début** et **Date fin** si applicable.
4. Ajouter une ligne en **Notes** en cas de blocage ou décision importante.
5. Mettre à jour la section **Checkpoint actuel** si le résumé global change.

# POST-PROD — Phase 2 : Tracker

**Référence** : [09_PHASE2_STRATEGIE.md](09_PHASE2_STRATEGIE.md) | [10_PHASE2_PLAN_10_ACTIONS.md](10_PHASE2_PLAN_10_ACTIONS.md)

---

## Tableau de suivi

| ID | Action | Axe | Priorité | Statut | Owner | PR/Commit | Date début | Date fin | Notes |
|----|--------|-----|----------|--------|-------|-----------|------------|----------|-------|
| 1 | Vue SQL v_integrity_checks (DOC) | 1 | P1 | TODO | — | — | — | — | |
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

---

## Checkpoint actuel

Phase 2 : documentation stratégique et plan 10 actions créés. Aucune implémentation en cours. Toutes les actions sont en statut TODO. Prochaine étape : assigner les owners et lancer les specs documentaires (Actions 1, 2, 5, 7, 10 en priorité).

---

## Règles d'update

À chaque PR ou commit lié à la Phase 2 :

1. Mettre à jour la colonne **Statut** de l'action concernée (TODO → IN_PROGRESS → DONE).
2. Renseigner **PR/Commit** (lien ou hash).
3. Renseigner **Date début** et **Date fin** si applicable.
4. Ajouter une ligne en **Notes** en cas de blocage ou décision importante.
5. Mettre à jour la section **Checkpoint actuel** si le résumé global change.

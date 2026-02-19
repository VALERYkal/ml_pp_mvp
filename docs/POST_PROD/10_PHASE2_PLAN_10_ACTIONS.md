# POST-PROD — Phase 2 : Plan 10 Actions Prioritaires

**Référence** : [09_PHASE2_STRATEGIE.md](09_PHASE2_STRATEGIE.md)

---

## Ordre recommandé (Semaine 1 à 4)

| Semaine | Actions |
|---------|---------|
| S1 | 1, 2, 3 |
| S2 | 4, 5 |
| S3 | 6, 7 |
| S4 | 8, 9, 10 |

---

## Action 1 — Vue SQL v_integrity_checks (DOC + STAGING-first) ✅ DONE

| Élément | Détail |
|---------|--------|
| **Objectif** | Vue SQL agrégée des contrôles d'intégrité métier (stock négatif, surcapacité, CDR stale, écarts réception/sortie 15°C) |
| **Livrables doc** | `docs/db/v_integrity_checks_contract.md` (colonnes, sources, règles V1) |
| **Livrables tech** | `staging/sql/phase2/phase2_01_v_integrity_checks.sql` — Vue `public.v_integrity_checks` (STAGING uniquement) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Vue exécutable en STAGING + validation "pas de bruit" (ex. 1 alerte CDR_ARRIVE_STALE pertinente, 0 sur A/B/D/E) |

**Règles V1 incluses** : STOCK_NEGATIF (CRITICAL), STOCK_OVER_CAPACITY (CRITICAL), CDR_ARRIVE_STALE (WARN), RECEPTION_ECART_15C (WARN), SORTIE_ECART_15C (WARN). Promotion PROD après PR + validation formelle.

---

## Action 2 — Table system_alerts (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter la spec d’une table `system_alerts` pour persister les alertes générées par le job d’évaluation |
| **Livrables doc** | Fichier `docs/db/spec_system_alerts.md` (colonnes, contraintes, index) |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Spec validée et versionnée |

---

## Action 3 — Job périodique d’évaluation (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter le design d’un job (cron/pg_cron ou équivalent) exécutant les contrôles d’intégrité et alimentant `system_alerts` |
| **Livrables doc** | Fichier `docs/db/spec_job_integrity_evaluation.md` (fréquence, requêtes, seuils) |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Actions 1, 2 |
| **Done** | Spec validée et versionnée |

---

## Action 4 — Écran intégrité système (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter le design d’un écran Flutter « Intégrité système » affichant les alertes actives et l’état des contrôles |
| **Livrables doc** | Fichier `docs/app/spec_ecran_integrite_systeme.md` (routes, rôles, wireframes) |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Actions 1, 2, 3 |
| **Done** | Spec validée et versionnée |

---

## Action 5 — Standardiser APP_ENV & APP_RELEASE (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter la convention des variables `APP_ENV` et `APP_RELEASE` pour tous les builds (Web, mobile si applicable) et leur intégration dans le script de release |
| **Livrables doc** | Mise à jour `docs/02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md` ou doc dédiée `docs/00_REFERENCE/APP_ENV_APP_RELEASE.md` |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Doc validée et versionnée |

---

## Action 6 — Endpoint /health + 2e moniteur uptime (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter le design d’un endpoint `/health` (ou équivalent) et la configuration d’un second moniteur UptimeRobot sur ce smoke endpoint |
| **Livrables doc** | Fichier `docs/infra/spec_health_endpoint.md` + mise à jour runbook monitoring |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Spec validée et versionnée |

---

## Action 7 — Audit RLS complet (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter l’audit RLS de toutes les tables sensibles : politiques par rôle, revue des trous, recommandations |
| **Livrables doc** | Fichier `docs/db/security/AUDIT_RLS_COMPLET.md` ou mise à jour de `docs/db/policies.md` |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Audit documenté et validé |

---

## Action 8 — Journal accès suspect (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter le design d’une table/journal pour tracer les accès suspects (401, 403, tentatives anormales) |
| **Livrables doc** | Fichier `docs/db/spec_journal_acces_suspect.md` |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Action 7 |
| **Done** | Spec validée et versionnée |

---

## Action 9 — Hash release visible UI (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Documenter le design pour afficher le hash (ou tag) de release dans l’UI (footer, profil, ou écran dédié) |
| **Livrables doc** | Fichier `docs/app/spec_release_hash_ui.md` |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Action 5 |
| **Done** | Spec validée et versionnée |

---

## Action 10 — Runbook rollback web (DOC uniquement)

| Élément | Détail |
|---------|--------|
| **Objectif** | Finaliser et valider le runbook de rollback web (procédure, commandes, critères de décision) |
| **Livrables doc** | Mise à jour `docs/02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md` section Rollback, ou doc dédiée `docs/02_RUNBOOKS/ROLLBACK_WEB_RUNBOOK.md` |
| **Livrables tech** | Aucun (DOC uniquement à ce stade) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune (runbook existant à enrichir) |
| **Done** | Runbook testé et validé |

---

## Interdictions

- **lib/** : aucun changement autorisé dans cette Phase 2 (DOC uniquement).
- **test/** : aucun changement autorisé.
- **Migrations SQL** : aucune migration ni trigger ni RLS à modifier dans le cadre de ce plan DOC.

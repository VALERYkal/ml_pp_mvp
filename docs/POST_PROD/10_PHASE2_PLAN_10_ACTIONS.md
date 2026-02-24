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

## Action 1 — Vue SQL v_integrity_checks (DOC + STAGING + PROD) ✅ DONE

| Élément | Détail |
|---------|--------|
| **Statut** | DONE (STAGING) — DONE (PROD) |
| **Objectif** | Vue SQL agrégée des contrôles d'intégrité métier (stock négatif, surcapacité, CDR stale, écarts réception/sortie 15°C) |
| **Livrables doc** | `docs/db/v_integrity_checks_contract.md` (colonnes, sources, règles V1) |
| **Livrables tech** | `staging/sql/phase2/phase2_01_v_integrity_checks.sql` — Vue `public.v_integrity_checks` (STAGING + PROD) |
| **Owner** | [À assigner] |
| **Dépendances** | Aucune |
| **Done** | Vue exécutable en STAGING + validation "pas de bruit" ; Production deployment completed ; Deployment log : `docs/POST_PROD/12_PHASE2_PROD_DEPLOY_LOG.md` |

**Règles V1 incluses** : STOCK_NEGATIF (CRITICAL), STOCK_OVER_CAPACITY (CRITICAL), CDR_ARRIVE_STALE (WARN), RECEPTION_ECART_15C (WARN), SORTIE_ECART_15C (WARN).

---

## Action 2 — Table system_alerts (persistence + workflow)

| Élément | Détail |
|---------|--------|
| **Objectif** | Persister les alertes intégrité avec workflow OPEN → ACK → RESOLVED via `public.system_alerts` |
| **Livrables doc** | `docs/db/spec_system_alerts.md` (schéma, workflow, RLS, rollback) |
| **Livrables tech** | `staging/sql/phase2/phase2_02_system_alerts.sql` — table, index, RLS, trigger updated_at |
| **Approche** | STAGING-first puis PROD avec backup. Sync job séparé (Patch 2.2). |
| **Owner** | [À assigner] |
| **Dépendances** | Action 1 (v_integrity_checks) |
| **Done** | Spec validée, SQL STAGING exécuté et validé |

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

## Action 4 — Écran intégrité système (DOC + IMPLEMENTATION) ✅ DONE

| Élément | Détail |
|---------|--------|
| **Statut** | DONE (DOC + IMPLEMENTATION) |
| **Objectif** | Écran Flutter d'observabilité métier basé sur `public.v_integrity_checks` |
| **Livrables doc** | `docs/app/spec_ecran_integrite_systeme.md` |
| **Livrables tech** | UI Flutter + Repository + Riverpod + Tests |
| **Route** | `/governance/integrity` |
| **Rôles** | admin, directeur, pca |
| **Sorting** | CRITICAL > WARN |
| **Limit** | 200 |
| **DB Mutation** | None |
| **Conformité** | Conforme stratégie Phase 2 |
| **PR** | #71 |
| **Tag** | checkpoint-phase2-integrity-ui-2026-02-19 |

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

## Action 7 — Audit RLS complet + Hardening (0 public policies) ✅ DONE

| Élément | Détail |
|---------|--------|
| **Statut** | DONE (2026-02-21) |
| **Objectif** | Documenter l’audit RLS de toutes les tables sensibles : éliminer toute policy `{public}` (notamment `SELECT true`) pour supprimer l'exposition via ANON REST |
| **Livrables doc** | `docs/POST_PROD/RUNBOOK_RLS_HARDENING.md` ; Entry 2 dans `12_PHASE2_PROD_DEPLOY_LOG.md` ; standard "0 public policies" dans stratégie/plan. |
| **Livrables tech** | RLS uniquement : DROP/migration policies (STAGING puis PROD). Aucune mutation de données. |
| **Résultat** | STAGING et PROD : `count(public policies) = 0`. Fuites ANON corrigées (ex. stocks_journaliers, citernes). |
| **Done** | Audit exécuté ; hardening appliqué ; runbook et déploiement log à jour. |

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

## BLOC 3 — ASTM53B Controlled Integration

| Élément | Détail |
|---------|--------|
| **[ ] Étape 3** | Réception wiring vers routeur |
| **Statut** | NOT STARTED |
| **Dépendance** | Validation dataset golden cases terrain |

---

## Interdictions

- **lib/** : interdiction levée pour Action 4 validée.
- **test/** : interdiction levée pour Action 4 validée.
- **Migrations SQL** : aucune migration ni trigger ni RLS à modifier dans le cadre de ce plan DOC.

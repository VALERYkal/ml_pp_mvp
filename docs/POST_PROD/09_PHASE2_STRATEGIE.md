# POST-PROD — Phase 2 : Stratégie (Industrialisation & Observabilité Métier)

**Statut** : Document stratégique officiel  
**Date** : 2026-02  
**Contexte** : ML_PP MVP en PROD (GO LIVE acté)

---

## Contexte

ML_PP est en exploitation production sur https://monaluxe.app. La Phase 1 (monitoring Niveau 0 + Niveau 1) est déployée (UptimeRobot, Sentry). La Phase 2 vise l'**industrialisation** et l'**observabilité métier** sans expansion fonctionnelle.

---

## État d'avancement — Livrables réalisés (STAGING)

- **Action 1 (v_integrity_checks) : DONE en STAGING**
  - Script : `staging/sql/phase2/phase2_01_v_integrity_checks.sql`
  - Contrat : `docs/db/v_integrity_checks_contract.md`
  - Vue : `public.v_integrity_checks`
  - Validation : exécutable en STAGING, 1 alerte CDR_ARRIVE_STALE pertinente, pas de bruit sur les autres checks.
  - **STAGING-first** : promotion PROD uniquement après PR + validation formelle.

---

## État d'avancement — PROD

### Action 1 — v_integrity_checks
Statut : DEPLOYED (PROD)

- STAGING validation completed
- Full backup PROD created:
  - prod_pre_phase2_integrity_20260219_1342_full.dump
  - prod_pre_phase2_integrity_20260219_1343_schema.dump
- View created successfully
- Post-deployment check:
  - 5 WARN (CDR_ARRIVE_STALE)
  - 0 CRITICAL
- No operational impact

---

## Objectif

Mettre en place les fondations pour une exploitation industrielle : invariants métier surveillés, traçabilité des releases, sécurité renforcée, discipline de déploiement. Aucune nouvelle fonctionnalité métier (exclure Préparation Finance, SBLC, factures, paiements).

---

## Périmètre — Axes Phase 2

### AXE 1 : Observabilité Métier
Surveillance des invariants métier critiques : stock négatif, snapshots absents, mélange propriétaires, sorties incohérentes, cours de route bloqués, etc.

### AXE 2 : Monitoring Niveau 2
Standardisation des variables d’environnement (APP_ENV, APP_RELEASE), endpoint /health dédié, second moniteur uptime sur un smoke endpoint.

### AXE 3 : Sécurité & Audit
Audit RLS complet, journal des accès suspects, renforcement de la traçabilité des accès.

### AXE 4 : Traçabilité & Discipline Release
Hash de release visible dans l’UI, runbook de rollback web formalisé et testé.

---

## Problème stratégique

Sans Phase 2, les incidents métier (données incohérentes, dérives silencieuses) restent découverts trop tard. Le temps de découverte (TTD) et le temps de mitigation (TTM) restent élevés pour les erreurs non techniques.

---

## Critères de réussite

- Invariants métier critiques surveillés (vue + job périodique)
- Écran d’intégrité système exploitable par l’équipe opérationnelle
- Audit RLS documenté et validé
- Runbook rollback web appliqué et vérifié
- Aucune régression sur le flux GO PROD

---

## Risques si non réalisée

- Incidents métier silencieux (stock négatif non détecté)
- Rollback improvisé en cas de problème post-déploiement
- RLS incomplets ou mal documentés → vulnérabilités potentielles

---

## Décision

La Phase 2 est validée comme priorité post-PROD. Exécution progressive, documentation d’abord, implémentation ensuite. Exclusion formelle de tout axe « Préparation Finance » (SBLC, factures, paiements).

---

## Règles de non-régression

- **GO PROD** : Les flux métier actuellement en production (réceptions, sorties, stocks, dashboard, cours de route) ne doivent pas être modifiés fonctionnellement.
- **Contrats DB** : Aucune modification destructive des schémas, vues ou RLS existants sans validation formelle. Les ajouts (nouvelles tables, vues) sont autorisés tant qu’ils ne cassent pas les contrats en place.
- **Tests** : Aucune suppression de tests. Les ajouts de tests sont encouragés.
- **Déploiement** : Le script officiel `tools/release_web_prod.sh` et le runbook `docs/02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md` restent la référence.

## Standard sécurité RLS — 0 policy publique (Feb 2026)

- **Décision** : Aucune policy RLS ne doit avoir `roles = {public}`. Toute policy doit cibler `authenticated` (ou rôles explicites) avec une condition métier ou technique (jamais `SELECT true` pour public).
- **Raison** : La clé ANON est exposée dans le front (Flutter Web). Une policy `{public}` avec `SELECT true` permet l'accès en lecture (voire écriture) sans authentification via REST.
- **Revue** : Toute nouvelle migration ou modification RLS doit être revue pour ne pas réintroduire de policy `public`. Un check automatique (CI ou script) est recommandé pour bloquer la réintroduction de policies `{public}` (voir `docs/POST_PROD/RUNBOOK_RLS_HARDENING.md`).

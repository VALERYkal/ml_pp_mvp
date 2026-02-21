# Phase 2 — PROD Deployment Log

## 1. Metadata
- Date (UTC)
- Environment: PROD
- Operator: (laisser champ à compléter)
- Change ID: Phase2-Action1-v_integrity_checks

## 2. Change Description
- Création de la vue public.v_integrity_checks
- Script source: staging/sql/phase2/phase2_01_v_integrity_checks.sql
- Nature: VIEW ONLY (no tables, no triggers, no data mutation)

## 3. Pre-Deployment Checks
- select to_regclass('public.v_integrity_checks') returned NULL
- Full backup created:
  - prod_pre_phase2_integrity_20260219_1342_full.dump
  - prod_pre_phase2_integrity_20260219_1343_schema.dump

## 4. Post-Deployment Validation
Requête exécutée :
```sql
select check_code, severity, count(*) as cnt
from public.v_integrity_checks
group by check_code, severity;
```

Résultat observé :
- CDR_ARRIVE_STALE — WARN — 5
- No CRITICAL detected
- No STOCK_NEGATIF
- No STOCK_OVER_CAPACITY
- No ECART_15C alerts

## 5. Rollback Procedure
If required:
```sql
DROP VIEW IF EXISTS public.v_integrity_checks;
```

## 6. Governance Notes
- Deployment followed STAGING-first validation
- Backup validated via pg_restore -l
- No runtime impact detected
- Change approved via PR merge before PROD execution

---

# Entry 2 — RLS Hardening (Remove public policies / Fix ANON exposure)

## 1. Metadata
- **Date (UTC)** : 2026-02-21 (timezone Africa/Kinshasa)
- **Environment** : PROD
- **Operator** : (compléter)
- **Change ID** : Phase2-Action7-RLS-Hardening

## 2. Change Description
- **Trigger** : Audit RLS table-by-table revealed policies with `roles = {public}`; some were dangerous (`SELECT true`) → exposure via ANON REST (ANON key is embedded in Flutter Web front).
- **Scope** : RLS policies only. No data mutation, no table/view/trigger schema change.
- **Method** : STAGING-first (correct + validate), then PROD (audit + fix). One action at a time; curl ANON tests to prove exposure then closure.

## 3. Pre-Deployment Checks
- Backup PROD recommended before any RLS change (per runbook).
- Identification of `{public}` policies via `pg_policies` (see Runbook).

## 4. Actions Performed (PROD)
1. **log_actions** : ANON test → `[]` (no leak).
2. **stocks_journaliers** : ANON test → **data** (leak). Identified `read stocks_journaliers` {public} SELECT true → **DROP** policy → retest ANON → `[]`.
3. **citernes** : ANON test → **data** (leak). Identified `read citernes` {public} SELECT true → **DROP** policy → retest ANON → `[]`.
4. Global scan `pg_policies` : remaining `{public}` conditional policies migrated to `{authenticated}` on:
   - profils (Insert/Read/Update own profile)
   - stocks_journaliers_select
   - cours_de_route_select, cours_de_route_insert
   - prises_de_hauteur_select, prises_de_hauteur_insert
   - sorties_produit_select, sp_read, sorties_produit_insert, sp_update_draft, sp_insert_draft, sp_delete
5. Final check: `count(public policies) = 0`.

## 5. Post-Deployment Validation (Proof)
- Query: list policies by table; `SELECT count(*) FROM pg_policies WHERE roles @> ARRAY['public']::name[]` → **0**.
- curl ANON (no real keys in doc):
  - `stocks_journaliers` → `[]`
  - `citernes` → `[]`

## 6. Rollback Procedure
If a legitimate use case requires a public policy (rare): recreate the policy with the same name and definition, then re-validate. Prefer `authenticated` + conditions over `public`. See `docs/POST_PROD/RUNBOOK_RLS_HARDENING.md`.

## 7. Governance Notes
- Zero data-destructive change.
- Aligns STAGING and PROD (both 0 public policies).
- Phase 2 Action 7 (Audit RLS) marked DONE; runbook and standard "0 public policies" added.

---

# Entry 3 — Governance ACK/RESOLVE Workflow (system_alerts + Web)

## 1. Metadata
- **Date (UTC)** : 2026-02 (post-Phase 2 Action 2.4)
- **Environment** : PROD
- **Operator** : (compléter)
- **Change ID** : Phase2-Action2.4-Governance-ACK-RESOLVE

## 2. Change Description

### DB PROD — Migration appliquée

**Table utilisée** : `public.system_alerts` (créée via phase2_02_system_alerts.sql puis déploiement PROD)

**Colonnes concernées** :
- `status` (OPEN / ACK / RESOLVED)
- `acknowledged_at` (timestamptz)
- `acknowledged_by` (uuid)
- `resolved_at` (timestamptz)
- `resolved_by` (uuid)

**Policies RLS existantes** :
- `system_alerts_select_authenticated` — SELECT pour utilisateurs authentifiés éligibles
- `system_alerts_update_admin_directeur` — UPDATE restreint aux rôles admin et directeur

⚠️ **Note** : La policy UPDATE actuelle compare `p.id = auth.uid()` (profil) et non `p.user_id = auth.uid()`. Dette technique documentée dans `docs/POST_PROD/PHASE2_TECH_DEBT.md`.

**Trigger ajouté en PROD** :
- Fonction : `system_alerts_set_actor()`
- Trigger : `trg_system_alerts_set_actor`
- **But** : Auto-remplissage de `acknowledged_at`, `acknowledged_by`, `resolved_at`, `resolved_by` lors des transitions de statut
- ⚠️ **Limitation** : Le trigger ne s'active que si `status` change réellement (pas sur simple UPDATE sans changement de status)

### Web Deploy

**Build Flutter Web** :
- Commande : `flutter build web --release --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...`
- Secrets injectés exclusivement via `--dart-define`
- Aucun fallback hardcodé

**Déploiement Firebase Hosting** :
- Commande : `firebase deploy`
- Hosting cible : `ml-pp-mvp-web`
- **URL PROD active** : https://monaluxe.app

## 3. Pre-Deployment Checks
- Backup PROD recommandé avant migration DB
- Validation STAGING des scripts phase2_02 et phase2_03 (system_alerts + sync)
- Validation UI Flutter sur environnement de test

## 4. Post-Deployment Validation
- Écran `/governance/integrity` accessible (admin, directeur, pca)
- Boutons ACK / RESOLVE visibles pour admin et directeur uniquement
- Cycle de vie OPEN → ACK → RESOLVED exploitable en exploitation réelle

## 5. Governance Notes
- Déploiement PROD validé
- Dette technique identifiée et volontairement différée (voir PHASE2_TECH_DEBT.md)

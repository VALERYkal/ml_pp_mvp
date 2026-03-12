# Runbook — Migration volumétrique PROD (ML_PP MVP)

**Document** : Procédure officielle de migration volumétrique production — moteur ASTM lookup-grid.  
**Version** : 2.0  
**Contexte** : ML_PP MVP — ERP logistique pétrolier — Stack Flutter Web + Riverpod + GoRouter + Supabase PostgreSQL.  
**Référence technique** : ASTM / API MPMS 11.1 — moteur lookup-grid uniquement en runtime.

**Durée estimée** : ~30 minutes (fenêtre maintenance).

---

## 1. Objective

This migration will:

1. **Deploy** the ASTM lookup-grid volumetric engine as the production runtime (receptions and sorties).
2. **Purge** the first 8 receptions that were created with legacy volumetric logic.
3. **Replay** those 8 receptions using the new engine so that `volume_15c` is computed by the lookup-grid.
4. **Guarantee** consistent stock recalculation (receptions − sorties, with no orphaned stock or CDR).

The golden-dataset engine remains **validation-only**; it is not used for production writes.  
**Migration window** : approximately **30 minutes**.

---

## 2. Migration risks

| Risk | Description | Mitigation |
|------|-------------|------------|
| **Hybrid volumetric engine** | Mixing golden and lookup-grid engines for receptions vs sorties causes inconsistent stock and NO-GO. | STAGING must be homogeneous (lookup-grid only). Verify before PROD. |
| **Incorrect trigger order** | Volumetric trigger running before `volume_ambiant` is set (e.g. on sorties) yields wrong or null `volume_corrige_15c`. | Triggers must run after volume ambiant is set. Validated in STAGING. |
| **Deleting receptions without restoring CDR status** | CDRs remain in DECHARGE; they cannot be received again. | Purge is CDR-aware: restore affected CDRs to ARRIVE after deleting receptions. |
| **Deleting stock baselines** | Deleting `stocks_journaliers` rows with `source = 'SYSTEM'` breaks stock baseline. | Only delete rows with `source = 'RECEPTION'` (or equivalent). Never delete SYSTEM. |
| **Incorrect density semantics** | Using densité @15°C as input instead of **densité observée** leads to wrong VCF and volume @15°C. | UI and triggers must use **densité observée** (at ambient temperature). Densité @15°C is computed only by the engine. |

---

## 3. GO / NO-GO checklist

Migration **must not start** unless every item below is validated.

### Technical checks

- [ ] **STAGING validated** — Volumétrie 15°C validated on STAGING; single engine (lookup-grid) for receptions and sorties.
- [ ] **Lookup-grid dataset installed** — Table `astm_lookup_grid_15c` (or equivalent) present with active batch (e.g. 63 rows, domain 820–860 kg/m³, 10–40 °C).
- [ ] **Volumetric functions installed** — `astm.compute_v15_from_lookup_grid`, `astm.assert_lookup_grid_domain`, and related routines present in PROD.
- [ ] **Domain guards active** — Triggers call domain assertion before computation; out-of-domain inputs are rejected.

### Business checks

- [ ] **Reception allowed only when CDR = ARRIVE** — Business rule enforced (app and/or DB).
- [ ] **Reception transitions CDR to DECHARGE** — Consumed CDR status updated correctly.
- [ ] **Stock = receptions − sorties** — Stock derivation logic and views consistent with this invariant.

### UI checks

- [ ] **Density input = densité observée** — User enters observed density (at ambient temperature), not density @15°C.
- [ ] **Densité @15°C never manually entered** — It is always computed by the engine.

### Operational checks

- [ ] **Backup ready** — Full PROD backup completed and verified (see `scripts/prod_migration/02_backup_instructions.md`).
- [ ] **Maintenance window validated** — No receptions/sorties in progress; window agreed with métier.
- [ ] **Rollback procedure prepared** — Steps documented and restore test performed (Section 7).

---

## 4. Migration timeline

| Time | Phase | Actions |
|------|--------|--------|
| **T-24h** | Validation | Verify STAGING; list the 8 receptions and related CDR ids; verify CDR status. |
| **T-1h** | Pre-migration | Notify users; snapshot stock state; verify stock consistency. |
| **T-0** | Migration start | Activate maintenance mode; run purge (03); restore CDR status; clean derived stock. |
| **T-0** | Deployment | Install lookup-grid dataset; install volumetric functions; install DB triggers (schema alignment if needed). |
| **T-0** | Validation | Run volumetric test query (05); replay the 8 receptions (06); verify stock (07). |
| **T+30 min** | Reopen | Reopen application; end maintenance mode. |
| **T+1h** | Monitoring | Monitor new transactions; confirm no DB errors and correct volume_15c. |

---

## 5. SQL procedure

Execute in order. Use scripts under `scripts/prod_migration/` for reproducibility.

### 5.1 Precheck

```bash
psql "$PROD_DATABASE_URL" -f scripts/prod_migration/01_precheck.sql
```

Verify: receptions count = 8; lookup-grid table and astm functions present; stock view exists.

### 5.2 Backup

Follow **scripts/prod_migration/02_backup_instructions.md**. Do not proceed without a validated backup.

### 5.3 Purge (CDR-aware)

Run **scripts/prod_migration/03_purge_receptions.sql** on PROD.

- Deletes logs linked to receptions.
- Deletes only `stocks_journaliers` rows with `source = 'RECEPTION'` for the affected citernes/produit (baseline SYSTEM rows are **never** deleted).
- Deletes receptions.
- Restores CDR status to ARRIVE for the 8 CDRs linked to those receptions.

After purge: `receptions` = 0, 8 CDRs in ARRIVE, ready for replay.

### 5.4 Deploy ASTM engine

Ensure schema and functions are installed (from project migrations). Verify with:

```bash
psql "$PROD_DATABASE_URL" -f scripts/prod_migration/04_deploy_astm_engine.sql
```

### 5.5 Validation and replay

- Run **05_validation_checks.sql** — volumetric test (e.g. `astm.compute_v15_from_lookup_grid(1000, 837, 19)`).
- Replay the 8 receptions using **06_replay_receptions_template.sql** (fill placeholders with real ids and values). `volume_15c` is set by the trigger.
- Run **07_post_migration_checks.sql** — verify receptions, sums, and stock view.

---

## 6. Verification

After replay, confirm:

- **Receptions** — 8 rows; each has non-null `volume_15c` and `densite_observee_kgm3` (or equivalent).
- **Stock view** — `v_stock_actuel` (or equivalent) returns expected values.
- **Consistency** — Sum(receptions.volume_15c) − Sum(sorties_produit.volume_corrige_15c) matches expected stock @15°C.
- **No DB errors** — Application and DB logs show no volumetric or trigger errors.

Queries are in **scripts/prod_migration/07_post_migration_checks.sql**.

---

## 7. Rollback

If migration fails or GO criteria are not met:

1. **Stop the application** — Prevent new writes to PROD.
2. **Restore the database backup** — Example:
   ```bash
   psql "$PROD_DATABASE_URL" < backup_prod_pre_astm.sql
   ```
   Or, for a custom-format dump:
   ```bash
   pg_restore --clean --if-exists -d "$PROD_DATABASE_URL" backup_prod_pre_astm_YYYYMMDD_HHMM.dump
   ```
3. **Restart the application** — Resume normal operation.

**Rollback duration** : approximately **10 minutes**.  
Document the rollback (date, reason, operator) in the release log or project tracker.

---

## 8. Monitoring

- **T+30 min** — Application reopened; first receptions/sorties after migration checked for correct `volume_15c` / `volume_corrige_15c`.
- **T+1h** — No volumetric errors in logs; stock view and reports consistent.
- **Ongoing** — UI continues to use **densité observée** as input; densité @15°C is never manually entered.

---

## 9. DRY-RUN (STAGING)

Before running in PROD, execute the same sequence on **STAGING**:

1. **01_precheck.sql** — Confirm STAGING has lookup-grid, functions, and stock view.
2. **02_backup_instructions.md** — (Optional for STAGING but recommended to practice restore.)
3. **03_purge_receptions.sql** — Run on STAGING; verify receptions = 0, CDR = ARRIVE, SYSTEM rows preserved.
4. **04_deploy_astm_engine.sql** — Verify engine objects (already present on STAGING).
5. **05_validation_checks.sql** — Run volumetric test.
6. **06_replay_receptions_template.sql** — Replay receptions on STAGING with test data.
7. **07_post_migration_checks.sql** — Verify counts and stock.

This validates the procedure and script order without touching PROD.

---

## 10. Rollback (reference)

Same as Section 7, summarized:

| Step | Action | Duration |
|------|--------|----------|
| 1 | Stop application | ~1 min |
| 2 | Restore backup: `psql $PROD_DB_URL < backup_prod_pre_astm.sql` (or pg_restore) | ~5–8 min |
| 3 | Restart application | ~1 min |

**Total** : under **10 minutes**.

---

## Appendix A — Schema alignment (PROD → STAGING)

Before installing the ASTM volumetric engine in production, the schema of the operational tables must be aligned with STAGING (additive only).

### Table: `public.receptions`

| PROD columns | STAGING-only columns to add |
|--------------|-----------------------------|
| `densite_a_15` | `densite_a_15_g_cm3`, `densite_a_15_kgm3`, `densite_observee_kgm3` |

```sql
ALTER TABLE public.receptions
ADD COLUMN IF NOT EXISTS densite_a_15_g_cm3 double precision,
ADD COLUMN IF NOT EXISTS densite_a_15_kgm3 double precision,
ADD COLUMN IF NOT EXISTS densite_observee_kgm3 double precision;
```

### Table: `public.sorties_produit`

| PROD columns | STAGING-only columns to add |
|--------------|-----------------------------|
| `densite_a_15` | `densite_a_15_g_cm3`, `densite_a_15_kgm3` |

```sql
ALTER TABLE public.sorties_produit
ADD COLUMN IF NOT EXISTS densite_a_15_g_cm3 double precision,
ADD COLUMN IF NOT EXISTS densite_a_15_kgm3 double precision;
```

Legacy field `densite_a_15` is retained until full validation; no drop or rename in this migration.

---

## Appendix B — Volumetric rounding policy (reception vs sortie)

- **Receptions** — Stored precision: **1 decimal**. Value in `receptions.volume_15c` from `astm.compute_v15_from_lookup_grid(...)`; stored as `round(volume_ambiant × VCF, 1)`.
- **Sorties** — Stored precision: **integer liter**. Value in `sorties_produit.volume_corrige_15c`; stored as `round(volume_15c)`.

Small differences below 0.5 L in theoretical reconciliation are expected and acceptable. The lookup-grid engine is deterministic across both flows.

---

## References

| Élément | Valeur |
|--------|--------|
| **Runbook** | `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md` |
| **Scripts** | `scripts/prod_migration/01_precheck.sql` … `07_post_migration_checks.sql`, `02_backup_instructions.md` |
| **Investigation** | `docs/POST_PROD/ASTM/2026-03-07_INVESTIGATION_STAGING_PROD_VOLUMETRIC_ALIGNMENT.md` |
| **PR / Tag** | #90, commit 25422eb, tag v0.9-volumetric-staging |

---

*Document runbook — Migration volumétrique PROD — ML_PP MVP — Ne pas exécuter en PROD sans avoir validé le checklist GO/NO-GO et la procédure de rollback.*

# Runbook: STAGING Reset for ASTM Volumetric Validation

**Purpose:** Document why STAGING transactional data was reset, which tables were impacted, risks, rollback, and how to replicate the approach for production later.  
**Audience:** Developers, DBAs, release managers.  
**Last updated:** 2026-03-05.  
**Scope:** STAGING only. Do not run destructive resets against PROD.

---

## 1. Why STAGING Was Reset

The project is stabilising the **volumetric pipeline** (volume corrected to 15°C for petroleum products) before production. Strategy:

1. Implement and validate the ASTM-aligned volumetric engine on **STAGING**.
2. Validate UI/UX and database behaviour with a **clean, controlled dataset**.
3. Ensure CI test stability.
4. Document everything.
5. Only then replicate to PROD.

To avoid noise from historical receptions, sorties, and stock movements, the decision was taken to **remove all transactional data that affects stock** on STAGING, while **preserving Cours de Route (CDR)**. This provides:

- A **clean baseline** for volumetric validation.
- No legacy values (e.g. old `volume_corrige_15c` vs new `volume_15c`) polluting tests or UX checks.
- Reproducible behaviour for integration and manual testing.

---

## 2. Tables Impacted

| Table / scope | Action | Purpose |
|---------------|--------|--------|
| `public.receptions` | Purged (or truncated as per script) | Remove all reception transactions. |
| `public.sorties_produit` | Purged | Remove all sortie transactions. |
| `public.stocks_journaliers` | Purged | Remove stock movement history. |
| `public.log_actions` | Purged for stock-related entries (receptions, sorties, stock) | Remove audit trail for removed transactions. |
| **Preserved** | | |
| `public.cours_de_route` | **Preserved** | Allow controlled volumetric and workflow testing without re-creating CDR from scratch. |

Exact SQL is in the project’s STAGING reset scripts (e.g. `docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql`). DB-STRICT flags (`app.receptions_allow_write`, `app.sorties_produit_allow_write`, `app.stocks_journaliers_allow_write`) are used transactionally during purge where required.

---

## 3. Risk Analysis

| Risk | Mitigation |
|------|-------------|
| Accidental run on PROD | Scripts must check URL (no `prod`/`production`) and require explicit opt-in (e.g. `ALLOW_STAGING_RESET=true`). See `docs/02_RUNBOOKS/staging.md`. |
| Data loss on STAGING | Acceptable by design; STAGING is a sandbox. Back up STAGING first if needed for debugging. |
| Dependent views/caches | After reset, snapshot/aggregation tables (e.g. `stocks_snapshot`) may need hygiene (e.g. purge, or recompute). See project hygiene script if present. |
| CDR referential integrity | Only transactional tables are purged; CDR is preserved so FKs from receptions/sorties to CDR can be satisfied for new data. |

---

## 4. Rollback Strategy

- **STAGING:** There is no rollback of the purge; the intent is a clean state. Restore from a STAGING backup if a previous state is required.
- **PROD:** This runbook does **not** apply to PROD. No purge of production transactional data is executed as part of this procedure.

---

## 5. Procedure to Replicate to Production Later

Replicating the **volumetric engine** to production will follow a separate, controlled process:

1. **Do not** run this STAGING reset procedure on PROD.
2. Apply only **approved** migration scripts (e.g. ASTM golden engine, new columns, triggers) to PROD after validation on STAGING.
3. Follow the project’s PROD runbooks (e.g. `docs/POST_PROD/13_ASTMB53B_PROD_RUNBOOK.md`, ASTM gates checklist) for backup, gates, and rollback.
4. Production data (receptions, sorties, stocks) remains intact; only schema and volumetric **logic** (e.g. triggers, functions) are updated when the team decides to go live.

---

## 6. Related Documentation

- **Decision:** `docs/01_DECISIONS/DECISION_STAGING_RESET_FOR_VOLUMETRICS.md`
- **Staging safety:** `docs/02_RUNBOOKS/staging.md`
- **Reset script (CDR-only):** `docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql`
- **ASTM engine checkpoint:** `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md`

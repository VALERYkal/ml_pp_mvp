# Runbook — ASTM PROD Migration (Completed)

**Purpose:** Document the production migration of ML_PP volumetric calculations to ASTM API MPMS 11.1 lookup-grid interpolation.  
**Audience:** Developers, DBAs, release managers, auditors.  
**Status:** Migration executed and verified in production.  
**Related:** `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md` (procedure), `docs/01_DECISIONS/ADR_VOLUMETRIC_ENGINE_ARCHITECTURE.md`.

---

## 1. Objective

Migrate ML_PP production volumetric calculations to **ASTM API MPMS 11.1 lookup-grid interpolation**.

Production previously used legacy volumetric logic. The migration replaces it with a deterministic, auditable engine based on the lookup-grid dataset and bilinear interpolation, with domain guard validation.

---

## 2. Migration Strategy

**Controlled purge + replay approach.**

Steps executed in production:

1. Install runtime schema (`astm`)
2. Install lookup dataset (`astm_lookup_grid_15c`)
3. Install runtime functions (`lookup_grid_domain`, `assert_lookup_grid_domain`, `lookup_15c_bilinear_v2`, `compute_v15_from_lookup_grid`)
4. Install triggers on business tables (receptions, sorties_produit)
5. Purge legacy transactions (receptions, stocks_snapshot, stocks_journaliers) with CDR status reset
6. Replay historical receptions using the new engine
7. Validate reconstructed stocks (stocks_journaliers, stocks_snapshot)
8. Reactivate database protections (triggers, write guards)

---

## 3. Verification Performed

The following was validated after migration:

- **Reception volumetric recomputation** — All replayed receptions have `volume_15c` computed by the lookup-grid engine; inputs (temperature_ambiante_c, densite_observee_kgm3, volume_ambiant) produce deterministic results.
- **stocks_journaliers reconstruction** — Daily stock movements and balances rebuilt consistently from receptions and sorties.
- **Automatic CDR closure** — Reception workflow correctly transitions CDR status (e.g. ARRIVE → DECHARGE) on reception validation.
- **Trigger protections reactivated** — Volumetric triggers and write-protection triggers are active; no direct manipulation of volumetric or stock data outside the engine.

---

## 4. Operational Guarantees

The system now guarantees:

- **Deterministic volumetric calculations** — Same inputs yield the same volume @15°C and density @15°C.
- **Consistent recomputation of historical data** — All replayed receptions use the same engine; no mixed legacy/new logic.
- **Database-level enforcement of volumetric logic** — Calculations occur inside PostgreSQL (schema `astm`); application sends observed density and reads computed values.
- **Prevention of manual stock manipulation** — Stock derivations (stocks_journaliers, snapshots) are driven by triggers and controlled rebuild; direct writes are blocked where applicable.

---

## 5. Migration Outcome Summary

- **Production is now fully aligned** with the ASTM lookup-grid volumetric engine.
- **All legacy volumetric calculations have been removed** from the production runtime.
- **The ML_PP production environment** operates using the ASTM runtime interpolation engine (API MPMS 11.1 lookup-grid).

For procedure details, rollback reference, and checklist, see `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md`.

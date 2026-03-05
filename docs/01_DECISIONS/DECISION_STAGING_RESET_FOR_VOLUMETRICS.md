# Decision: STAGING Reset for Volumetric Validation

**Status:** Accepted.  
**Date:** 2026-03-05.  
**Context:** ML_PP MVP — stabilisation of the volumetric pipeline (ASTM / 15°C) before production.

---

## 1. Summary

Transactional data (receptions, sorties, stock movements, and related log entries) was removed from the **STAGING** database to obtain a clean environment for validating the ASTM-aligned volumetric engine and UI behaviour. **Cours de Route (CDR)** was preserved. Production was not modified.

---

## 2. Why Transactional Data Was Removed in STAGING

- **Objective:** Stabilise the volumetric pipeline (volume and density at 15°C) and align behaviour with the field application (SEP) before any production change.
- **Problem:** Historical receptions, sorties, and stock data on STAGING mixed old and new semantics (e.g. legacy `volume_corrige_15c` vs DB-computed `volume_15c`, density observed vs density at 15°C). This made validation and debugging noisy and non-reproducible.
- **Decision:** Remove all transactions that affect stock on STAGING (receptions, sorties, stocks_journaliers, and related log_actions), and keep only Cours de Route. This gives:
  - A **clean baseline** for volumetric tests and manual checks.
  - **Reproducible** integration and E2E behaviour.
  - No ambiguity between legacy and new engine results.

STAGING is treated as a **sandbox**; data loss there is acceptable by design.

---

## 3. Why Alignment with Field Calculation Was Prioritised

- **Operational priority:** The field application (SEP) is the day-to-day reference for operators. Divergence between ML_PP and SEP (e.g. volume at 15°C) causes confusion and undermines trust.
- **Strategy:** First achieve **operational consistency** with the field (e.g. via ASTM_APP golden cases and IDW interpolation on STAGING). Then, in a later phase, move toward strict ASTM / API MPMS 11.1 compliance if required.
- **Consequence:** The current STAGING volumetric engine is aligned with the field “ASTM” oracle (golden cases, domain-limited). It is **not** yet certified as full API MPMS 11.1; that remains a future step.

---

## 4. Impact on Production

- **No direct impact.** This decision applies only to STAGING.
- **No purge** of production receptions, sorties, or stock data.
- **Future production rollout** of the volumetric engine will follow a separate process: validation on STAGING, then application of approved migrations and runbooks to PROD with backup and rollback plans.

---

## 5. References

- Runbook (procedure, tables, risks): `docs/02_RUNBOOKS/RUNBOOK_STAGING_RESET_FOR_ASTM.md`
- Staging safety rules: `docs/02_RUNBOOKS/staging.md`
- ASTM engine (STAGING): `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md`
- Volumetric architecture: `docs/00_REFERENCE/VOLUMETRIC_ENGINE_ARCHITECTURE.md`

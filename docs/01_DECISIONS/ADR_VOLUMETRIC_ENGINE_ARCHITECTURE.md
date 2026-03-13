# ADR — Volumetric Engine Architecture

**Date:** Post production migration  
**Status:** Accepted  
**Context:** ML_PP MVP — production volumetric calculation architecture.

---

## Decision

ML_PP volumetric calculations are now based on **ASTM API MPMS 11.1 lookup-grid interpolation**.

---

## Rationale

Provides **deterministic**, **auditable**, and **reproducible** volumetric calculations suitable for industrial operations and reconciliation.

---

## Key Properties

| Property | Description |
|----------|-------------|
| **Database-only calculations** | All volume @15°C and density @15°C computations are performed inside the PostgreSQL database (schema `astm`). The application supplies inputs and reads outputs; it does not implement the conversion logic. |
| **Deterministic interpolation** | Bilinear interpolation over the lookup grid yields the same result for the same inputs (volume_ambiant, temperature, observed density). |
| **Dataset versioning** | The lookup-grid dataset (`astm_lookup_grid_15c`) is versioned (e.g. batch identifier); changes to the grid are controlled and traceable. |
| **Domain guard validation** | Inputs are validated against the grid domain (e.g. density 820–860 kg/m³, temperature 10–40 °C). Out-of-domain inputs are rejected with explicit errors before computation. |

---

## Consequences

- Production and STAGING share the same volumetric architecture (lookup-grid).
- Golden-dataset engine is retained only for validation and testing, not for production writes.
- Any change to interpolation logic or grid data is a controlled change with audit trail.

---

## References

- Runbook (procedure): `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md`
- Runbook (completed migration): `docs/02_RUNBOOKS/RUNBOOK_ASTM_PROD_MIGRATION.md`
- Reference architecture: `docs/00_REFERENCE/VOLUMETRIC_ENGINE_ARCHITECTURE.md`
- CHANGELOG: Volumetric Engine Migration — Production Activation

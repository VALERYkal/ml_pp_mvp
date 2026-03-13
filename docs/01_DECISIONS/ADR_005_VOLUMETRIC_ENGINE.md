# ADR 005 — Volumetric Engine

**Decision** : Adopt ASTM API MPMS 11.1 lookup-grid interpolation for volumetric calculations.  
**Status** : Accepted  
**Context** : ML_PP MVP — production volumetric calculation architecture.

---

## Decision

Adopt **ASTM API MPMS 11.1 lookup-grid interpolation** for volumetric calculations.

---

## Consequences

All volumetric calculations are now:

- **deterministic**
- **database-controlled**
- **auditable**
- **reproducible**

---

## References

- Migration report: `docs/02_RUNBOOKS/MIGRATION_REPORT_ASTM_LOOKUP_GRID_PROD.md`
- Runbook: `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md`
- Architecture: `docs/00_REFERENCE/ARCHITECTURE.md` (Volumetric Engine section)

# ADR 005 — ASTM Runtime Alignment Strategy

**Status** : Accepted  
**Context** : ML_PP MVP — production alignment with STAGING after ASTM volumetric migration.

---

## Decision

Production must be aligned with staging on the **ASTM runtime path actually used by the application**, not necessarily on every experimental or staging-only helper function.

---

## Rationale

- **Priority on real business runtime** — The critical path is reception and sortie inserts with volume @15°C and density @15°C computed via the lookup-grid engine. This path must behave the same in STAGING and PROD.
- **Consistency between STAGING tests and PROD execution** — Validating in STAGING must give confidence that PROD will compute the same volumes and stocks.
- **Keeping some functions STAGING-only** — When a function is not implemented (e.g. raises by design), is validation-only, or is guarded against PROD, it remains out of PROD scope. This avoids false parity and keeps PROD minimal and auditable.

---

## Consequences

- **Useful datasets** are present in PROD: `public.astm_lookup_grid_15c`, `public.astm_golden_cases_15c`.
- **Useful runtime functions** (the 10 aligned functions) are present in PROD.
- **Runtime triggers** are active in PROD on `receptions` and `sorties_produit`.
- **Some validation / staging-only functions** remain limited to STAGING: `astm.calculate_ctl_54b_15c_official_only`, `astm.validate_golden_dataset`, `astm.fn_sortie_compute_golden_15c`.

---

## References

- Migration report: `docs/02_RUNBOOKS/MIGRATION_REPORT_ASTM_PROD_ALIGNMENT.md`
- Operations notes: `docs/02_RUNBOOKS/OPERATIONS_ASTM_NOTES.md`
- Architecture: `docs/00_REFERENCE/architecture.md` (ASTM Volumetric Architecture)

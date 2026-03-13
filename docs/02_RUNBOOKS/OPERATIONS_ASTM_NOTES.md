# Operations Notes — ASTM Volumetric Engine

**Document** : Operational guarantees and known intentional differences after PROD alignment.  
**Project** : ML_PP MVP

---

## Operational guarantees

- **Deterministic lookup-grid runtime in PROD** — Same inputs (temperature, observed density, volume) yield the same volume @15°C and density @15°C.
- **Runtime path aligned with STAGING** — The business-critical volumetric path (receptions and sorties) uses the same engine and datasets in both environments.
- **Replayed receptions recomputed through DB pipeline** — The 8 historical receptions were replayed and recalculated via the normal insert path and triggers.
- **Stock reconstruction verified** — stocks_journaliers and stocks_snapshot rebuilt; v_stock_actuel consistent.
- **CDR closure verified** — CDR status set to DECHARGE where applicable after replay.
- **Protections re-enabled after maintenance** — DB protection triggers were re-enabled once migration and replay were complete.

---

## Known intentional differences

The following 3 functions are present in STAGING but **not** deployed to PROD by design (non-blocking):

| Function | Reason |
|----------|--------|
| `astm.calculate_ctl_54b_15c_official_only` | Not implemented; raises an intentional exception. Not used by production runtime. |
| `astm.validate_golden_dataset` | Depends on `calculate_ctl_54b_15c_official_only`; validation-only. |
| `astm.fn_sortie_compute_golden_15c` | STAGING-only; depends on `public.app_settings` and has an anti-PROD guard. Not part of production runtime. |

These do not affect the production volumetric path. See `docs/02_RUNBOOKS/MIGRATION_REPORT_ASTM_PROD_ALIGNMENT.md` for full details.

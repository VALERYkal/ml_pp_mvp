# Production Alignment Report — ASTM Lookup Grid

**Document** : Report documenting PROD alignment with STAGING on the ASTM volumetric runtime.  
**Project** : ML_PP MVP  
**Status** : Migration executed and verified.

---

## Objective

The objective was to align PROD with STAGING on the **ASTM runtime actually used by the application** for volumetric calculations: lookup-grid interpolation for receptions and sorties, with deterministic volume @15°C and density @15°C.

---

## Scope

Alignment targeted:

- **Useful datasets** — runtime and golden ASTM tables
- **Runtime functions** — functions used by the business pipeline
- **Runtime triggers** — triggers attached to `receptions` and `sorties_produit`
- **Real pipeline** — reception → volume_15c / densite_a_15_kgm3 → stock reconstruction → sortie → logs and CDR closure

Not in scope: full parity of every STAGING-only or validation helper function.

---

## Datasets aligned

Present in both STAGING and PROD, same schema and content:

| Table | Schema | STAGING | PROD | Rows | Domain (confirmed) |
|-------|--------|---------|------|------|--------------------|
| `public.astm_lookup_grid_15c` | public | ✓ | ✓ | 63 | density 820→860 kg/m³, temp 10→40 °C |
| `public.astm_golden_cases_15c` | public | ✓ | ✓ | 13 | density 836→837.6 kg/m³, temp 19→29.7 °C, volume 33445→39391 L |

---

## Runtime functions aligned

The following 10 functions are present in both STAGING and PROD and are used by the runtime or validation path:

- `astm.assert_lookup_grid_domain`
- `astm.calculate_ctl_54b_15c`
- `astm.calculate_ctl_54b_15c_sep_display`
- `astm.compute_15c_from_golden`
- `astm.compute_v15_from_lookup_grid`
- `astm.ctl_from_golden`
- `astm.lookup_15c_bilinear`
- `astm.lookup_15c_bilinear_v2`
- `astm.lookup_15c_exact`
- `astm.lookup_grid_domain`

---

## Runtime triggers aligned

| Table | Trigger |
|-------|---------|
| `receptions` | `trg_receptions_compute_15c_before_ins` |
| `sorties_produit` | `trg_02_sorties_compute_lookup_15c` |

---

## Production migration executed

Steps actually performed in PROD:

1. Installation of ASTM lookup-grid runtime engine (schema `astm`, functions, dataset).
2. Creation of tables and loading of datasets: `public.astm_lookup_grid_15c`, `public.astm_golden_cases_15c`.
3. Installation of ASTM runtime functions (the 10 aligned functions listed above).
4. Installation and activation of runtime triggers on `receptions` and `sorties_produit`.
5. Controlled purge of legacy volumetric transactions (receptions, stocks_snapshot, stocks_journaliers, etc., per approved procedure).
6. Replay of the 8 historical receptions through the normal application/DB pipeline.
7. Reconstruction of stock states and CDR closure (DECHARGE).
8. Re-enabling of DB protection triggers.

---

## Verified outcomes

- 8 receptions present in PROD and recalculated with the ASTM lookup-grid engine.
- `volume_15c` populated for receptions (and sorties where applicable).
- `densite_a_15_kgm3` populated.
- `stocks_journaliers` rebuilt.
- CDR status set to DECHARGE where applicable.
- DB protection triggers re-enabled after maintenance.

---

## Remaining non-blocking differences

The following 3 functions exist in STAGING but are **not** deployed to PROD by design (intentional, non-blocking):

| Function | Reason not in PROD |
|----------|--------------------|
| `astm.calculate_ctl_54b_15c_official_only` | Present in STAGING but not actually implemented; raises an intentional exception. Not used by production runtime. |
| `astm.validate_golden_dataset` | Depends on `calculate_ctl_54b_15c_official_only`; not useful until that function is implemented. Validation-only, not part of runtime path. |
| `astm.fn_sortie_compute_golden_15c` | STAGING-only; depends on `public.app_settings` and contains an anti-PROD guard. Not part of production business runtime. |

---

## Final verdict

Production is aligned with staging for the ASTM lookup-grid runtime path and useful ASTM datasets. Remaining differences are limited to non-runtime validation or staging-only helper functions.

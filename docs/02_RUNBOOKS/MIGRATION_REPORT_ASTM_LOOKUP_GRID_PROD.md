# Production Migration Report — ASTM Lookup Grid Volumetric Engine

**Document** : Migration report for production volumetric engine activation.  
**Project** : ML_PP MVP (Monaluxe Petrol Platform)  
**Reference** : ASTM API MPMS 11.1 lookup-grid interpolation.  
**Status** : Migration executed and verified in production.

---

## Context

ML_PP previously used a legacy volumetric calculation model based on manual density input.

To achieve deterministic industrial-grade volumetric calculations, the system migrated to **ASTM API MPMS 11.1 lookup-grid interpolation**.

---

## Objective

Deploy the ASTM volumetric engine in production and recompute historical receptions using the new calculation model.

---

## Migration Strategy

**Controlled purge + replay strategy.**

Steps executed in production:

1. Installation of runtime schema `astm`
2. Deployment of lookup-grid dataset `astm_lookup_grid_15c`
3. Installation of interpolation functions
4. Installation of volumetric runtime engine
5. Installation of database triggers
6. Controlled purge of legacy transactions
7. Replay of historical receptions
8. Reconstruction of stock states
9. Reactivation of database protection triggers

---

## Runtime Components

### Dataset

**Table:** `public.astm_lookup_grid_15c`

Contains lookup-grid values used for volumetric interpolation.

### Runtime Functions

- `astm.lookup_grid_domain`
- `astm.assert_lookup_grid_domain`
- `astm.lookup_15c_bilinear_v2`
- `astm.compute_v15_from_lookup_grid`

### Business Triggers

**receptions:**

- `trg_receptions_compute_15c_before_ins`

**sorties_produit:**

- `trg_02_sorties_compute_lookup_15c`

### Post Processing Triggers

**receptions_after_ins_trg()**

Handles:

- stock reconstruction
- CDR closure
- journaling

---

*Migration executed in production. All volumetric calculations are now performed via ASTM API MPMS 11.1 lookup-grid interpolation.*

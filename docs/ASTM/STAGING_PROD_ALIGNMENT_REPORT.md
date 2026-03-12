# Staging vs Production Alignment Report — ASTM Volumetric Engine

**Document** : Formal technical comparison of STAGING and PRODUCTION database environments after ASTM volumetric engine deployment.  
**Project** : ML_PP MVP  
**Purpose** : Document alignment status and record any remaining differences.

---

## 1. Project context

ML_PP MVP is a petroleum logistics system. Critical business logic runs inside PostgreSQL. Volumetric calculations follow **API MPMS 11.1**. The system uses a **lookup-grid interpolation engine** implemented in the database.

Core runtime functions:

- `astm.compute_v15_from_lookup_grid`
- `astm.lookup_15c_bilinear_v2`
- `astm.assert_lookup_grid_domain`

These functions compute **densite_a_15**, **VCF**, and **volume_15c** from observed inputs (volume, temperature, observed density).

---

## 2. Comparison methodology

A diagnostic SQL comparison script was executed in both environments:

- **STAGING**
- **PRODUCTION**

The script compared:

- ASTM functions (schema `astm`)
- Runtime public functions
- Runtime triggers
- Lookup grid dataset
- Golden validation dataset
- Engine smoke test output

---

## 3. Runtime components comparison

### 3.1 Runtime functions (schema astm)

The following functions exist in **both** environments:

| Function |
|----------|
| `assert_lookup_grid_domain` |
| `calculate_ctl_54b_15c` |
| `calculate_ctl_54b_15c_sep_display` |
| `compute_15c_from_golden` |
| `compute_v15_from_lookup_grid` |
| `ctl_from_golden` |
| `lookup_15c_bilinear` |
| `lookup_15c_bilinear_v2` |
| `lookup_15c_exact` |
| `lookup_grid_domain` |

STAGING and PRODUCTION are aligned on these runtime functions.

### 3.2 Public runtime functions

These functions are identical in both environments:

- `receptions_compute_15c_before_ins`
- `sorties_compute_15c_before_ins_lookup`

### 3.3 Runtime triggers

Triggers executing the volumetric engine are identical in both environments.

**receptions**

| Attribute | Value |
|-----------|--------|
| Trigger | `trg_receptions_compute_15c_before_ins` |
| Timing | BEFORE INSERT |
| Function | `receptions_compute_15c_before_ins()` |

**sorties_produit**

| Attribute | Value |
|-----------|--------|
| Trigger | `trg_02_sorties_compute_lookup_15c` |
| Timing | BEFORE INSERT |
| Function | `sorties_compute_15c_before_ins_lookup()` |

---

## 4. Dataset comparison

### 4.1 Lookup grid dataset

**Table:** `public.astm_lookup_grid_15c`

**Configuration (both environments):**

- `produit_code` = GASOIL
- `source` = ASTM_OFFICIAL_APP
- `method_version` = API_MPMS_11_1
- `batch_id` = GASOIL_P0_2026-02-28

**Dataset size:** 63 rows

**Axes:** 9 density levels, 7 temperature levels

**Domain:**

- density: 820 → 860 kg/m³
- temperature: 10 → 40 °C

Both environments contain the exact same dataset configuration.

### 4.2 Golden validation dataset

**Table:** `public.astm_golden_cases_15c`

**Dataset size:** 13 rows

**Domain:**

- density: 836 → 837.6 kg/m³
- temperature: 19 → 29.7 °C
- volume range: 33445 → 39391 L

Both environments contain identical validation datasets.

---

## 5. Engine validation

### 5.1 Smoke test

The volumetric engine was executed using identical inputs in both environments.

**Input:**

- volume_observe = 1000 L
- temperature = 20 °C
- densite_observee = 840 kg/m³

**Result (both environments):**

- densite_a_15 = 843.4
- VCF = 0.9958
- volume_15c = 995.8

The output is identical in both environments. This confirms that the runtime engine behaves deterministically across STAGING and PRODUCTION.

---

## 6. Remaining differences

Three functions exist in **STAGING** but **not** in **PRODUCTION**:

| Function | Reason |
|----------|--------|
| `calculate_ctl_54b_15c_official_only` | Placeholder function not fully implemented. |
| `validate_golden_dataset` | Depends on the previous function; used for dataset validation only. |
| `fn_sortie_compute_golden_15c` | Staging-only helper used during volumetric experimentation. |

These functions are **not part of the production runtime path**. They are intentionally excluded from the production deployment.

---

## 7. Final verdict

Production is **aligned with staging on the ASTM lookup-grid runtime path**.

The following components are identical in both environments:

- Runtime functions (the 10 listed in section 3.1)
- Public runtime functions (reception and sortie compute functions)
- Runtime triggers (receptions and sorties_produit)
- Lookup grid dataset (`public.astm_lookup_grid_15c`)
- Golden validation dataset (`public.astm_golden_cases_15c`)
- Volumetric engine behavior (smoke test output)

Remaining differences are limited to **non-runtime validation or staging-only helper functions** (the three functions listed in section 6).

The business-critical volumetric engine used by the application is aligned across both environments.

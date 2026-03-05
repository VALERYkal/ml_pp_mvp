# Volumetric Engine Architecture (15°C Normalisation)

**Purpose:** Describe how the system converts observed volume and density to 15°C-normalised values, and clarify terminology for developers and operators.  
**Last updated:** 2026-03-05.

---

## 1. Overview

The system computes **volume corrected to 15°C** and **density at 15°C** for petroleum products. These values are used for stock accounting, reconciliation, and reporting. Inputs are **volume at ambient conditions**, **temperature**, and **observed density** (at that temperature).

---

## 2. Inputs Used by the System

| Input | Description | Typical source |
|-------|-------------|-----------------|
| **Volume (ambient)** | Volume at measurement temperature (e.g. from index difference or meter). | UI: index avant / index après, or direct volume. |
| **Temperature** | Product temperature at time of measurement (°C). | UI: “Température ambiante” or equivalent. |
| **Observed density** | Density of the product **at measurement temperature** (e.g. kg/m³ from field instrument). | UI: density field (see §4). |

All three are required for the conversion to 15°C.

---

## 3. Conversion Logic and 15°C Normalisation

- The engine takes **volume at ambient**, **temperature**, and **observed density**.
- It produces:
  - **Volume corrected to 15°C** (e.g. `volume_15c` in DB): volume equivalent at 15°C.
  - **Density at 15°C** (e.g. `densite_a_15_kgm3`): density equivalent at 15°C.

Conversion uses a **Volume Correction Factor (VCF)** or equivalent factor (e.g. CTL) so that:

- `volume_15c ≈ volume_ambient × factor`
- `density_15°C ≈ observed_density / factor` (conceptually; exact relation depends on the standard).

On **STAGING**, the current implementation uses a **golden-case** engine: interpolation (e.g. IDW) over a set of reference cases (ASTM_APP) stored in `public.astm_golden_cases_15c`. The DB trigger on `receptions` (and equivalent logic for sorties where applicable) computes `volume_15c` and `densite_a_15_kgm3` and persists them. The application sends **observed density** (and ambient volume and temperature); it does **not** send pre-corrected density at 15°C as the primary input.

---

## 4. Observed Density vs Density at 15°C — Critical Clarification

**Despite labels that may say “Densité @15” or similar in the UI:**

- The value the **operator enters** is the **observed density** (at ambient temperature), as measured in the field (e.g. kg/m³ from a densimeter at that temperature).
- The **system** then computes **density at 15°C** and stores it (e.g. `densite_a_15_kgm3`).

So:

| Term | Meaning |
|------|--------|
| **Observed density** | Density at measurement temperature. This is the **input** from the user/field. |
| **Density at 15°C** | Density normalised to 15°C. This is an **output** computed by the engine (and stored in DB). |

**UX/UI requirement (before production):** Labels and help text on Reception and Sortie forms must clearly distinguish “Densité observée (à la température de mesure)” from “Densité à 15°C (calculée)”. This avoids operator confusion and incorrect data entry.

---

## 5. Current and Future ASTM Alignment

- **Current (STAGING):** The volumetric engine is aligned with **field behaviour** (oracle “ASTM” / ASTM_APP golden cases). It is **domain-limited** (valid only within the range of golden cases). It is **STAGING-only** (guarded by `public.app_settings.env`). There is **no claim** to full API MPMS 11.1 / ASTM D1250 compliance at this stage.
- **Future:** A later phase may introduce strict ASTM / API MPMS 11.1 implementation (e.g. official tables, coefficients). That will be documented separately and gated by validation (e.g. golden cases, SEP comparison).

---

## 6. References

- STAGING ASTM engine checkpoint: `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md`
- Decision (STAGING reset): `docs/01_DECISIONS/DECISION_STAGING_RESET_FOR_VOLUMETRICS.md`
- Runbook (STAGING reset): `docs/02_RUNBOOKS/RUNBOOK_STAGING_RESET_FOR_ASTM.md`
- Normative reference (when applicable): `docs/NORMES/VOLUMETRIE_API_MPMS_11_1_2019.md`

# Volumetric Engine Architecture (15°C Normalisation)

**Purpose:** Describe how the system converts observed volume and density to 15°C-normalised values, and clarify terminology for developers and operators.  
**Last updated:** Post production migration.  
**Production status:** ASTM API MPMS 11.1 lookup-grid engine active in production.

---

## 1. Overview

The system computes **volume corrected to 15°C** and **density at 15°C** for petroleum products. These values are used for stock accounting, reconciliation, and reporting. Inputs are **volume at ambient conditions**, **temperature**, and **observed density** (at that temperature).

---

## 2. Volumetric Calculation Architecture (Production)

Production volumetric computation uses **lookup-grid interpolation** based on **ASTM API MPMS 11.1**.

**Inputs**

| Input | Description |
|-------|-------------|
| `temperature_ambiante_c` | Product temperature at measurement (°C). |
| `densite_observee_kgm3` | Observed density at measurement temperature (kg/m³). |
| `volume_ambiant` | Volume at measurement conditions (e.g. from index difference). |

**Outputs**

| Output | Description |
|--------|-------------|
| `densite_a_15_kgm3` | Density normalised to 15°C (computed). |
| `vcf` | Volume Correction Factor (from interpolation). |
| `volume_15c` | Volume corrected to 15°C (computed). |

All calculations occur inside the **PostgreSQL database** using the **`astm`** runtime schema. The application does not perform the conversion; it sends inputs and reads the persisted outputs.

---

## 3. Inputs Used by the System

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

On **production** and **STAGING**, the implementation uses the **lookup-grid engine**: table `astm_lookup_grid_15c`, bilinear interpolation (`astm.lookup_15c_bilinear_v2`), and domain guards (`astm.assert_lookup_grid_domain`). The DB triggers on `receptions` and `sorties_produit` compute `volume_15c` / `volume_corrige_15c` and `densite_a_15_kgm3` and persist them. The application sends **observed density** (and ambient volume and temperature); it does **not** send pre-corrected density at 15°C as the primary input.

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

## 6. Operational Guarantees

The system now guarantees:

- **Deterministic volumetric calculations** — Same inputs (temperature, observed density, volume ambiant) yield the same volume @15°C and density @15°C.
- **Consistent recomputation of historical data** — All receptions and sorties use the same lookup-grid engine; historical data replayed after migration is consistent with new transactions.
- **Database-level enforcement of volumetric logic** — Volumetric logic runs only in the database; the application cannot bypass or override it.
- **Prevention of manual stock manipulation** — Stock derivations (stocks_journaliers, snapshots) are driven by triggers and controlled rebuild; direct writes are blocked where applicable.

---

## 7. Current and Future ASTM Alignment

- **Production and STAGING:** The volumetric engine is **ASTM API MPMS 11.1 lookup-grid** (table `astm_lookup_grid_15c`, bilinear interpolation, domain guards). Production migration has been executed and verified.
- **Golden engine:** Retained only for validation and testing; not used for production writes.
- **Future:** Any evolution (e.g. new grid batch, extended domain) will be documented and gated by validation.

---

## 8. References

- Runbook (PROD migration completed): `docs/02_RUNBOOKS/RUNBOOK_ASTM_PROD_MIGRATION.md`
- Runbook (PROD procedure): `docs/RUNBOOKS/RUNBOOK_PROD_VOLUMETRIC_MIGRATION.md`
- ADR Volumetric Engine Architecture: `docs/01_DECISIONS/ADR_VOLUMETRIC_ENGINE_ARCHITECTURE.md`
- STAGING ASTM engine checkpoint: `docs/POST_PROD/ASTM/2026-02-28_STAGING_ASTM_APP_GOLDEN_ENGINE_CHECKPOINT.md`
- Decision (STAGING reset): `docs/01_DECISIONS/DECISION_STAGING_RESET_FOR_VOLUMETRICS.md`
- Runbook (STAGING reset): `docs/02_RUNBOOKS/RUNBOOK_STAGING_RESET_FOR_ASTM.md`
- Normative reference (when applicable): `docs/NORMES/VOLUMETRIE_API_MPMS_11_1_2019.md`

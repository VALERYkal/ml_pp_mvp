-- 05_validation_checks.sql
-- Purpose: Ensure volumetric engine behaves correctly before replay.
-- Run after: 04_deploy_astm_engine.sql (engine installed and verified).

\echo '=== Volumetric engine validation ==='

-- Test: compute_v15_from_lookup_grid(volume_ambiant_l, densite_observee_kgm3, temperature_c)
-- Expected: numeric result, no error. Example 1000 L, 837 kg/m³, 19 °C → ~996.6 or 997 L.
SELECT astm.compute_v15_from_lookup_grid(1000, 837, 19) AS volume_15c_l;
-- Verify result is numeric and in expected range (e.g. 990–1000).

\echo '=== If the query above returns a value and no error, engine is operational. ==='

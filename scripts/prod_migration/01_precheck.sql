-- 01_precheck.sql
-- Purpose: Ensure environment is ready before migration.
-- Run on: PROD (or STAGING for dry-run). Verify connection before executing.
-- Usage: psql $DATABASE_URL -f scripts/prod_migration/01_precheck.sql

\set QUIET on
\echo '=== Precheck: ASTM lookup-grid volumetric migration ==='

-- 1. Count receptions in production (expected 8 before migration)
\echo ''
\echo '--- Receptions count ---'
SELECT count(*) AS receptions_count FROM public.receptions;

-- 2. Verify lookup-grid dataset exists (table may be public.astm_lookup_grid_15c or astm.astm_lookup_grid_15c)
\echo ''
\echo '--- Lookup-grid dataset ---'
SELECT to_regclass('public.astm_lookup_grid_15c') AS lookup_grid_table_public;
SELECT to_regclass('astm.astm_lookup_grid_15c') AS lookup_grid_table_astm;
-- If both NULL, lookup-grid dataset is MISSING.

-- 3. Verify volumetric functions exist in schema astm
\echo ''
\echo '--- Volumetric functions (astm schema) ---'
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'astm'
ORDER BY routine_name;
-- Required: compute_v15_from_lookup_grid, assert_lookup_grid_domain, lookup_15c_bilinear_v2 (or equivalent)

-- 4. Verify domain guard function exists
\echo ''
\echo '--- Domain guard ---'
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'astm'
  AND routine_name IN ('assert_lookup_grid_domain', 'lookup_grid_domain');

-- 5. Verify stock view exists
\echo ''
\echo '--- Stock view ---'
SELECT table_schema, table_name
FROM information_schema.views
WHERE table_name IN ('v_stock_actuel', 'v_citerne_stock_actuel')
ORDER BY table_schema, table_name;

-- 6. Environment check
\echo ''
\echo '--- App environment ---'
SELECT key, value FROM public.app_settings WHERE key IN ('environment', 'app_env', 'env');

\echo ''
\echo '=== Precheck complete. Review output above. All required objects must be present before migration. ==='

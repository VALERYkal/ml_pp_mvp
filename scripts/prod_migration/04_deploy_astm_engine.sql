-- 04_deploy_astm_engine.sql
-- Purpose: Verify installation of ASTM lookup-grid runtime engine (schema, functions, dataset).
-- Installation: Run project migration scripts that create the astm schema, table astm_lookup_grid_15c,
-- and functions (e.g. from staging/sql or docs/DB_CHANGES). This script verifies presence only.

\echo '=== ASTM engine deployment verification ==='

-- 1. Schema astm exists
SELECT nspname AS schema_name
FROM pg_namespace
WHERE nspname = 'astm';
-- Must return one row.

-- 2. Lookup-grid dataset table (public or astm schema)
SELECT relname AS table_name, n.nspname AS schema_name
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname = 'astm_lookup_grid_15c'
  AND n.nspname IN ('public', 'astm');
-- Must return at least one row. Table holds batch (e.g. GASOIL_P0_2026-02-28).

-- 3. Required functions in schema astm
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'astm'
  AND routine_name IN (
    'lookup_15c_bilinear_v2',
    'compute_v15_from_lookup_grid',
    'assert_lookup_grid_domain',
    'lookup_grid_domain'
  )
ORDER BY routine_name;
-- Must include: compute_v15_from_lookup_grid, assert_lookup_grid_domain.
-- lookup_15c_bilinear_v2 and lookup_grid_domain are used by the engine.

-- 4. Row count in lookup grid (operational domain)
-- Table may be in public or astm schema
SELECT count(*) AS lookup_grid_rows FROM public.astm_lookup_grid_15c;
-- If error "relation does not exist", try: SELECT count(*) FROM astm.astm_lookup_grid_15c;
-- Expected: 63 or similar for batch GASOIL_P0_2026-02-28 (domain 820-860 kg/m³, 10-40 °C).

\echo '=== If any check above is missing, run project ASTM migration scripts before proceeding. ==='

-- 07_post_migration_checks.sql
-- Purpose: Verify migration success after purge, engine deploy, and replay.
-- Stock must equal: receptions − sorties (by volume @15°C).

\echo '=== Post-migration verification ==='

-- 1. List new receptions and computed volume_15c
\echo '--- Receptions (volume_15c computed by trigger) ---'
SELECT id, citerne_id, index_avant, index_apres,
       (index_apres - index_avant) AS volume_ambiant,
       temperature_ambiante_c, densite_observee_kgm3, volume_15c
FROM public.receptions
ORDER BY created_at;

-- 2. Sum reception volumes @15°C
\echo '--- Sum receptions volume_15c ---'
SELECT coalesce(sum(volume_15c), 0) AS sum_receptions_15c
FROM public.receptions;

-- 3. Sum sortie volumes @15°C
\echo '--- Sum sorties volume_corrige_15c ---'
SELECT coalesce(sum(volume_corrige_15c), 0) AS sum_sorties_15c
FROM public.sorties_produit;

-- 4. Stock view (if exists)
\echo '--- Stock view ---'
SELECT * FROM public.v_stock_actuel;
-- If view name differs:
-- SELECT * FROM public.v_citerne_stock_actuel;

-- 5. Consistency: stock = receptions − sorties (conceptually; exact view depends on schema)
\echo '--- Consistency check ---'
SELECT
  (SELECT coalesce(sum(volume_15c), 0) FROM public.receptions) AS rec_15c,
  (SELECT coalesce(sum(volume_corrige_15c), 0) FROM public.sorties_produit) AS sort_15c,
  (SELECT coalesce(sum(volume_15c), 0) FROM public.receptions)
  - (SELECT coalesce(sum(volume_corrige_15c), 0) FROM public.sorties_produit) AS expected_stock_15c;

\echo '=== Verify: 8 receptions present, volume_15c non-null, stock view consistent. ==='

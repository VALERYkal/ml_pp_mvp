-- OBJECTIF
-- Vérifier les prérequis critiques d'accès ASTM pour le pipeline Réception.
--
-- QUAND L'EXECUTER
-- - Avant toute intervention DB sur périmètre critique (Réception / ASTM / volumétrie / RLS associé)
-- - Après incident ou correction sur ce périmètre
--
-- INTERPRETATION MINIMALE
-- - Tous les checks doivent être TRUE avant GO.
-- - Si au moins un check est FALSE: NO-GO, analyser et corriger avant intervention.

WITH checks AS (
  SELECT
    has_schema_privilege('anon', 'astm', 'USAGE') AS anon_usage_on_astm,
    has_schema_privilege('authenticated', 'astm', 'USAGE') AS authenticated_usage_on_astm,
    has_function_privilege(
      'anon',
      'astm.assert_lookup_grid_domain(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS anon_execute_assert_lookup_grid_domain,
    has_function_privilege(
      'authenticated',
      'astm.assert_lookup_grid_domain(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS authenticated_execute_assert_lookup_grid_domain,
    has_function_privilege(
      'anon',
      'astm.compute_v15_from_lookup_grid(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS anon_execute_compute_v15_from_lookup_grid,
    has_function_privilege(
      'authenticated',
      'astm.compute_v15_from_lookup_grid(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS authenticated_execute_compute_v15_from_lookup_grid,
    has_function_privilege(
      'anon',
      'astm.lookup_15c_bilinear_v2(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS anon_execute_lookup_15c_bilinear_v2,
    has_function_privilege(
      'authenticated',
      'astm.lookup_15c_bilinear_v2(numeric,numeric,numeric)',
      'EXECUTE'
    ) AS authenticated_execute_lookup_15c_bilinear_v2,
    EXISTS (
      SELECT 1
      FROM pg_trigger
      WHERE tgname = 'trg_receptions_compute_15c_before_ins'
        AND NOT tgisinternal
    ) AS has_trg_receptions_compute_15c_before_ins,
    EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'receptions_compute_15c_before_ins'
        AND pg_get_functiondef(p.oid) ILIKE '%astm.compute_v15_from_lookup_grid%'
    ) AS receptions_trigger_calls_astm_compute,
    EXISTS (
      SELECT 1
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = 'receptions_compute_15c_before_ins'
        AND pg_get_functiondef(p.oid) ILIKE '%astm.assert_lookup_grid_domain%'
    ) AS receptions_trigger_calls_astm_guard
)
SELECT
  anon_usage_on_astm,
  authenticated_usage_on_astm,
  anon_execute_assert_lookup_grid_domain,
  authenticated_execute_assert_lookup_grid_domain,
  anon_execute_compute_v15_from_lookup_grid,
  authenticated_execute_compute_v15_from_lookup_grid,
  anon_execute_lookup_15c_bilinear_v2,
  authenticated_execute_lookup_15c_bilinear_v2,
  (anon_execute_assert_lookup_grid_domain
    AND anon_execute_compute_v15_from_lookup_grid
    AND anon_execute_lookup_15c_bilinear_v2) AS anon_execute_all_astm_functions,
  (authenticated_execute_assert_lookup_grid_domain
    AND authenticated_execute_compute_v15_from_lookup_grid
    AND authenticated_execute_lookup_15c_bilinear_v2) AS authenticated_execute_all_astm_functions,
  has_trg_receptions_compute_15c_before_ins,
  receptions_trigger_calls_astm_compute,
  receptions_trigger_calls_astm_guard
FROM checks;

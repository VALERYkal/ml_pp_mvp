-- =============================================================================
-- STAGING ONLY — Hygiene / Remove TANK TEST + Purge stocks_snapshot
-- =============================================================================
-- Fichier : docs/DB_CHANGES/2026-02-25_staging_hygiene_remove_tank_test_and_purge_snapshot.sql
-- Date    : 2026-02-25
-- Contexte: Après reset "CDR only", l'UI affichait encore du stock non-zéro car
--           public.stocks_snapshot contenait des lignes historiques (cache/snapshot)
--           et la FK fk_stocks_snapshot_citerne bloquait la suppression de la
--           citerne fantôme TANK TEST. Ce script restaure un baseline stock=0.
-- =============================================================================
-- PRÉCONDITIONS:
--   - STAGING only. Ne pas exécuter en PROD.
--   - À exécuter après reset CDR only si besoin d'une baseline stock=0 (prérequis
--     avant simulation UX terrain / validation ASTM).
-- =============================================================================
-- Pourquoi:
--   - L'UI lit stocks_snapshot (Dashboard, écran Stock). Tant que des lignes
--     existent, le stock total affiché est non nul.
--   - La FK stocks_snapshot -> citernes bloque le DELETE sur citernes tant que
--     des lignes stocks_snapshot référencent la citerne. Il faut d'abord supprimer
--     les lignes snapshot qui pointent vers TANK TEST, puis la citerne, puis
--     purger entièrement stocks_snapshot pour un baseline à zéro.
-- =============================================================================

-- Citerne fantôme concernée:
--   nom: TANK TEST
--   id:  44444444-4444-4444-4444-444444444444
--   Références fixtures: DEPOT STAGING (1111...), DIESEL STAGING (2222...)

-- 1) Supprimer les lignes stocks_snapshot qui référencent TANK TEST (débloquer FK)
DELETE FROM public.stocks_snapshot
WHERE citerne_id = '44444444-4444-4444-4444-444444444444';

-- 2) Supprimer la citerne fantôme TANK TEST
DELETE FROM public.citernes
WHERE id = '44444444-4444-4444-4444-444444444444';

-- 3) Purge totale de stocks_snapshot pour baseline à zéro (Dashboard/Stock = 0)
TRUNCATE public.stocks_snapshot;

-- =============================================================================
-- Vérifications intégrées
-- =============================================================================
DO $$
DECLARE
  v_tank_test_citernes bigint;
  v_tank_test_snapshot bigint;
  v_stocks_snapshot_total bigint;
BEGIN
  SELECT COUNT(*) INTO v_tank_test_citernes FROM public.citernes WHERE id = '44444444-4444-4444-4444-444444444444';
  SELECT COUNT(*) INTO v_tank_test_snapshot FROM public.stocks_snapshot WHERE citerne_id = '44444444-4444-4444-4444-444444444444';
  SELECT COUNT(*) INTO v_stocks_snapshot_total FROM public.stocks_snapshot;
  RAISE NOTICE 'tank_test_in_citernes = %', v_tank_test_citernes;
  RAISE NOTICE 'tank_test_in_snapshot = %', v_tank_test_snapshot;
  RAISE NOTICE 'stocks_snapshot_total = %', v_stocks_snapshot_total;
  IF v_tank_test_citernes <> 0 OR v_tank_test_snapshot <> 0 OR v_stocks_snapshot_total <> 0 THEN
    RAISE WARNING 'Hygiene check: expected all 0. Re-run script or check STAGING.';
  END IF;
END $$;

-- Résultat attendu: les trois comptes à 0. UI: Dashboard stock total = 0, Stock écran = 0.

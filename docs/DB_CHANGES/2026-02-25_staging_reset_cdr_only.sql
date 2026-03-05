-- =============================================================================
-- STAGING ONLY — RESET CDR ONLY
-- =============================================================================
-- Fichier : docs/DB_CHANGES/2026-02-25_staging_reset_cdr_only.sql
-- Date    : 2026-02-25
-- Contexte: Purge STAGING pour repartir sur une base saine (validation ASTM/UX).
-- Rappel  : NE JAMAIS EXÉCUTER EN PROD. Ce script est destiné à l'environnement
--           STAGING uniquement. Les tables immuables (receptions, sorties_produit,
--           stocks_journaliers) sont protégées par des triggers DB-STRICT ; la
--           purge nécessite d'activer temporairement les flags de write.
-- =============================================================================
-- Invariants:
--   - cours_de_route MUST remain unchanged (CDR preserved).
--   - Only stock-move tables impacted: log_actions (scoped), sorties_produit,
--     receptions, stocks_journaliers.
--   - DB-STRICT flags are transaction-scoped (set_config(..., true)).
-- =============================================================================

-- 1) Patch receptions_block_update_delete: autoriser UPDATE/DELETE si flag activé
--    (STAGING only; permet purge contrôlée dans une transaction)
CREATE OR REPLACE FUNCTION public.receptions_block_update_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if current_setting('app.receptions_allow_write', true) = '1' then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  raise exception
    'Ecriture interdite sur receptions (op=%). Table immutable: utiliser INSERT + triggers/RPC, jamais UPDATE/DELETE.',
    tg_op;
end;
$$;

-- 2) Script de purge transactionnel REJOUABLE (idempotent si tables déjà vides)
--    À exécuter dans Supabase SQL Editor ou psql sur STAGING uniquement.
--    Une seule transaction : BEGIN ... COMMIT.
BEGIN;
  -- Guardrail doc/humain: marquer la transaction comme staging
  SELECT set_config('app.environment', 'staging', true);
  SELECT set_config('app.receptions_allow_write', '1', true);
  SELECT set_config('app.sorties_produit_allow_write', '1', true);
  SELECT set_config('app.stocks_journaliers_allow_write', '1', true);

  -- Snapshots BEFORE (comptages)
  DO $$
  DECLARE
    v_receptions bigint;
    v_sorties bigint;
    v_stocks bigint;
    v_log_scoped bigint;
    v_cdr bigint;
  BEGIN
    SELECT count(*) INTO v_cdr FROM public.cours_de_route;
    SELECT count(*) INTO v_receptions FROM public.receptions;
    SELECT count(*) INTO v_sorties FROM public.sorties_produit;
    SELECT count(*) INTO v_stocks FROM public.stocks_journaliers;
    SELECT count(*) INTO v_log_scoped FROM public.log_actions
      WHERE module IN ('receptions', 'sorties') OR module ILIKE '%stock%';
    RAISE NOTICE 'BEFORE — cours_de_route: %, receptions: %, sorties_produit: %, stocks_journaliers: %, log_actions(scoped): %',
      v_cdr, v_receptions, v_sorties, v_stocks, v_log_scoped;
  END $$;

  -- Purge ordonnée (respect FK / ordre logique)
  DELETE FROM public.log_actions
    WHERE module IN ('receptions', 'sorties') OR module ILIKE '%stock%';
  DELETE FROM public.sorties_produit;
  DELETE FROM public.receptions;
  DELETE FROM public.stocks_journaliers;

  -- Snapshots AFTER (comptages)
  DO $$
  DECLARE
    v_receptions bigint;
    v_sorties bigint;
    v_stocks bigint;
    v_log_scoped bigint;
    v_cdr bigint;
  BEGIN
    SELECT count(*) INTO v_cdr FROM public.cours_de_route;
    SELECT count(*) INTO v_receptions FROM public.receptions;
    SELECT count(*) INTO v_sorties FROM public.sorties_produit;
    SELECT count(*) INTO v_stocks FROM public.stocks_journaliers;
    SELECT count(*) INTO v_log_scoped FROM public.log_actions
      WHERE module IN ('receptions', 'sorties') OR module ILIKE '%stock%';
    RAISE NOTICE 'AFTER — cours_de_route: % (invariant), receptions: %, sorties_produit: %, stocks_journaliers: %, log_actions(scoped): %',
      v_cdr, v_receptions, v_sorties, v_stocks, v_log_scoped;
  END $$;
COMMIT;

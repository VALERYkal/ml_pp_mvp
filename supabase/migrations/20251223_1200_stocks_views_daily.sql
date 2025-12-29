-- Migration: Vue canonique v_stocks_citerne_global_daily
-- Date: 2025-12-23
-- Objectif: Créer la vue canonique pour Flutter avec support date_jour
-- 
-- Cette vue expose des snapshots quotidiens par citerne & produit (tous propriétaires confondus)
-- avec support du filtrage par date_jour. L'application Flutter utilise exclusivement cette vue
-- pour tous les modules (Dashboard, Stocks, Citernes).
--
-- Référence: docs/db/stocks_views_contract.md

-- ============================================================================
-- VUE CANONIQUE: v_stocks_citerne_global_daily
-- ============================================================================
-- Canonical daily global stock by citerne/product/day (all owners aggregated)

CREATE OR REPLACE VIEW public.v_stocks_citerne_global_daily AS
WITH agg AS (
  SELECT
    sj.citerne_id,
    sj.produit_id,
    sj.date_jour,
    sum(sj.stock_ambiant) AS stock_ambiant_total,
    sum(sj.stock_15c) AS stock_15c_total
  FROM public.stocks_journaliers sj
  GROUP BY sj.citerne_id, sj.produit_id, sj.date_jour
)
SELECT
  a.citerne_id,
  c.nom AS citerne_nom,
  a.produit_id,
  p.nom AS produit_nom,
  d.id AS depot_id,
  d.nom AS depot_nom,
  a.date_jour,
  a.stock_ambiant_total,
  a.stock_15c_total,
  c.capacite_totale
FROM agg a
JOIN public.citernes c ON c.id = a.citerne_id
JOIN public.depots d ON d.id = c.depot_id
JOIN public.produits p ON p.id = a.produit_id;

COMMENT ON VIEW public.v_stocks_citerne_global_daily IS 
'Canonical daily global stock view by citerne/product/day (all owners aggregated). This is the canonical view consumed by Flutter for all modules (Dashboard, Stocks, Citernes). Exposes daily snapshots with date_jour filterable column.';


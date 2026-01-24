-- Migration: Vue snapshot stock actuel par propriétaire
-- Date: 2025-12-27
-- Description: Création de v_stock_actuel_owner_snapshot pour l'affichage cohérent 
--              du stock par propriétaire (MONALUXE/PARTENAIRE) indépendamment des trous de dates
--              dans stocks_journaliers.

-- VUE: v_stock_actuel_owner_snapshot
-- Retourne le dernier état connu de chaque combinaison (citerne, produit, propriétaire)
-- et agrège par (dépôt, produit, propriétaire)

DROP VIEW IF EXISTS public.v_stock_actuel_owner_snapshot;
-- (no CASCADE: verified no dependencies)

CREATE OR REPLACE VIEW public.v_stock_actuel_owner_snapshot AS
WITH base AS (
  SELECT 
    COALESCE(sj.depot_id, c.depot_id) AS depot_id,
    sj.citerne_id,
    sj.produit_id,
    sj.proprietaire_type,
    sj.date_jour,
    sj.stock_ambiant,
    sj.stock_15c
  FROM stocks_journaliers sj
  LEFT JOIN citernes c ON c.id = sj.citerne_id
),
last_date AS (
  SELECT 
    base.citerne_id,
    base.produit_id,
    base.proprietaire_type,
    MAX(base.date_jour) AS date_jour
  FROM base
  GROUP BY base.citerne_id, base.produit_id, base.proprietaire_type
),
last_rows AS (
  SELECT 
    b.depot_id,
    b.citerne_id,
    b.produit_id,
    b.proprietaire_type,
    b.date_jour,
    b.stock_ambiant,
    b.stock_15c
  FROM base b
  JOIN last_date ld ON (
    ld.citerne_id = b.citerne_id 
    AND ld.produit_id = b.produit_id 
    AND ld.proprietaire_type = b.proprietaire_type 
    AND ld.date_jour = b.date_jour
  )
),
agg AS (
  SELECT 
    last_rows.depot_id,
    last_rows.produit_id,
    last_rows.proprietaire_type,
    MAX(last_rows.date_jour) AS date_jour_max,
    SUM(last_rows.stock_ambiant) AS stock_ambiant_total,
    SUM(last_rows.stock_15c) AS stock_15c_total
  FROM last_rows
  GROUP BY last_rows.depot_id, last_rows.produit_id, last_rows.proprietaire_type
)
SELECT 
  a.depot_id,
  d.nom AS depot_nom,
  a.produit_id,
  p.nom AS produit_nom,
  a.proprietaire_type,
  a.stock_ambiant_total,
  a.stock_15c_total,
  a.date_jour_max AS updated_at_max
FROM agg a
JOIN depots d ON d.id = a.depot_id
JOIN produits p ON p.id = a.produit_id;

COMMENT ON VIEW public.v_stock_actuel_owner_snapshot IS 
  'Vue snapshot du stock actuel par dépôt, produit et propriétaire. 
   Retourne le dernier état connu de chaque combinaison (citerne, produit, propriétaire) 
   et agrège par (dépôt, produit, propriétaire). 
   Utilisée pour afficher le stock réel présent indépendamment des trous de dates dans stocks_journaliers.';


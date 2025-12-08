-- Vues Stocks pour Frontend - Phase 3 (idempotent)
-- Création de vues stables pour que Flutter consomme les données de stocks
-- sans dépendre de l'implémentation interne.
--
-- Référence : 
-- - docs/db/stocks_rules.md pour les règles métier
-- - docs/db/stocks_views_tests.md pour les tests manuels

-- ============================================================================
-- VUE 1 : v_stocks_citerne_global
-- ============================================================================
-- Vue principale de stock instantané par citerne / produit / propriétaire + total
-- Utilisée par : Citernes, Dashboard, KPI
-- Retourne le dernier stock connu avec agrégation MONALUXE + PARTENAIRE

CREATE OR REPLACE VIEW public.v_stocks_citerne_global AS
WITH dernier_stock AS (
  SELECT DISTINCT ON (citerne_id, produit_id, proprietaire_type)
    citerne_id,
    produit_id,
    proprietaire_type,
    stock_ambiant,
    stock_15c,
    date_jour,
    depot_id
  FROM public.stocks_journaliers
  ORDER BY citerne_id, produit_id, proprietaire_type, date_jour DESC
),
stocks_agreges AS (
  SELECT
    citerne_id,
    produit_id,
    depot_id,
    SUM(CASE WHEN proprietaire_type = 'MONALUXE' THEN stock_ambiant ELSE 0 END) AS stock_ambiant_monaluxe,
    SUM(CASE WHEN proprietaire_type = 'MONALUXE' THEN stock_15c ELSE 0 END) AS stock_15c_monaluxe,
    SUM(CASE WHEN proprietaire_type = 'PARTENAIRE' THEN stock_ambiant ELSE 0 END) AS stock_ambiant_partenaire,
    SUM(CASE WHEN proprietaire_type = 'PARTENAIRE' THEN stock_15c ELSE 0 END) AS stock_15c_partenaire,
    MAX(date_jour) AS date_dernier_mouvement
  FROM dernier_stock
  GROUP BY citerne_id, produit_id, depot_id
)
SELECT
  c.id AS citerne_id,
  c.nom AS citerne_nom,
  c.produit_id,
  p.nom AS produit_nom,
  p.code AS produit_code,
  sa.stock_ambiant_monaluxe + sa.stock_ambiant_partenaire AS stock_ambiant_total,
  sa.stock_15c_monaluxe + sa.stock_15c_partenaire AS stock_15c_total,
  sa.stock_ambiant_monaluxe,
  sa.stock_15c_monaluxe,
  sa.stock_ambiant_partenaire,
  sa.stock_15c_partenaire,
  c.capacite_totale,
  c.capacite_securite,
  CASE 
    WHEN c.capacite_totale > 0 
    THEN ((sa.stock_ambiant_monaluxe + sa.stock_ambiant_partenaire) / c.capacite_totale) * 100
    ELSE 0
  END AS ratio_utilisation,
  sa.depot_id,
  d.nom AS depot_nom,
  sa.date_dernier_mouvement
FROM public.citernes c
LEFT JOIN public.produits p ON p.id = c.produit_id
LEFT JOIN stocks_agreges sa ON sa.citerne_id = c.id AND sa.produit_id = c.produit_id
LEFT JOIN public.depots d ON d.id = COALESCE(sa.depot_id, c.depot_id);

COMMENT ON VIEW public.v_stocks_citerne_global IS 
'Vue principale de stock instantané par citerne / produit avec totaux MONALUXE + PARTENAIRE. Source unique de vérité pour les écrans Citernes, Dashboard et KPI.';

-- ============================================================================
-- VUE 2 : v_stocks_citernes
-- ============================================================================
-- Vue pour l'écran "Stocks journaliers"
-- Retourne les stocks par date, citerne, produit avec détails

CREATE OR REPLACE VIEW public.v_stocks_citernes AS
SELECT 
  sj.date_jour,
  sj.citerne_id,
  c.nom AS citerne_nom,
  sj.produit_id,
  p.nom AS produit_nom,
  p.code AS produit_code,
  sj.proprietaire_type,
  sj.stock_ambiant,
  sj.stock_15c,
  c.capacite_totale,
  c.capacite_securite,
  CASE 
    WHEN c.capacite_totale > 0 
    THEN (sj.stock_ambiant / c.capacite_totale) * 100
    ELSE 0
  END AS ratio_utilisation,
  sj.depot_id,
  d.nom AS depot_nom,
  sj.source,
  sj.created_at,
  sj.updated_at
FROM public.stocks_journaliers sj
LEFT JOIN public.citernes c ON c.id = sj.citerne_id
LEFT JOIN public.produits p ON p.id = sj.produit_id
LEFT JOIN public.depots d ON d.id = sj.depot_id;

COMMENT ON VIEW public.v_stocks_citernes IS 
'Vue pour l''écran Stocks journaliers : stocks par date, citerne, produit avec détails (capacité, ratio, etc.)';

-- ============================================================================
-- VUE 3 : v_dashboard_kpi
-- ============================================================================
-- Vue pour le Dashboard
-- Retourne les KPIs agrégés (totaux, volumes du jour, balance, tendance 7j)

CREATE OR REPLACE VIEW public.v_dashboard_kpi AS
WITH stocks_totaux AS (
  SELECT 
    date_jour,
    SUM(stock_ambiant) AS stock_total_ambiant,
    SUM(stock_15c) AS stock_total_15c
  FROM public.stocks_journaliers
  GROUP BY date_jour
),
receptions_jour AS (
  SELECT 
    date_reception::date AS date_jour,
    SUM(COALESCE(volume_ambiant, 0)) AS receptions_jour_ambiant,
    SUM(COALESCE(volume_corrige_15c, 0)) AS receptions_jour_15c,
    COUNT(*) AS nb_receptions
  FROM public.receptions
  WHERE statut = 'validee'
  GROUP BY date_reception::date
),
sorties_jour AS (
  SELECT 
    COALESCE(date_sortie::date, created_at::date) AS date_jour,
    SUM(COALESCE(volume_ambiant, 0)) AS sorties_jour_ambiant,
    SUM(COALESCE(volume_corrige_15c, 0)) AS sorties_jour_15c,
    COUNT(*) AS nb_sorties
  FROM public.sorties_produit
  WHERE statut = 'validee'
  GROUP BY COALESCE(date_sortie::date, created_at::date)
),
tendance_7j AS (
  SELECT 
    date_jour,
    SUM(CASE WHEN source = 'RECEPTION' THEN stock_ambiant ELSE 0 END) AS sum_receptions_ambiant,
    SUM(CASE WHEN source = 'RECEPTION' THEN stock_15c ELSE 0 END) AS sum_receptions_15c,
    SUM(CASE WHEN source = 'SORTIE' THEN ABS(stock_ambiant) ELSE 0 END) AS sum_sorties_ambiant,
    SUM(CASE WHEN source = 'SORTIE' THEN ABS(stock_15c) ELSE 0 END) AS sum_sorties_15c
  FROM public.stocks_journaliers
  WHERE date_jour >= CURRENT_DATE - INTERVAL '7 days'
  GROUP BY date_jour
)
SELECT 
  COALESCE(st.date_jour, rj.date_jour, sj.date_jour) AS date_jour,
  COALESCE(st.stock_total_ambiant, 0) AS stock_total_ambiant,
  COALESCE(st.stock_total_15c, 0) AS stock_total_15c,
  COALESCE(rj.receptions_jour_ambiant, 0) AS receptions_jour_ambiant,
  COALESCE(rj.receptions_jour_15c, 0) AS receptions_jour_15c,
  COALESCE(rj.nb_receptions, 0) AS nb_receptions,
  COALESCE(sj.sorties_jour_ambiant, 0) AS sorties_jour_ambiant,
  COALESCE(sj.sorties_jour_15c, 0) AS sorties_jour_15c,
  COALESCE(sj.nb_sorties, 0) AS nb_sorties,
  COALESCE(rj.receptions_jour_ambiant, 0) - COALESCE(sj.sorties_jour_ambiant, 0) AS balance_jour_ambiant,
  COALESCE(rj.receptions_jour_15c, 0) - COALESCE(sj.sorties_jour_15c, 0) AS balance_jour_15c,
  -- Tendance 7 jours (somme nette)
  (
    SELECT SUM(sum_receptions_ambiant - sum_sorties_ambiant)
    FROM tendance_7j
  ) AS tendance_7j_ambiant,
  (
    SELECT SUM(sum_receptions_15c - sum_sorties_15c)
    FROM tendance_7j
  ) AS tendance_7j_15c
FROM stocks_totaux st
FULL OUTER JOIN receptions_jour rj ON st.date_jour = rj.date_jour
FULL OUTER JOIN sorties_jour sj ON COALESCE(st.date_jour, rj.date_jour) = sj.date_jour;

COMMENT ON VIEW public.v_dashboard_kpi IS 
'Vue pour le Dashboard : KPIs agrégés (totaux stocks, volumes du jour, balance, tendance 7 jours)';

-- ============================================================================
-- VUE 4 : v_citernes_state
-- ============================================================================
-- Vue pour l'écran "Citernes"
-- Retourne l'état actuel de chaque citerne (dernier stock connu)

CREATE OR REPLACE VIEW public.v_citernes_state AS
WITH dernier_stock AS (
  SELECT DISTINCT ON (citerne_id, produit_id, proprietaire_type)
    citerne_id,
    produit_id,
    proprietaire_type,
    stock_ambiant,
    stock_15c,
    date_jour,
    ROW_NUMBER() OVER (
      PARTITION BY citerne_id, produit_id, proprietaire_type 
      ORDER BY date_jour DESC
    ) AS rn
  FROM public.stocks_journaliers
)
SELECT 
  c.id AS citerne_id,
  c.nom AS citerne_nom,
  c.produit_id,
  p.nom AS produit_nom,
  p.code AS produit_code,
  ds.proprietaire_type,
  COALESCE(ds.stock_ambiant, 0) AS stock_ambiant_actuel,
  COALESCE(ds.stock_15c, 0) AS stock_15c_actuel,
  ds.date_jour AS date_dernier_mouvement,
  c.capacite_totale,
  c.capacite_securite,
  CASE 
    WHEN c.capacite_totale > 0 
    THEN (COALESCE(ds.stock_ambiant, 0) / c.capacite_totale) * 100
    ELSE 0
  END AS ratio_utilisation,
  c.statut AS citerne_statut,
  c.depot_id,
  d.nom AS depot_nom
FROM public.citernes c
LEFT JOIN public.produits p ON p.id = c.produit_id
LEFT JOIN public.depots d ON d.id = c.depot_id
LEFT JOIN dernier_stock ds ON ds.citerne_id = c.id 
  AND ds.produit_id = c.produit_id
  AND ds.rn = 1;

COMMENT ON VIEW public.v_citernes_state IS 
'Vue pour l''écran Citernes : état actuel de chaque citerne avec dernier stock connu';

-- ============================================================================
-- INDEX pour performance (si nécessaire)
-- ============================================================================

-- Les index existants sur stocks_journaliers devraient suffire
-- Vérifier avec EXPLAIN ANALYZE et ajouter si nécessaire

-- ============================================================================
-- VUE 5 : v_kpi_stock_depot (optionnel - à créer si nécessaire)
-- ============================================================================
-- Vue pour les KPIs Dashboard : agrégation par dépôt / produit / propriétaire
-- TODO: Créer si les KPIs Dashboard nécessitent cette agrégation

-- ============================================================================
-- VUE 6 : v_kpi_stock_proprietaire_global (optionnel - à créer si nécessaire)
-- ============================================================================
-- Vue pour les KPIs Dashboard : agrégation globale Monaluxe vs Partenaire
-- TODO: Créer si les KPIs Dashboard nécessitent cette agrégation

-- ============================================================================
-- NOTES POUR IMPLÉMENTATION
-- ============================================================================

-- 1. v_stocks_citerne_global : Vue principale, utilisée par Citernes et Dashboard
-- 2. v_stocks_citernes : Simple jointure, devrait être performante
-- 3. v_dashboard_kpi : Utilise des CTE, vérifier performance avec EXPLAIN ANALYZE
-- 4. v_citernes_state : Utilise DISTINCT ON, vérifier performance
-- 5. Tester toutes les vues avec docs/db/stocks_views_tests.md
-- 6. Adapter les colonnes selon les besoins réels du frontend
-- 7. Voir docs/db/stocks_views_contract.md pour le contrat d'interface


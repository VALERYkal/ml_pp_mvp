-- Script de validation des stocks - Phase 2
-- À exécuter après chaque grosse migration pour vérifier la cohérence
-- entre v_mouvements_stock, stocks_journaliers et v_stocks_citerne_global

-- ============================================================================
-- VALIDATION 1 : Cohérence mouvements vs stocks journaliers
-- ============================================================================

-- Somme des mouvements depuis v_mouvements_stock
SELECT 
  'Mouvements (v_mouvements_stock)' AS source,
  SUM(delta_ambiant) AS total_ambiant,
  SUM(delta_15c) AS total_15c,
  COUNT(*) AS nb_mouvements
FROM public.v_mouvements_stock;

-- Stock au dernier jour depuis stocks_journaliers
SELECT 
  'Stocks journaliers (dernier jour)' AS source,
  SUM(stock_ambiant) AS total_ambiant,
  SUM(stock_15c) AS total_15c,
  COUNT(*) AS nb_lignes
FROM public.stocks_journaliers
WHERE date_jour = (
  SELECT MAX(date_jour) FROM public.stocks_journaliers
);

-- ============================================================================
-- VALIDATION 2 : Cohérence par citerne
-- ============================================================================

-- Comparer v_stocks_citerne_global avec stocks_journaliers (dernier jour)
SELECT 
  'v_stocks_citerne_global' AS source,
  citerne_nom,
  produit_nom,
  stock_ambiant_total,
  stock_15c_total
FROM public.v_stocks_citerne_global
ORDER BY citerne_nom, produit_nom;

-- Stocks journaliers par citerne (dernier jour)
SELECT 
  'stocks_journaliers (dernier jour)' AS source,
  c.nom AS citerne_nom,
  p.nom AS produit_nom,
  SUM(sj.stock_ambiant) AS stock_ambiant_total,
  SUM(sj.stock_15c) AS stock_15c_total
FROM public.stocks_journaliers sj
LEFT JOIN public.citernes c ON c.id = sj.citerne_id
LEFT JOIN public.produits p ON p.id = sj.produit_id
WHERE sj.date_jour = (
  SELECT MAX(date_jour) FROM public.stocks_journaliers
)
GROUP BY c.nom, p.nom, sj.citerne_id, sj.produit_id
ORDER BY c.nom, p.nom;

-- ============================================================================
-- VALIDATION 3 : Séparation propriétaires
-- ============================================================================

-- Vérifier que MONALUXE et PARTENAIRE sont bien séparés
SELECT 
  citerne_id,
  produit_id,
  proprietaire_type,
  COUNT(*) AS nb_lignes,
  SUM(stock_ambiant) AS total_ambiant,
  SUM(stock_15c) AS total_15c
FROM public.stocks_journaliers
WHERE date_jour = (
  SELECT MAX(date_jour) FROM public.stocks_journaliers
)
GROUP BY citerne_id, produit_id, proprietaire_type
ORDER BY citerne_id, produit_id, proprietaire_type;

-- ============================================================================
-- VALIDATION 4 : Vérification des totaux dans v_stocks_citerne_global
-- ============================================================================

-- Vérifier que stock_ambiant_total = stock_ambiant_monaluxe + stock_ambiant_partenaire
SELECT 
  citerne_nom,
  produit_nom,
  stock_ambiant_total,
  stock_ambiant_monaluxe,
  stock_ambiant_partenaire,
  (stock_ambiant_monaluxe + stock_ambiant_partenaire) AS calcul_manuel,
  CASE 
    WHEN ABS(stock_ambiant_total - (stock_ambiant_monaluxe + stock_ambiant_partenaire)) < 0.01 
    THEN 'OK' 
    ELSE 'ERREUR' 
  END AS validation
FROM public.v_stocks_citerne_global
WHERE stock_ambiant_total IS NOT NULL
ORDER BY citerne_nom, produit_nom;

-- ============================================================================
-- VALIDATION 5 : Vérification des dates
-- ============================================================================

-- Vérifier qu'il n'y a pas de dates futures
SELECT 
  'Dates futures détectées' AS check_type,
  COUNT(*) AS nb_lignes
FROM public.stocks_journaliers
WHERE date_jour > CURRENT_DATE;

-- Vérifier qu'il n'y a pas de dates trop anciennes (ex: avant 2020)
SELECT 
  'Dates trop anciennes (< 2020)' AS check_type,
  COUNT(*) AS nb_lignes
FROM public.stocks_journaliers
WHERE date_jour < '2020-01-01';

-- ============================================================================
-- VALIDATION 6 : Vérification des sources
-- ============================================================================

-- Compter les lignes par source
SELECT 
  source,
  COUNT(*) AS nb_lignes,
  SUM(stock_ambiant) AS total_ambiant,
  SUM(stock_15c) AS total_15c
FROM public.stocks_journaliers
WHERE date_jour = (
  SELECT MAX(date_jour) FROM public.stocks_journaliers
)
GROUP BY source;

-- ============================================================================
-- RÉSUMÉ
-- ============================================================================

-- Toutes les validations doivent retourner des résultats cohérents :
-- 1. Somme des mouvements = Stock au dernier jour
-- 2. v_stocks_citerne_global = stocks_journaliers (dernier jour) agrégé
-- 3. MONALUXE et PARTENAIRE sont séparés
-- 4. Totaux dans v_stocks_citerne_global sont corrects
-- 5. Pas de dates futures ou trop anciennes
-- 6. Sources SYSTEM vs MANUAL sont distinguées

COMMENT ON VIEW public.v_stocks_citerne_global IS 
'Vue principale de stock instantané par citerne / produit avec totaux MONALUXE + PARTENAIRE. Source unique de vérité pour les écrans Citernes, Dashboard et KPI.';


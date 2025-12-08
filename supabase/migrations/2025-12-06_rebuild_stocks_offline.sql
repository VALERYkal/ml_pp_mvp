-- Rebuild Stocks Journaliers - Phase 1 (idempotent)
-- Fonction pour recalculer les stocks journaliers à partir de v_mouvements_stock
-- en utilisant des window functions pour calculer les cumuls.
--
-- ⚠️ Cette fonction supprime uniquement les lignes source = 'SYSTEM',
-- puis les recalcule entièrement, en laissant intact d'éventuels ajustements manuels.
--
-- Référence : docs/db/stocks_rules.md pour les règles métier

-- ============================================================================
-- VUE : v_mouvements_stock
-- ============================================================================
-- Vue qui agrège tous les mouvements (réceptions et sorties) avec leurs deltas

CREATE OR REPLACE VIEW public.v_mouvements_stock AS
SELECT 
  date_jour,
  citerne_id,
  produit_id,
  depot_id,
  proprietaire_type,
  delta_ambiant,
  delta_15c
FROM (
  -- Réceptions (crédit positif)
  SELECT 
    date_reception::date AS date_jour,
    citerne_id,
    produit_id,
    c.depot_id,
    UPPER(COALESCE(TRIM(proprietaire_type), 'MONALUXE')) AS proprietaire_type,
    COALESCE(volume_ambiant,
      CASE 
        WHEN index_avant IS NOT NULL AND index_apres IS NOT NULL 
        THEN index_apres - index_avant 
        ELSE 0 
      END
    ) AS delta_ambiant,
    COALESCE(volume_corrige_15c,
      COALESCE(volume_ambiant,
        CASE 
          WHEN index_avant IS NOT NULL AND index_apres IS NOT NULL 
          THEN index_apres - index_avant 
          ELSE 0 
        END
      )
    ) AS delta_15c
  FROM public.receptions r
  LEFT JOIN public.citernes c ON c.id = r.citerne_id
  WHERE statut = 'validee'
  
  UNION ALL
  
  -- Sorties (débit négatif)
  SELECT 
    COALESCE(date_sortie::date, created_at::date) AS date_jour,
    citerne_id,
    produit_id,
    c.depot_id,
    UPPER(COALESCE(TRIM(proprietaire_type), 'MONALUXE')) AS proprietaire_type,
    -1 * COALESCE(volume_ambiant,
      CASE 
        WHEN index_avant IS NOT NULL AND index_apres IS NOT NULL 
        THEN index_apres - index_avant 
        ELSE 0 
      END
    ) AS delta_ambiant,
    -1 * COALESCE(volume_corrige_15c,
      COALESCE(volume_ambiant,
        CASE 
          WHEN index_avant IS NOT NULL AND index_apres IS NOT NULL 
          THEN index_apres - index_avant 
          ELSE 0 
        END
      )
    ) AS delta_15c
  FROM public.sorties_produit s
  LEFT JOIN public.citernes c ON c.id = s.citerne_id
  WHERE statut = 'validee'
) mouvements;

COMMENT ON VIEW public.v_mouvements_stock IS 
'Vue qui agrège tous les mouvements de stock (réceptions et sorties) avec leurs deltas journaliers. Les réceptions sont positives (crédit), les sorties sont négatives (débit).';

-- ============================================================================
-- FONCTION : rebuild_stocks_journaliers()
-- ============================================================================

CREATE OR REPLACE FUNCTION public.rebuild_stocks_journaliers(
  p_depot_id   uuid  DEFAULT NULL,
  p_start_date date  DEFAULT NULL,
  p_end_date   date  DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  --------------------------------------------------------------------
  -- 1) Supprimer les lignes SYSTEM existantes dans le périmètre
  --------------------------------------------------------------------
  DELETE FROM public.stocks_journaliers sj
  USING public.citernes c
  WHERE sj.citerne_id = c.id
    AND sj.source = 'SYSTEM'
    AND (p_depot_id  IS NULL OR c.depot_id = p_depot_id)
    AND (p_start_date IS NULL OR sj.date_jour >= p_start_date)
    AND (p_end_date   IS NULL OR sj.date_jour <= p_end_date);

  --------------------------------------------------------------------
  -- 2) Recalculer les stocks cumulés à partir de v_mouvements_stock
  --------------------------------------------------------------------
  INSERT INTO public.stocks_journaliers (
    citerne_id,
    produit_id,
    date_jour,
    stock_ambiant,
    stock_15c,
    proprietaire_type,
    depot_id,
    source,
    created_at,
    updated_at
  )
  SELECT
    m.citerne_id,
    m.produit_id,
    m.date_jour,
    m.cum_ambiant,
    m.cum_15c,
    m.proprietaire_type,
    m.depot_id,
    'SYSTEM' AS source,
    now()    AS created_at,
    now()    AS updated_at
  FROM (
    -- Cumuls par citerne / produit / depot / propriétaire
    SELECT
      date_jour,
      citerne_id,
      produit_id,
      depot_id,
      proprietaire_type,
      SUM(delta_ambiant) OVER (
        PARTITION BY citerne_id, produit_id, depot_id, proprietaire_type
        ORDER BY date_jour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cum_ambiant,
      SUM(delta_15c) OVER (
        PARTITION BY citerne_id, produit_id, depot_id, proprietaire_type
        ORDER BY date_jour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cum_15c
    FROM (
      -- Agrégation journalière des mouvements
      SELECT
        date_jour,
        citerne_id,
        produit_id,
        depot_id,
        proprietaire_type,
        SUM(delta_ambiant) AS delta_ambiant,
        SUM(delta_15c)     AS delta_15c
      FROM public.v_mouvements_stock
      WHERE (p_depot_id   IS NULL OR depot_id   = p_depot_id)
        AND (p_start_date IS NULL OR date_jour >= p_start_date)
        AND (p_end_date   IS NULL OR date_jour <= p_end_date)
      GROUP BY
        date_jour,
        citerne_id,
        produit_id,
        depot_id,
        proprietaire_type
    ) d
  ) m
  ORDER BY m.date_jour, m.citerne_id;

END;
$$;

-- ============================================================================
-- COMMENTAIRES
-- ============================================================================

COMMENT ON FUNCTION public.rebuild_stocks_journaliers(uuid, date, date) IS 
'Fonction pour recalculer les stocks journaliers à partir de v_mouvements_stock. Supprime uniquement les lignes source = ''SYSTEM'' dans le périmètre spécifié, puis recalcule les cumuls en utilisant des window functions. Laisse intact les ajustements manuels (source ≠ ''SYSTEM'').';

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. La fonction utilise v_mouvements_stock qui agrège réceptions (positif) et sorties (négatif)
-- 2. Les window functions calculent les cumuls par clé (citerne, produit, depot, propriétaire)
-- 3. Les filtres optionnels permettent de rebuild partiel (dépot, période)
-- 4. Les ajustements manuels (source ≠ 'SYSTEM') sont préservés
-- 5. Voir docs/db/stocks_rules.md pour les règles métier détaillées


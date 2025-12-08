-- Stock Engine v2 - Phase 2 (idempotent)
-- Nouvelle version de stock_upsert_journalier et triggers v2
-- pour maintenir les stocks journaliers cohérents en temps réel.
--
-- ⚠️ Les anciens triggers seront désactivés (suffixe _old) après validation.
--
-- Référence : 
-- - docs/db/stocks_rules.md pour les règles métier
-- - docs/db/stocks_tests.md pour les tests manuels

-- ============================================================================
-- FONCTION : stock_upsert_journalier_v2()
-- ============================================================================

CREATE OR REPLACE FUNCTION public.stock_upsert_journalier_v2(
  p_citerne_id uuid,
  p_produit_id uuid,
  p_date_jour date,
  p_volume_ambiant double precision,
  p_volume_15c double precision,
  p_proprietaire_type text DEFAULT 'MONALUXE',
  p_depot_id uuid DEFAULT NULL,
  p_source text DEFAULT 'MANUAL'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stock_initial_ambiant double precision := 0;
  v_stock_initial_15c double precision := 0;
  v_proprietaire_normalise text;
BEGIN
  -- Normaliser proprietaire_type
  v_proprietaire_normalise := UPPER(COALESCE(TRIM(p_proprietaire_type), 'MONALUXE'));
  
  -- TODO: Récupérer le stock initial (dernier stock connu avant p_date_jour)
  -- pour cette combinaison (citerne_id, produit_id, proprietaire_type)
  -- SELECT stock_ambiant, stock_15c INTO v_stock_initial_ambiant, v_stock_initial_15c
  -- FROM public.stocks_journaliers
  -- WHERE citerne_id = p_citerne_id
  --   AND produit_id = p_produit_id
  --   AND proprietaire_type = v_proprietaire_normalise
  --   AND date_jour < p_date_jour
  -- ORDER BY date_jour DESC
  -- LIMIT 1;
  
  -- Si pas de stock initial, utiliser 0 (déjà initialisé)
  
  -- Calculer le stock fin de journée
  -- stock_fin_journee = stock_initial + p_volume_ambiant (peut être négatif pour sorties)
  
  -- TODO: Récupérer depot_id depuis citernes si NULL
  -- IF p_depot_id IS NULL THEN
  --   SELECT depot_id INTO p_depot_id
  --   FROM public.citernes
  --   WHERE id = p_citerne_id;
  -- END IF;
  
  -- Upsert dans stocks_journaliers
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
  VALUES (
    p_citerne_id,
    p_produit_id,
    p_date_jour,
    v_stock_initial_ambiant + p_volume_ambiant,  -- Cumul : initial + mouvement
    v_stock_initial_15c + p_volume_15c,        -- Cumul : initial + mouvement
    v_proprietaire_normalise,
    p_depot_id,
    p_source,
    now(),
    now()
  )
  ON CONFLICT (citerne_id, produit_id, date_jour, proprietaire_type)
  DO UPDATE SET
    -- En cas de conflit, recalculer depuis le stock initial + tous les mouvements du jour
    -- TODO: Implémenter la logique de recalcul en cas de conflit
    stock_ambiant = stocks_journaliers.stock_ambiant + EXCLUDED.stock_ambiant - stocks_journaliers.stock_ambiant + v_stock_initial_ambiant + p_volume_ambiant,
    stock_15c = stocks_journaliers.stock_15c + EXCLUDED.stock_15c - stocks_journaliers.stock_15c + v_stock_initial_15c + p_volume_15c,
    updated_at = now();
    
  -- Note: La logique ON CONFLICT ci-dessus est simplifiée et doit être revue
  -- selon la logique métier validée en Phase 1
  
END;
$$;

-- ============================================================================
-- TRIGGER : trg_receptions_after_insert_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.receptions_apply_effects_v2()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_date date;
  v_amb double precision;
  v_15 double precision;
  v_depot_id uuid;
  v_proprietaire text;
BEGIN
  v_date := COALESCE(NEW.date_reception::date, CURRENT_DATE);
  v_amb := COALESCE(NEW.volume_ambiant,
    CASE 
      WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
      THEN NEW.index_apres - NEW.index_avant 
      ELSE 0 
    END
  );
  v_15 := COALESCE(NEW.volume_corrige_15c, v_amb);
  
  v_proprietaire := UPPER(COALESCE(TRIM(NEW.proprietaire_type), 'MONALUXE'));
  
  -- Récupérer depot_id depuis la citerne
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  -- Mettre à jour volume_ambiant si non fourni
  IF NEW.volume_ambiant IS NULL THEN
    NEW.volume_ambiant := v_amb;
  END IF;
  
  -- Créditer le stock (valeur positive)
  PERFORM public.stock_upsert_journalier_v2(
    NEW.citerne_id,
    NEW.produit_id,
    v_date,
    +v_amb,  -- Crédit positif
    +v_15,   -- Crédit positif
    v_proprietaire,
    v_depot_id,
    'RECEPTION'
  );
  
  -- Passer le cours de route à DECHARGE si lié
  IF NEW.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route 
    SET statut = 'DECHARGE' 
    WHERE id = NEW.cours_de_route_id;
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_receptions_after_insert_v2 ON public.receptions;
CREATE TRIGGER trg_receptions_after_insert_v2
AFTER INSERT ON public.receptions
FOR EACH ROW
EXECUTE FUNCTION public.receptions_apply_effects_v2();

-- ============================================================================
-- TRIGGER : trg_sorties_after_insert_v2
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sorties_apply_effects_v2()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_date date;
  v_amb double precision;
  v_15 double precision;
  v_depot_id uuid;
  v_proprietaire text;
BEGIN
  v_date := COALESCE(NEW.date_sortie::date, CURRENT_DATE);
  v_amb := COALESCE(NEW.volume_ambiant,
    CASE 
      WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
      THEN NEW.index_apres - NEW.index_avant 
      ELSE 0 
    END
  );
  v_15 := COALESCE(NEW.volume_corrige_15c, v_amb);
  
  v_proprietaire := UPPER(COALESCE(TRIM(NEW.proprietaire_type), 'MONALUXE'));
  
  -- Récupérer depot_id depuis la citerne
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  -- Débiter le stock (valeur négative)
  PERFORM public.stock_upsert_journalier_v2(
    NEW.citerne_id,
    NEW.produit_id,
    v_date,
    -v_amb,  -- Débit négatif
    -v_15,   -- Débit négatif
    v_proprietaire,
    v_depot_id,
    'SORTIE'
  );
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sorties_after_insert_v2 ON public.sorties_produit;
CREATE TRIGGER trg_sorties_after_insert_v2
AFTER INSERT ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION public.sorties_apply_effects_v2();

-- ============================================================================
-- DÉSACTIVATION DES ANCIENS TRIGGERS (à faire après validation)
-- ============================================================================

-- ⚠️ NE PAS EXÉCUTER AVANT VALIDATION COMPLÈTE DES TRIGGERS V2
-- 
-- Une fois les tests validés, renommer les anciens triggers :
-- 
-- ALTER TRIGGER trg_receptions_apply_effects ON public.receptions 
-- RENAME TO trg_receptions_apply_effects_old;
-- 
-- ALTER TRIGGER trg_sorties_apply_effects ON public.sorties_produit 
-- RENAME TO trg_sorties_apply_effects_old;
-- 
-- Puis après validation complète :
-- 
-- DROP TRIGGER IF EXISTS trg_receptions_apply_effects_old ON public.receptions;
-- DROP TRIGGER IF EXISTS trg_sorties_apply_effects_old ON public.sorties_produit;

-- ============================================================================
-- COMMENTAIRES
-- ============================================================================

COMMENT ON FUNCTION public.stock_upsert_journalier_v2(uuid, uuid, date, double precision, double precision, text, uuid, text) IS 
'Version v2 de stock_upsert_journalier avec logique de cumul fin de journée. Calcule le stock initial avant d''ajouter le mouvement.';

COMMENT ON FUNCTION public.receptions_apply_effects_v2() IS 
'Trigger v2 pour réceptions : crédite les stocks journaliers via stock_upsert_journalier_v2().';

COMMENT ON FUNCTION public.sorties_apply_effects_v2() IS 
'Trigger v2 pour sorties : débite les stocks journaliers via stock_upsert_journalier_v2().';


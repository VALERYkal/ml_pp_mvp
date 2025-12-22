-- ============================================================================
-- Sorties DB-STRICT: Refactor fn_sorties_after_insert() 
-- Date: 2025-12-19
-- Objectif: Séparer responsabilités - AFTER INSERT fait uniquement effets
--           irréversibles (débit stock + log). Toutes validations en BEFORE.
-- ============================================================================
--
-- CHANGEMENTS:
-- - Suppression validations dupliquées (déjà faites en BEFORE INSERT)
-- - Simplification: calcul volumes depuis NEW uniquement (pas depuis indexes)
-- - Log utilise NEW.created_by (pas auth.uid())
-- - Log stocke valeurs calculées (v_volume_ambiant, v_volume_15c, v_date_jour)
--
-- NOTE: Cette migration est idempotente (CREATE OR REPLACE).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_sorties_after_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_depot_id         uuid;
  v_proprietaire     text;
  v_volume_ambiant   double precision;
  v_volume_15c       double precision;
  v_date_jour        date;
BEGIN
  -- 1) Calculer date_jour (fallback sur created_at si date_sortie null)
  IF NEW.date_sortie IS NOT NULL THEN
    v_date_jour := (NEW.date_sortie AT TIME ZONE 'UTC')::date;
  ELSE
    v_date_jour := COALESCE(NEW.created_at::date, CURRENT_DATE);
  END IF;
  
  -- 2) Normaliser propriétaire
  v_proprietaire := UPPER(TRIM(COALESCE(NEW.proprietaire_type, 'MONALUXE')));
  
  -- 3) Charger depot_id depuis citerne (sans validations - déjà faites en BEFORE)
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  -- Si citerne introuvable (théoriquement impossible après BEFORE, mais sécurité)
  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CITERNE_NOT_FOUND: Citerne % introuvable pour débit stock', NEW.citerne_id;
  END IF;
  
  -- 4) Calculer volumes depuis NEW (valeurs déjà normalisées par BEFORE trigger)
  -- NOTE: Ne pas recalculer depuis indexes en AFTER - utiliser valeurs déjà calculées
  v_volume_ambiant := COALESCE(NEW.volume_ambiant, 0);
  v_volume_15c := COALESCE(NEW.volume_corrige_15c, v_volume_ambiant);
  
  -- 5) Débiter stock journalier
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id,
    NEW.produit_id,
    v_date_jour,
    -1 * v_volume_ambiant,  -- Débit (négatif)
    -1 * v_volume_15c,      -- Débit (négatif)
    v_proprietaire,
    v_depot_id,
    'SORTIE'
  );
  
  -- 6) Log action (utiliser NEW.created_by, pas auth.uid())
  INSERT INTO public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details
  )
  VALUES (
    NEW.created_by,  -- S'appuie sur BEFORE trigger pour définir created_by
    'SORTIE_CREEE',
    'sorties',
    'INFO',
    jsonb_build_object(
      'sortie_id', NEW.id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'volume_ambiant', v_volume_ambiant,  -- Valeur calculée
      'volume_15c', v_volume_15c,          -- Valeur calculée
      'date_sortie', v_date_jour,          -- Valeur calculée (date normalisée)
      'proprietaire_type', v_proprietaire, -- Valeur normalisée
      'client_id', NEW.client_id,
      'partenaire_id', NEW.partenaire_id,
      'statut', NEW.statut,
      'created_by', NEW.created_by
    )
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.fn_sorties_after_insert() IS 
'Trigger AFTER INSERT pour sorties: applique uniquement les effets irréversibles (débit stock + log). 
Toutes les validations sont faites en BEFORE INSERT par sorties_check_before_insert(). 
Utilise NEW.created_by pour le log (doit être défini par un BEFORE trigger ou l''application).';

-- ============================================================================
-- NOTE: Les triggers restent inchangés
-- - trg_sorties_check_before_insert (BEFORE INSERT) - validations/rejections
-- - trg_sorties_after_insert (AFTER INSERT) - effets irréversibles + log
-- ============================================================================


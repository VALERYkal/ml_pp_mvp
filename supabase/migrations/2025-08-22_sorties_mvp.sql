-- Sorties — MVP (idempotent)

-- A. Statut par défaut
DO $$ BEGIN
  ALTER TABLE public.sorties_produit ALTER COLUMN statut SET DEFAULT 'validee';
EXCEPTION WHEN others THEN NULL; END $$;

-- B. Cohérence produit↔citerne
CREATE OR REPLACE FUNCTION public.sorties_check_produit_citerne()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_count int;
BEGIN
  IF NEW.citerne_id IS NULL OR NEW.produit_id IS NULL THEN
    RAISE EXCEPTION 'CITERNE_OU_PRODUIT_NULL';
  END IF;
  SELECT 1 INTO v_count
  FROM public.citernes c
  WHERE c.id = NEW.citerne_id AND c.produit_id = NEW.produit_id
  LIMIT 1;
  IF v_count IS NULL THEN
    RAISE EXCEPTION 'PRODUIT_CITERNE_MISMATCH: citerne % ne porte pas le produit %', NEW.citerne_id, NEW.produit_id;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_sorties_check_produit_citerne ON public.sorties_produit;
CREATE TRIGGER trg_sorties_check_produit_citerne
BEFORE INSERT OR UPDATE ON public.sorties_produit
FOR EACH ROW EXECUTE FUNCTION public.sorties_check_produit_citerne();

-- C. Effets (débit stock)
CREATE OR REPLACE FUNCTION public.sorties_apply_effects()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_date date; v_amb double precision; v_15 double precision;
BEGIN
  v_date := COALESCE(NEW.date_sortie::date, CURRENT_DATE);
  v_amb  := COALESCE(NEW.volume_ambiant,
            CASE WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL
                 THEN NEW.index_apres - NEW.index_avant ELSE 0 END);
  v_15   := COALESCE(NEW.volume_corrige_15c, v_amb);
  PERFORM public.stock_upsert_journalier(NEW.citerne_id, NEW.produit_id, v_date, -1 * v_amb, -1 * v_15);
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_sorties_apply_effects ON public.sorties_produit;
CREATE TRIGGER trg_sorties_apply_effects
AFTER INSERT ON public.sorties_produit
FOR EACH ROW EXECUTE FUNCTION public.sorties_apply_effects();

-- D. BEFORE UPDATE (immutabilité hors brouillon sauf admin)
CREATE OR REPLACE FUNCTION public.sortie_before_upd_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT role_in(user_role(), VARIADIC ARRAY['admin']) THEN
    IF OLD.statut <> 'brouillon' THEN
      RAISE EXCEPTION 'IMMUTABLE_NON_BROUILLON';
    END IF;
  END IF;
  IF (NEW.index_avant IS DISTINCT FROM OLD.index_avant)
     OR (NEW.index_apres IS DISTINCT FROM OLD.index_apres) THEN
    IF NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL THEN
      IF NEW.index_apres <= NEW.index_avant THEN
        RAISE EXCEPTION 'INDEX_INCOHERENTS (% >= %)', NEW.index_apres, NEW.index_avant;
      END IF;
      NEW.volume_ambiant := NEW.index_apres - NEW.index_avant;
    END IF;
  END IF;
  RETURN NEW;
END; $$;

-- E. Logs
CREATE OR REPLACE FUNCTION public.sorties_log_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.log_actions(user_id, action, module, niveau, details)
  VALUES (
    auth.uid(), 'CREATE', 'sorties', 'INFO',
    jsonb_build_object(
      'sortie_id', NEW.id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'volume_ambiant', NEW.volume_ambiant,
      'volume_15c', NEW.volume_corrige_15c,
      'date_sortie', NEW.date_sortie,
      'proprietaire', NEW.proprietaire_type,
      'statut', NEW.statut,
      'created_by', NEW.created_by
    )
  );
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_sorties_log_created ON public.sorties_produit;
CREATE TRIGGER trg_sorties_log_created
AFTER INSERT ON public.sorties_produit
FOR EACH ROW EXECUTE FUNCTION public.sorties_log_created();

-- F. Index
CREATE INDEX IF NOT EXISTS idx_sorties_statut      ON public.sorties_produit (statut);
CREATE INDEX IF NOT EXISTS idx_sorties_created_at  ON public.sorties_produit (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sorties_date_sortie ON public.sorties_produit (date_sortie);
CREATE INDEX IF NOT EXISTS idx_sorties_citerne     ON public.sorties_produit (citerne_id);
CREATE INDEX IF NOT EXISTS idx_sorties_produit     ON public.sorties_produit (produit_id);

-- G. RLS
ALTER TABLE public.sorties_produit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS read_sorties_authenticated   ON public.sorties_produit;
DROP POLICY IF EXISTS insert_sorties_authenticated ON public.sorties_produit;
DROP POLICY IF EXISTS update_sorties_admin         ON public.sorties_produit;
DROP POLICY IF EXISTS delete_sorties_admin         ON public.sorties_produit;

CREATE POLICY read_sorties_authenticated
ON public.sorties_produit FOR SELECT TO authenticated
USING (true);

CREATE POLICY insert_sorties_authenticated
ON public.sorties_produit FOR INSERT TO authenticated
WITH CHECK (role_in(user_role(), VARIADIC ARRAY['operateur','gerant','directeur','admin']));

CREATE POLICY update_sorties_admin
ON public.sorties_produit FOR UPDATE TO authenticated
USING (role_in(user_role(), VARIADIC ARRAY['admin']))
WITH CHECK (role_in(user_role(), VARIADIC ARRAY['admin']));

CREATE POLICY delete_sorties_admin
ON public.sorties_produit FOR DELETE TO authenticated
USING (role_in(user_role(), VARIADIC ARRAY['admin']));


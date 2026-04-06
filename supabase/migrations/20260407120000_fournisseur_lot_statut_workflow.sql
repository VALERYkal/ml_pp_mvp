-- ============================================================================
-- Lot fournisseur — workflow de statut (source de vérité DB)
-- ============================================================================
-- Table : public.fournisseur_lot, colonne statut (texte).
--
-- Transitions autorisées :
--   ouvert → cloture
--   cloture → facture
-- INSERT : statut doit être strictement 'ouvert'.
-- Ne modifie pas cours_de_route, stock ni volumétrie.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_fournisseur_lot_statut_transition(
  p_old_statut text,
  p_new_statut text
) RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF p_old_statut IS NOT DISTINCT FROM p_new_statut THEN
    RETURN;
  END IF;

  IF p_new_statut IS NULL OR p_new_statut NOT IN ('ouvert', 'cloture', 'facture') THEN
    RAISE EXCEPTION 'Statut lot invalide : %', p_new_statut;
  END IF;

  IF p_old_statut IS NULL OR p_old_statut NOT IN ('ouvert', 'cloture', 'facture') THEN
    RAISE EXCEPTION 'Statut lot invalide : %', p_old_statut;
  END IF;

  IF p_old_statut = 'ouvert' AND p_new_statut = 'cloture' THEN
    RETURN;
  END IF;

  IF p_old_statut = 'cloture' AND p_new_statut = 'facture' THEN
    RETURN;
  END IF;

  RAISE EXCEPTION
    'Transition de statut lot invalide : % → %',
    p_old_statut,
    p_new_statut;
END;
$$;

COMMENT ON FUNCTION public.check_fournisseur_lot_statut_transition(text, text) IS
'Valide les changements de statut fournisseur_lot : ouvert→cloture, cloture→facture uniquement.';


CREATE OR REPLACE FUNCTION public.trg_fournisseur_lot_statut_transition()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.statut IS NULL OR NEW.statut IS DISTINCT FROM 'ouvert' THEN
      RAISE EXCEPTION 'Statut lot invalide : %', NEW.statut;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF OLD.statut IS DISTINCT FROM NEW.statut THEN
      PERFORM public.check_fournisseur_lot_statut_transition(OLD.statut, NEW.statut);
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fournisseur_lot_statut_transition ON public.fournisseur_lot;

CREATE TRIGGER trg_fournisseur_lot_statut_transition
  BEFORE INSERT OR UPDATE
  ON public.fournisseur_lot
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fournisseur_lot_statut_transition();

COMMENT ON TRIGGER trg_fournisseur_lot_statut_transition ON public.fournisseur_lot IS
'INSERT : statut = ouvert uniquement. UPDATE : transitions ouvert→cloture→facture, pas de retour arrière.';


-- Contrainte CHECK : alignée sur l''enum métier Flutter / JSON (ouvert | cloture | facture).
-- Échoue si des lignes hors périmètre existent : corriger les données avant d''appliquer la migration.
ALTER TABLE public.fournisseur_lot
  DROP CONSTRAINT IF EXISTS fournisseur_lot_statut_check;

ALTER TABLE public.fournisseur_lot
  ADD CONSTRAINT fournisseur_lot_statut_check
  CHECK (statut IN ('ouvert', 'cloture', 'facture'));

COMMENT ON CONSTRAINT fournisseur_lot_statut_check ON public.fournisseur_lot IS
'Statut lot autorisé : ouvert, cloture, facture (workflow géré par trigger).';

-- ---------------------------------------------------------------------------
-- Tests manuels (psql / staging) — adapter les UUID
-- ---------------------------------------------------------------------------
-- -- 1) INSERT avec statut ≠ ouvert → FAIL
-- INSERT INTO public.fournisseur_lot (fournisseur_id, produit_id, reference, statut)
-- VALUES (:fid, :pid, 'TEST-WF-1', 'cloture');
--
-- -- 2) ouvert → cloture → OK
-- INSERT INTO public.fournisseur_lot (fournisseur_id, produit_id, reference, statut)
-- VALUES (:fid, :pid, 'TEST-WF-2', 'ouvert')
-- RETURNING id \gset
-- UPDATE public.fournisseur_lot SET statut = 'cloture' WHERE id = :'id';
--
-- -- 3) cloture → ouvert → FAIL (ligne encore en cloture)
-- UPDATE public.fournisseur_lot SET statut = 'ouvert' WHERE id = :'id';
--
-- -- 4) cloture → facture → OK
-- UPDATE public.fournisseur_lot SET statut = 'facture' WHERE id = :'id';
--
-- -- 5) facture → cloture → FAIL
-- UPDATE public.fournisseur_lot SET statut = 'cloture' WHERE id = :'id';
--
-- -- 6) statut inconnu → FAIL (CHECK + trigger)
-- UPDATE public.fournisseur_lot SET statut = 'archive' WHERE id = :'id';

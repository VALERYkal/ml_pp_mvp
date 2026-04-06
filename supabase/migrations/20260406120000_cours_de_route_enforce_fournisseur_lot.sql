-- ============================================================================
-- Cours de route × lot fournisseur — cohérence serveur du lien
-- ============================================================================
-- Dépendances : tables public.cours_de_route (colonne fournisseur_lot_id),
--               public.fournisseur_lot (statuts text : ouvert | cloture | facture).
-- Ne modifie pas uniq_open_cdr_per_truck ni la volumétrie / stock.
--
-- Règles :
--   1) Rattachement : lot doit exister et statut = ouvert ; fournisseur_id
--      et produit_id du CDR = ceux du lot.
--   2) Détachement (fournisseur_lot_id → NULL) : le lot d’origine doit être ouvert.
--   3) Tant que statut CDR = DECHARGE : interdiction de changer fournisseur_lot_id.
--   4) Changement de lot (remplacement) : le lot source doit être ouvert ; le lot
--      cible : mêmes règles que le rattachement.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_cdr_fournisseur_lot_liaison(
  p_op text,
  p_old_lot_id uuid,
  p_new_lot_id uuid,
  p_new_fournisseur_id uuid,
  p_new_produit_id uuid
) RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_old_lot public.fournisseur_lot%ROWTYPE;
  v_new_lot public.fournisseur_lot%ROWTYPE;
BEGIN
  --------------------------------------------------------------------------
  -- Détachement : passage à sans lot
  --------------------------------------------------------------------------
  IF p_new_lot_id IS NULL THEN
    IF p_op = 'INSERT' OR p_old_lot_id IS NULL THEN
      RETURN;
    END IF;

    SELECT * INTO v_old_lot
    FROM public.fournisseur_lot fl
    WHERE fl.id = p_old_lot_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION
        'Lot fournisseur introuvable : impossible de détacher (lot_id=%).',
        p_old_lot_id;
    END IF;

    IF v_old_lot.statut IS DISTINCT FROM 'ouvert' THEN
      RAISE EXCEPTION
        'Impossible de détacher un CDR d''un lot qui n''est pas ouvert (statut du lot : %).',
        v_old_lot.statut;
    END IF;

    RETURN;
  END IF;

  --------------------------------------------------------------------------
  -- Quitter un lot pour en prendre un autre : le lot source doit être ouvert
  --------------------------------------------------------------------------
  IF p_op = 'UPDATE'
     AND p_old_lot_id IS NOT NULL
     AND p_old_lot_id IS DISTINCT FROM p_new_lot_id THEN
    SELECT * INTO v_old_lot
    FROM public.fournisseur_lot fl
    WHERE fl.id = p_old_lot_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION
        'Lot fournisseur (source) introuvable : %',
        p_old_lot_id;
    END IF;

    IF v_old_lot.statut IS DISTINCT FROM 'ouvert' THEN
      RAISE EXCEPTION
        'Impossible de retirer un CDR d''un lot qui n''est pas ouvert (statut du lot : %).',
        v_old_lot.statut;
    END IF;
  END IF;

  --------------------------------------------------------------------------
  -- Rattachement (ou validation après changement de lot / insert avec lot)
  --------------------------------------------------------------------------
  SELECT * INTO v_new_lot
  FROM public.fournisseur_lot fl
  WHERE fl.id = p_new_lot_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'Impossible de rattacher un CDR : lot fournisseur introuvable (id=%).',
      p_new_lot_id;
  END IF;

  IF v_new_lot.statut IS DISTINCT FROM 'ouvert' THEN
    RAISE EXCEPTION
      'Impossible de rattacher un CDR à un lot qui n''est pas ouvert (statut du lot : %).',
      v_new_lot.statut;
  END IF;

  IF p_new_fournisseur_id IS DISTINCT FROM v_new_lot.fournisseur_id THEN
    RAISE EXCEPTION
      'Impossible de rattacher : le fournisseur du CDR ne correspond pas à celui du lot.';
  END IF;

  IF p_new_produit_id IS DISTINCT FROM v_new_lot.produit_id THEN
    RAISE EXCEPTION
      'Impossible de rattacher : le produit du CDR ne correspond pas à celui du lot.';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.check_cdr_fournisseur_lot_liaison(
  text, uuid, uuid, uuid, uuid
) IS
'Valide rattachement / détachement / changement de lot sur cours_de_route : lot ouvert, '
'cohérence fournisseur_id & produit_id, détachement interdit si lot non ouvert.';


CREATE OR REPLACE FUNCTION public.trg_cours_de_route_enforce_fournisseur_lot()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  v_old_lot_id uuid;
  v_new_lot_id uuid;
BEGIN
  v_new_lot_id := NEW.fournisseur_lot_id;
  v_old_lot_id := CASE WHEN TG_OP = 'UPDATE' THEN OLD.fournisseur_lot_id ELSE NULL END;

  --------------------------------------------------------------------------
  -- Aucun impact sur les lignes sans changement pertinent
  --------------------------------------------------------------------------
  IF TG_OP = 'UPDATE'
     AND OLD.fournisseur_lot_id IS NOT DISTINCT FROM NEW.fournisseur_lot_id
     AND OLD.fournisseur_id IS NOT DISTINCT FROM NEW.fournisseur_id
     AND OLD.produit_id IS NOT DISTINCT FROM NEW.produit_id THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' AND NEW.fournisseur_lot_id IS NULL THEN
    RETURN NEW;
  END IF;

  --------------------------------------------------------------------------
  -- CDR déchargé : liaison au lot figée
  --------------------------------------------------------------------------
  IF TG_OP = 'UPDATE'
     AND (OLD.statut = 'DECHARGE' OR NEW.statut = 'DECHARGE')
     AND OLD.fournisseur_lot_id IS DISTINCT FROM NEW.fournisseur_lot_id THEN
    RAISE EXCEPTION
      'Impossible de modifier le rattachement au lot pour un CDR au statut DECHARGE.';
  END IF;

  PERFORM public.check_cdr_fournisseur_lot_liaison(
    TG_OP,
    v_old_lot_id,
    v_new_lot_id,
    NEW.fournisseur_id,
    NEW.produit_id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_cours_de_route_enforce_fournisseur_lot
  ON public.cours_de_route;

CREATE TRIGGER trg_cours_de_route_enforce_fournisseur_lot
  BEFORE INSERT OR UPDATE
  ON public.cours_de_route
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_cours_de_route_enforce_fournisseur_lot();

COMMENT ON TRIGGER trg_cours_de_route_enforce_fournisseur_lot ON public.cours_de_route IS
'Garde-fous liaison fournisseur_lot_id : lot ouvert, cohérence F×P, pas de détachement / '
'changement de lien si lot non ouvert ou si CDR en DECHARGE.';

-- ---------------------------------------------------------------------------
-- Tests manuels (staging / psql), à adapter avec des UUID réels :
-- ---------------------------------------------------------------------------
-- -- 1) Rattachement lot ouvert + mêmes F/P → OK
-- UPDATE cours_de_route SET fournisseur_lot_id = :lot_ouvert
-- WHERE id = :cdr AND fournisseur_id = (SELECT fournisseur_id FROM fournisseur_lot WHERE id = :lot_ouvert)
--   AND produit_id = (SELECT produit_id FROM fournisseur_lot WHERE id = :lot_ouvert);
--
-- -- 2) Rattachement lot clôturé → KO (exception « pas ouvert »)
-- UPDATE cours_de_route SET fournisseur_lot_id = :lot_cloture WHERE id = :cdr;
--
-- -- 3) Détachement CDR DECHARGE → KO
-- UPDATE cours_de_route SET fournisseur_lot_id = NULL WHERE id = :cdr_decharge;
--
-- -- 4) Fournisseur incompatible → KO
-- UPDATE cours_de_route SET fournisseur_lot_id = :lot_ouvert, fournisseur_id = :autre_f WHERE id = :cdr;
--
-- -- 5) Produit incompatible → KO
-- UPDATE cours_de_route SET fournisseur_lot_id = :lot_ouvert, produit_id = :autre_p WHERE id = :cdr;

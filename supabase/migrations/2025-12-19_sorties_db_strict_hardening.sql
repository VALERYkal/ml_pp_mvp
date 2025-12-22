-- ============================================================================
-- Sorties DB-STRICT Hardening (idempotent)
-- Date: 2025-12-19
-- Objectif: Verrouillage non contournable, validations BEFORE, stock suffisant
--           garanti, XOR strict, immutabilité absolue
-- ============================================================================
--
-- PATCHES APPLIQUÉS:
-- 1. Patch 1: Vérification stock suffisant + validations métier (BEFORE INSERT)
-- 2. Patch 2: Contrainte CHECK XOR stricte (client_id XOR partenaire_id)
-- 3. Patch 3: Immutabilité absolue UPDATE/DELETE
-- 4. Patch 4: Nettoyage fonctions obsolètes (optionnel)
--
-- NOTE: Cette migration ne modifie pas fn_sorties_after_insert() existante.
--       Elle ajoute des validations BEFORE INSERT pour garantir l'intégrité.
-- ============================================================================

-- ============================================================================
-- PATCH 1: Vérification stock suffisant + validations métier (BEFORE INSERT)
-- ============================================================================

-- Fonction de validation BEFORE INSERT
CREATE OR REPLACE FUNCTION public.sorties_check_before_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_citerne          public.citernes%ROWTYPE;
  v_stock_jour       public.stocks_journaliers%ROWTYPE;
  v_date_jour        date;
  v_proprietaire     text;
  v_volume_ambiant   double precision;
  v_volume_15c       double precision;
BEGIN
  -- 1) Normalisation date
  v_date_jour := COALESCE(NEW.date_sortie::date, CURRENT_DATE);
  
  -- 2) Normalisation propriétaire
  v_proprietaire := UPPER(TRIM(COALESCE(NEW.proprietaire_type, 'MONALUXE')));
  
  -- 3) Charger citerne (vérification existence)
  SELECT * INTO v_citerne
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CITERNE_NOT_FOUND: Citerne % introuvable', NEW.citerne_id;
  END IF;
  
  -- 4) Vérifier citerne active (DB-STRICT: doit être en BEFORE INSERT)
  IF v_citerne.statut <> 'active' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CITERNE_INACTIVE: Citerne % inactive ou en maintenance (statut: %)', 
      v_citerne.id, v_citerne.statut;
  END IF;
  
  -- 5) Vérifier produit/citerne cohérence
  IF v_citerne.produit_id <> NEW.produit_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'PRODUIT_INCOMPATIBLE: Citerne % ne porte pas le produit % (produit citerne: %)', 
      NEW.citerne_id, NEW.produit_id, v_citerne.produit_id;
  END IF;
  
  -- 6) Calculer volume ambiant (convention: index_apres - index_avant)
  v_volume_ambiant := COALESCE(
    NEW.volume_ambiant,
    CASE 
      WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
      THEN NEW.index_apres - NEW.index_avant 
      ELSE 0 
    END
  );
  
  -- 7) Calculer volume 15°C (fallback sur volume_ambiant)
  v_volume_15c := COALESCE(NEW.volume_corrige_15c, v_volume_ambiant);
  
  -- 8) Vérifier XOR bénéficiaire (DB-STRICT: en BEFORE INSERT)
  IF v_proprietaire = 'MONALUXE' THEN
    IF NEW.client_id IS NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'BENEFICIAIRE_XOR: client_id obligatoire pour sortie MONALUXE';
    END IF;
    IF NEW.partenaire_id IS NOT NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'BENEFICIAIRE_XOR: partenaire_id doit être NULL pour sortie MONALUXE';
    END IF;
  ELSIF v_proprietaire = 'PARTENAIRE' THEN
    IF NEW.partenaire_id IS NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'BENEFICIAIRE_XOR: partenaire_id obligatoire pour sortie PARTENAIRE';
    END IF;
    IF NEW.client_id IS NOT NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'BENEFICIAIRE_XOR: client_id doit être NULL pour sortie PARTENAIRE';
    END IF;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'BENEFICIAIRE_XOR: proprietaire_type invalide (%)', NEW.proprietaire_type;
  END IF;
  
  -- 9) Récupérer dernier stock connu (pour date <= v_date_jour)
  SELECT *
  INTO v_stock_jour
  FROM public.stocks_journaliers
  WHERE citerne_id = NEW.citerne_id
    AND produit_id = NEW.produit_id
    AND proprietaire_type = v_proprietaire
    AND date_jour <= v_date_jour
  ORDER BY date_jour DESC
  LIMIT 1;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'STOCK_INSUFFISANT: Aucun stock journalier trouvé pour citerne=% produit=% proprietaire=% date=%', 
      NEW.citerne_id, NEW.produit_id, v_proprietaire, v_date_jour;
  END IF;
  
  -- 10) Vérifier stock suffisant (DB-STRICT: doit bloquer si insuffisant)
  IF v_stock_jour.stock_ambiant < v_volume_ambiant THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'STOCK_INSUFFISANT: stock_disponible=% volume_demande=% (citerne=% produit=% proprietaire=%)', 
      v_stock_jour.stock_ambiant, v_volume_ambiant, NEW.citerne_id, NEW.produit_id, v_proprietaire;
  END IF;
  
  -- 11) Vérifier stock 15°C suffisant (optionnel mais recommandé)
  IF v_stock_jour.stock_15c < v_volume_15c THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'STOCK_INSUFFISANT_15C: stock_15c_disponible=% volume_15c_demande=% (citerne=% produit=% proprietaire=%)', 
      v_stock_jour.stock_15c, v_volume_15c, NEW.citerne_id, NEW.produit_id, v_proprietaire;
  END IF;
  
  -- 12) Vérifier capacité sécurité (ne pas descendre sous capacité_securite)
  IF (v_stock_jour.stock_ambiant - v_volume_ambiant) < v_citerne.capacite_securite THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'CAPACITE_SECURITE: Sortie dépasserait capacité sécurité (stock_apres=% cap_securite=% citerne=%)', 
      v_stock_jour.stock_ambiant - v_volume_ambiant, v_citerne.capacite_securite, NEW.citerne_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger BEFORE INSERT
DROP TRIGGER IF EXISTS trg_sorties_check_before_insert ON public.sorties_produit;
CREATE TRIGGER trg_sorties_check_before_insert
BEFORE INSERT ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION public.sorties_check_before_insert();

COMMENT ON FUNCTION public.sorties_check_before_insert() IS 
'Validation DB-STRICT BEFORE INSERT pour sorties: vérifie citerne active, produit/citerne, XOR bénéficiaire, stock suffisant, capacité sécurité. Bloque toute insertion invalide avant écriture.';

-- ============================================================================
-- PATCH 2: Contrainte CHECK XOR stricte (client_id XOR partenaire_id)
-- ============================================================================

-- Supprimer ancienne contrainte si elle existe (moins stricte)
ALTER TABLE public.sorties_produit 
DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_check;

-- Ajouter contrainte XOR stricte
ALTER TABLE public.sorties_produit 
DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_xor;

ALTER TABLE public.sorties_produit 
ADD CONSTRAINT sorties_produit_beneficiaire_xor
CHECK (
  (client_id IS NOT NULL AND partenaire_id IS NULL) OR
  (client_id IS NULL AND partenaire_id IS NOT NULL)
);

COMMENT ON CONSTRAINT sorties_produit_beneficiaire_xor ON public.sorties_produit IS 
'Contrainte XOR stricte: exactement un des deux (client_id OU partenaire_id) doit être présent, jamais les deux ni aucun.';

-- ============================================================================
-- PATCH 3: Immutabilité absolue UPDATE/DELETE
-- ============================================================================

-- Fonction blocage UPDATE absolu
CREATE OR REPLACE FUNCTION public.prevent_sortie_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = 'P0001',
    MESSAGE = 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être modifiées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN NEW;
END;
$$;

-- Fonction blocage DELETE absolu
CREATE OR REPLACE FUNCTION public.prevent_sortie_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = 'P0001',
    MESSAGE = 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être supprimées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN OLD;
END;
$$;

-- Remplacer trigger UPDATE (supprimer ancien trigger si existe)
DROP TRIGGER IF EXISTS trg_prevent_sortie_update ON public.sorties_produit;
DROP TRIGGER IF EXISTS trg_sortie_before_upd_trg ON public.sorties_produit;

CREATE TRIGGER trg_prevent_sortie_update
BEFORE UPDATE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_update();

-- Trigger DELETE
DROP TRIGGER IF EXISTS trg_prevent_sortie_delete ON public.sorties_produit;
CREATE TRIGGER trg_prevent_sortie_delete
BEFORE DELETE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_delete();

COMMENT ON FUNCTION public.prevent_sortie_update() IS 
'Blocage absolu UPDATE pour sorties (DB-STRICT): toutes les modifications sont interdites. Corrections via stock_adjustments uniquement.';

COMMENT ON FUNCTION public.prevent_sortie_delete() IS 
'Blocage absolu DELETE pour sorties (DB-STRICT): toutes les suppressions sont interdites. Corrections via stock_adjustments uniquement.';

-- ============================================================================
-- PATCH 4: Nettoyage fonctions obsolètes (optionnel - commenté par sécurité)
-- ============================================================================
--
-- NOTE: Ces fonctions peuvent encore être référencées par d'autres objets.
--       Vérifier avant de supprimer avec:
--       SELECT * FROM pg_proc WHERE proname LIKE 'sorties%';
--       SELECT * FROM pg_depend WHERE objid = 'public.sorties_check_produit_citerne()'::regproc;
--
-- Fonctions candidates à suppression (après validation):
-- - sorties_check_produit_citerne() : remplacée par sorties_check_before_insert()
-- - sorties_apply_effects() : logique intégrée dans fn_sorties_after_insert()
-- - sorties_log_created() : logique intégrée dans fn_sorties_after_insert()
-- - sortie_before_upd_trg() : remplacée par prevent_sortie_update()
--
-- DROP FUNCTION IF EXISTS public.sorties_check_produit_citerne();
-- DROP FUNCTION IF EXISTS public.sorties_apply_effects();
-- DROP FUNCTION IF EXISTS public.sorties_log_created();
-- DROP FUNCTION IF EXISTS public.sortie_before_upd_trg();
-- ============================================================================

-- ============================================================================
-- RÉSUMÉ DES CHANGEMENTS
-- ============================================================================
--
-- ✅ Patch 1: Validation BEFORE INSERT (stock suffisant + métier)
--    - Fonction: sorties_check_before_insert()
--    - Trigger: trg_sorties_check_before_insert (BEFORE INSERT)
--    - Codes erreur: CITERNE_NOT_FOUND, CITERNE_INACTIVE, PRODUIT_INCOMPATIBLE,
--                    BENEFICIAIRE_XOR, STOCK_INSUFFISANT, STOCK_INSUFFISANT_15C,
--                    CAPACITE_SECURITE
--
-- ✅ Patch 2: Contrainte CHECK XOR stricte
--    - Contrainte: sorties_produit_beneficiaire_xor
--    - Garantit: (client_id IS NOT NULL XOR partenaire_id IS NOT NULL)
--
-- ✅ Patch 3: Immutabilité absolue
--    - Fonction: prevent_sortie_update() (BEFORE UPDATE)
--    - Fonction: prevent_sortie_delete() (BEFORE DELETE)
--    - Code erreur: IMMUTABLE_TRANSACTION
--
-- ✅ Patch 4: Nettoyage (optionnel, commenté)
--
-- ============================================================================


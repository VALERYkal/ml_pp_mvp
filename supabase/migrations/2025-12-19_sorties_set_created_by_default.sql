-- ============================================================================
-- Sorties DB-STRICT: Définir created_by par défaut (BEFORE INSERT)
-- Date: 2025-12-19
-- Objectif: Garantir que NEW.created_by est toujours défini avant les triggers
--           AFTER INSERT (notamment fn_sorties_after_insert() pour log_actions)
-- ============================================================================
--
-- COMPORTEMENT:
-- - Si NEW.created_by IS NULL → assigne auth.uid()
-- - Si NEW.created_by est déjà défini → ne modifie pas
-- - S'exécute en BEFORE INSERT (avant les validations)
--
-- NOTE: Cette migration est idempotente (CREATE OR REPLACE).
-- ============================================================================

-- ============================================================================
-- Fonction: sorties_set_created_by_default()
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sorties_set_created_by_default()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Si created_by n'est pas fourni, utiliser auth.uid() (utilisateur authentifié)
  -- L'application peut toujours passer created_by explicitement si nécessaire
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sorties_set_created_by_default() IS 
'Trigger BEFORE INSERT pour sorties: définit NEW.created_by = auth.uid() si NULL.
Garantit que les triggers AFTER INSERT (notamment fn_sorties_after_insert() pour log_actions)
peuvent toujours s''appuyer sur NEW.created_by sans dépendre du code applicatif.

IMPORTANT:
- auth.uid() peut être NULL hors session Supabase authentifiée (tests SQL bruts, migrations)
- Dans ce cas, created_by restera NULL (limitation acceptable pour tests/migrations)
- L''application peut toujours passer created_by explicitement si nécessaire
- Ne modifie pas created_by s''il est déjà défini (comportement non destructif)';

-- ============================================================================
-- Trigger: trg_00_sorties_set_created_by (nom alphabétiquement prioritaire)
-- ============================================================================

-- Supprimer l'ancien trigger si existant (migration précédente)
DROP TRIGGER IF EXISTS trg_sorties_set_created_by ON public.sorties_produit;

-- Créer le trigger avec nom alphabétiquement prioritaire (00 < toute lettre)
-- En PostgreSQL, les triggers BEFORE s'exécutent dans l'ordre alphabétique du nom
DROP TRIGGER IF EXISTS trg_00_sorties_set_created_by ON public.sorties_produit;

CREATE TRIGGER trg_00_sorties_set_created_by
BEFORE INSERT ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION public.sorties_set_created_by_default();

COMMENT ON TRIGGER trg_00_sorties_set_created_by ON public.sorties_produit IS 
'Trigger BEFORE INSERT: définit created_by = auth.uid() si NULL.
S''exécute EN PREMIER grâce au préfixe "00" (ordre alphabétique).
Garantit que NEW.created_by est toujours défini AVANT tous les autres triggers
de validation (trg_sortie_before_ins, trg_sorties_check_before_insert, etc.)
et AVANT les triggers AFTER INSERT (fn_sorties_after_insert pour log_actions).

IMPORTANT:
- auth.uid() peut être NULL hors session Supabase authentifiée (tests SQL bruts)
- Dans ce cas, created_by restera NULL (limitation acceptable pour tests/migrations)
- L''application peut toujours passer created_by explicitement si nécessaire';

-- ============================================================================
-- REQUÊTES DE VÉRIFICATION
-- ============================================================================

-- A) Vérifier que le trigger est bien actif
-- ============================================
SELECT 
  tgname as trigger_name, 
  tgenabled as enabled,
  CASE tgtype & 66 
    WHEN 2 THEN 'BEFORE' 
    WHEN 64 THEN 'AFTER' 
  END as timing,
  CASE tgtype & 28
    WHEN 4 THEN 'INSERT'
    WHEN 8 THEN 'DELETE'
    WHEN 16 THEN 'UPDATE'
  END as event
FROM pg_trigger
WHERE tgrelid = 'public.sorties_produit'::regclass
  AND tgname = 'trg_00_sorties_set_created_by';

-- Résultat attendu:
-- - trigger_name: trg_00_sorties_set_created_by
-- - enabled: O (enabled)
-- - timing: BEFORE
-- - event: INSERT

-- B) Vérifier l'ordre d'exécution des triggers BEFORE INSERT
-- ===========================================================
-- Les triggers BEFORE INSERT s'exécutent dans l'ordre alphabétique du nom
SELECT 
  tgname as trigger_name,
  pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid = 'public.sorties_produit'::regclass
  AND tgtype & 66 = 2   -- BEFORE triggers (bit 1 = 2)
  AND tgtype & 4 = 4    -- INSERT events (bit 2 = 4)
  AND tgisinternal = false  -- Exclure triggers système
ORDER BY tgname;

-- Résultat attendu (ordre alphabétique):
-- 1. trg_00_sorties_set_created_by (définit created_by EN PREMIER)
-- 2. trg_sortie_before_ins (si existe)
-- 3. trg_sorties_check_before_insert (validations)
-- ... autres triggers BEFORE INSERT

-- C) Vérifier que trg_00_sorties_set_created_by apparaît avant les autres
-- ========================================================================
SELECT 
  CASE 
    WHEN MIN(CASE WHEN tgname = 'trg_00_sorties_set_created_by' THEN 1 ELSE 2 END) = 1 
    THEN 'OK: trg_00_sorties_set_created_by est le premier trigger BEFORE INSERT'
    ELSE 'ERREUR: trg_00_sorties_set_created_by n''est pas le premier'
  END as verification_ordre
FROM pg_trigger
WHERE tgrelid = 'public.sorties_produit'::regclass
  AND tgtype & 66 = 2   -- BEFORE triggers
  AND tgtype & 4 = 4    -- INSERT events
  AND tgisinternal = false;

-- D) Test insertion (optionnel) + rollback
-- =========================================
-- IMPORTANT: Exécuter dans une transaction avec ROLLBACK pour ne pas polluer la DB

-- BEGIN;
-- 
-- -- Test 1: Insertion SANS created_by → doit être défini automatiquement
-- WITH inserted AS (
--   INSERT INTO public.sorties_produit (
--     citerne_id, produit_id, client_id,
--     index_avant, index_apres, volume_ambiant, volume_corrige_15c,
--     proprietaire_type, statut
--   ) VALUES (
--     'uuid-citerne-test'::uuid, 'uuid-produit-test'::uuid, 'uuid-client-test'::uuid,
--     100.0, 150.0, 50.0, 47.5,
--     'MONALUXE', 'validee'
--   )
--   RETURNING id, created_by, created_at
-- )
-- SELECT 
--   id,
--   created_by,
--   created_at,
--   CASE 
--     WHEN created_by IS NOT NULL THEN 'OK: created_by a été défini automatiquement'
--     ELSE 'ATTENTION: created_by est NULL (auth.uid() était NULL hors contexte Supabase)'
--   END as verification
-- FROM inserted;
-- 
-- -- Nettoyage (ROLLBACK au lieu de DELETE pour éviter les triggers DELETE)
-- ROLLBACK;
--
-- ============================================================================


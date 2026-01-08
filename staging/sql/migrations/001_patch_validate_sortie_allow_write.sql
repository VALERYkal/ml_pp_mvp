-- Patch validate_sortie: autoriser écriture sur stocks_journaliers
-- À appliquer sur STAGING uniquement
-- 
-- Ce patch ajoute set_config('app.stocks_journaliers_allow_write','1', true)
-- au début de validate_sortie() pour permettre l'écriture sur stocks_journaliers
-- via le trigger stocks_journaliers_block_writes().

-- INSTRUCTIONS:
-- 1. Exécuter dans Supabase SQL Editor sur STAGING
-- 2. Lire la fonction actuelle avec: \df+ validate_sortie
--    ou: SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'validate_sortie' AND pg_get_function_arguments(oid) = 'p_id uuid';
-- 3. Copier la fonction complète
-- 4. Ajouter cette ligne juste après BEGIN (après les vérifications de rôle si présentes):
--    PERFORM set_config('app.stocks_journaliers_allow_write', '1', true);
-- 5. Recréer la fonction avec CREATE OR REPLACE FUNCTION

-- Exemple de structure attendue (à adapter selon votre fonction actuelle):
/*
CREATE OR REPLACE FUNCTION public.validate_sortie(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  -- vos variables existantes
BEGIN
  -- vos vérifications de rôle existantes (si présentes)
  
  -- ⬇️ AJOUTER CETTE LIGNE ICI:
  PERFORM set_config('app.stocks_journaliers_allow_write', '1', true);
  
  -- reste de votre fonction inchangé
  -- (vérifications, UPDATE statut, INSERT/UPDATE stocks_journaliers, etc.)
END;
$$;
*/

-- Script automatique (alternative):
-- Ce script lit la fonction actuelle et applique le patch automatiquement
DO $$
DECLARE
  v_func_def text;
  v_patched_def text;
BEGIN
  -- Lire la définition actuelle
  SELECT pg_get_functiondef(p.oid) INTO v_func_def
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname = 'validate_sortie'
    AND pg_get_function_identity_arguments(p.oid) = 'p_id uuid'
  ORDER BY p.oid DESC
  LIMIT 1;
  
  IF v_func_def IS NULL THEN
    RAISE EXCEPTION 'Function validate_sortie(p_id uuid) not found';
  END IF;
  
  -- Vérifier si le patch est déjà appliqué
  IF v_func_def LIKE '%set_config(''app.stocks_journaliers_allow_write''%' THEN
    RAISE NOTICE 'Function validate_sortie already contains set_config, skipping';
    RETURN;
  END IF;
  
  -- Insérer set_config juste après BEGIN
  -- Pattern: remplacer "\nBEGIN\n" (première occurrence uniquement) par "\nBEGIN\n  PERFORM set_config(...);\n"
  v_patched_def := regexp_replace(
    v_func_def,
    E'(\\nBEGIN\\s*\\n)',
    E'\\1  PERFORM set_config(''app.stocks_journaliers_allow_write'', ''1'', true);\\n',
    ''  -- (sans flag) => remplace seulement la 1ère occurrence
  );
  
  -- Exécuter la fonction patched
  EXECUTE v_patched_def;
  
  RAISE NOTICE 'Function validate_sortie patched successfully';
END;
$$;

-- ============================================================================
-- RLS S2 - Smoke Tests (STAGING)
-- Fichier: staging/sql/rls_smoke_test_s2.sql
-- Date: 2026-01-09
--
-- OBJECTIF:
-- Tests simples pour vérifier les scénarios clés RLS S2 en STAGING
--
-- UTILISATION:
-- Exécuter via Supabase SQL Editor.
-- Chaque test simule un utilisateur authentifié avec JWT claims + rôle authenticated.
--
-- PRÉREQUIS:
-- - Migration RLS S2 appliquée (20260109041723_axe_c_rls_s2.sql)
-- - Profils STAGING existants:
--   * admin: user_id = 2bf68c7c-a907-4504-9aba-89061be487a2
--   * lecture: user_id = 14064b77-e138-408b-94ff-59fef8d1adfe
-- ============================================================================

-- ============================================================================
-- CONSTANTES STAGING (UUIDs utilisateurs)
-- ============================================================================
-- 
-- ADMIN_USER_UUID = 2bf68c7c-a907-4504-9aba-89061be487a2
-- LECTURE_USER_UUID = 14064b77-e138-408b-94ff-59fef8d1adfe
--
-- Dépôt staging (fixe):
-- DEPOT_STAGING_UUID = 11111111-1111-1111-1111-111111111111
-- ============================================================================

-- ============================================================================
-- BLOC STANDARD "CONTEXTE AUTH" (réutilisable)
-- ============================================================================
-- 
-- Pour chaque test, utiliser ce bloc avec l'UUID réel:
--
-- SELECT set_config('request.jwt.claim.sub', '<USER_UUID>', true);
-- SELECT set_config('request.jwt.claim.role', 'authenticated', true);
-- SELECT set_config('request.jwt.claims', json_build_object('sub','<USER_UUID>','role','authenticated')::text, true);
-- SET LOCAL ROLE authenticated;
--
-- IMPORTANT: Les 3 set_config + SET LOCAL ROLE sont OBLIGATOIRES pour que RLS fonctionne
-- dans Supabase SQL Editor (sinon RLS peut être bypass).
-- ============================================================================

-- ============================================================================
-- TESTS RÔLES NON PRÉSENTS EN STAGING
-- ============================================================================
-- 
-- Les tests suivants sont désactivés car les profils correspondants n'existent pas en STAGING:
-- - Operateur (operateur)
-- - Directeur (directeur)
-- - Gérant (gerant)
-- - PCA (pca)
--
-- À activer quand ces utilisateurs seront créés avec leurs profils correspondants.
-- ============================================================================

-- ============================================================================
-- TEST A: Helpers sanity (admin)
-- ============================================================================
--
-- Scénario:
-- - Utilisateur: admin (user_id = 2bf68c7c-a907-4504-9aba-89061be487a2)
-- - Action: Vérifier que les helpers SQL fonctionnent correctement
-- - Résultat attendu: Helpers retournent les valeurs attendues pour admin
-- ============================================================================

BEGIN;

-- CONTEXTE AUTH (obligatoire en SQL Editor)
SELECT set_config('request.jwt.claim.sub', '2bf68c7c-a907-4504-9aba-89061be487a2', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config('request.jwt.claims', json_build_object('sub','2bf68c7c-a907-4504-9aba-89061be487a2','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- TEST A.1: Vérifier auth.uid() et app_uid()
SELECT 
  auth.uid() as auth_uid,
  public.app_uid() as app_uid,
  public.app_current_role() as role,
  public.app_is_admin() as is_admin,
  public.app_is_cadre() as is_cadre;
-- ✅ RÉSULTAT ATTENDU: auth_uid = app_uid = 2bf68c7c-a907-4504-9aba-89061be487a2, role = 'admin', is_admin = true, is_cadre = true

-- TEST A.2: Vérifier app_current_role()
SELECT public.app_current_role() as current_role;
-- ✅ RÉSULTAT ATTENDU: 'admin'

-- TEST A.3: Vérifier app_current_depot_id()
SELECT public.app_current_depot_id() as current_depot_id;
-- ✅ RÉSULTAT ATTENDU: depot_id de l'admin (ou NULL)

-- TEST A.4: Vérifier app_is_admin()
SELECT public.app_is_admin() as is_admin;
-- ✅ RÉSULTAT ATTENDU: true

-- TEST A.5: Vérifier app_is_cadre()
SELECT public.app_is_cadre() as is_cadre;
-- ✅ RÉSULTAT ATTENDU: true (admin est un cadre)

-- Fin du test (rollback pour isolation)
ROLLBACK;

-- ============================================================================
-- TEST B: Admin INSERT stocks_adjustments (doit PASSER)
-- ============================================================================
--
-- Scénario:
-- - Utilisateur: admin (user_id = 2bf68c7c-a907-4504-9aba-89061be487a2)
-- - Action: INSERT sur stocks_adjustments
-- - Résultat attendu: Succès (INSERT réussi, created_by non NULL)
-- ============================================================================

BEGIN;

-- CONTEXTE AUTH (obligatoire en SQL Editor)
SELECT set_config('request.jwt.claim.sub', '2bf68c7c-a907-4504-9aba-89061be487a2', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config('request.jwt.claims', json_build_object('sub','2bf68c7c-a907-4504-9aba-89061be487a2','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- Sanity check: vérifier que le contexte auth est correct
SELECT 
  public.app_uid() as uid, 
  public.app_current_role() as role, 
  public.app_is_admin() as is_admin;
-- ✅ RÉSULTAT ATTENDU: uid = 2bf68c7c-a907-4504-9aba-89061be487a2, role = 'admin', is_admin = true

-- Pick un mouvement réel (réception existante)
WITH picked AS (
  SELECT r.id AS reception_id
  FROM public.receptions r
  LIMIT 1
)
INSERT INTO public.stocks_adjustments (
  mouvement_type,
  mouvement_id,
  delta_ambiant,
  delta_15c,
  reason,
  created_by
)
SELECT
  'RECEPTION',
  picked.reception_id,
  10.5,
  10.0,
  'Test RLS S2 - Ajustement admin',
  public.app_uid()
FROM picked;

-- Vérification: SELECT sur la ligne insérée
SELECT 
  id, 
  mouvement_type, 
  mouvement_id, 
  delta_ambiant, 
  delta_15c, 
  reason, 
  created_by, 
  created_at
FROM public.stocks_adjustments
WHERE reason LIKE 'Test RLS S2 - Ajustement admin%'
ORDER BY created_at DESC
LIMIT 1;
-- ✅ RÉSULTAT ATTENDU: La ligne insérée avec created_by = 2bf68c7c-a907-4504-9aba-89061be487a2 (non NULL)

-- Fin du test (rollback pour isolation)
ROLLBACK;

-- ============================================================================
-- TEST C: Lecture INSERT stocks_adjustments (doit ÉCHOUER 42501)
-- ============================================================================
--
-- Scénario:
-- - Utilisateur: lecture (user_id = 14064b77-e138-408b-94ff-59fef8d1adfe)
-- - Action: INSERT sur stocks_adjustments
-- - Résultat attendu: Erreur RLS (permission denied, ERROR 42501)
-- ============================================================================

BEGIN;

-- CONTEXTE AUTH (obligatoire en SQL Editor)
SELECT set_config('request.jwt.claim.sub', '14064b77-e138-408b-94ff-59fef8d1adfe', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config('request.jwt.claims', json_build_object('sub','14064b77-e138-408b-94ff-59fef8d1adfe','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- Sanity check: vérifier que le contexte auth est correct
SELECT 
  public.app_uid() as uid, 
  public.app_current_role() as role, 
  public.app_is_admin() as is_admin;
-- ✅ RÉSULTAT ATTENDU: uid = 14064b77-e138-408b-94ff-59fef8d1adfe, role = 'lecture', is_admin = false

-- Pick un mouvement réel (réception existante)
WITH picked AS (
  SELECT r.id AS reception_id
  FROM public.receptions r
  LIMIT 1
)
INSERT INTO public.stocks_adjustments (
  mouvement_type,
  mouvement_id,
  delta_ambiant,
  delta_15c,
  reason,
  created_by
)
SELECT
  'RECEPTION',
  picked.reception_id,
  1.0,
  1.0,
  'Test RLS S2 - Tentative ajustement lecture',
  public.app_uid()
FROM picked;
-- ✅ Attendu: ERROR 42501: new row violates row-level security policy for table "stocks_adjustments"
-- ✅ RLS doit bloquer car lecture n'est pas admin

-- Fin du test (rollback pour isolation)
ROLLBACK;

-- ============================================================================
-- TEST D: Lecture SELECT scoped (citernes + receptions JOIN citernes)
-- ============================================================================
--
-- Scénario:
-- - Utilisateur: lecture (user_id = 14064b77-e138-408b-94ff-59fef8d1adfe)
-- - Action: SELECT sur citernes et réceptions du dépôt staging
-- - Résultat attendu: Citernes et réceptions du dépôt staging uniquement (RLS filtre automatiquement)
-- ============================================================================

BEGIN;

-- CONTEXTE AUTH (obligatoire en SQL Editor)
SELECT set_config('request.jwt.claim.sub', '14064b77-e138-408b-94ff-59fef8d1adfe', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config('request.jwt.claims', json_build_object('sub','14064b77-e138-408b-94ff-59fef8d1adfe','role','authenticated')::text, true);
SET LOCAL ROLE authenticated;

-- Sanity check: vérifier que le contexte auth est correct
SELECT 
  public.app_uid() as uid, 
  public.app_current_role() as role, 
  public.app_current_depot_id() as depot_id;
-- ✅ RÉSULTAT ATTENDU: uid = 14064b77-e138-408b-94ff-59fef8d1adfe, role = 'lecture', depot_id = 11111111-1111-1111-1111-111111111111

-- TEST D.1: SELECT citernes dépôt staging (doit retourner les citernes du dépôt staging)
SELECT id, nom, depot_id
FROM public.citernes
WHERE depot_id = '11111111-1111-1111-1111-111111111111';
-- ✅ RÉSULTAT ATTENDU: Citernes du dépôt staging uniquement

-- TEST D.2: SELECT toutes les citernes (doit retourner uniquement celles du dépôt staging via RLS)
SELECT id, nom, depot_id
FROM public.citernes;
-- ✅ RÉSULTAT ATTENDU: Citernes du dépôt staging uniquement (RLS filtre automatiquement)

-- TEST D.3: SELECT receptions via citerne dépôt staging (doit retourner les réceptions du dépôt)
SELECT r.id, r.citerne_id, c.depot_id
FROM public.receptions r
JOIN public.citernes c ON c.id = r.citerne_id
WHERE c.depot_id = '11111111-1111-1111-1111-111111111111';
-- ✅ RÉSULTAT ATTENDU: Réceptions du dépôt staging uniquement

-- TEST D.4: SELECT toutes les réceptions (doit retourner uniquement celles du dépôt staging via RLS)
SELECT r.id, r.citerne_id, c.depot_id
FROM public.receptions r
JOIN public.citernes c ON c.id = r.citerne_id;
-- ✅ RÉSULTAT ATTENDU: Réceptions du dépôt staging uniquement (RLS filtre automatiquement)

-- Fin du test (rollback pour isolation)
ROLLBACK;

-- ============================================================================
-- RÉSUMÉ DES TESTS
-- ============================================================================
--
-- ✅ TEST A: Helpers sanity (admin) - Vérifie que les helpers SQL fonctionnent
-- ✅ TEST B: Admin INSERT stocks_adjustments - Doit PASSER (INSERT réussi)
-- ✅ TEST C: Lecture INSERT stocks_adjustments - Doit ÉCHOUER (ERROR 42501)
-- ✅ TEST D: Lecture SELECT scoped - Doit retourner uniquement dépôt staging
--
-- ============================================================================
-- NOTES FINALES
-- ============================================================================
--
-- Ces tests sont des guides reproductibles pour STAGING.
-- Chaque test est isolé dans une transaction (BEGIN/ROLLBACK) pour isolation.
--
-- UUIDs utilisés (hardcodés pour STAGING):
-- - ADMIN_USER_UUID = 2bf68c7c-a907-4504-9aba-89061be487a2
-- - LECTURE_USER_UUID = 14064b77-e138-408b-94ff-59fef8d1adfe
-- - DEPOT_STAGING_UUID = 11111111-1111-1111-1111-111111111111
--
-- Pour exécuter un test:
-- 1. Copier le bloc BEGIN; ... ROLLBACK; du test souhaité
-- 2. Exécuter dans Supabase SQL Editor
-- 3. Vérifier le résultat attendu
--
-- ============================================================================

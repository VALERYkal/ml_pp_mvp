-- Script de diagnostic pour identifier les problèmes
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier l'utilisateur connecté
SELECT 
  id, 
  email, 
  created_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'dir@ml.pp';

-- 2. Vérifier si le profil existe
SELECT 
  p.*,
  u.email as auth_email
FROM public.profils p
LEFT JOIN auth.users u ON p.user_id = u.id
WHERE u.email = 'dir@ml.pp';

-- 3. Vérifier les tables existantes
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 4. Vérifier les politiques RLS sur profils
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'profils';

-- 5. Tester l'accès aux profils (en tant qu'utilisateur connecté)
SELECT * FROM public.profils LIMIT 5;
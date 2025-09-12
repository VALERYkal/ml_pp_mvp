-- Script pour créer un profil admin
-- À exécuter dans Supabase SQL Editor

-- Vérifier si l'utilisateur admin existe
SELECT id, email FROM auth.users WHERE email = 'admin@ml.pp';

-- Insérer le profil admin (remplacer l'ID par celui de l'utilisateur)
INSERT INTO public.profils (user_id, role, depot_id, nom, prenom, email, telephone, created_at, updated_at)
VALUES (
  'd96de149-8732-475f-a9d2-9f5b3466c4fb', -- ID de l'utilisateur admin@ml.pp
  'admin',
  'depot-001', -- ou l'ID du dépôt approprié
  'Admin',
  'Système',
  'admin@ml.pp',
  '+243123456789',
  NOW(),
  NOW()
)
ON CONFLICT (user_id) DO UPDATE SET
  role = EXCLUDED.role,
  depot_id = EXCLUDED.depot_id,
  nom = EXCLUDED.nom,
  prenom = EXCLUDED.prenom,
  email = EXCLUDED.email,
  telephone = EXCLUDED.telephone,
  updated_at = NOW();

-- Vérifier que le profil a été créé
SELECT * FROM public.profils WHERE user_id = 'd96de149-8732-475f-a9d2-9f5b3466c4fb';
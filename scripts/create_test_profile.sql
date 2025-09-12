-- Script pour créer un profil de test pour l'utilisateur directeur
-- À exécuter dans Supabase SQL Editor

-- Vérifier si l'utilisateur existe
SELECT id, email FROM auth.users WHERE email = 'dir@ml.pp';

-- Insérer le profil directeur (remplacer l'ID par celui de l'utilisateur)
INSERT INTO public.profils (user_id, role, depot_id, nom, prenom, email, telephone, created_at, updated_at)
VALUES (
  'a25fe6ec-be09-428a-a276-27e650320d4e', -- ID de l'utilisateur dir@ml.pp
  'directeur',
  'depot-001', -- ou l'ID du dépôt approprié
  'Directeur',
  'Test',
  'dir@ml.pp',
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
SELECT * FROM public.profils WHERE user_id = 'a25fe6ec-be09-428a-a276-27e650320d4e';
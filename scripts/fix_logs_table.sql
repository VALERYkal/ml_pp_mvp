-- Script pour corriger le problème de la table logs
-- À exécuter dans Supabase SQL Editor

-- Vérifier les tables existantes
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%log%';

-- Si la table s'appelle 'log_actions' et non 'logs', créer un alias
-- (Optionnel) Créer une vue pour compatibilité
CREATE OR REPLACE VIEW public.logs AS 
SELECT * FROM public.log_actions;

-- Ou si la table n'existe pas du tout, la créer
CREATE TABLE IF NOT EXISTS public.log_actions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  module TEXT NOT NULL,
  action TEXT NOT NULL,
  niveau TEXT NOT NULL CHECK (niveau IN ('INFO', 'WARNING', 'CRITICAL')),
  user_id UUID REFERENCES auth.users(id),
  details JSONB DEFAULT '{}'::jsonb
);

-- Activer RLS
ALTER TABLE public.log_actions ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS pour log_actions
CREATE POLICY "Users can insert their own logs" ON public.log_actions
  FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Staff can read logs" ON public.log_actions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profils 
      WHERE user_id = auth.uid() 
      AND role IN ('admin', 'directeur')
    )
  );

-- Vérifier que la table existe maintenant
SELECT COUNT(*) FROM public.log_actions;
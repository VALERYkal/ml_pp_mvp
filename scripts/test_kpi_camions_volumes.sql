-- Test rapide pour vérifier le KPI Camions + Volumes
-- À exécuter dans Supabase SQL Editor pour valider les données

-- 1. Vérifier la structure de la table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'cours_de_route' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les données existantes
SELECT 
  statut,
  count(*) as nb_camions,
  sum(volume) as volume_total_litres,
  avg(volume) as volume_moyen_litres
FROM public.cours_de_route 
WHERE statut IN ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE')
GROUP BY statut
ORDER BY statut;

-- 3. Test du KPI complet (simulation de l'app)
SELECT 
  CASE 
    WHEN statut IN ('CHARGEMENT','TRANSIT','FRONTIERE') THEN 'enRoute'
    WHEN statut = 'ARRIVE' THEN 'attente'
    ELSE 'autre'
  END as categorie,
  count(*) as nb_camions,
  sum(volume) as volume_litres
FROM public.cours_de_route 
WHERE statut IN ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE')
GROUP BY 
  CASE 
    WHEN statut IN ('CHARGEMENT','TRANSIT','FRONTIERE') THEN 'enRoute'
    WHEN statut = 'ARRIVE' THEN 'attente'
    ELSE 'autre'
  END
ORDER BY categorie;

-- 4. Test avec filtre par dépôt (si applicable)
SELECT 
  depot_destination_id,
  CASE 
    WHEN statut IN ('CHARGEMENT','TRANSIT','FRONTIERE') THEN 'enRoute'
    WHEN statut = 'ARRIVE' THEN 'attente'
  END as categorie,
  count(*) as nb_camions,
  sum(volume) as volume_litres
FROM public.cours_de_route 
WHERE statut IN ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE')
AND depot_destination_id IS NOT NULL
GROUP BY depot_destination_id, 
  CASE 
    WHEN statut IN ('CHARGEMENT','TRANSIT','FRONTIERE') THEN 'enRoute'
    WHEN statut = 'ARRIVE' THEN 'attente'
  END
ORDER BY depot_destination_id, categorie;

-- 5. Vérifier les index (optionnel)
SELECT 
  schemaname, 
  tablename, 
  indexname, 
  indexdef 
FROM pg_indexes 
WHERE schemaname='public' 
AND tablename='cours_de_route'
ORDER BY indexname;

-- Index et RLS pour KPI Cours de Route enrichi
-- À exécuter dans Supabase SQL Editor une seule fois

-- Index pour optimiser les requêtes par statut
create index if not exists idx_cours_statut on public.cours_de_route(statut);

-- Index pour optimiser les requêtes par dépôt destination
create index if not exists idx_cours_depot on public.cours_de_route(depot_destination_id);

-- Index pour optimiser les requêtes par produit
create index if not exists idx_cours_produit on public.cours_de_route(produit_id);

-- Index composite pour les requêtes fréquentes (statut + dépôt)
create index if not exists idx_cours_statut_depot on public.cours_de_route(statut, depot_destination_id);

-- Activer RLS sur la table cours_de_route
alter table public.cours_de_route enable row level security;

-- Créer la policy de lecture pour cours_de_route (si elle n'existe pas)
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where schemaname='public' 
    and tablename='cours_de_route' 
    and policyname='read cours'
  ) then
    create policy "read cours" on public.cours_de_route for select using (true);
  end if;
end $$;

-- Vérification des index créés
select 
  schemaname, 
  tablename, 
  indexname, 
  indexdef 
from pg_indexes 
where schemaname='public' 
and tablename='cours_de_route'
order by indexname;

-- Vérification des policies créées
select 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
from pg_policies 
where schemaname='public' 
and tablename='cours_de_route'
order by policyname;

-- Test de la requête KPI (optionnel - pour vérifier que ça fonctionne)
-- select 
--   statut,
--   count(*) as nb_camions,
--   sum(volume) as volume_total_litres
-- from public.cours_de_route 
-- where statut in ('CHARGEMENT','TRANSIT','FRONTIERE','ARRIVE')
-- group by statut
-- order by statut;

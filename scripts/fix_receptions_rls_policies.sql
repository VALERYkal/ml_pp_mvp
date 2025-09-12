-- RLS Policies pour KPI Réceptions du jour
-- À exécuter dans Supabase SQL Editor une seule fois

-- Activer RLS sur la table receptions
alter table public.receptions enable row level security;

-- Créer la policy de lecture pour receptions (si elle n'existe pas)
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where schemaname='public' 
    and tablename='receptions' 
    and policyname='read receptions'
  ) then
    create policy "read receptions" on public.receptions for select using (true);
  end if;
end $$;

-- Activer RLS sur la table citernes (requis pour le join avec depot_id)
alter table public.citernes enable row level security;

-- Créer la policy de lecture pour citernes (si elle n'existe pas)
do $$ begin
  if not exists (
    select 1 from pg_policies 
    where schemaname='public' 
    and tablename='citernes' 
    and policyname='read citernes'
  ) then
    create policy "read citernes" on public.citernes for select using (true);
  end if;
end $$;

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
and tablename in ('receptions', 'citernes')
order by tablename, policyname;

-- Test de la requête KPI (optionnel - pour vérifier que ça fonctionne)
-- select 
--   count(*) as nb_camions,
--   sum(volume_ambiant) as vol_ambiant,
--   sum(volume_corrige_15c) as vol_15c
-- from public.receptions 
-- where statut = 'validee' 
-- and date_reception = current_date;

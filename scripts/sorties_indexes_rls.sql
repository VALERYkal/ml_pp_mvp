-- Index et RLS pour KPI 4 (Sorties du jour)
-- À exécuter dans Supabase SQL Editor une seule fois

-- Index pour les performances de lecture
create index if not exists idx_sorties_date on public.sorties_produit(date_sortie desc);
create index if not exists idx_sorties_citerne on public.sorties_produit(citerne_id);
create index if not exists idx_sorties_statut on public.sorties_produit(statut);

-- RLS pour sorties_produit
alter table public.sorties_produit enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
    and tablename='sorties_produit'
    and policyname='read sorties'
  ) then
    create policy "read sorties" on public.sorties_produit for select using (true);
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
and tablename='sorties_produit'
order by tablename, policyname;

-- Test de la requête KPI (optionnel - pour vérifier que ça fonctionne)
-- select
--   count(*) as nb_camions,
--   sum(volume_ambiant) as total_ambiant,
--   sum(volume_corrige_15c) as total_15c
-- from public.sorties_produit
-- where statut = 'validee'
-- and date_sortie >= current_date
-- and date_sortie < current_date + interval '1 day';

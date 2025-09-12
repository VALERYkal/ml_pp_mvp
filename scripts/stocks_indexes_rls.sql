-- Index et RLS pour KPI 3 (Stocks totaux)
-- À exécuter dans Supabase SQL Editor une seule fois

-- Index pour les performances de lecture
create index if not exists idx_stocks_j_citerne_date on public.stocks_journaliers(citerne_id, date_jour desc);
create index if not exists idx_citernes_depot on public.citernes(depot_id);

-- RLS pour stocks_journaliers
alter table public.stocks_journaliers enable row level security;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
    and tablename='stocks_journaliers'
    and policyname='read stocks_j'
  ) then
    create policy "read stocks_j" on public.stocks_journaliers for select using (true);
  end if;
end $$;

-- RLS pour citernes (si pas encore fait)
alter table public.citernes enable row level security;

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
and tablename in ('stocks_journaliers', 'citernes')
order by tablename, policyname;

-- Test de la requête KPI (optionnel - pour vérifier que ça fonctionne)
-- select
--   sum(stock_ambiant) as total_ambiant,
--   sum(stock_15c) as total_15c,
--   max(date_jour) as last_day
-- from public.v_citerne_stock_actuel;

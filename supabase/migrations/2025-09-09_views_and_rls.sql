-- WARNING: reference migration to keep repo & DB in sync (idempotent-ish)

-- View: public.logs
create or replace view public.logs as
select
  la.id,
  la.created_at,
  la.module,
  la.action,
  la.niveau,
  la.user_id,
  la.details
from public.log_actions la;

-- RLS log_actions (read)
alter table public.log_actions enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='log_actions' and policyname='read logs'
  ) then
    create policy "read logs" on public.log_actions for select using (true);
  end if;
end $$;

-- View: public.v_citerne_stock_actuel
create or replace view public.v_citerne_stock_actuel as
with ranked as (
  select
    s.*,
    row_number() over (partition by s.citerne_id order by s.date_jour desc) as rn
  from public.stocks_journaliers s
)
select
  r.citerne_id,
  r.produit_id,
  r.stock_ambiant,
  r.stock_15c,
  r.date_jour
from ranked r
where r.rn = 1;

-- RLS on tables (NOT on views)
alter table public.stocks_journaliers enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='stocks_journaliers' and policyname='read stocks_journaliers'
  ) then
    create policy "read stocks_journaliers" on public.stocks_journaliers for select using (true);
  end if;
end $$;

alter table public.citernes enable row level security;
do $$
begin
  if not exists (
    select 1 from pg_policies where schemaname='public' and tablename='citernes' and policyname='read citernes'
  ) then
    create policy "read citernes" on public.citernes for select using (true);
  end if;
end $$;

-- Index recommandé pour performance
create index if not exists idx_stocks_journaliers_citerne_date_desc 
on public.stocks_journaliers (citerne_id, date_jour desc);

-- Commentaires pour documentation
comment on view public.logs is 'Vue de compatibilité pour le code existant pointant vers logs';
comment on view public.v_citerne_stock_actuel is 'Renvoie le dernier stock connu par citerne via stocks_journaliers';
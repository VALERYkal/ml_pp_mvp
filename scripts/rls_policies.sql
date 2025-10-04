-- Supabase RLS Policies (MVP)
-- Context: tables receptions, sorties_produit, stocks_journaliers, citernes, log_actions
-- Prereq: profiles table `public.profils(user_id uuid, role text, depot_id uuid)`

-- Helper functions
create or replace function public.user_role() returns text
language sql stable security definer as $$
  select p.role from public.profils p where p.user_id = auth.uid() limit 1;
$$;

create or replace function public.role_in(variadic roles text[]) returns boolean
language sql stable security definer as $$
  select coalesce(public.user_role(), '') = any(roles);
$$;

-- Receptions -----------------------------------------------------------------
alter table public.receptions enable row level security;

-- Read: all authenticated users can read (MVP)
drop policy if exists receptions_select on public.receptions;
create policy receptions_select on public.receptions
  for select using (auth.role() = 'authenticated');

-- Insert: admin, gerant, operateur
drop policy if exists receptions_insert on public.receptions;
create policy receptions_insert on public.receptions
  for insert with check (public.role_in('admin','gerant','operateur'));

-- Update: admin, gerant (validation)
drop policy if exists receptions_update on public.receptions;
create policy receptions_update on public.receptions
  for update using (public.role_in('admin','gerant')) with check (public.role_in('admin','gerant'));

-- Delete: admin only
drop policy if exists receptions_delete on public.receptions;
create policy receptions_delete on public.receptions
  for delete using (public.role_in('admin'));

-- Sorties produit -------------------------------------------------------------
alter table public.sorties_produit enable row level security;

drop policy if exists sorties_select on public.sorties_produit;
create policy sorties_select on public.sorties_produit
  for select using (auth.role() = 'authenticated');

drop policy if exists sorties_insert on public.sorties_produit;
create policy sorties_insert on public.sorties_produit
  for insert with check (public.role_in('admin','gerant','operateur'));

drop policy if exists sorties_update on public.sorties_produit;
create policy sorties_update on public.sorties_produit
  for update using (public.role_in('admin','gerant')) with check (public.role_in('admin','gerant'));

drop policy if exists sorties_delete on public.sorties_produit;
create policy sorties_delete on public.sorties_produit
  for delete using (public.role_in('admin'));

-- Stocks journaliers ----------------------------------------------------------
alter table public.stocks_journaliers enable row level security;

drop policy if exists stocks_select on public.stocks_journaliers;
create policy stocks_select on public.stocks_journaliers
  for select using (auth.role() = 'authenticated');

-- MAJ par service: admin, gerant, operateur (MVP)
drop policy if exists stocks_upsert on public.stocks_journaliers;
create policy stocks_upsert on public.stocks_journaliers
  for all using (public.role_in('admin','gerant','operateur')) with check (public.role_in('admin','gerant','operateur'));

-- Citernes --------------------------------------------------------------------
alter table public.citernes enable row level security;

drop policy if exists citernes_select on public.citernes;
create policy citernes_select on public.citernes
  for select using (auth.role() = 'authenticated');

drop policy if exists citernes_update on public.citernes;
create policy citernes_update on public.citernes
  for update using (public.role_in('admin')) with check (public.role_in('admin'));

-- Log actions -----------------------------------------------------------------
alter table public.log_actions enable row level security;

drop policy if exists logs_select_admin on public.log_actions;
create policy logs_select_admin on public.log_actions
  for select using (public.role_in('admin','directeur','gerant','pca'));

-- Optionnel: empêcher insert direct (réservé au backend) → autoriser tous authentifiés pour journaliser via app
drop policy if exists logs_insert on public.log_actions;
create policy logs_insert on public.log_actions
  for insert with check (auth.role() = 'authenticated');

-- Notes:
-- - Adapter selon besoins précis (dépôt, propriété). Pour MVP, visibilité globale authentifiée pour SELECT.
-- - Tester via comptes de test: admin, directeur, gerant, operateur, lecture, pca.


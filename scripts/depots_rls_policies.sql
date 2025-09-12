-- RLS Policies pour la table depots
-- À exécuter dans Supabase SQL Editor une seule fois

-- Activer RLS sur la table depots
alter table public.depots enable row level security;

-- Créer la policy de lecture pour depots (si elle n'existe pas)
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname='public'
    and tablename='depots'
    and policyname='read depots'
  ) then
    create policy "read depots" on public.depots for select using (true);
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
and tablename='depots'
order by tablename, policyname;

-- Test de la requête (optionnel - pour vérifier que ça fonctionne)
-- select id, nom from public.depots limit 5;

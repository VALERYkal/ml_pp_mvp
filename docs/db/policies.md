# Row-Level Security (RLS)

## log_actions

```sql
alter table public.log_actions enable row level security;

create policy "read logs"
  on public.log_actions
  for select using (true); -- Adapter selon la sécurité
```

## stocks_journaliers

```sql
alter table public.stocks_journaliers enable row level security;

create policy "read stocks_journaliers"
  on public.stocks_journaliers
  for select using (true); -- Adapter selon la sécurité
```

## citernes

```sql
alter table public.citernes enable row level security;

create policy "read citernes"
  on public.citernes
  for select using (true); -- Adapter selon la sécurité
```

## Important

**RLS non appliqué aux vues.** Toujours sécuriser les tables sources.

### Tables avec RLS activé

- ✅ `public.log_actions`
- ✅ `public.stocks_journaliers` 
- ✅ `public.citernes`

### Vues (pas de RLS)

- ❌ `public.logs` (vue de compatibilité)
- ❌ `public.v_citerne_stock_actuel` (vue de stock actuel)

### Politique de sécurité

Les policies actuelles permettent la lecture à tous les utilisateurs authentifiés (`using (true)`). 

Pour un environnement de production, adapter selon les besoins :

```sql
-- Exemple: lecture limitée par rôle
create policy "read logs by role"
  on public.log_actions
  for select using (
    auth.jwt() ->> 'role' in ('admin', 'directeur', 'gerant')
  );
```

### Vérification des policies

```sql
-- Lister toutes les policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual
from pg_policies 
where schemaname = 'public'
order by tablename, policyname;

-- Vérifier RLS activé
select schemaname, tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
and rowsecurity = true;
```
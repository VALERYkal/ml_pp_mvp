# View: public.logs

Vue de compatibilité pour le code qui interroge `from('logs')`.  
Elle mappe `public.log_actions` → mêmes colonnes utilisées par l'app.

## Définition
```sql
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
```

## RLS

Pas de policy sur la vue (les RLS s'appliquent aux tables uniquement).

**Table source:** `public.log_actions`

```sql
alter table public.log_actions enable row level security;

create policy "read logs" on public.log_actions for select using (true); -- adapter selon sécurité
```

## Usage (app)

- **KPIs Admin** + activité récente lisent `public.logs`.
- **Recherche par tranche temporelle** via `created_at`.

## Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique du log |
| `created_at` | TIMESTAMPTZ | Date/heure de création |
| `module` | TEXT | Module de l'application |
| `action` | TEXT | Action effectuée |
| `niveau` | TEXT | Niveau de log (INFO, WARN, ERROR) |
| `user_id` | UUID | ID de l'utilisateur |
| `details` | JSONB | Détails supplémentaires |
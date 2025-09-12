# View: public.v_citerne_stock_actuel

Renvoie **le dernier stock** connu par citerne (`stocks_journaliers`).

## Définition
```sql
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
```

## RLS

Note: pas de RLS sur la vue. Activer RLS et policies sur `stocks_journaliers`.

```sql
alter table public.stocks_journaliers enable row level security;
create policy "read stocks_journaliers" on public.stocks_journaliers for select using (true);
```

## Usage (app)

- **KPIs Admin & Directeur**: "citernes sous seuil", "ratio d'utilisation", "stock total".
- **Jointure logique** avec `citernes(capacite_totale, capacite_securite)`.

## Performance

**Index recommandé:** `(citerne_id, date_jour desc)` sur `stocks_journaliers`.

```sql
create index idx_stocks_journaliers_citerne_date_desc 
on public.stocks_journaliers (citerne_id, date_jour desc);
```

## Colonnes

| Colonne | Type | Description |
|---------|------|-------------|
| `citerne_id` | UUID | Identifiant de la citerne |
| `produit_id` | UUID | Identifiant du produit |
| `stock_ambiant` | NUMERIC | Stock à température ambiante |
| `stock_15c` | NUMERIC | Stock à 15°C (si disponible) |
| `date_jour` | DATE | Date du dernier stock |

## Exemple d'usage

```sql
-- KPIs Directeur: citernes sous seuil de sécurité
select 
  c.nom,
  v.stock_ambiant,
  c.capacite_securite,
  (v.stock_ambiant < c.capacite_securite) as sous_seuil
from public.v_citerne_stock_actuel v
join public.citernes c on c.id = v.citerne_id
where v.stock_ambiant < c.capacite_securite;
```
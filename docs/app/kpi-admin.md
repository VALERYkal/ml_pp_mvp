# KPIs Admin — Références de données

## Sources
- `public.logs` (vue) ← `public.log_actions`
- `public.receptions` (DATE: `date_reception`)
- `public.sorties_produit` (TIMESTAMPTZ: `date_sortie`)
- `public.v_citerne_stock_actuel` + `public.citernes`

## Filtres temporels
- **24h erreurs:** `created_at >= now() - interval '24h'`
- **Jour réceptions:** `date_reception = YYYY-MM-DD (UTC)`
- **Jour sorties:** `date_sortie in [dayStartUTC, dayEndUTC)`

## Calculs

### Erreurs système
```sql
-- Erreurs des dernières 24h
select count(*) as erreurs24h
from public.logs 
where niveau = 'ERROR' 
and created_at >= now() - interval '24h';
```

### Activité quotidienne
```sql
-- Réceptions du jour
select count(*) as receptionsJour
from public.receptions 
where date_reception = current_date;

-- Sorties du jour
select count(*) as sortiesJour
from public.sorties_produit 
where date_sortie >= date_trunc('day', now())
and date_sortie < date_trunc('day', now()) + interval '1 day';
```

### État des citernes
```sql
-- Citernes sous seuil de sécurité
select count(*) as citernesSousSeuil
from public.v_citerne_stock_actuel v
join public.citernes c on c.id = v.citerne_id
where v.stock_ambiant < c.capacite_securite;
```

### Produits actifs
```sql
-- Nombre de produits actifs
select count(*) as produitsActifs
from public.produits 
where actif = true;
```

## KPIs consolidés

| KPI | Description | Source |
|-----|-------------|--------|
| `erreurs24h` | Erreurs système dernières 24h | `public.logs` |
| `receptionsJour` | Réceptions du jour | `public.receptions` |
| `sortiesJour` | Sorties du jour | `public.sorties_produit` |
| `citernesSousSeuil` | Citernes sous seuil sécurité | `v_citerne_stock_actuel` + `citernes` |
| `produitsActifs` | Produits actifs | `public.produits` |

## Alertes Admin

- **Erreurs > 10/24h** : Vérifier les logs système
- **Citernes sous seuil > 2** : Alerter la maintenance
- **Réceptions = 0** : Vérifier l'activité opérationnelle
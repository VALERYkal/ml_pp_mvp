# KPIs Directeur — Références de données

## Sources
- `public.receptions` (volume_corrige_15c ou volume_ambiant, `date_reception` DATE)
- `public.sorties_produit` (volume_corrige_15c ou volume_ambiant, `date_sortie` TIMESTAMPTZ)
- `public.v_citerne_stock_actuel` + `public.citernes`

## Filtres temporels (UTC)
- **Réceptions (jour):** `date_reception = YYYY-MM-DD`
- **Sorties (jour):** `date_sortie >= dayStartUTC AND date_sortie < dayEndUTC`

## Calculs

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

### Volumes quotidiens
```sql
-- Volume total réceptions (préférer 15°C si disponible)
select 
  sum(coalesce(volume_corrige_15c, volume_ambiant)) as volumeTotalReceptions
from public.receptions 
where date_reception = current_date;

-- Volume total sorties (préférer 15°C si disponible)
select 
  sum(coalesce(volume_corrige_15c, volume_ambiant)) as volumeTotalSorties
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

-- Ratio d'utilisation global
select 
  sum(v.stock_ambiant) / sum(c.capacite_totale) * 100 as ratioUtilisation
from public.v_citerne_stock_actuel v
join public.citernes c on c.id = v.citerne_id;
```

### Détail par citerne
```sql
-- État détaillé des citernes
select 
  c.nom,
  v.stock_ambiant,
  c.capacite_totale,
  c.capacite_securite,
  round((v.stock_ambiant / c.capacite_totale) * 100, 2) as pourcentage_utilisation,
  (v.stock_ambiant < c.capacite_securite) as sous_seuil
from public.v_citerne_stock_actuel v
join public.citernes c on c.id = v.citerne_id
order by pourcentage_utilisation desc;
```

## KPIs consolidés

| KPI | Description | Source |
|-----|-------------|--------|
| `receptionsJour` | Nombre de réceptions du jour | `public.receptions` |
| `sortiesJour` | Nombre de sorties du jour | `public.sorties_produit` |
| `volumeTotalReceptions` | Volume total réceptions (L) | `public.receptions` |
| `volumeTotalSorties` | Volume total sorties (L) | `public.sorties_produit` |
| `citernesSousSeuil` | Citernes sous seuil sécurité | `v_citerne_stock_actuel` + `citernes` |
| `ratioUtilisation` | Ratio utilisation global (%) | `v_citerne_stock_actuel` + `citernes` |

## Alertes Directeur

- **Ratio utilisation > 90%** : Risque de saturation
- **Citernes sous seuil > 1** : Planification approvisionnement
- **Volume sorties > Volume réceptions** : Vérifier la cohérence
- **Réceptions = 0** : Vérifier l'activité opérationnelle

## Périodes de reporting

- **Quotidien** : Activité du jour en cours
- **Hebdomadaire** : Cumul sur 7 jours glissants
- **Mensuel** : Cumul sur le mois en cours
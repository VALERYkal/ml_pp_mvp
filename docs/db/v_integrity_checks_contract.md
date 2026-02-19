# v_integrity_checks — Contract (Phase 2 / V1)

## Objectif
Vue de contrôle d’intégrité métier et technique (STAGING-first), destinée à :
- détecter des incohérences de stock et des anomalies opérationnelles,
- alimenter ensuite une table `system_alerts` (Phase 2, Action 2/3).

**Non-bloquant** : la vue signale, ne bloque pas les opérations.

## Sources de vérité
- Stock actuel : `public.v_stock_actuel`
- Citernes : `public.citernes`
- Cours de route : `public.cours_de_route`
- Réceptions : `public.receptions`
- Sorties : `public.sorties_produit`

## Format standard (colonnes)
- `check_code` (text)
- `severity` (text: INFO/WARN/CRITICAL)
- `entity_type` (text)
- `entity_id` (uuid)
- `message` (text)
- `payload` (jsonb)
- `detected_at` (timestamptz) — instant de lecture (`now()`)

## Règles (V1)

### A — STOCK_NEGATIF (CRITICAL)
Déclenche si :
- `stock_ambiant < -0.01` **ou**
- `stock_15c < -0.01`

Tolérance flottante : -0.01.

### B — STOCK_OVER_CAPACITY (CRITICAL)
Déclenche si citerne active (`citernes.statut = 'active'`) et :
- `stock_ambiant > capacite_totale - capacite_securite` **ou**
- `stock_15c > capacite_totale - capacite_securite`

Tolérance : 0.

### C — CDR_ARRIVE_STALE (WARN)
Déclenche si :
- `cours_de_route.statut = 'ARRIVE'`
- `cours_de_route.created_at < now() - interval '2 days'`
- aucune réception validée liée (`receptions.cours_de_route_id`, `receptions.statut = 'validee'`)

Note : absence de champ `arrive_at` dans `cours_de_route` → proxy V1 = `created_at`.

### D — RECEPTION_ECART_15C (WARN)
Déclenche si réception validée et écart > 5% :
- `receptions.statut = 'validee'`
- `volume_ambiant > 0`
- `V15C = coalesce(volume_15c, volume_corrige_15c)`
- `abs(V15C - volume_ambiant) / volume_ambiant > 0.05`

### E — SORTIE_ECART_15C (WARN)
Déclenche si sortie validée et écart > 5% :
- `sorties_produit.statut = 'validee'`
- `volume_ambiant > 0`
- `V15C = volume_corrige_15c`
- `abs(V15C - volume_ambiant) / volume_ambiant > 0.05`

## Validation STAGING
Requête :
```sql
select check_code, severity, count(*) cnt
from public.v_integrity_checks
group by check_code, severity;


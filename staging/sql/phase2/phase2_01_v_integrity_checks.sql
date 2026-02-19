-- Phase 2 (V1) — v_integrity_checks
-- STAGING-first. No tables, no triggers, no functions.

create or replace view public.v_integrity_checks as

/* =========================
 * A) STOCK_NEGATIF (CRITICAL)
 * ========================= */
select
  'STOCK_NEGATIF'::text as check_code,
  'CRITICAL'::text      as severity,
  'CITERNE_STOCK'::text as entity_type,
  s.citerne_id          as entity_id,
  'Stock négatif détecté (ambiant ou 15°C).'::text as message,
  jsonb_build_object(
    'depot_id', s.depot_id,
    'citerne_id', s.citerne_id,
    'produit_id', s.produit_id,
    'proprietaire_type', s.proprietaire_type,
    'stock_ambiant', s.stock_ambiant,
    'stock_15c', s.stock_15c,
    'threshold_negative', -0.01
  ) as payload,
  now() as detected_at
from public.v_stock_actuel s
where
  (s.stock_ambiant is not null and s.stock_ambiant < -0.01)
  or
  (s.stock_15c is not null and s.stock_15c < -0.01)

union all

/* ==============================
 * B) STOCK_OVER_CAPACITY (CRITICAL)
 * ============================== */
select
  'STOCK_OVER_CAPACITY'::text as check_code,
  'CRITICAL'::text            as severity,
  'CITERNE_STOCK'::text       as entity_type,
  s.citerne_id                as entity_id,
  'Stock supérieur à la capacité utile sur citerne active.'::text as message,
  jsonb_build_object(
    'citerne_id', s.citerne_id,
    'stock_ambiant', s.stock_ambiant,
    'stock_15c', s.stock_15c,
    'capacite_totale', c.capacite_totale,
    'capacite_securite', c.capacite_securite,
    'capacite_utile', (c.capacite_totale - c.capacite_securite)
  ) as payload,
  now() as detected_at
from public.v_stock_actuel s
join public.citernes c on c.id = s.citerne_id
where
  c.statut = 'active'
  and (
    (s.stock_ambiant is not null and s.stock_ambiant > (c.capacite_totale - c.capacite_securite))
    or
    (s.stock_15c is not null and s.stock_15c > (c.capacite_totale - c.capacite_securite))
  )

union all

/* =========================
 * C) CDR_ARRIVE_STALE (WARN)
 * ========================= */
select
  'CDR_ARRIVE_STALE'::text as check_code,
  'WARN'::text             as severity,
  'CDR'::text              as entity_type,
  cdr.id                   as entity_id,
  'CDR en ARRIVE > 2 jours sans réception validée.'::text as message,
  jsonb_build_object(
    'cours_de_route_id', cdr.id,
    'created_at', cdr.created_at
  ) as payload,
  now() as detected_at
from public.cours_de_route cdr
left join public.receptions r
  on r.cours_de_route_id = cdr.id
  and r.statut = 'validee'
where
  cdr.statut = 'ARRIVE'
  and cdr.created_at < (now() - interval '2 days')
  and r.id is null

union all

/* ==============================
 * D) RECEPTION_ECART_15C (WARN)
 * ============================== */
select
  'RECEPTION_ECART_15C'::text as check_code,
  'WARN'::text                as severity,
  'RECEPTION'::text           as entity_type,
  r.id                        as entity_id,
  'Réception validée avec écart > 5% entre 15°C et ambiant.'::text as message,
  jsonb_build_object(
    'reception_id', r.id,
    'volume_ambiant', r.volume_ambiant,
    'v15c_used', coalesce(r.volume_15c, r.volume_corrige_15c),
    'ecart_percent', round(
      ((abs(coalesce(r.volume_15c, r.volume_corrige_15c) - r.volume_ambiant) 
      / r.volume_ambiant) * 100.0)::numeric,
      3
    )
  ) as payload,
  now() as detected_at
from public.receptions r
where
  r.statut = 'validee'
  and r.volume_ambiant is not null
  and r.volume_ambiant > 0
  and coalesce(r.volume_15c, r.volume_corrige_15c) is not null
  and (abs(coalesce(r.volume_15c, r.volume_corrige_15c) - r.volume_ambiant) 
      / r.volume_ambiant) > 0.05

union all

/* ==========================
 * E) SORTIE_ECART_15C (WARN)
 * ========================== */
select
  'SORTIE_ECART_15C'::text as check_code,
  'WARN'::text             as severity,
  'SORTIE'::text           as entity_type,
  s.id                     as entity_id,
  'Sortie validée avec écart > 5% entre 15°C et ambiant.'::text as message,
  jsonb_build_object(
    'sortie_id', s.id,
    'volume_ambiant', s.volume_ambiant,
    'volume_corrige_15c', s.volume_corrige_15c,
    'ecart_percent', round(
      ((abs(s.volume_corrige_15c - s.volume_ambiant) 
      / s.volume_ambiant) * 100.0)::numeric,
      3
    )
  ) as payload,
  now() as detected_at
from public.sorties_produit s
where
  s.statut = 'validee'
  and s.volume_ambiant is not null
  and s.volume_ambiant > 0
  and s.volume_corrige_15c is not null
  and (abs(s.volume_corrige_15c - s.volume_ambiant) 
      / s.volume_ambiant) > 0.05
;

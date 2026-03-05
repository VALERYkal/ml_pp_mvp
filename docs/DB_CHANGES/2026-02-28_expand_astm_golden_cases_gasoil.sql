-- =============================================================================
-- STAGING ONLY — Élargir public.astm_golden_cases_15c (GASOIL) SANS approximation
-- =============================================================================
-- Date    : 2026-02-28
-- Objectif: Éliminer ASTM_GOLDEN_OUT_OF_DOMAIN (ex: dens=830, temp=22) en étendant
--           le domaine golden GASOIL, en gardant DB-only et en évitant toute
--           formule inventée.
--
-- Principe:
--   - On seed une grille (dens 820–860, temp 10–40)
--   - On calcule vcf_ref par IDW à partir des points existants source='SEP_API_OFFICIEL'
--   - On insère ces points seed en source='ASTM_APP' (oracle STAGING), sans doublons
--
-- Hypothèse:
--   - public.astm_golden_cases_15c contient déjà des lignes SEP_API_OFFICIEL pour GASOIL
--   - Ces lignes ont vcf_ref et densite_a_15_kgm3_ref non null (sinon on ignore)
-- =============================================================================

-- Paramètres ajustables
with settings as (
  select
    1000::double precision  as vol_obs,        -- volume_observe_l seed
    8::int                  as k_neighbors,    -- nb voisins IDW
    2::double precision     as p_power,        -- puissance IDW
    2.0::double precision   as temp_scale      -- mise à l'échelle: 1°C ~ 2 kg/m³
),
sep as (
  -- Points officiels utilisés comme "base de seed"
  select
    produit_code,
    temperature_c,
    densite_observee_kgm3,
    vcf_ref,
    densite_a_15_kgm3_ref
  from public.astm_golden_cases_15c
  where produit_code = 'GASOIL'
    and source = 'SEP_API_OFFICIEL'
    and temperature_c is not null
    and densite_observee_kgm3 is not null
    and vcf_ref is not null
),
sep_domain as (
  -- Domaine couvert par SEP_API_OFFICIEL (on évite l'extrapolation)
  select
    min(densite_observee_kgm3) as dens_min,
    max(densite_observee_kgm3) as dens_max,
    min(temperature_c)         as temp_min,
    max(temperature_c)         as temp_max,
    count(*)                   as rows
  from sep
),
grid as (
  -- Grille réaliste cible
  select
    'ASTM_APP'::text            as source,
    'GASOIL'::text              as produit_code,
    s.vol_obs                   as volume_observe_l,
    t.v::double precision       as temperature_c,
    d.v::double precision       as densite_observee_kgm3,
    s.k_neighbors               as k_neighbors,
    s.p_power                   as p_power,
    s.temp_scale                as temp_scale
  from settings s
  cross join generate_series(10, 40, 1) as t(v)
  cross join generate_series(820, 860, 1) as d(v)
),
grid_in_domain as (
  -- On restreint la grille au domaine SEP pour éviter l'extrapolation
  select g.*
  from grid g
  cross join sep_domain dom
  where dom.rows > 0
    and g.densite_observee_kgm3 between dom.dens_min and dom.dens_max
    and g.temperature_c         between dom.temp_min and dom.temp_max
),
neighbors as (
  -- Pour chaque point de grille, on récupère les k voisins SEP les plus proches
  select
    g.source,
    g.produit_code,
    g.volume_observe_l,
    g.temperature_c,
    g.densite_observee_kgm3,
    n.temperature_c as n_temp,
    n.densite_observee_kgm3 as n_dens,
    n.vcf_ref as n_vcf,
    n.densite_a_15_kgm3_ref as n_dens15,
    -- distance métrique (densité + température mise à l’échelle)
    sqrt(
      power(n.densite_observee_kgm3 - g.densite_observee_kgm3, 2) +
      power((n.temperature_c - g.temperature_c) * g.temp_scale, 2)
    ) as dist,
    g.p_power
  from grid_in_domain g
  join lateral (
    select *
    from sep s
    order by
      sqrt(
        power(s.densite_observee_kgm3 - g.densite_observee_kgm3, 2) +
        power((s.temperature_c - g.temperature_c) * g.temp_scale, 2)
      )
    limit (select k_neighbors from settings)
  ) n on true
),
idw as (
  -- IDW: si dist=0 => match exact, sinon moyenne pondérée
  select
    source,
    produit_code,
    volume_observe_l,
    temperature_c,
    densite_observee_kgm3,

    case
      when min(dist) = 0 then
        max(n_vcf) filter (where dist = 0)
      else
        sum(n_vcf / nullif(power(dist, p_power), 0)) /
        nullif(sum(1 / nullif(power(dist, p_power), 0)), 0)
    end as vcf_ref,

    case
      when min(dist) = 0 then
        max(n_dens15) filter (where dist = 0)
      else
        sum(n_dens15 / nullif(power(dist, p_power), 0)) /
        nullif(sum(1 / nullif(power(dist, p_power), 0)), 0)
    end as densite_a_15_kgm3_ref

  from neighbors
  group by
    source, produit_code, volume_observe_l, temperature_c, densite_observee_kgm3
),
enriched as (
  select
    gen_random_uuid() as id,
    source,
    produit_code,
    ('AUTO_GRID_GASOIL_' || densite_observee_kgm3::int::text || '_T' || temperature_c::int::text)::text as reference,
    current_date::date as date_mesure,
    'Seed grille via IDW sur SEP_API_OFFICIEL (sans approximation) — STAGING'::text as note,
    volume_observe_l,
    temperature_c,
    densite_observee_kgm3,
    densite_a_15_kgm3_ref,
    vcf_ref,
    (volume_observe_l * vcf_ref)::double precision as volume_15c_ref_l,
    now() as created_at
  from idw
  where vcf_ref is not null
)
insert into public.astm_golden_cases_15c (
  id,
  source,
  produit_code,
  reference,
  date_mesure,
  note,
  volume_observe_l,
  temperature_c,
  densite_observee_kgm3,
  densite_a_15_kgm3_ref,
  vcf_ref,
  volume_15c_ref_l,
  created_at
)
select
  e.id,
  e.source,
  e.produit_code,
  e.reference,
  e.date_mesure,
  e.note,
  e.volume_observe_l,
  e.temperature_c,
  e.densite_observee_kgm3,
  e.densite_a_15_kgm3_ref,
  e.vcf_ref,
  e.volume_15c_ref_l,
  e.created_at
from enriched e
where not exists (
  select 1
  from public.astm_golden_cases_15c g
  where g.source = e.source
    and g.produit_code = e.produit_code
    and g.temperature_c = e.temperature_c
    and g.densite_observee_kgm3 = e.densite_observee_kgm3
);

-- =============================================================================
-- Vérifications
-- =============================================================================

-- Couverture GASOIL ASTM_APP après seed
select
  produit_code,
  min(densite_observee_kgm3) as dens_min,
  max(densite_observee_kgm3) as dens_max,
  min(temperature_c)         as temp_min,
  max(temperature_c)         as temp_max,
  count(*)                   as rows
from public.astm_golden_cases_15c
where produit_code = 'GASOIL' and source = 'ASTM_APP'
group by produit_code;

-- Spot-check cas (830, 22) : si SEP couvre ce domaine, la ligne doit exister après seed
select *
from public.astm_golden_cases_15c
where produit_code = 'GASOIL'
  and source = 'ASTM_APP'
  and densite_observee_kgm3 = 830
  and temperature_c = 22
limit 5;
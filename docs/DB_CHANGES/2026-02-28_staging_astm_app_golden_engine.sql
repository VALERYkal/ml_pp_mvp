-- STAGING ONLY
-- Checkpoint: ASTM_APP Golden Engine (Stability Mode) — 2026-02-28
-- Decision: align volumetrics to field app "ASTM" oracle (ASTM_APP) for immediate stability.
-- Not an API MPMS 11.1 / ASTM D1250 certified engine. Domain-limited to golden cases.
-- Anti-PROD: guarded by public.app_settings.env == 'staging'. If not staging -> block inserts.

-- 0) Persistent env flag (Supabase-safe; avoids ALTER ROLE)
create table if not exists public.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

insert into public.app_settings (key, value)
values ('env', 'staging')
on conflict (key) do update
set value = excluded.value,
    updated_at = now();

-- 1) Golden-calibrated CTL from oracle dataset (IDW interpolation)
create or replace function astm.ctl_from_golden(
  p_produit_code text,
  p_density_obs_kgm3 double precision,
  p_temperature_c double precision
)
returns double precision
language plpgsql
as $$
declare
  v_count int;
  v_ctl double precision;
begin
  select count(*) into v_count
  from public.astm_golden_cases_15c
  where source = 'ASTM_APP'
    and produit_code = p_produit_code;

  if v_count < 5 then
    raise exception 'ASTM_GOLDEN_INSUFFICIENT: need >=5 rows for produit_code=%', p_produit_code;
  end if;

  -- Domain guardrails (min/max observed)
  if p_density_obs_kgm3 < (
      select min(densite_observee_kgm3) from public.astm_golden_cases_15c
      where source='ASTM_APP' and produit_code=p_produit_code
    )
    or p_density_obs_kgm3 > (
      select max(densite_observee_kgm3) from public.astm_golden_cases_15c
      where source='ASTM_APP' and produit_code=p_produit_code
    )
    or p_temperature_c < (
      select min(temperature_c) from public.astm_golden_cases_15c
      where source='ASTM_APP' and produit_code=p_produit_code
    )
    or p_temperature_c > (
      select max(temperature_c) from public.astm_golden_cases_15c
      where source='ASTM_APP' and produit_code=p_produit_code
    )
  then
    raise exception
      'ASTM_GOLDEN_OUT_OF_DOMAIN: produit=% density=% temp=%',
      p_produit_code, p_density_obs_kgm3, p_temperature_c;
  end if;

  -- 2 nearest points (euclidean distance) + inverse-distance weighting (IDW)
  with base as (
    select
      g.*,
      (g.volume_15c_ref_l / g.volume_observe_l) as ctl_exact,
      sqrt(
        power(g.densite_observee_kgm3 - p_density_obs_kgm3, 2) +
        power(g.temperature_c - p_temperature_c, 2)
      ) as dist
    from public.astm_golden_cases_15c g
    where g.source = 'ASTM_APP'
      and g.produit_code = p_produit_code
  ),
  nearest as (
    select * from base
    order by dist asc
    limit 2
  ),
  weights as (
    select
      case when dist = 0 then 1e9 else 1.0 / dist end as w,
      ctl_exact
    from nearest
  )
  select
    sum(w * ctl_exact) / sum(w)
  into v_ctl
  from weights;

  if v_ctl is null then
    raise exception 'ASTM_GOLDEN_CTL_NULL: produit=%', p_produit_code;
  end if;

  return v_ctl;
end;
$$;

-- 2) Compute 15C outputs from golden CTL
create or replace function astm.compute_15c_from_golden(
  p_produit_code text,
  p_volume_observe_l double precision,
  p_density_obs_kgm3 double precision,
  p_temperature_c double precision
)
returns table (
  ctl double precision,
  volume_15c_l double precision,
  density_15_kgm3 double precision
)
language plpgsql
as $$
declare
  v_ctl double precision;
begin
  if p_volume_observe_l is null or p_volume_observe_l <= 0 then
    raise exception 'ASTM_INVALID_INPUT: volume_observe_l=%', p_volume_observe_l;
  end if;
  if p_density_obs_kgm3 is null or p_density_obs_kgm3 <= 0 then
    raise exception 'ASTM_INVALID_INPUT: density_obs_kgm3=%', p_density_obs_kgm3;
  end if;
  if p_temperature_c is null then
    raise exception 'ASTM_INVALID_INPUT: temperature_c is null';
  end if;

  v_ctl := astm.ctl_from_golden(p_produit_code, p_density_obs_kgm3, p_temperature_c);

  ctl := v_ctl;
  volume_15c_l := p_volume_observe_l * v_ctl;
  density_15_kgm3 := p_density_obs_kgm3 / v_ctl;

  return next;
end;
$$;

-- 3) BEFORE INSERT trigger on receptions (STAGING ONLY)
create or replace function public.receptions_compute_15c_before_ins()
returns trigger
language plpgsql
as $$
declare
  v_env text;
  v_volume_ambiant double precision;
  v_density_obs double precision;
  v_temp double precision;
  r record;
begin
  -- persistent env flag
  select value into v_env
  from public.app_settings
  where key = 'env';

  v_env := coalesce(v_env, 'unknown');

  if v_env <> 'staging' then
    raise exception
      'RECEPTION_VOLUMETRICS_BLOCKED: golden engine is STAGING ONLY. env=%',
      v_env;
  end if;

  -- STAGING: force legacy/app-provided volume_corrige_15c to NULL to avoid divergence.
  -- DB is the source of truth for volume_15c during ASTM validation.
  new.volume_corrige_15c := null;

  -- compute volume_ambiant if missing
  v_volume_ambiant := new.volume_ambiant;
  if v_volume_ambiant is null then
    if new.index_avant is null or new.index_apres is null then
      raise exception 'RECEPTION_INPUT_MISSING: provide volume_ambiant OR (index_avant,index_apres)';
    end if;
    v_volume_ambiant := new.index_apres - new.index_avant;
    new.volume_ambiant := v_volume_ambiant;
  end if;

  -- temperature input
  v_temp := new.temperature_ambiante_c;
  if v_temp is null then
    raise exception 'RECEPTION_INPUT_MISSING: temperature_ambiante_c';
  end if;

  -- TEMPORARY legacy naming:
  -- densite_a_15_kgm3 is used as INPUT density observed (kg/m3) until receptions schema is refactored.
  v_density_obs := new.densite_a_15_kgm3;
  if v_density_obs is null then
    raise exception 'RECEPTION_INPUT_MISSING: densite_observee_kgm3 (temporarily stored in densite_a_15_kgm3)';
  end if;

  begin
    select *
    into r
    from astm.compute_15c_from_golden(
      'GASOIL',
      v_volume_ambiant,
      v_density_obs,
      v_temp
    );
  exception
    when others then
      raise exception
        'RECEPTION_VOLUMETRICS_FAILED: cannot compute Volume@15 using ASTM_APP golden engine. '
        'Inputs: volume_ambiant=%, densite_obs_kgm3=%, temp_c=%. '
        'Cause: %. '
        'Action: add a matching row to public.astm_golden_cases_15c (source=ASTM_APP, produit_code=GASOIL) '
        'covering this density/temp domain, then retry.',
        v_volume_ambiant, v_density_obs, v_temp, sqlerrm;
  end;

  -- lock terrain rounding (unit liters)
  new.volume_15c := round(r.volume_15c_l)::double precision;

  -- computed density @15
  new.densite_a_15_kgm3 := r.density_15_kgm3;
  new.densite_a_15_g_cm3 := r.density_15_kgm3 / 1000.0;

  return new;
end;
$$;

drop trigger if exists trg_receptions_compute_15c_before_ins on public.receptions;

create trigger trg_receptions_compute_15c_before_ins
before insert on public.receptions
for each row
execute function public.receptions_compute_15c_before_ins();

-- 4) Validation query (read-only) — expected: v15_db == v15_oracle (unit liters)
-- select
--   reference,
--   volume_observe_l,
--   temperature_c,
--   densite_observee_kgm3,
--   volume_15c_ref_l as v15_oracle,
--   round(
--     (volume_observe_l * astm.ctl_from_golden('GASOIL', densite_observee_kgm3, temperature_c))::numeric,
--     0
--   ) as v15_db
-- from public.astm_golden_cases_15c
-- where source='ASTM_APP'
-- order by reference;

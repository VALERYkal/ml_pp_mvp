-- =============================================================================
-- STAGING ONLY — Force volume_corrige_15c = NULL in receptions trigger
-- =============================================================================
-- Date    : 2026-02-28
-- Objectif: En STAGING, la DB est la seule source de vérité pour le volume @15.
--           Même si l'app envoie encore volume_corrige_15c (legacy), le trigger
--           le force à NULL pour éviter toute divergence avec volume_15c (lookup-grid).
-- Idempotent: CREATE OR REPLACE.
-- Prérequis: public.app_settings(key='env') = 'staging', trigger déjà déployé.
-- =============================================================================

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
    -- Also accept densite_observee_kgm3 if present (app canonical input)
    v_density_obs := new.densite_observee_kgm3;
  end if;
  if v_density_obs is null then
    raise exception 'RECEPTION_INPUT_MISSING: densite_observee_kgm3 (or densite_a_15_kgm3)';
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

-- =============================================================================
-- VÉRIFICATION (exécuter manuellement après déploiement, env=staging)
-- =============================================================================
-- 1) INSERT test en envoyant explicitement volume_corrige_15c non-null (simule app legacy).
--    Adapter citerne_id / produit_id si besoin pour votre schéma.
/*
insert into public.receptions (
  citerne_id, produit_id, index_avant, index_apres,
  temperature_ambiante_c, densite_observee_kgm3,
  volume_corrige_15c, statut, note
) values (
  '905b3104-0324-4b5c-ba3d-ae1019746c70',
  '22222222-2222-2222-2222-222222222222',
  0, 1000,
  22, 830,
  995.45,
  'validee',
  'TEST_FORCE_NULL_VOLUME_CORRIGE_STAGING'
)
returning id;
*/

-- 2) Vérifier que la ligne a volume_corrige_15c IS NULL et volume_15c IS NOT NULL.
/*
select id, volume_corrige_15c, volume_15c, densite_observee_kgm3, densite_a_15_kgm3
from public.receptions
where note = 'TEST_FORCE_NULL_VOLUME_CORRIGE_STAGING'
order by created_at desc
limit 1;
*/
-- Attendu: volume_corrige_15c = NULL, volume_15c ≈ 994, densite_a_15_kgm3 ≈ 834.9

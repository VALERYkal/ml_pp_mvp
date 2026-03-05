-- STAGING ONLY — Golden Engine sorties_produit (ASTM_APP oracle)
-- Date: 2026-02-28
-- Objectif: calculer volume_corrige_15c via golden engine + arrondi litre
-- Garde-fou: bloque si env != 'staging'

create or replace function astm.fn_sortie_compute_golden_15c()
returns trigger
language plpgsql
as $$
declare
  v_env text;
  r record;
begin
  -- 🔒 Garde-fou anti PROD
  select value into v_env
  from public.app_settings
  where key = 'env';

  if v_env is distinct from 'staging' then
    raise exception 'SORTIE_VOLUMETRICS_BLOCKED: not in staging';
  end if;

  -- Champs requis (densité observée, température, volume)
  if new.densite_a_15_kgm3 is null then
    raise exception 'DENSITE_OBSERVEE_REQUIRED';
  end if;

  if new.temperature_ambiante_c is null then
    raise exception 'TEMPERATURE_REQUIRED';
  end if;

  -- Si volume ambiant absent mais index fournis
  if new.volume_ambiant is null
     and new.index_avant is not null
     and new.index_apres is not null then
    new.volume_ambiant := new.index_apres - new.index_avant;
  end if;

  if new.volume_ambiant is null then
    raise exception 'VOLUME_AMBIANT_REQUIRED';
  end if;

  -- 🔥 Golden engine
  select *
  into r
  from astm.compute_15c_from_golden(
    new.volume_ambiant,
    new.temperature_ambiante_c,
    new.densite_a_15_kgm3
  );

  -- 🎯 Arrondi litre unité (comme réception)
  new.volume_corrige_15c := round(r.volume_15c_l);

  return new;
end;
$$;

drop trigger if exists trg_sortie_compute_golden_15c
on public.sorties_produit;

create trigger trg_sortie_compute_golden_15c
before insert on public.sorties_produit
for each row
execute function astm.fn_sortie_compute_golden_15c();

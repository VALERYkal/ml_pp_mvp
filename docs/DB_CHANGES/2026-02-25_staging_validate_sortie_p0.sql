-- =============================================================================
-- 2026-02-25_staging_validate_sortie_p0.sql
-- =============================================================================
-- Date/heure    : 2026-02-25
-- Contexte      : DB tests STAGING B2.2 (test/integration/sortie_stock_log_test.dart)
-- Pourquoi      : Autoriser UPDATE contrôlé pendant la RPC validate_sortie
--                 + autoriser UPDATE stocks_journaliers pendant la validation.
-- Rappel        : Script STAGING-only. À répliquer en PROD après runbook.
-- =============================================================================
-- Contenu       : 2 fonctions uniquement (pas de triggers, policies, tables, grants).
-- =============================================================================

-- 1) Trigger function: bloque UPDATE/DELETE sur sorties_produit sauf si flag activé
CREATE OR REPLACE FUNCTION public.sorties_produit_block_update_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if current_setting('app.sorties_produit_allow_write', true) = '1' then
    if tg_op = 'DELETE' then return old; else return new; end if;
  end if;
  raise exception
    'Ecriture interdite sur sorties_produit (op=%). Table immutable: utiliser INSERT + triggers/RPC, jamais UPDATE/DELETE.',
    tg_op;
end;
$$;

-- 2) RPC validate_sortie: set_config au tout début du begin pour autoriser écritures
CREATE OR REPLACE FUNCTION public.validate_sortie(p_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_role text := public._current_role();
  v_row record;
  v_today date;
  v_stock_avant double precision;
  v_v15 double precision;
begin
  perform set_config('app.stocks_journaliers_allow_write','1', true);
  perform set_config('app.sorties_produit_allow_write','1', true);

  if coalesce(v_role,'') not in ('admin','directeur','gerant') then
    raise exception 'ROLE_FORBIDDEN';
  end if;

  -- ✅ CHANGE ICI : accepter NULL (pending) ou 'brouillon'
  select s.*
  into v_row
  from public.sorties_produit s
  where s.id = p_id
    and (s.statut is null or s.statut = 'brouillon')
  for update;

  if not found then
    raise exception 'INVALID_ID_OR_STATE';
  end if;

  if v_row.client_id is null and v_row.partenaire_id is null then
    raise exception 'BENEFICIAIRE_REQUIRED';
  end if;

  perform 1
  from public.citernes c
  where c.id = v_row.citerne_id
    and c.produit_id = v_row.produit_id
    and c.statut = 'active';
  if not found then
    raise exception 'CITERNE_INACTIVE_OR_INCOMPATIBLE';
  end if;

  if v_row.volume_ambiant is null then
    if v_row.index_avant is null or v_row.index_apres is null then
      raise exception 'INDICES_MANQUANTS';
    end if;
    if v_row.index_apres <= v_row.index_avant then
      raise exception 'INDEX_INCOHERENTS (% >= %)', v_row.index_apres, v_row.index_avant;
    end if;
    v_row.volume_ambiant := v_row.index_apres - v_row.index_avant;
  end if;
  if v_row.volume_ambiant <= 0 then
    raise exception 'VOLUME_AMBIANT_NON_POSITIF';
  end if;

  v_today := coalesce(date(v_row.date_sortie), current_date);

  insert into public.stocks_journaliers(id, citerne_id, produit_id, date_jour, stock_ambiant, stock_15c)
  select gen_random_uuid(), v_row.citerne_id, v_row.produit_id, v_today,
         coalesce((
           select sj2.stock_ambiant
           from public.stocks_journaliers sj2
           where sj2.citerne_id = v_row.citerne_id
             and sj2.produit_id = v_row.produit_id
           order by sj2.date_jour desc
           limit 1
         ), 0)::double precision,
         coalesce((
           select sj2.stock_15c
           from public.stocks_journaliers sj2
           where sj2.citerne_id = v_row.citerne_id
             and sj2.produit_id = v_row.produit_id
           order by sj2.date_jour desc
           limit 1
         ), 0)::double precision
  where not exists (
    select 1 from public.stocks_journaliers sj
    where sj.citerne_id = v_row.citerne_id
      and sj.produit_id = v_row.produit_id
      and sj.date_jour = v_today
  );

  select sj.stock_ambiant
  into v_stock_avant
  from public.stocks_journaliers sj
  where sj.citerne_id = v_row.citerne_id
    and sj.produit_id = v_row.produit_id
    and sj.date_jour = v_today
  for update;

  if coalesce(v_stock_avant,0) < v_row.volume_ambiant then
    raise exception 'INSUFFICIENT_STOCK';
  end if;

  v_v15 := coalesce(v_row.volume_corrige_15c, v_row.volume_ambiant);

  update public.stocks_journaliers sj
  set stock_ambiant = greatest(0, sj.stock_ambiant - v_row.volume_ambiant),
      stock_15c     = greatest(0, sj.stock_15c - v_v15)
  where sj.citerne_id = v_row.citerne_id
    and sj.produit_id = v_row.produit_id
    and sj.date_jour  = v_today;

  update public.sorties_produit s
  set statut       = 'validee',
      validated_by = auth.uid(),
      date_sortie  = coalesce(s.date_sortie, now())
  where s.id = p_id;

  insert into public.log_actions(id, user_id, action, module, niveau, details)
  values (gen_random_uuid(), auth.uid(), 'SORTIE_VALIDEE', 'sorties', 'INFO',
          jsonb_build_object(
            'sortie_id', p_id,
            'citerne_id', v_row.citerne_id,
            'produit_id', v_row.produit_id,
            'volume_ambiant', v_row.volume_ambiant,
            'volume_15c', v_v15,
            'date_jour', v_today
          ));
end
$$;

--
-- PostgreSQL database dump
--

\restrict 47igivqcSe68Pczp7dbpiw7Kw6ZX5UDLC90e05hl7Rf56ayxssMNm51rz4ADXs6

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: _current_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public._current_role() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select pr.role
  from public.profils pr
  where pr.user_id = auth.uid()
  order by pr.created_at desc
  limit 1;
$$;


--
-- Name: create_sortie(uuid, uuid, timestamp with time zone, double precision, double precision, double precision, text, uuid, text, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_sortie(citerne_id uuid, client_id uuid, date_sortie timestamp with time zone, densite_a_15 double precision, index_apres double precision, index_avant double precision, note text DEFAULT NULL::text, produit_id uuid DEFAULT NULL::uuid, proprietaire_type text DEFAULT 'MONALUXE'::text, temperature_ambiante_c double precision DEFAULT NULL::double precision, volume_corrige_15c double precision DEFAULT NULL::double precision) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_new_id          uuid;
  v_volume_ambiant  double precision;
begin
  -- Calcul du volume ambiant à partir des index
  if index_apres is not null and index_avant is not null then
    v_volume_ambiant := index_apres - index_avant;
  else
    v_volume_ambiant := null;
  end if;

  -- Insertion dans sorties_produit
  insert into public.sorties_produit (
    citerne_id,
    produit_id,
    client_id,
    volume_corrige_15c,
    temperature_ambiante_c,
    densite_a_15,
    proprietaire_type,
    note,
    created_at,
    index_avant,
    index_apres,
    volume_ambiant,
    statut,
    date_sortie
  )
  values (
    citerne_id,
    produit_id,
    client_id,
    volume_corrige_15c,
    temperature_ambiante_c,
    densite_a_15,
    proprietaire_type,
    note,
    now(),
    index_avant,
    index_apres,
    v_volume_ambiant,
    'validee',
    date_sortie
  )
  returning id into v_new_id;

  -- Log action
  insert into public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details,
    created_at
  )
  values (
    auth.uid(),
    'SORTIE_CREEE',
    'SORTIES',
    'INFO',
    jsonb_build_object(
      'sortie_id', v_new_id,
      'citerne_id', citerne_id,
      'client_id', client_id,
      'proprietaire_type', proprietaire_type,
      'produit_id', produit_id,
      'volume_ambiant', v_volume_ambiant,
      'volume_corrige_15c', volume_corrige_15c
    ),
    now()
  );

  return v_new_id;
end;
$$;


--
-- Name: fn_sorties_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_sorties_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_citerne            public.citernes%ROWTYPE;
  v_date_jour          date;
  v_volume_ambiant     double precision;
  v_volume_15c         double precision;
  v_proprietaire_type  text;
  v_depot_id           uuid;
BEGIN
  ----------------------------------------------------------------------
  -- 1. Ne traiter que les sorties "validees"
  ----------------------------------------------------------------------
  IF NEW.statut IS DISTINCT FROM 'validee' THEN
    RETURN NEW;
  END IF;

  ----------------------------------------------------------------------
  -- 2. Charger et vérifier la citerne
  ----------------------------------------------------------------------
  SELECT c.*
  INTO v_citerne
  FROM public.citernes c
  WHERE c.id = NEW.citerne_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - citerne introuvable: %',
      NEW.citerne_id;
  END IF;

  IF v_citerne.statut <> 'active' THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - citerne inactive ou en maintenance: % (statut=%)',
      NEW.citerne_id, v_citerne.statut;
  END IF;

  IF v_citerne.produit_id IS DISTINCT FROM NEW.produit_id THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - produit incompatible pour la citerne: citerne %, produit_citerne %, produit_sortie %',
      NEW.citerne_id, v_citerne.produit_id, NEW.produit_id;
  END IF;

  v_depot_id := v_citerne.depot_id;

  ----------------------------------------------------------------------
  -- 3. Normaliser la date du mouvement (date_jour)
  ----------------------------------------------------------------------
  v_date_jour :=
      COALESCE(
        NEW.date_sortie::date,
        NEW.created_at::date,
        CURRENT_DATE
      );

  ----------------------------------------------------------------------
  -- 4. Calcul des volumes (ambiant & 15°C) avec fallback indices
  ----------------------------------------------------------------------
  v_volume_ambiant := NEW.volume_ambiant;

  -- Si volume_ambiant nul mais indices présents → on calcule
  IF v_volume_ambiant IS NULL
     AND NEW.index_avant IS NOT NULL
     AND NEW.index_apres IS NOT NULL
  THEN
    v_volume_ambiant := NEW.index_apres - NEW.index_avant;
  END IF;

  v_volume_15c := NEW.volume_corrige_15c;

  -- Si 15°C nul → fallback sur volume_ambiant (comportement MVP)
  IF v_volume_15c IS NULL THEN
    v_volume_15c := v_volume_ambiant;
  END IF;

  IF v_volume_ambiant IS NULL OR v_volume_15c IS NULL THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - volumes non calculables pour la sortie %',
      NEW.id;
  END IF;

  ----------------------------------------------------------------------
  -- 5. Normalisation du proprietaire_type (depuis la SORTIE, pas la citerne)
  ----------------------------------------------------------------------
  v_proprietaire_type :=
      UPPER(TRIM(COALESCE(NEW.proprietaire_type, 'MONALUXE')));

  IF v_proprietaire_type NOT IN ('MONALUXE', 'PARTENAIRE') THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - proprietaire_type invalide: %',
      v_proprietaire_type;
  END IF;

  ----------------------------------------------------------------------
  -- 6. Cohérence client / partenaire selon le propriétaire
  ----------------------------------------------------------------------
  IF v_proprietaire_type = 'MONALUXE' AND NEW.client_id IS NULL THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - client_id requis pour une sortie MONALUXE (sortie=%)',
      NEW.id;
  END IF;

  IF v_proprietaire_type = 'PARTENAIRE' AND NEW.partenaire_id IS NULL THEN
    RAISE EXCEPTION
      'fn_sorties_after_insert() - partenaire_id requis pour une sortie PARTENAIRE (sortie=%)',
      NEW.id;
  END IF;

  ----------------------------------------------------------------------
  -- 7. Upsert dans stocks_journaliers (débit = volumes négatifs)
  ----------------------------------------------------------------------
  PERFORM public.stock_upsert_journalier(
      NEW.citerne_id,
      NEW.produit_id,
      v_date_jour,
      -v_volume_ambiant,
      -v_volume_15c,
      v_proprietaire_type,
      v_depot_id,
      'SORTIE'
  );

  ----------------------------------------------------------------------
  -- 8. Journalisation dans log_actions
  ----------------------------------------------------------------------
  INSERT INTO public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details,
    cible_id
  )
  VALUES (
    NEW.created_by,
    'SORTIE_CREEE',
    'SORTIE',      -- ou 'sorties' si tu préfères rester en minuscule partout
    'INFO',
    jsonb_build_object(
      'sortie_id',         NEW.id,
      'citerne_id',        NEW.citerne_id,
      'produit_id',        NEW.produit_id,
      'volume_ambiant',    v_volume_ambiant,
      'volume_15c',        v_volume_15c,
      'proprietaire_type', v_proprietaire_type,
      'client_id',         NEW.client_id,
      'partenaire_id',     NEW.partenaire_id,
      'date_jour',         v_date_jour,
      'depot_id',          v_depot_id
    ),
    NEW.id  -- cible_id = id de la sortie
  );

  RETURN NEW;
END;
$$;


--
-- Name: get_last_stock_ambiant(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_last_stock_ambiant(p_citerne uuid, p_produit uuid) RETURNS double precision
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE((
    SELECT s.stock_ambiant
    FROM public.stocks_journaliers s
    WHERE s.citerne_id = p_citerne
      AND s.produit_id = p_produit
    ORDER BY s.date_jour DESC
    LIMIT 1
  ), 0::double precision)
$$;


--
-- Name: increment_stock_journalier(date, uuid, uuid, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_stock_journalier(p_date date, p_citerne uuid, p_produit uuid, p_ambiant double precision, p_15c double precision) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO public.stocks_journaliers
    (date_jour, citerne_id, produit_id, stock_ambiant, stock_15c)
  VALUES
    (p_date, p_citerne, p_produit, p_ambiant, p_15c)
  ON CONFLICT (date_jour, citerne_id, produit_id)
  DO UPDATE SET
    stock_ambiant = public.stocks_journaliers.stock_ambiant + EXCLUDED.stock_ambiant,
    stock_15c     = public.stocks_journaliers.stock_15c + EXCLUDED.stock_15c;
END;
$$;


--
-- Name: log_action_sortie(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_action_sortie(p_sortie_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  s          public.sorties_produit%ROWTYPE;
  v_depot_id uuid;
BEGIN
  -- On recharge la sortie pour construire un JSON complet
  SELECT *
  INTO s
  FROM public.sorties_produit
  WHERE id = p_sortie_id;

  IF NOT FOUND THEN
    RAISE NOTICE 'log_action_sortie: sortie % introuvable', p_sortie_id;
    RETURN;
  END IF;

  -- Récupérer le dépôt via la citerne
  SELECT c.depot_id
  INTO v_depot_id
  FROM public.citernes c
  WHERE c.id = s.citerne_id;

  -- Insérer dans log_actions avec un JSON détaillé
  INSERT INTO public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details
  )
  VALUES (
    s.created_by,              -- utilisateur qui a créé la sortie (si présent)
    'SORTIE_CREEE',            -- code d'action
    'SORTIE',                  -- module concerné
    'INFO',                    -- niveau
    jsonb_build_object(
      'sortie_id',            s.id,
      'citerne_id',           s.citerne_id,
      'produit_id',           s.produit_id,
      'client_id',            s.client_id,
      'partenaire_id',        s.partenaire_id,
      'proprietaire_type',    s.proprietaire_type,
      'volume_ambiant',       s.volume_ambiant,
      'volume_15c',           s.volume_corrige_15c,
      'temperature_ambiante_c', s.temperature_ambiante_c,
      'densite_a_15',         s.densite_a_15,
      'depot_id',             v_depot_id,
      'statut',               s.statut,
      'date_sortie',          s.date_sortie,
      'chauffeur_nom',        s.chauffeur_nom,
      'plaque_camion',        s.plaque_camion,
      'plaque_remorque',      s.plaque_remorque,
      'transporteur',         s.transporteur,
      'note',                 s.note,
      'created_at',           s.created_at,
      'source',               'TRIGGER_SORTIE'
    )
  );
END;
$$;


--
-- Name: rebuild_stocks_journaliers(uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.rebuild_stocks_journaliers(p_depot_id uuid DEFAULT NULL::uuid, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  -- Autoriser les écritures contrôlées pendant le rebuild
  perform set_config('app.stocks_journaliers_allow_write', '1', true);

  -- 1) Nettoyage des anciennes lignes rebuild/system (si présentes)
  delete from public.stocks_journaliers sj
  using public.citernes c
  where sj.citerne_id = c.id
    and sj.source in ('SYSTEM','REBUILD')
    and (p_depot_id is null or c.depot_id = p_depot_id)
    and (p_start_date is null or sj.date_jour >= p_start_date)
    and (p_end_date is null or sj.date_jour <= p_end_date);

  -- 2) Rebuild depuis les mouvements (déjà normalisés)
  insert into public.stocks_journaliers (
    citerne_id,
    produit_id,
    date_jour,
    stock_ambiant,
    stock_15c,
    proprietaire_type,
    depot_id,
    source,
    created_at,
    updated_at
  )
  select
    m.citerne_id,
    m.produit_id,
    m.date_jour,
    m.cum_ambiant,
    m.cum_15c,
    m.proprietaire_type,
    m.depot_id,
    'SYSTEM' as source,
    now() as created_at,
    now() as updated_at
  from (
    select
      date_jour,
      citerne_id,
      produit_id,
      depot_id,
      proprietaire_type,
      sum(delta_ambiant) over (
        partition by citerne_id, produit_id, depot_id, proprietaire_type
        order by date_jour
        rows between unbounded preceding and current row
      ) as cum_ambiant,
      sum(delta_15c) over (
        partition by citerne_id, produit_id, depot_id, proprietaire_type
        order by date_jour
        rows between unbounded preceding and current row
      ) as cum_15c
    from (
      select
        date_jour,
        citerne_id,
        produit_id,
        depot_id,
        proprietaire_type,
        sum(delta_ambiant) as delta_ambiant,
        sum(delta_15c)     as delta_15c
      from public.v_mouvements_stock
      where (p_depot_id is null or depot_id = p_depot_id)
        and (p_start_date is null or date_jour >= p_start_date)
        and (p_end_date is null or date_jour <= p_end_date)
      group by date_jour, citerne_id, produit_id, depot_id, proprietaire_type
    ) d
  ) m
  order by m.date_jour, m.citerne_id;
end;
$$;


--
-- Name: reception_after_ins_trg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reception_after_ins_trg() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_date     date := COALESCE(NEW.date_reception, current_date);
  v_depot_id uuid;
BEGIN
  -- ✅ Autoriser l'écriture contrôlée dans stocks_journaliers pour cette transaction (triggers only)
  PERFORM set_config('app.stocks_journaliers_allow_write', '1', true);

  -- Récupérer le dépôt lié à la citerne (pour alimenter stocks_journaliers.depot_id)
  SELECT c.depot_id
    INTO v_depot_id
    FROM public.citernes c
   WHERE c.id = NEW.citerne_id;

  -- 1) Créditer le journal (DELTA agrégé du jour) - existant
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id,
    NEW.produit_id,
    v_date,
    NEW.volume_ambiant,
    COALESCE(NEW.volume_15c, NEW.volume_corrige_15c),
    NEW.proprietaire_type,
    v_depot_id,
    'RECEPTION'
  );

  -- ✅ 1bis) Créditer le SNAPSHOT (stock réel) - nouveau
  PERFORM public.stock_snapshot_apply_delta(
    NEW.citerne_id,
    NEW.produit_id,
    NEW.proprietaire_type,
    COALESCE(NEW.volume_ambiant, 0),
    COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0),
    v_depot_id,
    NEW.created_at
  );

  -- 2) Si rattachée à un CDR, le passer à DECHARGE
  IF NEW.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route
       SET statut = 'DECHARGE'
     WHERE id = NEW.cours_de_route_id
       AND statut <> 'DECHARGE';
  END IF;

  -- 3) Journalisation
  INSERT INTO public.log_actions (user_id, action, module, niveau, details)
  VALUES (
    NEW.created_by,
    'RECEPTION_VALIDE',
    'receptions',
    'INFO',
    jsonb_build_object(
      'reception_id',      NEW.id,
      'citerne_id',        NEW.citerne_id,
      'produit_id',        NEW.produit_id,
      'volume_ambiant',    NEW.volume_ambiant,
      'volume_15c',        COALESCE(NEW.volume_15c, NEW.volume_corrige_15c),
      'date_reception',    v_date,
      'proprietaire_type', NEW.proprietaire_type
    )
  );

  RETURN NEW;
END;
$$;


--
-- Name: receptions_apply_effects(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_apply_effects() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'pg_temp'
    AS $$
DECLARE
  v_vol_amb double precision;
BEGIN
  -- 1) Calcul de secours du volume ambiant si manquant (le BEFORE trigger le fixe déjà normalement)
  v_vol_amb := COALESCE(NEW.volume_ambiant, NEW.index_apres - NEW.index_avant);
  IF v_vol_amb IS NULL OR v_vol_amb <= 0 THEN
    RAISE EXCEPTION 'Volumes incohérents (index_apres <= index_avant)';
  END IF;

  -- 2) Crédit du stock journalier (ambiant + 15°C)
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id,
    NEW.produit_id,
    COALESCE(NEW.date_reception, CURRENT_DATE),
    v_vol_amb,
    COALESCE(NEW.volume_corrige_15c, 0)
  );

  -- 3) Passage du CDR lié en DECHARGE (si présent)
  IF NEW.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route
       SET statut = 'DECHARGE'
     WHERE id = NEW.cours_de_route_id;
  END IF;

  -- 4) Journalisation
  INSERT INTO public.log_actions(user_id, action, module, niveau, details)
  VALUES (
    auth.uid(),
    'RECEPTION_VALIDEE_AUTO',
    'receptions',
    'INFO',
    jsonb_build_object('reception_id', NEW.id)
  );

  RETURN NEW;
END $$;


--
-- Name: receptions_block_update_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_block_update_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  raise exception
    'Ecriture interdite sur receptions (op=%). Table immutable: utiliser INSERT + triggers/RPC, jamais UPDATE/DELETE.',
    tg_op;
end;
$$;


--
-- Name: receptions_check_cdr_arrive(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_check_cdr_arrive() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_statut text;
  v_produit_id uuid;
BEGIN
  -- Pas de CDR => OK (cas PARTENAIRE / hors CDR)
  IF NEW.cours_de_route_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Lecture CDR
  SELECT statut, produit_id
    INTO v_statut, v_produit_id
  FROM public.cours_de_route
  WHERE id = NEW.cours_de_route_id;

  IF v_statut IS NULL THEN
    RAISE EXCEPTION 'CDR introuvable: %', NEW.cours_de_route_id
      USING ERRCODE = '23503';
  END IF;

  -- Verrou DB-STRICT: ARRIVE uniquement
  IF v_statut <> 'ARRIVE' THEN
    RAISE EXCEPTION 'CDR statut invalide: %, attendu ARRIVE', v_statut
      USING ERRCODE = 'P0001';
  END IF;

  -- Cohérence produit (fortement recommandé)
  IF v_produit_id IS NOT NULL AND NEW.produit_id IS DISTINCT FROM v_produit_id THEN
    RAISE EXCEPTION 'Produit réception (%) != produit CDR (%)',
      NEW.produit_id, v_produit_id
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: receptions_check_produit_citerne(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_check_produit_citerne() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_produit uuid;
BEGIN
  SELECT produit_id INTO v_produit
  FROM public.citernes
  WHERE id = NEW.citerne_id;

  IF v_produit IS NULL THEN
    RAISE EXCEPTION 'Citerne % introuvable', NEW.citerne_id;
  END IF;

  IF NEW.produit_id IS DISTINCT FROM v_produit THEN
    RAISE EXCEPTION 'Produit % incompatible avec la citerne % (attendu %)',
      NEW.produit_id, NEW.citerne_id, v_produit;
  END IF;

  RETURN NEW;
END $$;


--
-- Name: receptions_log_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_log_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO public.log_actions (user_id, action, module, niveau, details)
  VALUES (
    NEW.created_by,                -- ✅ fiable (set par trigger BEFORE)
    'RECEPTION_CREEE',
    'receptions',
    'INFO',
    jsonb_build_object(
      'reception_id', NEW.id,
      'citerne_id',   NEW.citerne_id,
      'produit_id',   NEW.produit_id,
      'statut',       NEW.statut
    )
  );
  RETURN NEW;
END;
$$;


--
-- Name: receptions_set_created_by_default(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_set_created_by_default() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created_by IS NULL THEN
    NEW.created_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: receptions_set_volume_ambiant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.receptions_set_volume_ambiant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Sécurisation (les colonnes sont NOT NULL avec checks >=0)
  IF NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL THEN
    NEW.volume_ambiant := GREATEST(NEW.index_apres - NEW.index_avant, 0);
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: role_in(text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.role_in(p_role text, VARIADIC p_allowed text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  SELECT COALESCE(p_role = ANY(p_allowed), FALSE)
$$;


--
-- Name: sortie_before_ins_trg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sortie_before_ins_trg() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  if new.created_by is null then
    new.created_by := auth.uid();
  end if;

  -- Normalisation des indices (>= 0) couverte par CHECK; on protège aussi ici
  if new.index_avant is not null and new.index_avant < 0 then
    raise exception 'INDEX_AVANT_NEGATIF';
  end if;
  if new.index_apres is not null and new.index_apres < 0 then
    raise exception 'INDEX_APRES_NEGATIF';
  end if;

  -- Calcul volume_ambiant si non fourni
  if new.volume_ambiant is null and new.index_avant is not null and new.index_apres is not null then
    if new.index_apres <= new.index_avant then
      raise exception 'INDEX_INCOHERENTS (% >= %)', new.index_apres, new.index_avant;
    end if;
    new.volume_ambiant := new.index_apres - new.index_avant;
  end if;

  -- Date de sortie par défaut à maintenant si non fournie (utile pour journalisation)
  if new.date_sortie is null then
    new.date_sortie := now();
  end if;

  return new;
end
$$;


--
-- Name: sortie_before_upd_trg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sortie_before_upd_trg() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Si ce n'est PAS un admin, l'enregistrement devient immuable dès qu'il n'est plus "brouillon"
  IF NOT role_in(user_role(), VARIADIC ARRAY['admin']) THEN
    IF OLD.statut <> 'brouillon' THEN
      RAISE EXCEPTION 'IMMUTABLE_NON_BROUILLON';
    END IF;
  END IF;

  -- Recalcul volume_ambiant si les index changent (pour tous, y compris admin)
  IF (NEW.index_avant IS DISTINCT FROM OLD.index_avant)
     OR (NEW.index_apres IS DISTINCT FROM OLD.index_apres) THEN
    IF NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL THEN
      IF NEW.index_apres <= NEW.index_avant THEN
        RAISE EXCEPTION 'INDEX_INCOHERENTS (% >= %)', NEW.index_apres, NEW.index_avant;
      END IF;
      NEW.volume_ambiant := NEW.index_apres - NEW.index_avant;
    END IF;
  END IF;

  RETURN NEW;
END
$$;


--
-- Name: sorties_after_insert_trg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_after_insert_trg() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_date_jour   date;
  v_depot_id    uuid;
BEGIN
  -- ✅ Autoriser les écritures contrôlées sur stocks_journaliers pour CETTE transaction
  PERFORM set_config('app.stocks_journaliers_allow_write', '1', true);

  -- Ne traiter que les sorties validées
  IF NEW.statut IS NULL OR NEW.statut <> 'validee' THEN
    RETURN NEW;
  END IF;

  v_date_jour := COALESCE((NEW.date_sortie)::date, CURRENT_DATE);

  -- Récupérer le dépôt de la citerne
  SELECT depot_id
    INTO v_depot_id
    FROM public.citernes
   WHERE id = NEW.citerne_id;

  -- 1) Débiter le journal (delta négatif)
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id,
    NEW.produit_id,
    v_date_jour,
    -COALESCE(NEW.volume_ambiant,      0),
    -COALESCE(NEW.volume_corrige_15c,  0),
    NEW.proprietaire_type,
    v_depot_id,
    'SORTIE'
  );

  -- 1bis) Débiter le SNAPSHOT (stock réel)
  PERFORM public.stock_snapshot_apply_delta(
    NEW.citerne_id,
    NEW.produit_id,
    NEW.proprietaire_type,
    -COALESCE(NEW.volume_ambiant, 0),
    -COALESCE(NEW.volume_corrige_15c, 0),
    v_depot_id,
    NEW.created_at
  );

  -- 2) Journalisation
  INSERT INTO public.log_actions (user_id, action, module, niveau, details)
  VALUES (
    NEW.created_by,
    'SORTIE_VALIDE',
    'sorties_produit',
    'INFO',
    jsonb_build_object(
      'sortie_id', NEW.id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'proprietaire_type', NEW.proprietaire_type,
      'volume_ambiant', NEW.volume_ambiant,
      'volume_15c', NEW.volume_corrige_15c,
      'date_sortie', v_date_jour,
      'client_id', NEW.client_id,
      'partenaire_id', NEW.partenaire_id
    )
  );

  RETURN NEW;
END;
$$;


--
-- Name: sorties_apply_effects(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_apply_effects() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_date date := coalesce(new.date_sortie::date, current_date);
  v_vol_amb double precision;
  v_vol_15c double precision;
begin
  -- volume ambiant de secours si absent (avant-trigger calculant index_apres-index_avant)
  v_vol_amb := coalesce(new.volume_ambiant, new.index_apres - new.index_avant);
  if v_vol_amb is null or v_vol_amb <= 0 then
    raise exception 'Volume ambiant invalide pour la sortie %', new.id;
  end if;
  v_vol_15c := coalesce(new.volume_corrige_15c, v_vol_amb);

  -- Débit: on passe des deltas négatifs
  perform public.stock_upsert_journalier(
    new.citerne_id,
    new.produit_id,
    v_date,
    - v_vol_amb,
    - v_vol_15c
  );

  -- Journal
  insert into public.log_actions (user_id, action, module, niveau, details)
  values (
    coalesce(new.created_by, auth.uid()),
    'SORTIE_VALIDE',
    'sorties',
    'INFO',
    jsonb_build_object(
      'sortie_id', new.id,
      'citerne_id', new.citerne_id,
      'produit_id', new.produit_id,
      'date_sortie', v_date,
      'volume_ambiant', v_vol_amb,
      'volume_15c', v_vol_15c
    )
  );

  return new;
end;
$$;


--
-- Name: sorties_before_validate_trg(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_before_validate_trg() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_statut_citerne   text;
  v_proprietaire     text;
  v_date_jour        date;
  v_stock_dispo_15c  double precision;
  v_stock_dispo_amb  double precision;
  v_cap_securite     double precision;
BEGIN
  -- Ne faire les contrôles complets que pour les sorties validées
  IF NEW.statut IS NULL OR NEW.statut <> 'validee' THEN
    RETURN NEW;
  END IF;

  v_date_jour := COALESCE(NEW.date_sortie::date, CURRENT_DATE);

  -- 1) Normalisation proprietaire
  IF NEW.client_id IS NOT NULL AND NEW.partenaire_id IS NULL THEN
    v_proprietaire := 'MONALUXE';
  ELSIF NEW.partenaire_id IS NOT NULL AND NEW.client_id IS NULL THEN
    v_proprietaire := 'PARTENAIRE';
  ELSIF NEW.proprietaire_type IS NOT NULL THEN
    v_proprietaire := UPPER(TRIM(NEW.proprietaire_type));
  ELSE
    RAISE EXCEPTION
      'SORTIE_PROPRIETAIRE_INVALIDE: client_id=%, partenaire_id=%',
      NEW.client_id, NEW.partenaire_id;
  END IF;

  IF v_proprietaire NOT IN ('MONALUXE', 'PARTENAIRE') THEN
    RAISE EXCEPTION
      'SORTIE_PROPRIETAIRE_INVALIDE: proprietaire_type=%',
      v_proprietaire;
  END IF;

  NEW.proprietaire_type := v_proprietaire;

  -- 2) Citerne obligatoire + active
  IF NEW.citerne_id IS NULL THEN
    RAISE EXCEPTION 'SORTIE_CITERNE_OBLIGATOIRE';
  END IF;

  SELECT statut, capacite_securite
    INTO v_statut_citerne, v_cap_securite
    FROM public.citernes
   WHERE id = NEW.citerne_id;

  IF v_statut_citerne IS NULL THEN
    RAISE EXCEPTION
      'SORTIE_CITERNE_INVALIDE: citerne_id=%',
      NEW.citerne_id;
  END IF;

  IF v_statut_citerne <> 'active' THEN
    RAISE EXCEPTION
      'SORTIE_CITERNE_INACTIVE: citerne_id=% statut=%',
      NEW.citerne_id, v_statut_citerne;
  END IF;

  -- 3) Volumes requis
  IF NEW.volume_ambiant IS NULL THEN
    RAISE EXCEPTION 'SORTIE_VOLUME_AMBIANT_OBLIGATOIRE';
  END IF;

  IF NEW.volume_corrige_15c IS NULL THEN
    RAISE EXCEPTION 'SORTIE_VOLUME_15C_OBLIGATOIRE';
  END IF;

  -- 4) ✅ Stock dispo depuis SNAPSHOT (source de vérité)
  SELECT stock_ambiant, stock_15c
    INTO v_stock_dispo_amb, v_stock_dispo_15c
    FROM public.stocks_snapshot
   WHERE citerne_id        = NEW.citerne_id
     AND produit_id        = NEW.produit_id
     AND proprietaire_type = v_proprietaire;

  IF v_stock_dispo_15c IS NULL THEN
    RAISE EXCEPTION
      'SORTIE_STOCK_INTROUVABLE (snapshot): citerne=%, produit=%, proprietaire=%',
      NEW.citerne_id, NEW.produit_id, v_proprietaire;
  END IF;

  -- 5) Stock suffisant
  IF v_stock_dispo_15c < NEW.volume_corrige_15c THEN
    RAISE EXCEPTION
      'SORTIE_STOCK_INSUFFISANT_15C: demande=%, stock_dispo=%',
      NEW.volume_corrige_15c, v_stock_dispo_15c;
  END IF;

  IF v_stock_dispo_amb < NEW.volume_ambiant THEN
    RAISE EXCEPTION
      'SORTIE_STOCK_INSUFFISANT_AMB: demande=%, stock_dispo=%',
      NEW.volume_ambiant, v_stock_dispo_amb;
  END IF;

  -- 6) Capacité sécurité
  IF v_cap_securite IS NOT NULL THEN
    IF (v_stock_dispo_amb - NEW.volume_ambiant) < v_cap_securite THEN
      RAISE EXCEPTION
        'SORTIE_CAPACITE_SECURITE: stock=% sortie=% cap_securite=%',
        v_stock_dispo_amb, NEW.volume_ambiant, v_cap_securite;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: sorties_check_produit_citerne(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_check_produit_citerne() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count int;
BEGIN
  IF NEW.citerne_id IS NULL OR NEW.produit_id IS NULL THEN
    RAISE EXCEPTION 'CITERNE_OU_PRODUIT_NULL';
  END IF;

  SELECT 1 INTO v_count
  FROM public.citernes c
  WHERE c.id = NEW.citerne_id
    AND c.produit_id = NEW.produit_id
  LIMIT 1;

  IF v_count IS NULL THEN
    RAISE EXCEPTION 'PRODUIT_CITERNE_MISMATCH: citerne % ne porte pas le produit %', NEW.citerne_id, NEW.produit_id;
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: sorties_log_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_log_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.log_actions(user_id, action, module, niveau, details)
  VALUES (
    auth.uid(),
    'CREATE',
    'sorties',
    'INFO',
    jsonb_build_object(
      'sortie_id',        NEW.id,
      'citerne_id',       NEW.citerne_id,
      'produit_id',       NEW.produit_id,
      'volume_ambiant',   NEW.volume_ambiant,
      'volume_15c',       NEW.volume_corrige_15c,
      'date_sortie',      NEW.date_sortie,
      'proprietaire',     NEW.proprietaire_type,
      'statut',           NEW.statut,
      'created_by',       NEW.created_by
    )
  );
  RETURN NEW;
END;
$$;


--
-- Name: sorties_produit_block_update_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_produit_block_update_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  raise exception
    'Ecriture interdite sur sorties_produit (op=%). Table immutable: utiliser INSERT + triggers/RPC, jamais UPDATE/DELETE.',
    tg_op;
end;
$$;


--
-- Name: sorties_reject_validated_on_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_reject_validated_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.statut = 'validee' THEN
    RAISE EXCEPTION
      'DB-STRICT: insertion directe en statut validee interdite — utiliser validate_sortie(id)';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: sorties_set_created_by_default(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_set_created_by_default() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.created_by is null then
    new.created_by := auth.uid();
  end if;

  return new;
end;
$$;


--
-- Name: FUNCTION sorties_set_created_by_default(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.sorties_set_created_by_default() IS 'BEFORE INSERT: if NEW.created_by is NULL, set it to auth.uid(). Note: auth.uid() may be NULL outside an authenticated Supabase context (SQL editor, migrations).';


--
-- Name: sorties_set_volume_ambiant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sorties_set_volume_ambiant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.index_avant is not null and new.index_apres is not null then
    new.volume_ambiant := greatest(new.index_apres - new.index_avant, 0);
  end if;
  return new;
end;
$$;


--
-- Name: stock_snapshot_apply_delta(uuid, uuid, text, double precision, double precision, uuid, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stock_snapshot_apply_delta(p_citerne_id uuid, p_produit_id uuid, p_proprietaire_type text, p_delta_ambiant double precision, p_delta_15c double precision, p_depot_id uuid, p_event_ts timestamp with time zone) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_owner text := UPPER(TRIM(p_proprietaire_type));
  v_curr_amb double precision;
  v_curr_15c double precision;
  v_next_amb double precision;
  v_next_15c double precision;
BEGIN
  -- Normalisation propriétaire
  IF v_owner NOT IN ('MONALUXE', 'PARTENAIRE') THEN
    RAISE EXCEPTION 'SNAPSHOT_OWNER_INVALID: %', v_owner;
  END IF;

  -- 1) Lire l'état courant (lock row pour éviter course)
  SELECT s.stock_ambiant, s.stock_15c
    INTO v_curr_amb, v_curr_15c
    FROM public.stocks_snapshot s
   WHERE s.citerne_id = p_citerne_id
     AND s.produit_id = p_produit_id
     AND s.proprietaire_type = v_owner
   FOR UPDATE;

  -- 2) Si ligne inexistante
  IF v_curr_amb IS NULL OR v_curr_15c IS NULL THEN
    -- Insert autorisé uniquement si delta positif
    IF COALESCE(p_delta_ambiant, 0) < 0 OR COALESCE(p_delta_15c, 0) < 0 THEN
      RAISE EXCEPTION
        'SNAPSHOT_MISSING_FOR_NEGATIVE_DELTA: citerne=%, produit=%, proprietaire=%',
        p_citerne_id, p_produit_id, v_owner;
    END IF;

    INSERT INTO public.stocks_snapshot (
      citerne_id, produit_id, proprietaire_type, depot_id,
      stock_ambiant, stock_15c,
      last_movement_at, updated_at
    )
    VALUES (
      p_citerne_id, p_produit_id, v_owner, p_depot_id,
      COALESCE(p_delta_ambiant, 0), COALESCE(p_delta_15c, 0),
      COALESCE(p_event_ts, now()), COALESCE(p_event_ts, now())
    );

    RETURN;
  END IF;

  -- 3) Calcul futur stock (avant update)
  v_next_amb := v_curr_amb + COALESCE(p_delta_ambiant, 0);
  v_next_15c := v_curr_15c + COALESCE(p_delta_15c, 0);

  IF v_next_amb < 0 OR v_next_15c < 0 THEN
    RAISE EXCEPTION
      'SNAPSHOT_NEGATIVE_STOCK_FORBIDDEN: owner=% citerne=% produit=% curr_amb=% curr_15c=% delta_amb=% delta_15c=% next_amb=% next_15c=%',
      v_owner, p_citerne_id, p_produit_id,
      v_curr_amb, v_curr_15c,
      COALESCE(p_delta_ambiant, 0), COALESCE(p_delta_15c, 0),
      v_next_amb, v_next_15c;
  END IF;

  -- 4) Update
  UPDATE public.stocks_snapshot s
     SET stock_ambiant    = v_next_amb,
         stock_15c        = v_next_15c,
         depot_id         = COALESCE(p_depot_id, s.depot_id),
         last_movement_at = COALESCE(p_event_ts, now()),
         updated_at       = COALESCE(p_event_ts, now())
   WHERE s.citerne_id = p_citerne_id
     AND s.produit_id = p_produit_id
     AND s.proprietaire_type = v_owner;
END;
$$;


--
-- Name: stock_upsert_journalier(uuid, uuid, date, double precision, double precision, text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stock_upsert_journalier(p_citerne_id uuid, p_produit_id uuid, p_date_jour date, p_delta_stock_ambiant double precision, p_delta_stock_15c double precision, p_proprietaire_type text DEFAULT 'MONALUXE'::text, p_depot_id uuid DEFAULT NULL::uuid, p_source text DEFAULT 'SYSTEM'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_owner text;
  v_prev_ambiant double precision := 0;
  v_prev_15c double precision := 0;
  v_exists boolean := false;
BEGIN
  v_owner := UPPER(TRIM(COALESCE(p_proprietaire_type, 'MONALUXE')));

  IF v_owner NOT IN ('MONALUXE', 'PARTENAIRE') THEN
    RAISE EXCEPTION 'stock_upsert_journalier() - proprietaire_type invalide: %', v_owner;
  END IF;

  -- 1) Est-ce qu'une ligne existe déjà pour ce jour ?
  SELECT EXISTS (
    SELECT 1
    FROM public.stocks_journaliers
    WHERE citerne_id = p_citerne_id
      AND produit_id = p_produit_id
      AND date_jour  = p_date_jour
      AND proprietaire_type = v_owner
  ) INTO v_exists;

  IF v_exists THEN
    -- 2a) Si la ligne du jour existe déjà : on ajoute le delta
    UPDATE public.stocks_journaliers
    SET stock_ambiant = stock_ambiant + COALESCE(p_delta_stock_ambiant, 0),
        stock_15c     = stock_15c     + COALESCE(p_delta_stock_15c, 0),
        depot_id      = COALESCE(p_depot_id, depot_id),
        source        = p_source,
        updated_at    = now()
    WHERE citerne_id = p_citerne_id
      AND produit_id = p_produit_id
      AND date_jour  = p_date_jour
      AND proprietaire_type = v_owner;

  ELSE
    -- 2b) Sinon, on récupère le dernier snapshot strictement avant ce jour
    SELECT sj.stock_ambiant, sj.stock_15c
    INTO v_prev_ambiant, v_prev_15c
    FROM public.stocks_journaliers sj
    WHERE sj.citerne_id = p_citerne_id
      AND sj.produit_id = p_produit_id
      AND sj.proprietaire_type = v_owner
      AND sj.date_jour < p_date_jour
    ORDER BY sj.date_jour DESC
    LIMIT 1;

    v_prev_ambiant := COALESCE(v_prev_ambiant, 0);
    v_prev_15c     := COALESCE(v_prev_15c, 0);

    -- 3) On insère le snapshot du jour = prev + delta
    INSERT INTO public.stocks_journaliers (
      citerne_id, produit_id, date_jour,
      stock_ambiant, stock_15c,
      proprietaire_type, depot_id, source,
      created_at, updated_at
    )
    VALUES (
      p_citerne_id, p_produit_id, p_date_jour,
      v_prev_ambiant + COALESCE(p_delta_stock_ambiant, 0),
      v_prev_15c     + COALESCE(p_delta_stock_15c, 0),
      v_owner, p_depot_id, p_source,
      now(), now()
    );
  END IF;
END;
$$;


--
-- Name: stocks_adjustments_block_update_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stocks_adjustments_block_update_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  raise exception
    'Ecriture interdite sur stocks_adjustments (op=%). Table immutable: INSERT only.',
    tg_op;
end;
$$;


--
-- Name: stocks_adjustments_check_mouvement_ref(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stocks_adjustments_check_mouvement_ref() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.mouvement_type = 'RECEPTION' then
    if not exists (select 1 from public.receptions r where r.id = new.mouvement_id) then
      raise exception 'MOUVEMENT_NOT_FOUND: receptions.id % introuvable', new.mouvement_id;
    end if;

  elsif new.mouvement_type = 'SORTIE' then
    if not exists (select 1 from public.sorties_produit s where s.id = new.mouvement_id) then
      raise exception 'MOUVEMENT_NOT_FOUND: sorties_produit.id % introuvable', new.mouvement_id;
    end if;

  else
    raise exception 'MOUVEMENT_TYPE_INVALID: %', new.mouvement_type;
  end if;

  return new;
end;
$$;


--
-- Name: stocks_adjustments_set_context_from_mouvement(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stocks_adjustments_set_context_from_mouvement() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_citerne_id uuid;
  v_produit_id uuid;
  v_proprietaire_type text;
  v_depot_id uuid;
begin
  -- 1) Lire le mouvement source
  if new.mouvement_type = 'RECEPTION' then
    select r.citerne_id, r.produit_id, r.proprietaire_type
      into v_citerne_id, v_produit_id, v_proprietaire_type
    from public.receptions r
    where r.id = new.mouvement_id;

  elsif new.mouvement_type = 'SORTIE' then
    select s.citerne_id, s.produit_id, s.proprietaire_type
      into v_citerne_id, v_produit_id, v_proprietaire_type
    from public.sorties_produit s
    where s.id = new.mouvement_id;

  else
    raise exception 'MOUVEMENT_TYPE_INVALID: %', new.mouvement_type;
  end if;

  -- 2) Déduire depot_id depuis la citerne
  select c.depot_id into v_depot_id
  from public.citernes c
  where c.id = v_citerne_id;

  -- 3) Si l'app a envoyé un contexte, on vérifie qu'il matche (sinon fraude/erreur)
  if new.citerne_id is not null and new.citerne_id <> v_citerne_id then
    raise exception 'CONTEXT_MISMATCH: citerne_id attendu %, reçu %', v_citerne_id, new.citerne_id;
  end if;

  if new.produit_id is not null and new.produit_id <> v_produit_id then
    raise exception 'CONTEXT_MISMATCH: produit_id attendu %, reçu %', v_produit_id, new.produit_id;
  end if;

  if new.proprietaire_type is not null and new.proprietaire_type <> v_proprietaire_type then
    raise exception 'CONTEXT_MISMATCH: proprietaire_type attendu %, reçu %', v_proprietaire_type, new.proprietaire_type;
  end if;

  if new.depot_id is not null and new.depot_id <> v_depot_id then
    raise exception 'CONTEXT_MISMATCH: depot_id attendu %, reçu %', v_depot_id, new.depot_id;
  end if;

  -- 4) Forcer le contexte officiel
  new.citerne_id := v_citerne_id;
  new.produit_id := v_produit_id;
  new.proprietaire_type := v_proprietaire_type;
  new.depot_id := v_depot_id;

  return new;
end;
$$;


--
-- Name: stocks_adjustments_set_created_by(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stocks_adjustments_set_created_by() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_uid uuid;
begin
  -- Récupère l'user id depuis le JWT Supabase
  v_uid := nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;

  if new.created_by is null then
    new.created_by := v_uid;
  end if;

  return new;
end;
$$;


--
-- Name: stocks_journaliers_block_writes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.stocks_journaliers_block_writes() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_allow text;
begin
  -- Autoriser les écritures UNIQUEMENT si un contexte contrôlé l’a explicitement demandé
  v_allow := current_setting('app.stocks_journaliers_allow_write', true);

  if v_allow = '1' then
    if tg_op = 'DELETE' then
      return old;
    else
      return new;
    end if;
  end if;

  raise exception
    'Ecriture directe interdite sur stocks_journaliers (op=%). Utiliser les triggers (receptions/sorties) ou la fonction de rebuild contrôlée.',
    tg_op;

end;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: user_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.user_role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  SELECT p.role
  FROM public.profils p
  WHERE p.user_id = auth.uid()
  ORDER BY p.created_at DESC
  LIMIT 1
$$;


--
-- Name: validate_reception(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_reception(p_reception_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_role text;
  r RECORD;
  c RECORD;   -- citerne
  p RECORD;   -- produit
  v_stock_actuel double precision := 0;
  v_cap_dispo double precision := 0;
  v_volume_ambiant double precision := 0;
  v_volume_15c double precision := NULL;
  v_alpha double precision := 0.0009;
BEGIN
  -- Rôle
  v_role := public.user_role();
  IF NOT public.role_in(v_role, 'gerant','directeur','admin') THEN
    RAISE EXCEPTION 'Accès refusé: rôle % non autorisé à valider', v_role
      USING ERRCODE = '42501';
  END IF;

  -- Charger la réception
  SELECT rec.*, pr.code AS prod_code
    INTO r
  FROM public.receptions rec
  JOIN public.produits pr ON pr.id = rec.produit_id
  WHERE rec.id = p_reception_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Réception introuvable'; END IF;
  IF r.statut IS DISTINCT FROM 'brouillon' THEN
    RAISE EXCEPTION 'Seules les réceptions en "brouillon" peuvent être validées (statut=%)', r.statut;
  END IF;

  -- Citerne / compatibilité / capacité (identique à avant)
  SELECT ct.id, ct.produit_id AS citerne_produit_id, ct.statut, ct.capacite_totale, ct.capacite_securite
    INTO c
  FROM public.citernes ct
  WHERE ct.id = r.citerne_id;
  IF c.id IS NULL THEN RAISE EXCEPTION 'Citerne introuvable'; END IF;
  IF c.statut <> 'active' THEN RAISE EXCEPTION 'Citerne non active (statut=%)', c.statut; END IF;
  IF c.citerne_produit_id IS DISTINCT FROM r.produit_id THEN
    RAISE EXCEPTION 'Produit incompatible avec la citerne';
  END IF;

  v_stock_actuel := public.get_last_stock_ambiant(r.citerne_id, r.produit_id);
  v_volume_ambiant := COALESCE(r.volume_ambiant, 0);
  v_cap_dispo := GREATEST(c.capacite_totale - c.capacite_securite - v_stock_actuel, 0);
  IF v_volume_ambiant <= 0 THEN RAISE EXCEPTION 'Volume ambiant invalide (<=0).'; END IF;
  IF v_volume_ambiant > v_cap_dispo THEN
    RAISE EXCEPTION 'Capacité insuffisante (disponible=%, demandé=%)', v_cap_dispo, v_volume_ambiant;
  END IF;

  -- Partenaire
  IF r.proprietaire_type = 'PARTENAIRE' AND r.partenaire_id IS NULL THEN
    RAISE EXCEPTION 'partenaire_id requis pour proprietaire_type=PARTENAIRE';
  END IF;

  -- Cours (si lié)
  IF r.cours_de_route_id IS NOT NULL THEN
    PERFORM 1 FROM public.cours_de_route cr WHERE cr.id = r.cours_de_route_id AND cr.statut = 'arrivé';
    IF NOT FOUND THEN RAISE EXCEPTION 'Cours de route non éligible (doit être "arrivé")'; END IF;
  END IF;

  -- V15 (si absent) — identique à avant
  IF r.volume_corrige_15c IS NULL THEN
    IF r.prod_code IS NOT NULL THEN
      IF upper(r.prod_code) = 'ESS' THEN v_alpha := 0.00100;
      ELSIF upper(r.prod_code) = 'AGO' THEN v_alpha := 0.00085;
      ELSE v_alpha := 0.00090;
      END IF;
    END IF;
    IF r.temperature_ambiante_c IS NOT NULL THEN
      v_volume_15c := v_volume_ambiant * (1 - v_alpha * (r.temperature_ambiante_c - 15.0));
    ELSE
      v_volume_15c := v_volume_ambiant;
    END IF;
    UPDATE public.receptions SET volume_corrige_15c = v_volume_15c WHERE id = r.id;
  ELSE
    v_volume_15c := r.volume_corrige_15c;
  END IF;

  -- Valider
  UPDATE public.receptions
     SET statut = 'validee',
         validated_by = auth.uid()
   WHERE id = r.id;

  -- Utiliser la date de la réception si fournie
  PERFORM public.increment_stock_journalier(
    COALESCE(r.date_reception, CURRENT_DATE),
    r.citerne_id,
    r.produit_id,
    v_volume_ambiant,
    COALESCE(v_volume_15c, v_volume_ambiant)
  );

  -- Cours -> déchargé si lié
  IF r.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route SET statut = 'déchargé' WHERE id = r.cours_de_route_id;
  END IF;

  -- Log
  INSERT INTO public.log_actions (user_id, action, module, niveau, details)
  VALUES (
    auth.uid(), 'RECEPTION_VALIDEE', 'receptions', 'INFO',
    jsonb_build_object('reception_id', r.id, 'citerne_id', r.citerne_id, 'produit_id', r.produit_id,
                       'volume_ambiant', v_volume_ambiant, 'volume_15c', v_volume_15c)
  );
END;
$$;


--
-- Name: validate_sortie(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_sortie(p_id uuid) RETURNS void
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: citernes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.citernes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    depot_id uuid,
    nom text NOT NULL,
    capacite_totale double precision NOT NULL,
    capacite_securite double precision NOT NULL,
    localisation text NOT NULL,
    statut text DEFAULT 'active'::text,
    created_at timestamp with time zone DEFAULT now(),
    produit_id uuid NOT NULL,
    CONSTRAINT citernes_capacite_securite_check CHECK ((capacite_securite >= (0)::double precision)),
    CONSTRAINT citernes_capacite_totale_check CHECK ((capacite_totale > (0)::double precision)),
    CONSTRAINT citernes_statut_check CHECK ((statut = ANY (ARRAY['active'::text, 'inactive'::text, 'maintenance'::text])))
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom text NOT NULL,
    contact_personne text,
    email text,
    telephone text,
    adresse text,
    pays text,
    note_supplementaire text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: cours_de_route; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cours_de_route (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fournisseur_id uuid,
    depot_destination_id uuid,
    produit_id uuid,
    plaque_camion text NOT NULL,
    plaque_remorque text,
    chauffeur_nom text,
    transporteur text,
    depart_pays text,
    date_chargement date NOT NULL,
    volume numeric,
    statut text DEFAULT 'CHARGEMENT'::text,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT cours_de_route_statut_check CHECK ((statut = ANY (ARRAY['CHARGEMENT'::text, 'TRANSIT'::text, 'FRONTIERE'::text, 'ARRIVE'::text, 'DECHARGE'::text])))
);


--
-- Name: cours_route; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cours_route WITH (security_invoker='on') AS
 SELECT id,
    fournisseur_id,
    depot_destination_id,
    produit_id,
    TRIM(BOTH FROM concat_ws(' • '::text, NULLIF(plaque_camion, ''::text), NULLIF(plaque_remorque, ''::text))) AS plaques,
    COALESCE(chauffeur_nom, ''::text) AS chauffeur,
    COALESCE(transporteur, ''::text) AS transporteur,
    volume,
    statut,
    date_chargement AS date,
    created_at
   FROM public.cours_de_route c;


--
-- Name: profils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profils (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    nom_complet text,
    role text NOT NULL,
    depot_id uuid,
    email text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT profils_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'directeur'::text, 'gerant'::text, 'lecture'::text, 'pca'::text])))
);


--
-- Name: current_user_profile; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.current_user_profile AS
 SELECT p.id,
    p.user_id,
    p.nom_complet,
    p.role,
    p.depot_id,
    p.email,
    p.created_at
   FROM (auth.users u
     JOIN public.profils p ON ((u.id = p.user_id)))
  WHERE (u.id = auth.uid());


--
-- Name: depots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.depots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom text NOT NULL,
    adresse text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: fournisseurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fournisseurs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom text NOT NULL,
    contact_personne text,
    email text,
    telephone text,
    adresse text,
    pays text,
    note_supplementaire text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: log_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action text NOT NULL,
    module text NOT NULL,
    niveau text DEFAULT 'INFO'::text,
    details jsonb,
    created_at timestamp with time zone DEFAULT now(),
    cible_id uuid,
    CONSTRAINT log_actions_niveau_check CHECK ((niveau = ANY (ARRAY['INFO'::text, 'WARNING'::text, 'CRITICAL'::text])))
);


--
-- Name: logs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.logs AS
 SELECT id,
    created_at,
    module,
    action,
    niveau,
    user_id,
    details
   FROM public.log_actions la;


--
-- Name: partenaires; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partenaires (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom text NOT NULL,
    contact text,
    email text,
    telephone text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: prises_de_hauteur; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prises_de_hauteur (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    citerne_id uuid,
    volume_mesure double precision NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT prises_de_hauteur_volume_mesure_check CHECK ((volume_mesure >= (0)::double precision))
);


--
-- Name: produits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom text NOT NULL,
    code text,
    description text,
    actif boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: receptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cours_de_route_id uuid,
    citerne_id uuid NOT NULL,
    produit_id uuid NOT NULL,
    partenaire_id uuid,
    index_avant double precision NOT NULL,
    index_apres double precision NOT NULL,
    volume_corrige_15c double precision,
    temperature_ambiante_c double precision,
    densite_a_15 double precision,
    proprietaire_type text DEFAULT 'MONALUXE'::text,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    volume_ambiant double precision,
    statut text DEFAULT 'validee'::text NOT NULL,
    created_by uuid,
    validated_by uuid,
    date_reception date DEFAULT CURRENT_DATE,
    volume_observe double precision,
    volume_15c double precision,
    CONSTRAINT receptions_ambiant_required_if_valid CHECK (((statut <> 'validee'::text) OR (volume_ambiant IS NOT NULL))),
    CONSTRAINT receptions_index_nonneg CHECK (((index_avant >= (0)::double precision) AND (index_apres >= (0)::double precision))),
    CONSTRAINT receptions_index_order CHECK ((index_apres > index_avant)),
    CONSTRAINT receptions_partenaire_required CHECK (((proprietaire_type <> 'PARTENAIRE'::text) OR (partenaire_id IS NOT NULL))),
    CONSTRAINT receptions_proprietaire_type_check CHECK ((proprietaire_type = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text]))),
    CONSTRAINT receptions_statut_check CHECK ((statut = ANY (ARRAY['validee'::text, 'rejetee'::text])))
);


--
-- Name: sorties_produit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sorties_produit (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    citerne_id uuid NOT NULL,
    produit_id uuid NOT NULL,
    client_id uuid,
    partenaire_id uuid,
    volume_corrige_15c double precision,
    temperature_ambiante_c double precision,
    densite_a_15 double precision,
    proprietaire_type text DEFAULT 'MONALUXE'::text,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    index_avant double precision,
    index_apres double precision,
    volume_ambiant double precision,
    statut text DEFAULT 'validee'::text NOT NULL,
    created_by uuid,
    validated_by uuid,
    date_sortie timestamp with time zone,
    chauffeur_nom text,
    plaque_camion text,
    plaque_remorque text,
    transporteur text,
    CONSTRAINT sorties_ambiant_required_if_valid CHECK (((statut <> 'validee'::text) OR (volume_ambiant IS NOT NULL))),
    CONSTRAINT sorties_produit_beneficiaire_check CHECK (((client_id IS NOT NULL) OR (partenaire_id IS NOT NULL))),
    CONSTRAINT sorties_produit_index_apres_check CHECK ((index_apres >= (0)::double precision)),
    CONSTRAINT sorties_produit_index_avant_check CHECK ((index_avant >= (0)::double precision)),
    CONSTRAINT sorties_produit_proprietaire_type_check CHECK ((proprietaire_type = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text]))),
    CONSTRAINT sorties_produit_statut_check CHECK ((statut = ANY (ARRAY['brouillon'::text, 'validee'::text, 'rejetee'::text])))
);


--
-- Name: stocks_journaliers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks_journaliers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    citerne_id uuid,
    produit_id uuid,
    date_jour date NOT NULL,
    stock_ambiant double precision NOT NULL,
    stock_15c double precision NOT NULL,
    proprietaire_type text DEFAULT 'MONALUXE'::text,
    depot_id uuid,
    source text DEFAULT 'SYSTEM'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT stocks_journaliers_proprietaire_type_check CHECK ((proprietaire_type = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text])))
);


--
-- Name: stock_actuel; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.stock_actuel AS
 SELECT DISTINCT ON (citerne_id, produit_id) citerne_id,
    produit_id,
    date_jour,
    stock_ambiant,
    stock_15c
   FROM public.stocks_journaliers sj
  ORDER BY citerne_id, produit_id, date_jour DESC;


--
-- Name: stocks_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks_adjustments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mouvement_type text NOT NULL,
    mouvement_id uuid NOT NULL,
    delta_ambiant double precision NOT NULL,
    delta_15c double precision DEFAULT 0 NOT NULL,
    reason text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    depot_id uuid,
    citerne_id uuid,
    produit_id uuid,
    proprietaire_type text,
    CONSTRAINT stocks_adjustments_mouvement_type_check CHECK ((mouvement_type = ANY (ARRAY['RECEPTION'::text, 'SORTIE'::text]))),
    CONSTRAINT stocks_adjustments_proprietaire_type_check CHECK ((proprietaire_type = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text]))),
    CONSTRAINT stocks_adjustments_reason_check CHECK ((char_length(TRIM(BOTH FROM reason)) >= 10))
);


--
-- Name: stocks_journaliers_bak; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks_journaliers_bak (
    id uuid,
    citerne_id uuid,
    produit_id uuid,
    date_jour date,
    stock_ambiant double precision,
    stock_15c double precision,
    proprietaire_type text,
    depot_id uuid,
    source text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: stocks_snapshot; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stocks_snapshot (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    citerne_id uuid NOT NULL,
    produit_id uuid NOT NULL,
    proprietaire_type text NOT NULL,
    depot_id uuid,
    stock_ambiant double precision DEFAULT 0 NOT NULL,
    stock_15c double precision DEFAULT 0 NOT NULL,
    last_movement_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT stocks_snapshot_proprietaire_type_check CHECK ((proprietaire_type = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text]))),
    CONSTRAINT stocks_snapshot_stock_15c_check CHECK ((stock_15c >= (0)::double precision)),
    CONSTRAINT stocks_snapshot_stock_ambiant_check CHECK ((stock_ambiant >= (0)::double precision))
);


--
-- Name: v_citerne_stock_actuel; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_citerne_stock_actuel AS
 WITH base AS (
         SELECT sj.citerne_id,
            sj.produit_id,
            sj.proprietaire_type,
            sj.date_jour,
            sj.stock_ambiant,
            sj.stock_15c
           FROM public.stocks_journaliers sj
        ), last_date AS (
         SELECT base.citerne_id,
            base.produit_id,
            base.proprietaire_type,
            max(base.date_jour) AS date_jour
           FROM base
          GROUP BY base.citerne_id, base.produit_id, base.proprietaire_type
        ), last_rows AS (
         SELECT b.citerne_id,
            b.produit_id,
            b.proprietaire_type,
            b.date_jour,
            b.stock_ambiant,
            b.stock_15c
           FROM (base b
             JOIN last_date ld ON (((ld.citerne_id = b.citerne_id) AND (ld.produit_id = b.produit_id) AND (ld.proprietaire_type = b.proprietaire_type) AND (ld.date_jour = b.date_jour))))
        )
 SELECT citerne_id,
    produit_id,
    max(date_jour) AS date_jour,
    sum(stock_ambiant) AS stock_ambiant,
    sum(stock_15c) AS stock_15c
   FROM last_rows
  GROUP BY citerne_id, produit_id;


--
-- Name: v_stock_actuel_snapshot; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stock_actuel_snapshot AS
 SELECT ss.citerne_id,
    c.nom AS citerne_nom,
    ss.produit_id,
    p.nom AS produit_nom,
    ss.depot_id,
    d.nom AS depot_nom,
    ss.proprietaire_type,
    ss.stock_ambiant,
    ss.stock_15c,
    ss.updated_at,
    c.capacite_totale,
    c.capacite_securite
   FROM (((public.stocks_snapshot ss
     JOIN public.citernes c ON ((c.id = ss.citerne_id)))
     JOIN public.produits p ON ((p.id = ss.produit_id)))
     JOIN public.depots d ON ((d.id = ss.depot_id)));


--
-- Name: VIEW v_stock_actuel_snapshot; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_stock_actuel_snapshot IS '🚨 SOURCE DE VERITE STOCK ACTUEL 🚨
Vue snapshot calculée depuis stocks_journaliers.
A utiliser EXCLUSIVEMENT pour :
- Dashboard
- Module Stocks
- Module Citernes
- KPI globaux
Toute autre agrégation historique est interdite.';


--
-- Name: v_citerne_stock_snapshot_agg; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_citerne_stock_snapshot_agg AS
 SELECT c.id AS citerne_id,
    c.nom AS citerne_nom,
    c.depot_id,
    c.produit_id,
    sum(s.stock_ambiant) AS stock_ambiant_total,
    sum(s.stock_15c) AS stock_15c_total,
    max(s.updated_at) AS last_snapshot_at
   FROM (public.v_stock_actuel_snapshot s
     JOIN public.citernes c ON ((c.id = s.citerne_id)))
  GROUP BY c.id, c.nom, c.depot_id, c.produit_id;


--
-- Name: v_kpi_stock_global; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_kpi_stock_global AS
 SELECT depot_id,
    TRIM(BOTH FROM depot_nom) AS depot_nom,
    produit_id,
    produit_nom,
    (max(updated_at))::date AS date_jour,
    sum(stock_ambiant) AS stock_ambiant_total,
    sum(stock_15c) AS stock_15c_total,
    sum(
        CASE
            WHEN (proprietaire_type = 'MONALUXE'::text) THEN stock_ambiant
            ELSE (0)::double precision
        END) AS stock_ambiant_monaluxe,
    sum(
        CASE
            WHEN (proprietaire_type = 'MONALUXE'::text) THEN stock_15c
            ELSE (0)::double precision
        END) AS stock_15c_monaluxe,
    sum(
        CASE
            WHEN (proprietaire_type = 'PARTENAIRE'::text) THEN stock_ambiant
            ELSE (0)::double precision
        END) AS stock_ambiant_partenaire,
    sum(
        CASE
            WHEN (proprietaire_type = 'PARTENAIRE'::text) THEN stock_15c
            ELSE (0)::double precision
        END) AS stock_15c_partenaire
   FROM public.v_stock_actuel_snapshot s
  GROUP BY depot_id, (TRIM(BOTH FROM depot_nom)), produit_id, produit_nom;


--
-- Name: v_mouvements_stock; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_mouvements_stock AS
 WITH snapshot_norm AS (
         SELECT (s.last_movement_at)::date AS date_jour,
            s.citerne_id,
            s.produit_id,
            s.depot_id,
            upper(TRIM(BOTH FROM s.proprietaire_type)) AS proprietaire_type,
            s.stock_ambiant AS delta_ambiant,
            s.stock_15c AS delta_15c
           FROM public.stocks_snapshot s
          WHERE ((s.last_movement_at IS NOT NULL) AND (upper(TRIM(BOTH FROM s.proprietaire_type)) = ANY (ARRAY['MONALUXE'::text, 'PARTENAIRE'::text])) AND (NOT (EXISTS ( SELECT 1
                   FROM (public.receptions r
                     JOIN public.citernes c ON ((c.id = r.citerne_id)))
                  WHERE ((r.statut = 'validee'::text) AND (r.citerne_id = s.citerne_id) AND (r.produit_id = s.produit_id) AND (c.depot_id = s.depot_id) AND (upper(TRIM(BOTH FROM COALESCE(r.proprietaire_type, 'MONALUXE'::text))) = upper(TRIM(BOTH FROM s.proprietaire_type))) AND (r.date_reception < (s.last_movement_at)::date))))) AND (NOT (EXISTS ( SELECT 1
                   FROM (public.sorties_produit so
                     JOIN public.citernes c ON ((c.id = so.citerne_id)))
                  WHERE ((so.statut = 'validee'::text) AND (so.citerne_id = s.citerne_id) AND (so.produit_id = s.produit_id) AND (c.depot_id = s.depot_id) AND (upper(TRIM(BOTH FROM COALESCE(so.proprietaire_type, 'MONALUXE'::text))) = upper(TRIM(BOTH FROM s.proprietaire_type))) AND ((so.date_sortie)::date < (s.last_movement_at)::date))))))
        ), receptions_norm AS (
         SELECT r.date_reception AS date_jour,
            r.citerne_id,
            r.produit_id,
            c.depot_id,
            upper(TRIM(BOTH FROM COALESCE(r.proprietaire_type, 'MONALUXE'::text))) AS proprietaire_type,
            COALESCE(r.volume_ambiant, r.volume_observe, (0)::double precision) AS delta_ambiant,
            COALESCE(r.volume_15c, r.volume_corrige_15c, r.volume_ambiant, (0)::double precision) AS delta_15c
           FROM (public.receptions r
             JOIN public.citernes c ON ((c.id = r.citerne_id)))
          WHERE (r.statut = 'validee'::text)
        ), sorties_norm AS (
         SELECT (s.date_sortie)::date AS date_jour,
            s.citerne_id,
            s.produit_id,
            c.depot_id,
            upper(TRIM(BOTH FROM COALESCE(s.proprietaire_type, 'MONALUXE'::text))) AS proprietaire_type,
            (- COALESCE(s.volume_ambiant, (0)::double precision)) AS delta_ambiant,
            (- COALESCE(s.volume_corrige_15c, s.volume_ambiant, (0)::double precision)) AS delta_15c
           FROM (public.sorties_produit s
             JOIN public.citernes c ON ((c.id = s.citerne_id)))
          WHERE (s.statut = 'validee'::text)
        )
 SELECT snapshot_norm.date_jour,
    snapshot_norm.citerne_id,
    snapshot_norm.produit_id,
    snapshot_norm.depot_id,
    snapshot_norm.proprietaire_type,
    snapshot_norm.delta_ambiant,
    snapshot_norm.delta_15c
   FROM snapshot_norm
UNION ALL
 SELECT receptions_norm.date_jour,
    receptions_norm.citerne_id,
    receptions_norm.produit_id,
    receptions_norm.depot_id,
    receptions_norm.proprietaire_type,
    receptions_norm.delta_ambiant,
    receptions_norm.delta_15c
   FROM receptions_norm
UNION ALL
 SELECT sorties_norm.date_jour,
    sorties_norm.citerne_id,
    sorties_norm.produit_id,
    sorties_norm.depot_id,
    sorties_norm.proprietaire_type,
    sorties_norm.delta_ambiant,
    sorties_norm.delta_15c
   FROM sorties_norm;


--
-- Name: v_stocks_snapshot_corrige; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stocks_snapshot_corrige AS
 SELECT ss.depot_id,
    ss.citerne_id,
    ss.produit_id,
    ss.proprietaire_type,
    ss.stock_ambiant AS stock_ambiant_base,
    ss.stock_15c AS stock_15c_base,
    COALESCE(adj.delta_ambiant_total, (0)::double precision) AS delta_ambiant_total,
    COALESCE(adj.delta_15c_total, (0)::double precision) AS delta_15c_total,
    GREATEST((ss.stock_ambiant + COALESCE(adj.delta_ambiant_total, (0)::double precision)), (0)::double precision) AS stock_ambiant_corrige,
    GREATEST((ss.stock_15c + COALESCE(adj.delta_15c_total, (0)::double precision)), (0)::double precision) AS stock_15c_corrige,
    ss.last_movement_at,
    ss.updated_at
   FROM (public.stocks_snapshot ss
     LEFT JOIN ( SELECT stocks_adjustments.depot_id,
            stocks_adjustments.citerne_id,
            stocks_adjustments.produit_id,
            stocks_adjustments.proprietaire_type,
            sum(stocks_adjustments.delta_ambiant) AS delta_ambiant_total,
            sum(stocks_adjustments.delta_15c) AS delta_15c_total
           FROM public.stocks_adjustments
          GROUP BY stocks_adjustments.depot_id, stocks_adjustments.citerne_id, stocks_adjustments.produit_id, stocks_adjustments.proprietaire_type) adj ON (((adj.depot_id = ss.depot_id) AND (adj.citerne_id = ss.citerne_id) AND (adj.produit_id = ss.produit_id) AND (adj.proprietaire_type = ss.proprietaire_type))));


--
-- Name: v_stock_actuel; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stock_actuel AS
 SELECT depot_id,
    citerne_id,
    produit_id,
    proprietaire_type,
    stock_ambiant_corrige AS stock_ambiant,
    stock_15c_corrige AS stock_15c,
    last_movement_at,
    updated_at,
    stock_ambiant_base,
    stock_15c_base,
    delta_ambiant_total,
    delta_15c_total
   FROM public.v_stocks_snapshot_corrige;


--
-- Name: v_stock_actuel_owner_snapshot; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_stock_actuel_owner_snapshot AS
 WITH base AS (
         SELECT COALESCE(sj.depot_id, c.depot_id) AS depot_id,
            sj.citerne_id,
            sj.produit_id,
            upper(TRIM(BOTH FROM COALESCE(sj.proprietaire_type, 'MONALUXE'::text))) AS proprietaire_type,
            sj.date_jour,
            sj.stock_ambiant,
            sj.stock_15c
           FROM (public.stocks_journaliers sj
             LEFT JOIN public.citernes c ON ((c.id = sj.citerne_id)))
        ), last_date AS (
         SELECT base.depot_id,
            base.citerne_id,
            base.produit_id,
            base.proprietaire_type,
            max(base.date_jour) AS date_jour
           FROM base
          GROUP BY base.depot_id, base.citerne_id, base.produit_id, base.proprietaire_type
        ), last_rows AS (
         SELECT b.depot_id,
            b.citerne_id,
            b.produit_id,
            b.proprietaire_type,
            b.date_jour,
            b.stock_ambiant,
            b.stock_15c
           FROM (base b
             JOIN last_date ld ON (((ld.depot_id = b.depot_id) AND (ld.citerne_id = b.citerne_id) AND (ld.produit_id = b.produit_id) AND (ld.proprietaire_type = b.proprietaire_type) AND (ld.date_jour = b.date_jour))))
        ), agg AS (
         SELECT last_rows.depot_id,
            last_rows.produit_id,
            last_rows.proprietaire_type,
            max(last_rows.date_jour) AS date_jour,
            sum(last_rows.stock_ambiant) AS stock_ambiant_total,
            sum(last_rows.stock_15c) AS stock_15c_total
           FROM last_rows
          GROUP BY last_rows.depot_id, last_rows.produit_id, last_rows.proprietaire_type
        )
 SELECT a.depot_id,
    d.nom AS depot_nom,
    a.produit_id,
    p.nom AS produit_nom,
    a.proprietaire_type,
    a.date_jour,
    a.stock_ambiant_total,
    a.stock_15c_total
   FROM ((agg a
     JOIN public.depots d ON ((d.id = a.depot_id)))
     JOIN public.produits p ON ((p.id = a.produit_id)));


--
-- Name: citernes citernes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citernes
    ADD CONSTRAINT citernes_pkey PRIMARY KEY (id);


--
-- Name: clients clients_nom_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_nom_key UNIQUE (nom);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: cours_de_route cours_de_route_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cours_de_route
    ADD CONSTRAINT cours_de_route_pkey PRIMARY KEY (id);


--
-- Name: depots depots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.depots
    ADD CONSTRAINT depots_pkey PRIMARY KEY (id);


--
-- Name: fournisseurs fournisseurs_nom_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fournisseurs
    ADD CONSTRAINT fournisseurs_nom_key UNIQUE (nom);


--
-- Name: fournisseurs fournisseurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fournisseurs
    ADD CONSTRAINT fournisseurs_pkey PRIMARY KEY (id);


--
-- Name: log_actions log_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_actions
    ADD CONSTRAINT log_actions_pkey PRIMARY KEY (id);


--
-- Name: partenaires partenaires_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partenaires
    ADD CONSTRAINT partenaires_pkey PRIMARY KEY (id);


--
-- Name: prises_de_hauteur prises_de_hauteur_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prises_de_hauteur
    ADD CONSTRAINT prises_de_hauteur_pkey PRIMARY KEY (id);


--
-- Name: produits produits_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produits
    ADD CONSTRAINT produits_code_key UNIQUE (code);


--
-- Name: produits produits_nom_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produits
    ADD CONSTRAINT produits_nom_key UNIQUE (nom);


--
-- Name: produits produits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produits
    ADD CONSTRAINT produits_pkey PRIMARY KEY (id);


--
-- Name: profils profils_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profils
    ADD CONSTRAINT profils_pkey PRIMARY KEY (id);


--
-- Name: receptions receptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_pkey PRIMARY KEY (id);


--
-- Name: sorties_produit sorties_produit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_pkey PRIMARY KEY (id);


--
-- Name: stocks_adjustments stocks_adjustments_dedup; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_adjustments
    ADD CONSTRAINT stocks_adjustments_dedup UNIQUE (mouvement_type, mouvement_id, delta_ambiant, delta_15c, reason);


--
-- Name: stocks_adjustments stocks_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_adjustments
    ADD CONSTRAINT stocks_adjustments_pkey PRIMARY KEY (id);


--
-- Name: stocks_journaliers stocks_journaliers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_journaliers
    ADD CONSTRAINT stocks_journaliers_pkey PRIMARY KEY (id);


--
-- Name: stocks_journaliers stocks_journaliers_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_journaliers
    ADD CONSTRAINT stocks_journaliers_unique UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type);


--
-- Name: stocks_snapshot stocks_snapshot_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_snapshot
    ADD CONSTRAINT stocks_snapshot_pkey PRIMARY KEY (id);


--
-- Name: stocks_snapshot ux_stocks_snapshot; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_snapshot
    ADD CONSTRAINT ux_stocks_snapshot UNIQUE (citerne_id, produit_id, proprietaire_type);


--
-- Name: cdr_arrive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cdr_arrive_idx ON public.cours_de_route USING btree (depot_destination_id) WHERE (statut = 'ARRIVE'::text);


--
-- Name: cdr_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cdr_date_idx ON public.cours_de_route USING btree (date_chargement);


--
-- Name: cdr_depot_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cdr_depot_idx ON public.cours_de_route USING btree (depot_destination_id);


--
-- Name: cdr_produit_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cdr_produit_idx ON public.cours_de_route USING btree (produit_id);


--
-- Name: cdr_statut_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cdr_statut_idx ON public.cours_de_route USING btree (statut);


--
-- Name: idx_cdr_hist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cdr_hist ON public.cours_de_route USING btree (depot_destination_id, statut, date_chargement DESC);


--
-- Name: idx_cdr_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cdr_statut ON public.cours_de_route USING btree (statut);


--
-- Name: idx_receptions_citerne; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receptions_citerne ON public.receptions USING btree (citerne_id);


--
-- Name: idx_receptions_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receptions_created_at ON public.receptions USING btree (created_at);


--
-- Name: idx_receptions_date_reception; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receptions_date_reception ON public.receptions USING btree (date_reception);


--
-- Name: idx_receptions_produit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receptions_produit ON public.receptions USING btree (produit_id);


--
-- Name: idx_receptions_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receptions_statut ON public.receptions USING btree (statut);


--
-- Name: idx_sorties_citerne; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sorties_citerne ON public.sorties_produit USING btree (citerne_id);


--
-- Name: idx_sorties_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sorties_created_at ON public.sorties_produit USING btree (created_at DESC);


--
-- Name: idx_sorties_date_sortie; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sorties_date_sortie ON public.sorties_produit USING btree (date_sortie);


--
-- Name: idx_sorties_produit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sorties_produit ON public.sorties_produit USING btree (produit_id);


--
-- Name: idx_sorties_statut; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sorties_statut ON public.sorties_produit USING btree (statut);


--
-- Name: idx_stocks_j_citerne_produit_date_proprio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_j_citerne_produit_date_proprio ON public.stocks_journaliers USING btree (citerne_id, produit_id, date_jour, proprietaire_type);


--
-- Name: idx_stocks_snapshot_citerne; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_snapshot_citerne ON public.stocks_snapshot USING btree (citerne_id);


--
-- Name: idx_stocks_snapshot_depot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_snapshot_depot ON public.stocks_snapshot USING btree (depot_id);


--
-- Name: idx_stocks_snapshot_produit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_snapshot_produit ON public.stocks_snapshot USING btree (produit_id);


--
-- Name: idx_stocks_snapshot_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stocks_snapshot_updated_at ON public.stocks_snapshot USING btree (updated_at);


--
-- Name: uniq_open_cdr_per_truck; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_open_cdr_per_truck ON public.cours_de_route USING btree (plaque_camion) WHERE (statut <> 'DECHARGE'::text);


--
-- Name: ux_receptions_cdr_once; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_receptions_cdr_once ON public.receptions USING btree (cours_de_route_id) WHERE (cours_de_route_id IS NOT NULL);


--
-- Name: ux_stocks_journaliers_keys; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_stocks_journaliers_keys ON public.stocks_journaliers USING btree (citerne_id, produit_id, date_jour, proprietaire_type);


--
-- Name: receptions receptions_after_ins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER receptions_after_ins AFTER INSERT ON public.receptions FOR EACH ROW WHEN ((new.statut = 'validee'::text)) EXECUTE FUNCTION public.reception_after_ins_trg();


--
-- Name: stocks_journaliers stocks_journaliers_block_writes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER stocks_journaliers_block_writes BEFORE INSERT OR DELETE OR UPDATE ON public.stocks_journaliers FOR EACH ROW EXECUTE FUNCTION public.stocks_journaliers_block_writes();


--
-- Name: receptions trg_00_receptions_block_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_00_receptions_block_update_delete BEFORE DELETE OR UPDATE ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_block_update_delete();


--
-- Name: sorties_produit trg_00_sorties_produit_block_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_00_sorties_produit_block_update_delete BEFORE DELETE OR UPDATE ON public.sorties_produit FOR EACH ROW EXECUTE FUNCTION public.sorties_produit_block_update_delete();


--
-- Name: sorties_produit trg_00_sorties_set_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_00_sorties_set_created_by BEFORE INSERT ON public.sorties_produit FOR EACH ROW EXECUTE FUNCTION public.sorties_set_created_by_default();


--
-- Name: TRIGGER trg_00_sorties_set_created_by ON sorties_produit; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER trg_00_sorties_set_created_by ON public.sorties_produit IS 'Ensure created_by is set (auth.uid()) BEFORE other BEFORE INSERT validations/triggers.';


--
-- Name: stocks_adjustments trg_00_stocks_adjustments_block_update_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_00_stocks_adjustments_block_update_delete BEFORE DELETE OR UPDATE ON public.stocks_adjustments FOR EACH ROW EXECUTE FUNCTION public.stocks_adjustments_block_update_delete();


--
-- Name: sorties_produit trg_01_sorties_set_volume_ambiant; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_01_sorties_set_volume_ambiant BEFORE INSERT OR UPDATE ON public.sorties_produit FOR EACH ROW EXECUTE FUNCTION public.sorties_set_volume_ambiant();


--
-- Name: receptions trg_receptions_check_cdr_arrive; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_receptions_check_cdr_arrive BEFORE INSERT ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_check_cdr_arrive();


--
-- Name: receptions trg_receptions_check_produit_citerne; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_receptions_check_produit_citerne BEFORE INSERT OR UPDATE OF citerne_id, produit_id ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_check_produit_citerne();


--
-- Name: receptions trg_receptions_log_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_receptions_log_created AFTER INSERT ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_log_created();


--
-- Name: receptions trg_receptions_set_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_receptions_set_created_by BEFORE INSERT ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_set_created_by_default();


--
-- Name: receptions trg_receptions_set_volume_ambiant; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_receptions_set_volume_ambiant BEFORE INSERT OR UPDATE ON public.receptions FOR EACH ROW EXECUTE FUNCTION public.receptions_set_volume_ambiant();


--
-- Name: sorties_produit trg_sortie_before_ins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sortie_before_ins BEFORE INSERT ON public.sorties_produit FOR EACH ROW WHEN ((new.statut = 'validee'::text)) EXECUTE FUNCTION public.sorties_before_validate_trg();


--
-- Name: sorties_produit trg_sortie_before_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sortie_before_upd BEFORE UPDATE ON public.sorties_produit FOR EACH ROW WHEN ((new.statut = 'validee'::text)) EXECUTE FUNCTION public.sorties_before_validate_trg();

ALTER TABLE public.sorties_produit DISABLE TRIGGER trg_sortie_before_upd;


--
-- Name: sorties_produit trg_sorties_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sorties_after_insert AFTER INSERT ON public.sorties_produit FOR EACH ROW WHEN ((new.statut = 'validee'::text)) EXECUTE FUNCTION public.sorties_after_insert_trg();


--
-- Name: sorties_produit trg_sorties_check_produit_citerne; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sorties_check_produit_citerne BEFORE INSERT OR UPDATE ON public.sorties_produit FOR EACH ROW EXECUTE FUNCTION public.sorties_check_produit_citerne();


--
-- Name: stocks_adjustments trg_stocks_adjustments_check_mouvement_ref; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stocks_adjustments_check_mouvement_ref BEFORE INSERT ON public.stocks_adjustments FOR EACH ROW EXECUTE FUNCTION public.stocks_adjustments_check_mouvement_ref();


--
-- Name: stocks_adjustments trg_stocks_adjustments_set_context_from_mouvement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stocks_adjustments_set_context_from_mouvement BEFORE INSERT ON public.stocks_adjustments FOR EACH ROW EXECUTE FUNCTION public.stocks_adjustments_set_context_from_mouvement();


--
-- Name: stocks_adjustments trg_stocks_adjustments_set_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_stocks_adjustments_set_created_by BEFORE INSERT ON public.stocks_adjustments FOR EACH ROW EXECUTE FUNCTION public.stocks_adjustments_set_created_by();


--
-- Name: citernes citernes_depot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citernes
    ADD CONSTRAINT citernes_depot_id_fkey FOREIGN KEY (depot_id) REFERENCES public.depots(id);


--
-- Name: cours_de_route cours_de_route_depot_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cours_de_route
    ADD CONSTRAINT cours_de_route_depot_destination_id_fkey FOREIGN KEY (depot_destination_id) REFERENCES public.depots(id);


--
-- Name: cours_de_route cours_de_route_fournisseur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cours_de_route
    ADD CONSTRAINT cours_de_route_fournisseur_id_fkey FOREIGN KEY (fournisseur_id) REFERENCES public.fournisseurs(id);


--
-- Name: cours_de_route cours_de_route_produit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cours_de_route
    ADD CONSTRAINT cours_de_route_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: citernes fk_citernes_produit_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citernes
    ADD CONSTRAINT fk_citernes_produit_id FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: stocks_snapshot fk_stocks_snapshot_citerne; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_snapshot
    ADD CONSTRAINT fk_stocks_snapshot_citerne FOREIGN KEY (citerne_id) REFERENCES public.citernes(id);


--
-- Name: stocks_snapshot fk_stocks_snapshot_depot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_snapshot
    ADD CONSTRAINT fk_stocks_snapshot_depot FOREIGN KEY (depot_id) REFERENCES public.depots(id);


--
-- Name: stocks_snapshot fk_stocks_snapshot_produit; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_snapshot
    ADD CONSTRAINT fk_stocks_snapshot_produit FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: log_actions log_actions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_actions
    ADD CONSTRAINT log_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: prises_de_hauteur prises_de_hauteur_citerne_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prises_de_hauteur
    ADD CONSTRAINT prises_de_hauteur_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id);


--
-- Name: profils profils_depot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profils
    ADD CONSTRAINT profils_depot_id_fkey FOREIGN KEY (depot_id) REFERENCES public.depots(id);


--
-- Name: profils profils_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profils
    ADD CONSTRAINT profils_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: receptions receptions_citerne_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id);


--
-- Name: receptions receptions_cours_de_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_cours_de_route_id_fkey FOREIGN KEY (cours_de_route_id) REFERENCES public.cours_de_route(id);


--
-- Name: receptions receptions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: receptions receptions_partenaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_partenaire_id_fkey FOREIGN KEY (partenaire_id) REFERENCES public.partenaires(id);


--
-- Name: receptions receptions_produit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: receptions receptions_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receptions
    ADD CONSTRAINT receptions_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES auth.users(id);


--
-- Name: sorties_produit sorties_produit_citerne_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id);


--
-- Name: sorties_produit sorties_produit_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: sorties_produit sorties_produit_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: sorties_produit sorties_produit_partenaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_partenaire_id_fkey FOREIGN KEY (partenaire_id) REFERENCES public.partenaires(id);


--
-- Name: sorties_produit sorties_produit_produit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: sorties_produit sorties_produit_validated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sorties_produit
    ADD CONSTRAINT sorties_produit_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES auth.users(id);


--
-- Name: stocks_journaliers stocks_journaliers_citerne_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_journaliers
    ADD CONSTRAINT stocks_journaliers_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id);


--
-- Name: stocks_journaliers stocks_journaliers_produit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stocks_journaliers
    ADD CONSTRAINT stocks_journaliers_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id);


--
-- Name: profils Insert own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Insert own profile" ON public.profils FOR INSERT WITH CHECK ((user_id = auth.uid()));


--
-- Name: profils Read own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Read own profile" ON public.profils FOR SELECT USING ((user_id = auth.uid()));


--
-- Name: profils Update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Update own profile" ON public.profils FOR UPDATE USING ((user_id = auth.uid()));


--
-- Name: cours_de_route admin_all_cours; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_all_cours ON public.cours_de_route TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: log_actions admin_all_logs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_all_logs ON public.log_actions TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: sorties_produit admin_all_sorties; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_all_sorties ON public.sorties_produit TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: stocks_journaliers admin_all_stocks; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY admin_all_stocks ON public.stocks_journaliers TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: citernes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.citernes ENABLE ROW LEVEL SECURITY;

--
-- Name: citernes citernes_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY citernes_update ON public.citernes FOR UPDATE TO authenticated USING ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text]))) WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text])));


--
-- Name: clients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

--
-- Name: cours_de_route; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.cours_de_route ENABLE ROW LEVEL SECURITY;

--
-- Name: cours_de_route cours_de_route_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cours_de_route_insert ON public.cours_de_route FOR INSERT WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text])));


--
-- Name: cours_de_route cours_de_route_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cours_de_route_select ON public.cours_de_route FOR SELECT USING (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'PCA'::text])) OR (depot_destination_id = ( SELECT current_user_profile.depot_id
   FROM public.current_user_profile))));


--
-- Name: cours_de_route cours_de_route_update_status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY cours_de_route_update_status ON public.cours_de_route FOR UPDATE TO authenticated USING (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'gerant'::text, 'operateur'::text])) AND ((( SELECT current_user_profile.depot_id
   FROM public.current_user_profile) IS NULL) OR (depot_destination_id = ( SELECT current_user_profile.depot_id
   FROM public.current_user_profile))))) WITH CHECK (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'gerant'::text, 'operateur'::text])) AND ((( SELECT current_user_profile.depot_id
   FROM public.current_user_profile) IS NULL) OR (depot_destination_id = ( SELECT current_user_profile.depot_id
   FROM public.current_user_profile))) AND ((statut <> 'DECHARGE'::text) OR (EXISTS ( SELECT 1
   FROM public.receptions r
  WHERE ((r.cours_de_route_id = r.id) AND (r.statut = 'validee'::text)))))));


--
-- Name: receptions delete_receptions_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY delete_receptions_admin ON public.receptions FOR DELETE TO authenticated USING ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = 'admin'::text));


--
-- Name: sorties_produit delete_sorties_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY delete_sorties_admin ON public.sorties_produit FOR DELETE TO authenticated USING (public.role_in(public.user_role(), VARIADIC ARRAY['admin'::text]));


--
-- Name: depots; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.depots ENABLE ROW LEVEL SECURITY;

--
-- Name: fournisseurs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fournisseurs ENABLE ROW LEVEL SECURITY;

--
-- Name: receptions insert_receptions_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY insert_receptions_authenticated ON public.receptions FOR INSERT TO authenticated WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'gerant'::text, 'operateur'::text])));


--
-- Name: sorties_produit insert_sorties_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY insert_sorties_authenticated ON public.sorties_produit FOR INSERT TO authenticated WITH CHECK (public.role_in(public.user_role(), VARIADIC ARRAY['operateur'::text, 'gerant'::text, 'directeur'::text, 'admin'::text]));


--
-- Name: log_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.log_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: log_actions log_actions_insert_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY log_actions_insert_authenticated ON public.log_actions FOR INSERT TO authenticated WITH CHECK (((user_id = auth.uid()) OR (user_id IS NULL)));


--
-- Name: log_actions logs_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY logs_admin_read ON public.log_actions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: log_actions logs_staff_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY logs_staff_read ON public.log_actions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = ANY (ARRAY['admin'::text, 'directeur'::text, 'gerant'::text, 'lecture'::text, 'pca'::text]))))));


--
-- Name: cours_de_route own_cours_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY own_cours_select ON public.cours_de_route FOR SELECT TO authenticated USING (true);


--
-- Name: profils own_profile_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY own_profile_select ON public.profils FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: sorties_produit own_sorties_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY own_sorties_select ON public.sorties_produit FOR SELECT TO authenticated USING (true);


--
-- Name: partenaires; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.partenaires ENABLE ROW LEVEL SECURITY;

--
-- Name: prises_de_hauteur; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.prises_de_hauteur ENABLE ROW LEVEL SECURITY;

--
-- Name: prises_de_hauteur prises_de_hauteur_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY prises_de_hauteur_insert ON public.prises_de_hauteur FOR INSERT WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text])));


--
-- Name: prises_de_hauteur prises_de_hauteur_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY prises_de_hauteur_select ON public.prises_de_hauteur FOR SELECT USING (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'PCA'::text])) OR (citerne_id IN ( SELECT citernes.id
   FROM public.citernes
  WHERE (citernes.depot_id = ( SELECT current_user_profile.depot_id
           FROM public.current_user_profile))))));


--
-- Name: produits; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.produits ENABLE ROW LEVEL SECURITY;

--
-- Name: profils; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profils ENABLE ROW LEVEL SECURITY;

--
-- Name: citernes read citernes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "read citernes" ON public.citernes FOR SELECT USING (true);


--
-- Name: stocks_journaliers read stocks_journaliers; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "read stocks_journaliers" ON public.stocks_journaliers FOR SELECT USING (true);


--
-- Name: citernes read_citernes_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_citernes_authenticated ON public.citernes FOR SELECT TO authenticated USING (true);


--
-- Name: clients read_clients_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_clients_authenticated ON public.clients FOR SELECT TO authenticated USING (true);


--
-- Name: depots read_depots_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_depots_authenticated ON public.depots FOR SELECT TO authenticated USING (true);


--
-- Name: fournisseurs read_fournisseurs_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_fournisseurs_authenticated ON public.fournisseurs FOR SELECT TO authenticated USING (true);


--
-- Name: partenaires read_partenaires_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_partenaires_authenticated ON public.partenaires FOR SELECT TO authenticated USING (true);


--
-- Name: produits read_produits_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_produits_authenticated ON public.produits FOR SELECT TO authenticated USING (true);


--
-- Name: receptions read_receptions_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_receptions_authenticated ON public.receptions FOR SELECT TO authenticated USING (true);


--
-- Name: sorties_produit read_sorties_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_sorties_authenticated ON public.sorties_produit FOR SELECT TO authenticated USING (true);


--
-- Name: stocks_journaliers read_stocks_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY read_stocks_authenticated ON public.stocks_journaliers FOR SELECT TO authenticated USING (true);


--
-- Name: receptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.receptions ENABLE ROW LEVEL SECURITY;

--
-- Name: sorties_produit; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sorties_produit ENABLE ROW LEVEL SECURITY;

--
-- Name: sorties_produit sorties_produit_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sorties_produit_insert ON public.sorties_produit FOR INSERT WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text])));


--
-- Name: sorties_produit sorties_produit_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sorties_produit_select ON public.sorties_produit FOR SELECT USING (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'PCA'::text])) OR (citerne_id IN ( SELECT citernes.id
   FROM public.citernes
  WHERE (citernes.depot_id = ( SELECT current_user_profile.depot_id
           FROM public.current_user_profile))))));


--
-- Name: sorties_produit sp_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sp_delete ON public.sorties_produit FOR DELETE USING (false);


--
-- Name: sorties_produit sp_insert_draft; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sp_insert_draft ON public.sorties_produit FOR INSERT WITH CHECK (true);


--
-- Name: sorties_produit sp_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sp_read ON public.sorties_produit FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profils pr
  WHERE (pr.user_id = auth.uid()))));


--
-- Name: sorties_produit sp_update_draft; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY sp_update_draft ON public.sorties_produit FOR UPDATE USING (((statut = 'brouillon'::text) AND (created_by = auth.uid()))) WITH CHECK (((statut = 'brouillon'::text) AND (created_by = auth.uid())));


--
-- Name: stocks_journaliers stocks_admin_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_admin_delete ON public.stocks_journaliers FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = ANY (ARRAY['admin'::text, 'directeur'::text]))))));


--
-- Name: stocks_journaliers stocks_j_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_j_select ON public.stocks_journaliers FOR SELECT TO authenticated USING (true);


--
-- Name: stocks_journaliers; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stocks_journaliers ENABLE ROW LEVEL SECURITY;

--
-- Name: stocks_journaliers stocks_journaliers_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_journaliers_select ON public.stocks_journaliers FOR SELECT USING (((( SELECT current_user_profile.role
   FROM public.current_user_profile) = ANY (ARRAY['admin'::text, 'directeur'::text, 'PCA'::text])) OR (citerne_id IN ( SELECT citernes.id
   FROM public.citernes
  WHERE (citernes.depot_id = ( SELECT current_user_profile.depot_id
           FROM public.current_user_profile))))));


--
-- Name: stocks_journaliers stocks_read_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_read_all ON public.stocks_journaliers FOR SELECT TO authenticated USING (true);


--
-- Name: stocks_snapshot; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.stocks_snapshot ENABLE ROW LEVEL SECURITY;

--
-- Name: stocks_snapshot stocks_snapshot_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_snapshot_admin_all ON public.stocks_snapshot TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profils p
  WHERE ((p.user_id = auth.uid()) AND (p.role = 'admin'::text)))));


--
-- Name: stocks_snapshot stocks_snapshot_read_authenticated; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stocks_snapshot_read_authenticated ON public.stocks_snapshot FOR SELECT TO authenticated USING (true);


--
-- Name: receptions update_receptions_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY update_receptions_admin ON public.receptions FOR UPDATE TO authenticated USING ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = 'admin'::text)) WITH CHECK ((( SELECT current_user_profile.role
   FROM public.current_user_profile) = 'admin'::text));


--
-- Name: sorties_produit update_sorties_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY update_sorties_admin ON public.sorties_produit FOR UPDATE TO authenticated USING (public.role_in(public.user_role(), VARIADIC ARRAY['admin'::text])) WITH CHECK (public.role_in(public.user_role(), VARIADIC ARRAY['admin'::text]));


--
-- PostgreSQL database dump complete
--

\unrestrict 47igivqcSe68Pczp7dbpiw7Kw6ZX5UDLC90e05hl7Rf56ayxssMNm51rz4ADXs6


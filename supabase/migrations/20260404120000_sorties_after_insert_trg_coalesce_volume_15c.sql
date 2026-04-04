-- Migration : harmoniser public.sorties_after_insert_trg() avec STAGING (volume_15c prioritaire).
--
-- Raison :
--   En PROD, COALESCE(NEW.volume_corrige_15c, 0) ignore volume_15c lorsque volume_corrige_15c est NULL.
--   Une sortie avec volume_15c renseigné mais volume_corrige_15c NULL débite 0 en stock @15 °C (bug métier).
--
-- Changement :
--   Utiliser COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0) pour :
--   - stock_upsert_journalier (delta @15 °C)
--   - stock_snapshot_apply_delta (delta @15 °C)
--   - log_actions.details.volume_15c (aligné sur le volume réellement débité)
--
-- Compatibilité :
--   volume_corrige_15c reste le fallback legacy (migration volume_15c en mode coexistence).
--
-- Alignement : logique validée en STAGING ; cette migration rapproche PROD sans toucher aux triggers ni aux tables.
--
-- NE PAS EXÉCUTER sans validation humaine, tests STAGING puis fenêtre PROD contrôlée.

BEGIN;

CREATE OR REPLACE FUNCTION public.sorties_after_insert_trg() RETURNS trigger
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
    -COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0),
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
    -COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0),
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
      'volume_15c', COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0),
      'date_sortie', v_date_jour,
      'client_id', NEW.client_id,
      'partenaire_id', NEW.partenaire_id
    )
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sorties_after_insert_trg() IS
'Débit stock après insert sortie validée : COALESCE(volume_15c, volume_corrige_15c, 0) pour @15 °C (alignement STAGING, fallback legacy).';

COMMIT;

-- =============================================================================
-- VALIDATION À EFFECTUER (manuelle, hors transaction ci-dessus)
-- =============================================================================
--
-- 1) Sortie avec volume_15c renseigné, volume_corrige_15c NULL (STAGING puis PROD)
--    - Insérer une sortie validee de test avec les contraintes métier respectées.
--    - Vérifier que le débit @15 °C dans stocks_journaliers / snapshot correspond à -volume_15c
--      (pas 0).
--
-- 2) Sortie avec volume_corrige_15c seul, volume_15c NULL
--    - Comportement inchangé attendu : débit = -volume_corrige_15c.
--
-- 3) Cohérence post-insert (remplacer IDs / dates selon contexte) :
--
--    SELECT * FROM public.stocks_journaliers
--    WHERE citerne_id = '<citerne>' AND produit_id = '<produit>' AND date_jour = '<date>';
--
--    SELECT * FROM public.stocks_snapshot
--    WHERE citerne_id = '<citerne>' AND produit_id = '<produit>';
--
--    SELECT * FROM public.v_stock_actuel
--    WHERE citerne_id = '<citerne>' AND produit_id = '<produit>';
--
--    SELECT details FROM public.log_actions
--    WHERE action = 'SORTIE_VALIDE' AND module = 'sorties_produit'
--    ORDER BY created_at DESC LIMIT 5;
--    -- Vérifier details->>'volume_15c' = volume réellement débité (coalesce).
--
-- 4) Après déploiement : comparer pg_get_functiondef('public.sorties_after_insert_trg()'::regproc)
--    et confirmer présence de COALESCE(NEW.volume_15c, NEW.volume_corrige_15c, 0).
--
-- =============================================================================
-- RISQUES
-- =============================================================================
--
-- - Historique : les lignes log_actions / stocks déjà écrites avant migration ne sont pas
--   recalculées ; seul le comportement des nouvelles sorties change.
-- - Dépendance : si une sortie anormale n’a ni volume_15c ni volume_corrige_15c, le débit @15 °C
--   reste 0 (comportement inchangé vs ancien COALESCE legacy seul).
-- - Rollback : redéployer la définition précédente de sorties_after_insert_trg() (sauvegarde
--   pg_get_functiondef avant migration) en cas de régression.

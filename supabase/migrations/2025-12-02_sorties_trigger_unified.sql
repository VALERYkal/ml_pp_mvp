-- Sorties — Trigger Unifié (idempotent)
-- Remplace les triggers séparés par une fonction unifiée fn_sorties_after_insert()
-- qui gère toutes les validations métier, la mise à jour des stocks journaliers
-- (avec proprietaire_type, depot_id, source) et la journalisation.

-- ============================================================================
-- ÉTAPE 1 : Migration de stocks_journaliers (ajout colonnes si manquantes)
-- ============================================================================

-- Ajouter proprietaire_type si absent
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD COLUMN proprietaire_type text DEFAULT 'MONALUXE' 
  CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE'));
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Ajouter depot_id si absent
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD COLUMN depot_id uuid REFERENCES public.depots(id);
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Ajouter source si absent
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD COLUMN source text DEFAULT 'MANUAL';
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Ajouter created_at si absent
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD COLUMN created_at timestamptz DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Ajouter updated_at si absent
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD COLUMN updated_at timestamptz DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Mettre à jour les valeurs par défaut pour les lignes existantes
UPDATE public.stocks_journaliers 
SET proprietaire_type = 'MONALUXE' 
WHERE proprietaire_type IS NULL;

UPDATE public.stocks_journaliers 
SET source = 'MANUAL' 
WHERE source IS NULL;

-- Mettre à jour depot_id depuis citernes pour les lignes existantes
UPDATE public.stocks_journaliers sj
SET depot_id = c.depot_id
FROM public.citernes c
WHERE sj.citerne_id = c.id 
  AND sj.depot_id IS NULL;

-- Supprimer anciennes contraintes UNIQUE si elles existent (plusieurs noms possibles)
ALTER TABLE public.stocks_journaliers 
DROP CONSTRAINT IF EXISTS stocks_journaliers_citerne_produit_date_key;

ALTER TABLE public.stocks_journaliers 
DROP CONSTRAINT IF EXISTS stocks_journaliers_pkey;

-- Supprimer aussi les index uniques qui pourraient servir de contrainte
DROP INDEX IF EXISTS public.stocks_journaliers_citerne_produit_date_key;
DROP INDEX IF EXISTS public.stocks_journaliers_citerne_produit_date_idx;

-- Créer nouvelle contrainte UNIQUE avec proprietaire_type
DO $$ BEGIN
  ALTER TABLE public.stocks_journaliers 
  ADD CONSTRAINT stocks_journaliers_unique 
  UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type);
EXCEPTION 
  WHEN duplicate_object THEN 
    -- Si la contrainte existe déjà, on ne fait rien
    NULL;
  WHEN OTHERS THEN 
    -- Autres erreurs (par exemple si l'index unique existe déjà)
    NULL;
END $$;

-- Index composite pour performance
CREATE INDEX IF NOT EXISTS idx_stocks_j_citerne_produit_date_proprietaire 
ON public.stocks_journaliers(citerne_id, produit_id, date_jour DESC, proprietaire_type);

-- ============================================================================
-- ÉTAPE 2 : Adapter stock_upsert_journalier pour proprietaire_type/depot_id/source
-- ============================================================================

CREATE OR REPLACE FUNCTION public.stock_upsert_journalier(
  p_citerne_id uuid,
  p_produit_id uuid,
  p_date_jour date,
  p_volume_ambiant double precision,
  p_volume_15c double precision,
  p_proprietaire_type text DEFAULT 'MONALUXE',
  p_depot_id uuid DEFAULT NULL,
  p_source text DEFAULT 'MANUAL'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Normaliser proprietaire_type
  p_proprietaire_type := upper(coalesce(trim(p_proprietaire_type), 'MONALUXE'));
  
  INSERT INTO public.stocks_journaliers (
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
  VALUES (
    p_citerne_id, 
    p_produit_id, 
    p_date_jour, 
    p_volume_ambiant, 
    p_volume_15c,
    p_proprietaire_type,
    p_depot_id,
    p_source,
    now(),
    now()
  )
  ON CONFLICT (citerne_id, produit_id, date_jour, proprietaire_type)
  DO UPDATE SET
    stock_ambiant = stocks_journaliers.stock_ambiant + EXCLUDED.stock_ambiant,
    stock_15c = stocks_journaliers.stock_15c + EXCLUDED.stock_15c,
    updated_at = now();
END; $$;

-- ============================================================================
-- ÉTAPE 3 : Adapter receptions_apply_effects() pour utiliser la nouvelle signature
-- ============================================================================

CREATE OR REPLACE FUNCTION public.receptions_apply_effects()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE 
  v_date date; 
  v_amb double precision; 
  v_15 double precision;
  v_depot_id uuid;
  v_proprietaire text;
BEGIN
  v_date := COALESCE(NEW.date_reception::date, CURRENT_DATE);
  v_amb  := COALESCE(NEW.volume_ambiant,
            CASE WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL
                 THEN NEW.index_apres - NEW.index_avant ELSE 0 END);
  v_15   := COALESCE(NEW.volume_corrige_15c, v_amb);
  
  -- Normaliser proprietaire_type
  v_proprietaire := upper(coalesce(trim(NEW.proprietaire_type), 'MONALUXE'));
  
  -- Récupérer depot_id depuis la citerne
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  -- Mettre à jour volume_ambiant si non fourni
  IF NEW.volume_ambiant IS NULL THEN
    NEW.volume_ambiant := v_amb;
  END IF;
  
  -- Créditer le stock avec les nouveaux paramètres
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id, 
    NEW.produit_id, 
    v_date, 
    v_amb, 
    v_15,
    v_proprietaire,
    v_depot_id,
    'RECEPTION'
  );
  
  -- Passer le cours de route à DECHARGE si lié
  IF NEW.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route 
    SET statut = 'DECHARGE' 
    WHERE id = NEW.cours_de_route_id;
  END IF;
  
  RETURN NEW;
END; $$;

-- ============================================================================
-- ÉTAPE 4 : Créer fn_sorties_after_insert() unifiée
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_sorties_after_insert()
RETURNS trigger AS $$
DECLARE
  v_citerne          public.citernes%ROWTYPE;
  v_depot_id         uuid;
  v_proprietaire     text;
  v_volume_ambiant   double precision;
  v_volume_15c       double precision;
  v_stock_jour       public.stocks_journaliers%ROWTYPE;
  v_date_jour        date;
BEGIN
  -- 1) Normalisation date + propriétaire
  v_date_jour := (NEW.date_sortie AT TIME ZONE 'UTC')::date;
  IF v_date_jour IS NULL THEN
    v_date_jour := CURRENT_DATE;
  END IF;
  
  v_proprietaire := upper(coalesce(trim(NEW.proprietaire_type), 'MONALUXE'));

  -- 2) Charger citerne + validations de base
  -- Note: La validation produit/citerne est déjà faite par trg_sorties_check_produit_citerne (BEFORE INSERT)
  -- mais on vérifie quand même ici pour robustesse et pour récupérer les infos de la citerne
  SELECT * INTO v_citerne
  FROM public.citernes
  WHERE id = NEW.citerne_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Citerne introuvable pour sortie %', NEW.id;
  END IF;

  IF v_citerne.statut <> 'active' THEN
    RAISE EXCEPTION 'Citerne % inactive ou en maintenance', v_citerne.id;
  END IF;

  -- Double vérification produit/citerne (déjà fait par BEFORE INSERT, mais sécurité supplémentaire)
  IF v_citerne.produit_id <> NEW.produit_id THEN
    RAISE EXCEPTION 'Produit incompatible avec la citerne %', v_citerne.id;
  END IF;

  v_depot_id := v_citerne.depot_id;

  -- 3) Normalisation des volumes
  v_volume_ambiant := coalesce(
    NEW.volume_ambiant,
    CASE 
      WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
      THEN NEW.index_apres - NEW.index_avant 
      ELSE 0 
    END
  );

  -- Convention : pour les stocks, si volume_15c est NULL
  -- on utilise soit NEW.volume_corrige_15c, soit à défaut volume_ambiant
  v_volume_15c := coalesce(NEW.volume_corrige_15c, v_volume_ambiant);

  -- 4) Cohérence propriétaire / client / partenaire
  IF v_proprietaire = 'MONALUXE' THEN
    IF NEW.client_id IS NULL THEN
      RAISE EXCEPTION 'Client obligatoire pour une sortie MONALUXE';
    END IF;
    IF NEW.partenaire_id IS NOT NULL THEN
      RAISE EXCEPTION 'partenaire_id doit être NULL pour MONALUXE';
    END IF;
  ELSIF v_proprietaire = 'PARTENAIRE' THEN
    IF NEW.partenaire_id IS NULL THEN
      RAISE EXCEPTION 'Partenaire obligatoire pour une sortie PARTENAIRE';
    END IF;
    IF NEW.client_id IS NOT NULL THEN
      RAISE EXCEPTION 'client_id doit être NULL pour PARTENAIRE';
    END IF;
  END IF;

  -- 5) Récupérer le dernier stock connu
  SELECT *
  INTO v_stock_jour
  FROM public.stocks_journaliers
  WHERE citerne_id = NEW.citerne_id
    AND produit_id = NEW.produit_id
    AND proprietaire_type = v_proprietaire
    AND date_jour <= v_date_jour
  ORDER BY date_jour DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Aucun stock journalier trouvé pour cette citerne / produit / propriétaire';
  END IF;

  -- Contrôle capacité sécurité
  IF (v_stock_jour.stock_ambiant - v_volume_ambiant) < v_citerne.capacite_securite THEN
    RAISE EXCEPTION
      'Sortie dépasserait la capacité de sécurité: stock=% sortie=% cap_securite=%',
      v_stock_jour.stock_ambiant, v_volume_ambiant, v_citerne.capacite_securite;
  END IF;

  -- 6) Upsert du stock du jour (débit)
  PERFORM public.stock_upsert_journalier(
    NEW.citerne_id,
    NEW.produit_id,
    v_date_jour,
    -1 * v_volume_ambiant,  -- Débit (négatif)
    -1 * v_volume_15c,      -- Débit (négatif)
    v_proprietaire,
    v_depot_id,
    'SORTIE'
  );

  -- 7) Log action
  INSERT INTO public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details
  )
  VALUES (
    coalesce(NEW.created_by, auth.uid()),
    'SORTIE_CREEE',
    'sorties',
    'INFO',
    jsonb_build_object(
      'sortie_id', NEW.id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'volume_ambiant', NEW.volume_ambiant,
      'volume_15c', NEW.volume_corrige_15c,
      'date_sortie', NEW.date_sortie,
      'proprietaire_type', v_proprietaire,
      'client_id', NEW.client_id,
      'partenaire_id', NEW.partenaire_id,
      'statut', NEW.statut,
      'created_by', NEW.created_by
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ÉTAPE 5 : Remplacer les triggers existants
-- ============================================================================

-- Supprimer les anciens triggers AFTER INSERT
DROP TRIGGER IF EXISTS trg_sorties_apply_effects ON public.sorties_produit;
DROP TRIGGER IF EXISTS trg_sorties_log_created ON public.sorties_produit;

-- Conserver le trigger BEFORE INSERT pour validation produit/citerne
-- (doit être fait avant l'INSERT pour éviter d'insérer une ligne invalide)
-- Le trigger trg_sorties_check_produit_citerne reste actif

-- Créer le nouveau trigger unifié AFTER INSERT
DROP TRIGGER IF EXISTS trg_sorties_after_insert ON public.sorties_produit;
CREATE TRIGGER trg_sorties_after_insert
AFTER INSERT ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION public.fn_sorties_after_insert();

-- Note: Les triggers suivants sont conservés :
-- - trg_sorties_check_produit_citerne (BEFORE INSERT/UPDATE) : validation produit/citerne
-- - trg_sortie_before_upd_trg (BEFORE UPDATE) : gestion immutabilité UPDATE

-- ============================================================================
-- ÉTAPE 6 : Nettoyage (optionnel - supprimer fonctions obsolètes)
-- ============================================================================

-- Les fonctions obsolètes peuvent être supprimées si on est sûr qu'elles ne sont plus utilisées
-- DROP FUNCTION IF EXISTS public.sorties_check_produit_citerne();
-- DROP FUNCTION IF EXISTS public.sorties_apply_effects();
-- DROP FUNCTION IF EXISTS public.sorties_log_created();

-- ============================================================================
-- COMMENTAIRES POUR DOCUMENTATION
-- ============================================================================

COMMENT ON FUNCTION public.fn_sorties_after_insert() IS 
'Trigger unifié pour les sorties : valide les données, met à jour les stocks journaliers (avec proprietaire_type, depot_id, source) et journalise l''action. Remplace les triggers AFTER INSERT séparés (sorties_apply_effects et sorties_log_created). Le trigger BEFORE INSERT sorties_check_produit_citerne est conservé pour validation produit/citerne.';

COMMENT ON FUNCTION public.stock_upsert_journalier(uuid, uuid, date, double precision, double precision, text, uuid, text) IS 
'Fonction pour upsert les stocks journaliers avec support de proprietaire_type, depot_id et source. Clé composite : (citerne_id, produit_id, date_jour, proprietaire_type).';


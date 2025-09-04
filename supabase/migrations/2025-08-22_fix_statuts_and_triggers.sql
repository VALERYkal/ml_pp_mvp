-- Fix statuts cours de route et ajout triggers manquants (idempotent)

-- A. Corriger les statuts cours de route (majuscules sans accents)
UPDATE public.cours_de_route SET statut = 'CHARGEMENT' WHERE statut = 'chargement';
UPDATE public.cours_de_route SET statut = 'TRANSIT' WHERE statut = 'transit';
UPDATE public.cours_de_route SET statut = 'FRONTIERE' WHERE statut IN ('frontiere', 'frontière');
UPDATE public.cours_de_route SET statut = 'ARRIVE' WHERE statut IN ('arrive', 'arrivé');
UPDATE public.cours_de_route SET statut = 'DECHARGE' WHERE statut IN ('decharge', 'déchargé');

-- B. Mettre à jour la contrainte CHECK pour les statuts
ALTER TABLE public.cours_de_route DROP CONSTRAINT IF EXISTS cours_de_route_statut_check;
ALTER TABLE public.cours_de_route ADD CONSTRAINT cours_de_route_statut_check 
  CHECK (statut IN ('CHARGEMENT', 'TRANSIT', 'FRONTIERE', 'ARRIVE', 'DECHARGE'));

-- C. Fonction pour upsert stocks journaliers
CREATE OR REPLACE FUNCTION public.stock_upsert_journalier(
  p_citerne_id uuid,
  p_produit_id uuid, 
  p_date_jour date,
  p_volume_ambiant double precision,
  p_volume_15c double precision
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.stocks_journaliers (citerne_id, produit_id, date_jour, stock_ambiant, stock_15c)
  VALUES (p_citerne_id, p_produit_id, p_date_jour, p_volume_ambiant, p_volume_15c)
  ON CONFLICT (citerne_id, produit_id, date_jour)
  DO UPDATE SET
    stock_ambiant = stocks_journaliers.stock_ambiant + EXCLUDED.stock_ambiant,
    stock_15c = stocks_journaliers.stock_15c + EXCLUDED.stock_15c;
END; $$;

-- D. Trigger pour réceptions (calcul volume_ambiant + crédit stock)
CREATE OR REPLACE FUNCTION public.receptions_apply_effects()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_date date; v_amb double precision; v_15 double precision;
BEGIN
  v_date := COALESCE(NEW.date_reception::date, CURRENT_DATE);
  v_amb  := COALESCE(NEW.volume_ambiant,
            CASE WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL
                 THEN NEW.index_apres - NEW.index_avant ELSE 0 END);
  v_15   := COALESCE(NEW.volume_corrige_15c, v_amb);
  
  -- Mettre à jour volume_ambiant si non fourni
  IF NEW.volume_ambiant IS NULL THEN
    NEW.volume_ambiant := v_amb;
  END IF;
  
  -- Créditer le stock
  PERFORM public.stock_upsert_journalier(NEW.citerne_id, NEW.produit_id, v_date, v_amb, v_15);
  
  -- Passer le cours de route à DECHARGE si lié
  IF NEW.cours_de_route_id IS NOT NULL THEN
    UPDATE public.cours_de_route 
    SET statut = 'DECHARGE' 
    WHERE id = NEW.cours_de_route_id;
  END IF;
  
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_receptions_apply_effects ON public.receptions;
CREATE TRIGGER trg_receptions_apply_effects
AFTER INSERT ON public.receptions
FOR EACH ROW EXECUTE FUNCTION public.receptions_apply_effects();

-- E. Logs pour réceptions
CREATE OR REPLACE FUNCTION public.receptions_log_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.log_actions(user_id, action, module, niveau, details, cible_id)
  VALUES (
    auth.uid(), 'RECEPTION_CREEE', 'receptions', 'INFO',
    jsonb_build_object(
      'reception_id', NEW.id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'volume_ambiant', NEW.volume_ambiant,
      'volume_15c', NEW.volume_corrige_15c,
      'cours_de_route_id', NEW.cours_de_route_id,
      'proprietaire_type', NEW.proprietaire_type,
      'partenaire_id', NEW.partenaire_id
    ),
    NEW.id
  );
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_receptions_log_created ON public.receptions;
CREATE TRIGGER trg_receptions_log_created
AFTER INSERT ON public.receptions
FOR EACH ROW EXECUTE FUNCTION public.receptions_log_created();

-- F. Contrainte bénéficiaire pour sorties (client OU partenaire)
ALTER TABLE public.sorties_produit DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_check;
ALTER TABLE public.sorties_produit ADD CONSTRAINT sorties_produit_beneficiaire_check
  CHECK (client_id IS NOT NULL OR partenaire_id IS NOT NULL);

-- G. Contraintes NOT NULL pour réceptions et sorties (MVP)
ALTER TABLE public.receptions ALTER COLUMN citerne_id SET NOT NULL;
ALTER TABLE public.receptions ALTER COLUMN produit_id SET NOT NULL;
ALTER TABLE public.sorties_produit ALTER COLUMN citerne_id SET NOT NULL;
ALTER TABLE public.sorties_produit ALTER COLUMN produit_id SET NOT NULL;

-- H. Index pour performance
CREATE INDEX IF NOT EXISTS idx_receptions_citerne ON public.receptions (citerne_id);
CREATE INDEX IF NOT EXISTS idx_receptions_produit ON public.receptions (produit_id);
CREATE INDEX IF NOT EXISTS idx_receptions_date ON public.receptions (date_reception);
CREATE INDEX IF NOT EXISTS idx_stocks_journaliers_date ON public.stocks_journaliers (date_jour);
CREATE INDEX IF NOT EXISTS idx_stocks_journaliers_citerne_produit ON public.stocks_journaliers (citerne_id, produit_id);

-- I. RLS pour réceptions
ALTER TABLE public.receptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS read_receptions_authenticated ON public.receptions;
DROP POLICY IF EXISTS insert_receptions_authenticated ON public.receptions;

CREATE POLICY read_receptions_authenticated
ON public.receptions FOR SELECT TO authenticated
USING (true);

CREATE POLICY insert_receptions_authenticated
ON public.receptions FOR INSERT TO authenticated
WITH CHECK (role_in(user_role(), VARIADIC ARRAY['operateur','gerant','directeur','admin']));

-- SCHEMA SQL – ML_PP MVP – vFinal

-- Dépôts
CREATE TABLE public.depots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom text NOT NULL,
  adresse text,
  created_at timestamptz DEFAULT now()
);

-- Produits
CREATE TABLE public.produits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  code text UNIQUE,
  description text,
  actif boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Fournisseurs
CREATE TABLE public.fournisseurs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  contact_personne text,
  email text,
  telephone text,
  adresse text,
  pays text,
  note_supplementaire text,
  created_at timestamptz DEFAULT now()
);

-- Clients
CREATE TABLE public.clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  contact_personne text,
  email text,
  telephone text,
  adresse text,
  pays text,
  note_supplementaire text,
  created_at timestamptz DEFAULT now()
);

-- Partenaires
CREATE TABLE public.partenaires (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom text NOT NULL,
  contact text,
  email text,
  telephone text,
  created_at timestamptz DEFAULT now()
);

-- Citernes
CREATE TABLE public.citernes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  depot_id uuid REFERENCES public.depots(id),
  nom text NOT NULL,
  capacite_totale double precision NOT NULL CHECK (capacite_totale > 0),
  capacite_securite double precision NOT NULL CHECK (capacite_securite >= 0),
  type_produit text NOT NULL,
  localisation text NOT NULL,
  statut text DEFAULT 'active' CHECK (statut IN ('active', 'inactive', 'maintenance')),
  created_at timestamptz DEFAULT now()
);

-- Cours de route
CREATE TABLE public.cours_de_route (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fournisseur_id uuid REFERENCES public.fournisseurs(id),
  depot_destination_id uuid REFERENCES public.depots(id),
  produit_id uuid REFERENCES public.produits(id),
  plaque_camion text NOT NULL,
  plaque_remorque text,
  chauffeur_nom text,
  transporteur text,
  depart_pays text,
  date_chargement date NOT NULL,
  volume numeric,
  statut text DEFAULT 'CHARGEMENT' CHECK (statut IN ('CHARGEMENT', 'TRANSIT', 'FRONTIERE', 'ARRIVE', 'DECHARGE')),
  note text,
  created_at timestamptz DEFAULT now()
);

-- Réceptions
CREATE TABLE public.receptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cours_de_route_id uuid REFERENCES public.cours_de_route(id),
  citerne_id uuid REFERENCES public.citernes(id),
  produit_id uuid REFERENCES public.produits(id),
  partenaire_id uuid REFERENCES public.partenaires(id),
  index_avant double precision NOT NULL CHECK (index_avant >= 0),
  index_apres double precision NOT NULL CHECK (index_apres >= 0),
  volume_corrige_15c double precision,
  temperature_ambiante_c double precision,
  densite_a_15 double precision,
  proprietaire_type text DEFAULT 'MONALUXE' CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  note text,
  created_at timestamptz DEFAULT now()
);

-- Sorties de produit
CREATE TABLE public.sorties_produit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  citerne_id uuid REFERENCES public.citernes(id),
  produit_id uuid REFERENCES public.produits(id),
  client_id uuid REFERENCES public.clients(id),
  partenaire_id uuid REFERENCES public.partenaires(id),
  volume_corrige_15c double precision,
  temperature_ambiante_c double precision,
  densite_a_15 double precision,
  proprietaire_type text DEFAULT 'MONALUXE' CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  note text,
  created_at timestamptz DEFAULT now()
);

-- Stocks journaliers
CREATE TABLE public.stocks_journaliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  citerne_id uuid REFERENCES public.citernes(id),
  produit_id uuid REFERENCES public.produits(id),
  date_jour date NOT NULL,
  stock_ambiant double precision NOT NULL,
  stock_15c double precision NOT NULL
);

-- Prises de hauteur (mesures manuelles)
CREATE TABLE public.prises_de_hauteur (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  citerne_id uuid REFERENCES public.citernes(id),
  volume_mesure double precision NOT NULL CHECK (volume_mesure >= 0),
  note text,
  created_at timestamptz DEFAULT now()
);

-- Profils utilisateurs
CREATE TABLE public.profils (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  nom_complet text,
  role text NOT NULL CHECK (role IN ('admin', 'directeur', 'gerant', 'lecture', 'pca')),
  depot_id uuid REFERENCES public.depots(id),
  email text,
  created_at timestamptz DEFAULT now()
);

-- Journalisation des actions (audit log)
CREATE TABLE public.log_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  module text NOT NULL,
  niveau text DEFAULT 'INFO' CHECK (niveau IN ('INFO', 'WARNING', 'CRITICAL')),
  details jsonb,
  created_at timestamptz DEFAULT now()
);

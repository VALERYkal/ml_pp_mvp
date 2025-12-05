-- SCHEMA SQL – ML_PP MVP – v4.0 (Décembre 2025)
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.
-- Use migrations in supabase/migrations/ for actual database setup.

-- ============================================================================
-- RÉFÉRENTIELS
-- ============================================================================

-- Dépôts
CREATE TABLE public.depots (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nom text NOT NULL,
  adresse text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT depots_pkey PRIMARY KEY (id)
);

-- Produits
CREATE TABLE public.produits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  code text UNIQUE,
  description text,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT produits_pkey PRIMARY KEY (id)
);

-- Fournisseurs
CREATE TABLE public.fournisseurs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  contact_personne text,
  email text,
  telephone text,
  adresse text,
  pays text,
  note_supplementaire text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT fournisseurs_pkey PRIMARY KEY (id)
);

-- Clients
CREATE TABLE public.clients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nom text NOT NULL UNIQUE,
  contact_personne text,
  email text,
  telephone text,
  adresse text,
  pays text,
  note_supplementaire text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT clients_pkey PRIMARY KEY (id)
);

-- Partenaires
CREATE TABLE public.partenaires (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nom text NOT NULL,
  contact text,
  email text,
  telephone text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT partenaires_pkey PRIMARY KEY (id)
);

-- ============================================================================
-- INFRASTRUCTURE
-- ============================================================================

-- Citernes
CREATE TABLE public.citernes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  depot_id uuid,
  nom text NOT NULL,
  capacite_totale double precision NOT NULL CHECK (capacite_totale > 0),
  capacite_securite double precision NOT NULL CHECK (capacite_securite >= 0),
  localisation text NOT NULL,
  statut text DEFAULT 'active' CHECK (statut IN ('active', 'inactive', 'maintenance')),
  produit_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT citernes_pkey PRIMARY KEY (id),
  CONSTRAINT fk_citernes_produit_id FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT citernes_depot_id_fkey FOREIGN KEY (depot_id) REFERENCES public.depots(id)
);

-- Prises de hauteur (mesures manuelles)
CREATE TABLE public.prises_de_hauteur (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  citerne_id uuid,
  volume_mesure double precision NOT NULL CHECK (volume_mesure >= 0),
  note text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT prises_de_hauteur_pkey PRIMARY KEY (id),
  CONSTRAINT prises_de_hauteur_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id)
);

-- ============================================================================
-- FLUX LOGISTIQUES
-- ============================================================================

-- Cours de route
CREATE TABLE public.cours_de_route (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
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
  statut text DEFAULT 'CHARGEMENT' CHECK (statut IN ('CHARGEMENT', 'TRANSIT', 'FRONTIERE', 'ARRIVE', 'DECHARGE')),
  note text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cours_de_route_pkey PRIMARY KEY (id),
  CONSTRAINT cours_de_route_fournisseur_id_fkey FOREIGN KEY (fournisseur_id) REFERENCES public.fournisseurs(id),
  CONSTRAINT cours_de_route_depot_destination_id_fkey FOREIGN KEY (depot_destination_id) REFERENCES public.depots(id),
  CONSTRAINT cours_de_route_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);

-- Réceptions
CREATE TABLE public.receptions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  cours_de_route_id uuid,
  citerne_id uuid NOT NULL,
  produit_id uuid NOT NULL,
  partenaire_id uuid,
  index_avant double precision NOT NULL CHECK (index_avant >= 0),
  index_apres double precision NOT NULL CHECK (index_apres >= 0),
  volume_ambiant double precision,
  volume_corrige_15c double precision,
  temperature_ambiante_c double precision,
  densite_a_15 double precision,
  proprietaire_type text DEFAULT 'MONALUXE' CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  statut text NOT NULL DEFAULT 'validee' CHECK (statut IN ('validee', 'rejetee')),
  date_reception date DEFAULT CURRENT_DATE,
  created_by uuid,
  validated_by uuid,
  note text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT receptions_pkey PRIMARY KEY (id),
  CONSTRAINT receptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT receptions_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES auth.users(id),
  CONSTRAINT receptions_cours_de_route_id_fkey FOREIGN KEY (cours_de_route_id) REFERENCES public.cours_de_route(id),
  CONSTRAINT receptions_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id),
  CONSTRAINT receptions_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT receptions_partenaire_id_fkey FOREIGN KEY (partenaire_id) REFERENCES public.partenaires(id)
);

-- Sorties de produit
CREATE TABLE public.sorties_produit (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  citerne_id uuid NOT NULL,
  produit_id uuid NOT NULL,
  client_id uuid,
  partenaire_id uuid,
  index_avant double precision CHECK (index_avant >= 0),
  index_apres double precision CHECK (index_apres >= 0),
  volume_ambiant double precision,
  volume_corrige_15c double precision,
  temperature_ambiante_c double precision,
  densite_a_15 double precision,
  proprietaire_type text DEFAULT 'MONALUXE' CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  statut text NOT NULL DEFAULT 'validee' CHECK (statut IN ('brouillon', 'validee', 'rejetee')),
  date_sortie timestamp with time zone,
  created_by uuid,
  validated_by uuid,
  chauffeur_nom text,
  plaque_camion text,
  plaque_remorque text,
  transporteur text,
  note text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT sorties_produit_pkey PRIMARY KEY (id),
  CONSTRAINT sorties_produit_beneficiaire_check CHECK (client_id IS NOT NULL OR partenaire_id IS NOT NULL),
  CONSTRAINT sorties_produit_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT sorties_produit_validated_by_fkey FOREIGN KEY (validated_by) REFERENCES auth.users(id),
  CONSTRAINT sorties_produit_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id),
  CONSTRAINT sorties_produit_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT sorties_produit_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id),
  CONSTRAINT sorties_produit_partenaire_id_fkey FOREIGN KEY (partenaire_id) REFERENCES public.partenaires(id)
);

-- ============================================================================
-- STOCKS
-- ============================================================================

-- Stocks journaliers
-- IMPORTANT: Contrainte UNIQUE composite (citerne_id, produit_id, date_jour, proprietaire_type)
-- Permet la séparation complète des stocks MONALUXE et PARTENAIRE
CREATE TABLE public.stocks_journaliers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  citerne_id uuid,
  produit_id uuid,
  date_jour date NOT NULL,
  stock_ambiant double precision NOT NULL,
  stock_15c double precision NOT NULL,
  proprietaire_type text DEFAULT 'MONALUXE' CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  depot_id uuid,
  source text DEFAULT 'SYSTEM' CHECK (source IN ('RECEPTION', 'SORTIE', 'MANUAL', 'SYSTEM')),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT stocks_journaliers_pkey PRIMARY KEY (id),
  CONSTRAINT stocks_journaliers_unique UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type),
  CONSTRAINT stocks_journaliers_citerne_id_fkey FOREIGN KEY (citerne_id) REFERENCES public.citernes(id),
  CONSTRAINT stocks_journaliers_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);

-- ============================================================================
-- UTILISATEURS & SÉCURITÉ
-- ============================================================================

-- Profils utilisateurs
CREATE TABLE public.profils (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  nom_complet text,
  role text NOT NULL CHECK (role IN ('admin', 'directeur', 'gerant', 'lecture', 'pca')),
  depot_id uuid,
  email text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profils_pkey PRIMARY KEY (id),
  CONSTRAINT profils_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT profils_depot_id_fkey FOREIGN KEY (depot_id) REFERENCES public.depots(id)
);

-- Journalisation des actions (audit log)
CREATE TABLE public.log_actions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  action text NOT NULL,
  module text NOT NULL,
  niveau text DEFAULT 'INFO' CHECK (niveau IN ('INFO', 'WARNING', 'CRITICAL')),
  details jsonb,
  cible_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT log_actions_pkey PRIMARY KEY (id),
  CONSTRAINT log_actions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- ============================================================================
-- INDEX POUR PERFORMANCE
-- ============================================================================

-- Index réceptions
CREATE INDEX IF NOT EXISTS idx_receptions_citerne ON public.receptions (citerne_id);
CREATE INDEX IF NOT EXISTS idx_receptions_produit ON public.receptions (produit_id);
CREATE INDEX IF NOT EXISTS idx_receptions_date ON public.receptions (date_reception);

-- Index sorties
CREATE INDEX IF NOT EXISTS idx_sorties_statut ON public.sorties_produit (statut);
CREATE INDEX IF NOT EXISTS idx_sorties_created_at ON public.sorties_produit (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sorties_date_sortie ON public.sorties_produit (date_sortie);
CREATE INDEX IF NOT EXISTS idx_sorties_citerne ON public.sorties_produit (citerne_id);
CREATE INDEX IF NOT EXISTS idx_sorties_produit ON public.sorties_produit (produit_id);

-- Index stocks journaliers
CREATE INDEX IF NOT EXISTS idx_stocks_journaliers_date ON public.stocks_journaliers (date_jour);
CREATE INDEX IF NOT EXISTS idx_stocks_journaliers_citerne_produit ON public.stocks_journaliers (citerne_id, produit_id);
CREATE INDEX IF NOT EXISTS idx_stocks_j_citerne_produit_date_proprietaire 
  ON public.stocks_journaliers(citerne_id, produit_id, date_jour DESC, proprietaire_type);
CREATE INDEX IF NOT EXISTS idx_stocks_journaliers_citerne_date_desc 
  ON public.stocks_journaliers (citerne_id, date_jour DESC);

-- ============================================================================
-- NOTES IMPORTANTES
-- ============================================================================

-- 1. SÉPARATION DES STOCKS PAR PROPRIÉTAIRE
--    La contrainte UNIQUE (citerne_id, produit_id, date_jour, proprietaire_type)
--    permet de séparer complètement les stocks MONALUXE et PARTENAIRE.
--    Chaque combinaison a son propre stock journalier.

-- 2. TRIGGERS SQL
--    - receptions_apply_effects() : Calcul volumes, crédit stock, journalisation
--    - fn_sorties_after_insert() : Validation, débit stock, journalisation
--    - stock_upsert_journalier() : Upsert avec support proprietaire_type, depot_id, source

-- 3. CONTRAINTES MÉTIER
--    - sorties_produit_beneficiaire_check : client_id OU partenaire_id requis
--    - citerne_id et produit_id NOT NULL pour réceptions et sorties (MVP)
--    - Validation produit/citerne via trigger BEFORE INSERT

-- 4. ROW LEVEL SECURITY (RLS)
--    Activée sur toutes les tables sensibles avec politiques par rôle.

-- 5. AUDIT TRAIL
--    Toutes les actions critiques sont journalisées dans log_actions via triggers.

-- Seed STAGING prod-like — ML_PP MVP
-- Objectif: Recréer les référentiels réels (depot + produits + 6 citernes)
-- Conforme à la vérité métier validée en DEV
--
-- Usage (opt-in explicite):
--   CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
--   ALLOW_STAGING_RESET=true \
--   SEED_FILE=staging/sql/seed_staging_prod_like.sql \
--   ./scripts/reset_staging.sh
--
-- ========================= INVARIANTS CRITIQUES =========================
-- Produits (IDs HARDCODÉS dans l'app Flutter) :
--   - 452b557c-e974-4315-b6c2-cda8487db428 → Gasoil / AGO
--   - 640cf7ec-1616-4503-a484-0a61afb20005 → Essence
--
-- Dépôt (ID fixe requis pour FK) :
--   - 11111111-1111-1111-1111-111111111111 → Dépôt Daipn
--
-- Citernes attendues UNIQUEMENT :
--   TANK1, TANK2, TANK3, TANK4, TANK5, TANK6
--
-- Citernes fantômes STRICTEMENT INTERDITES :
--   - 33333333-3333-3333-3333-333333333333 (TANK STAGING 1)
--   - 44444444-4444-4444-4444-444444444444 (TANK TEST)
-- ======================================================================

BEGIN;

-- ----------------------------------------------------------------------
-- 1) DEPOT (source de vérité métier)
-- ----------------------------------------------------------------------
INSERT INTO public.depots (id, nom, adresse, created_at)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Dépôt Daipn',
  'Route Kipushi',
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET nom = EXCLUDED.nom,
    adresse = EXCLUDED.adresse;

-- ----------------------------------------------------------------------
-- 2) PRODUITS (IDs hardcodés dans l'app)
-- ----------------------------------------------------------------------

-- Gasoil / AGO
INSERT INTO public.produits (id, nom, code, description, actif, created_at)
VALUES (
  '452b557c-e974-4315-b6c2-cda8487db428',
  'Gasoil/AGO',
  'G.O',
  'gasoil',
  TRUE,
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET nom = EXCLUDED.nom,
    code = EXCLUDED.code,
    description = EXCLUDED.description,
    actif = EXCLUDED.actif;

-- Essence
INSERT INTO public.produits (id, nom, code, description, actif, created_at)
VALUES (
  '640cf7ec-1616-4503-a484-0a61afb20005',
  'Essence',
  'ESS',
  'Essence',
  TRUE,
  NOW()
)
ON CONFLICT (id) DO UPDATE
SET nom = EXCLUDED.nom,
    code = EXCLUDED.code,
    description = EXCLUDED.description,
    actif = EXCLUDED.actif;

-- ----------------------------------------------------------------------
-- 3) CITERNES (IDs FIXES → seed idempotent)
-- ----------------------------------------------------------------------
INSERT INTO public.citernes
(id, depot_id, nom, capacite_totale, capacite_securite, localisation, statut, created_at, produit_id)
VALUES
('57da330a-1305-4582-be45-ceab0f1aa795','11111111-1111-1111-1111-111111111111','TANK1',500000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428'),
('905b3104-0324-4b5c-ba3d-ae1019746c70','11111111-1111-1111-1111-111111111111','TANK2',500000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428'),
('7bf64a46-ca77-4857-af89-2e14d9128473','11111111-1111-1111-1111-111111111111','TANK3',500000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428'),
('91d2078b-8e19-43c2-bf33-322a42cd4e94','11111111-1111-1111-1111-111111111111','TANK4',500000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428'),
('a76a08a6-9017-421e-b5d3-afe8129a8f9d','11111111-1111-1111-1111-111111111111','TANK5',300000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428'),
('6f3e0b4c-abfc-4b67-aaa0-2ca20a59ae1a','11111111-1111-1111-1111-111111111111','TANK6',300000,0,'DAIPN LSHI','active',NOW(),'452b557c-e974-4315-b6c2-cda8487db428')
ON CONFLICT (id) DO UPDATE
SET depot_id = EXCLUDED.depot_id,
    nom = EXCLUDED.nom,
    capacite_totale = EXCLUDED.capacite_totale,
    capacite_securite = EXCLUDED.capacite_securite,
    localisation = EXCLUDED.localisation,
    statut = EXCLUDED.statut,
    produit_id = EXCLUDED.produit_id;

-- ----------------------------------------------------------------------
-- 4) GARDE ANTI-FANTÔMES (HARD FAIL)
-- ----------------------------------------------------------------------
DO $$
DECLARE
  v_phantom_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_phantom_count
  FROM public.citernes
  WHERE nom IN ('TANK STAGING 1','TANK TEST')
     OR id IN (
       '33333333-3333-3333-3333-333333333333',
       '44444444-4444-4444-4444-444444444444'
     );

  IF v_phantom_count > 0 THEN
    RAISE EXCEPTION
      'INVARIANT VIOLÉ: citernes fantômes détectées (count=%).',
      v_phantom_count;
  END IF;
END $$;

COMMIT;


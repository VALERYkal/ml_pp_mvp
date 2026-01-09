-- ============================================================================
-- AXE C / C2 - RLS S2 (Row Level Security - Option S2)
-- Migration: 20260109041723_axe_c_rls_s2.sql
-- Date: 2026-01-09
-- 
-- OBJECTIF:
-- Implémenter RLS selon l'option S2:
-- - Cadres (admin, directeur, gerant, pca) → lecture globale
-- - Non-cadres (operateur, lecture) → lecture limitée au dépôt assigné
-- - CRITIQUE: SEUL admin peut créer des ajustements de stock
--
-- GARDE-FOUS:
-- ❌ Ne pas modifier triggers / fonctions AXE A
-- ❌ Ne pas changer le schéma des tables
-- ✅ Policies simples, lisibles, auditables
-- ============================================================================

-- ============================================================================
-- 1. HELPERS SQL (SECURITY DEFINER)
-- ============================================================================

-- 1.1 app_uid() : Retourne auth.uid()
CREATE OR REPLACE FUNCTION public.app_uid()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT auth.uid();
$$;

COMMENT ON FUNCTION public.app_uid() IS 'Retourne auth.uid() pour l''utilisateur actuel';

-- 1.2 app_current_role() : Lit profils.role via auth.uid()
CREATE OR REPLACE FUNCTION public.app_current_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.role
  FROM public.profils p
  WHERE p.user_id = auth.uid()
  LIMIT 1;
$$;

COMMENT ON FUNCTION public.app_current_role() IS 'Retourne le rôle de l''utilisateur actuel depuis profils';

-- 1.3 app_current_depot_id() : Lit profils.depot_id via auth.uid()
CREATE OR REPLACE FUNCTION public.app_current_depot_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.depot_id
  FROM public.profils p
  WHERE p.user_id = auth.uid()
  LIMIT 1;
$$;

COMMENT ON FUNCTION public.app_current_depot_id() IS 'Retourne le depot_id de l''utilisateur actuel depuis profils';

-- 1.4 app_is_admin() : Boolean basé sur app_current_role()
CREATE OR REPLACE FUNCTION public.app_is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT LOWER(COALESCE(public.app_current_role(), '')) = 'admin';
$$;

COMMENT ON FUNCTION public.app_is_admin() IS 'Retourne true si l''utilisateur actuel est admin';

-- 1.5 app_is_pca() : Boolean basé sur app_current_role()
CREATE OR REPLACE FUNCTION public.app_is_pca()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT LOWER(COALESCE(public.app_current_role(), '')) = 'pca';
$$;

COMMENT ON FUNCTION public.app_is_pca() IS 'Retourne true si l''utilisateur actuel est pca';

-- 1.6 app_is_cadre() : true si role ∈ {admin, directeur, gerant, pca}
CREATE OR REPLACE FUNCTION public.app_is_cadre()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT LOWER(COALESCE(public.app_current_role(), '')) IN ('admin', 'directeur', 'gerant', 'pca');
$$;

COMMENT ON FUNCTION public.app_is_cadre() IS 'Retourne true si l''utilisateur actuel est un cadre (admin, directeur, gerant, pca)';

-- ============================================================================
-- 2. ACTIVATION RLS SUR TABLES CIBLES
-- ============================================================================

-- Tables opérationnelles
ALTER TABLE IF EXISTS public.stocks_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cours_de_route ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.receptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sorties_produit ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.stocks_journaliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.citernes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profils ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.log_actions ENABLE ROW LEVEL SECURITY;

-- Référentiels
ALTER TABLE IF EXISTS public.produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.depots ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.partenaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fournisseurs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. POLICIES RLS - RÉFÉRENTIELS (SELECT global pour tous)
-- ============================================================================

-- 3.A Produits
DROP POLICY IF EXISTS produits_select ON public.produits;
CREATE POLICY produits_select ON public.produits
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS produits_insert ON public.produits;
CREATE POLICY produits_insert ON public.produits
  FOR INSERT
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS produits_update ON public.produits;
CREATE POLICY produits_update ON public.produits
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS produits_delete ON public.produits;
CREATE POLICY produits_delete ON public.produits
  FOR DELETE
  USING (public.app_is_admin());

-- 3.B Dépôts
DROP POLICY IF EXISTS depots_select ON public.depots;
CREATE POLICY depots_select ON public.depots
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS depots_insert ON public.depots;
CREATE POLICY depots_insert ON public.depots
  FOR INSERT
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS depots_update ON public.depots;
CREATE POLICY depots_update ON public.depots
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS depots_delete ON public.depots;
CREATE POLICY depots_delete ON public.depots
  FOR DELETE
  USING (public.app_is_admin());

-- 3.C Clients
DROP POLICY IF EXISTS clients_select ON public.clients;
CREATE POLICY clients_select ON public.clients
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS clients_insert ON public.clients;
CREATE POLICY clients_insert ON public.clients
  FOR INSERT
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS clients_update ON public.clients;
CREATE POLICY clients_update ON public.clients
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS clients_delete ON public.clients;
CREATE POLICY clients_delete ON public.clients
  FOR DELETE
  USING (public.app_is_admin());

-- 3.D Partenaires
DROP POLICY IF EXISTS partenaires_select ON public.partenaires;
CREATE POLICY partenaires_select ON public.partenaires
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS partenaires_insert ON public.partenaires;
CREATE POLICY partenaires_insert ON public.partenaires
  FOR INSERT
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS partenaires_update ON public.partenaires;
CREATE POLICY partenaires_update ON public.partenaires
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS partenaires_delete ON public.partenaires;
CREATE POLICY partenaires_delete ON public.partenaires
  FOR DELETE
  USING (public.app_is_admin());

-- 3.E Fournisseurs
DROP POLICY IF EXISTS fournisseurs_select ON public.fournisseurs;
CREATE POLICY fournisseurs_select ON public.fournisseurs
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS fournisseurs_insert ON public.fournisseurs;
CREATE POLICY fournisseurs_insert ON public.fournisseurs
  FOR INSERT
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS fournisseurs_update ON public.fournisseurs;
CREATE POLICY fournisseurs_update ON public.fournisseurs
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS fournisseurs_delete ON public.fournisseurs;
CREATE POLICY fournisseurs_delete ON public.fournisseurs
  FOR DELETE
  USING (public.app_is_admin());

-- ============================================================================
-- 4. POLICIES RLS - PROFILS
-- ============================================================================

-- SELECT: cadres global, non-cadres uniquement leur propre profil
DROP POLICY IF EXISTS profils_select ON public.profils;
CREATE POLICY profils_select ON public.profils
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (auth.uid() IS NOT NULL AND user_id = auth.uid())
  );

-- UPDATE: l'utilisateur peut mettre à jour certains champs de son profil (si prévu)
-- Sinon admin only - pour MVP: admin only
DROP POLICY IF EXISTS profils_update ON public.profils;
CREATE POLICY profils_update ON public.profils
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

-- INSERT: admin only (ou via backend provisioning)
DROP POLICY IF EXISTS profils_insert ON public.profils;
CREATE POLICY profils_insert ON public.profils
  FOR INSERT
  WITH CHECK (public.app_is_admin());

-- DELETE: admin only
DROP POLICY IF EXISTS profils_delete ON public.profils;
CREATE POLICY profils_delete ON public.profils
  FOR DELETE
  USING (public.app_is_admin());

-- ============================================================================
-- 5. POLICIES RLS - TABLES OPÉRATIONNELLES (SELECT)
-- ============================================================================

-- 5.A Citernes
-- SELECT: cadres global, non-cadres scoped dépôt
DROP POLICY IF EXISTS citernes_select ON public.citernes;
CREATE POLICY citernes_select ON public.citernes
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (public.app_current_depot_id() IS NOT NULL AND depot_id = public.app_current_depot_id())
  );

-- UPDATE: admin only
DROP POLICY IF EXISTS citernes_update ON public.citernes;
CREATE POLICY citernes_update ON public.citernes
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

-- INSERT: admin only
DROP POLICY IF EXISTS citernes_insert ON public.citernes;
CREATE POLICY citernes_insert ON public.citernes
  FOR INSERT
  WITH CHECK (public.app_is_admin());

-- DELETE: admin only
DROP POLICY IF EXISTS citernes_delete ON public.citernes;
CREATE POLICY citernes_delete ON public.citernes
  FOR DELETE
  USING (public.app_is_admin());

-- 5.B Cours de route
-- SELECT: cadres global, non-cadres scoped dépôt (via depot_destination_id)
DROP POLICY IF EXISTS cours_de_route_select ON public.cours_de_route;
CREATE POLICY cours_de_route_select ON public.cours_de_route
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (public.app_current_depot_id() IS NOT NULL AND depot_destination_id = public.app_current_depot_id())
  );

-- INSERT: operateur (scoped dépôt), directeur/gerant (global), admin (global)
DROP POLICY IF EXISTS cours_de_route_insert ON public.cours_de_route;
CREATE POLICY cours_de_route_insert ON public.cours_de_route
  FOR INSERT
  WITH CHECK (
    public.app_is_admin()
    OR (LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant'))
    OR (
      LOWER(COALESCE(public.app_current_role(), '')) = 'operateur'
      AND public.app_current_depot_id() IS NOT NULL
      AND depot_destination_id = public.app_current_depot_id()
    )
  );

-- UPDATE: directeur/gerant/admin (validation statuts)
DROP POLICY IF EXISTS cours_de_route_update ON public.cours_de_route;
CREATE POLICY cours_de_route_update ON public.cours_de_route
  FOR UPDATE
  USING (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  )
  WITH CHECK (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  );

-- DELETE: admin only
DROP POLICY IF EXISTS cours_de_route_delete ON public.cours_de_route;
CREATE POLICY cours_de_route_delete ON public.cours_de_route
  FOR DELETE
  USING (public.app_is_admin());

-- 5.C Réceptions
-- SELECT: cadres global, non-cadres scoped dépôt (via citerne → depot)
DROP POLICY IF EXISTS receptions_select ON public.receptions;
CREATE POLICY receptions_select ON public.receptions
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (
      public.app_current_depot_id() IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.citernes c
        WHERE c.id = receptions.citerne_id
        AND c.depot_id = public.app_current_depot_id()
      )
    )
  );

-- INSERT: operateur (scoped dépôt), directeur/gerant (global), admin (global)
DROP POLICY IF EXISTS receptions_insert ON public.receptions;
CREATE POLICY receptions_insert ON public.receptions
  FOR INSERT
  WITH CHECK (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
    OR (
      LOWER(COALESCE(public.app_current_role(), '')) = 'operateur'
      AND public.app_current_depot_id() IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.citernes c
        WHERE c.id = receptions.citerne_id
        AND c.depot_id = public.app_current_depot_id()
      )
    )
  );

-- UPDATE: directeur/gerant/admin (validation statuts)
DROP POLICY IF EXISTS receptions_update ON public.receptions;
CREATE POLICY receptions_update ON public.receptions
  FOR UPDATE
  USING (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  )
  WITH CHECK (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  );

-- DELETE: admin only
DROP POLICY IF EXISTS receptions_delete ON public.receptions;
CREATE POLICY receptions_delete ON public.receptions
  FOR DELETE
  USING (public.app_is_admin());

-- 5.D Sorties produit
-- SELECT: cadres global, non-cadres scoped dépôt (via citerne → depot)
DROP POLICY IF EXISTS sorties_produit_select ON public.sorties_produit;
CREATE POLICY sorties_produit_select ON public.sorties_produit
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (
      public.app_current_depot_id() IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.citernes c
        WHERE c.id = sorties_produit.citerne_id
        AND c.depot_id = public.app_current_depot_id()
      )
    )
  );

-- INSERT: operateur (scoped dépôt), directeur/gerant (global), admin (global)
DROP POLICY IF EXISTS sorties_produit_insert ON public.sorties_produit;
CREATE POLICY sorties_produit_insert ON public.sorties_produit
  FOR INSERT
  WITH CHECK (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
    OR (
      LOWER(COALESCE(public.app_current_role(), '')) = 'operateur'
      AND public.app_current_depot_id() IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.citernes c
        WHERE c.id = sorties_produit.citerne_id
        AND c.depot_id = public.app_current_depot_id()
      )
    )
  );

-- UPDATE: directeur/gerant/admin (validation statuts)
DROP POLICY IF EXISTS sorties_produit_update ON public.sorties_produit;
CREATE POLICY sorties_produit_update ON public.sorties_produit
  FOR UPDATE
  USING (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  )
  WITH CHECK (
    public.app_is_admin()
    OR LOWER(COALESCE(public.app_current_role(), '')) IN ('directeur', 'gerant')
  );

-- DELETE: admin only
DROP POLICY IF EXISTS sorties_produit_delete ON public.sorties_produit;
CREATE POLICY sorties_produit_delete ON public.sorties_produit
  FOR DELETE
  USING (public.app_is_admin());

-- 5.E Stocks journaliers
-- SELECT: cadres global, non-cadres scoped dépôt (via citerne → depot)
DROP POLICY IF EXISTS stocks_journaliers_select ON public.stocks_journaliers;
CREATE POLICY stocks_journaliers_select ON public.stocks_journaliers
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (
      public.app_current_depot_id() IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM public.citernes c
        WHERE c.id = stocks_journaliers.citerne_id
        AND c.depot_id = public.app_current_depot_id()
      )
    )
  );

-- INSERT/UPDATE: réservé aux triggers (AXE A) - aucune policy INSERT/UPDATE pour les utilisateurs
-- DELETE: admin only (si nécessaire, sinon none)
DROP POLICY IF EXISTS stocks_journaliers_delete ON public.stocks_journaliers;
CREATE POLICY stocks_journaliers_delete ON public.stocks_journaliers
  FOR DELETE
  USING (public.app_is_admin());

-- 5.F Log actions
-- SELECT: cadres global
DROP POLICY IF EXISTS log_actions_select ON public.log_actions;
CREATE POLICY log_actions_select ON public.log_actions
  FOR SELECT
  USING (public.app_is_cadre());

-- INSERT: tous authentifiés (pour journalisation via app)
DROP POLICY IF EXISTS log_actions_insert ON public.log_actions;
CREATE POLICY log_actions_insert ON public.log_actions
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- UPDATE/DELETE: admin only
DROP POLICY IF EXISTS log_actions_update ON public.log_actions;
CREATE POLICY log_actions_update ON public.log_actions
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

DROP POLICY IF EXISTS log_actions_delete ON public.log_actions;
CREATE POLICY log_actions_delete ON public.log_actions
  FOR DELETE
  USING (public.app_is_admin());

-- ============================================================================
-- 6. POLICIES RLS - STOCKS_ADJUSTMENTS (CRITIQUE: ADMIN ONLY INSERT)
-- ============================================================================

-- SELECT: cadres global, non-cadres scoped dépôt (via mouvement → depot)
DROP POLICY IF EXISTS stocks_adjustments_select ON public.stocks_adjustments;
CREATE POLICY stocks_adjustments_select ON public.stocks_adjustments
  FOR SELECT
  USING (
    public.app_is_cadre()
    OR (
      public.app_current_depot_id() IS NOT NULL
      AND (
        -- Si mouvement_type = 'RECEPTION', vérifier via receptions → citernes → depot
        (
          mouvement_type = 'RECEPTION'
          AND EXISTS (
            SELECT 1
            FROM public.receptions r
            JOIN public.citernes c ON c.id = r.citerne_id
            WHERE r.id = stocks_adjustments.mouvement_id
            AND c.depot_id = public.app_current_depot_id()
          )
        )
        OR
        -- Si mouvement_type = 'SORTIE', vérifier via sorties_produit → citernes → depot
        (
          mouvement_type = 'SORTIE'
          AND EXISTS (
            SELECT 1
            FROM public.sorties_produit s
            JOIN public.citernes c ON c.id = s.citerne_id
            WHERE s.id = stocks_adjustments.mouvement_id
            AND c.depot_id = public.app_current_depot_id()
          )
        )
      )
    )
  );

-- INSERT: ✅ ADMIN ONLY (CRITIQUE)
DROP POLICY IF EXISTS stocks_adjustments_insert ON public.stocks_adjustments;
CREATE POLICY stocks_adjustments_insert ON public.stocks_adjustments
  FOR INSERT
  WITH CHECK (public.app_is_admin());

-- UPDATE: interdit (historique) - admin only si exception existe
DROP POLICY IF EXISTS stocks_adjustments_update ON public.stocks_adjustments;
CREATE POLICY stocks_adjustments_update ON public.stocks_adjustments
  FOR UPDATE
  USING (public.app_is_admin())
  WITH CHECK (public.app_is_admin());

-- DELETE: interdit (historique) - admin only si exception existe
DROP POLICY IF EXISTS stocks_adjustments_delete ON public.stocks_adjustments;
CREATE POLICY stocks_adjustments_delete ON public.stocks_adjustments
  FOR DELETE
  USING (public.app_is_admin());

-- ============================================================================
-- COMMENTAIRES FINAUX
-- ============================================================================

COMMENT ON FUNCTION public.app_uid() IS 'Helper RLS S2: Retourne auth.uid()';
COMMENT ON FUNCTION public.app_current_role() IS 'Helper RLS S2: Retourne le rôle depuis profils';
COMMENT ON FUNCTION public.app_current_depot_id() IS 'Helper RLS S2: Retourne le depot_id depuis profils';
COMMENT ON FUNCTION public.app_is_admin() IS 'Helper RLS S2: Vérifie si utilisateur est admin';
COMMENT ON FUNCTION public.app_is_pca() IS 'Helper RLS S2: Vérifie si utilisateur est pca';
COMMENT ON FUNCTION public.app_is_cadre() IS 'Helper RLS S2: Vérifie si utilisateur est cadre (admin, directeur, gerant, pca)';

-- ============================================================================
-- FIN DE LA MIGRATION
-- ============================================================================

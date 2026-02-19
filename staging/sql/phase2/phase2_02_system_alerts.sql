-- ============================================================================
-- Phase 2 — Action 2 (Patch 2.1) — public.system_alerts
-- STAGING only. Additive. Reversible.
-- ============================================================================
-- Purpose: Persistence + workflow (OPEN/ACK/RESOLVED) for integrity alerts.
-- Source: v_integrity_checks (populated by sync job in Patch 2.2).
--
-- PREREQUISITES:
-- - public.update_updated_at_column() exists (from prod schema)
-- - public.app_uid(), app_current_role(), app_is_admin(), app_is_pca() exist (RLS S2)
--
-- VALIDATION (STAGING):
-- 1. Execute this script against STAGING DB
-- 2. \d+ public.system_alerts
-- 3. INSERT test row (as service_role): insert into public.system_alerts (check_code, severity, entity_type, entity_id, message) values ('TEST', 'WARN', 'CDR', gen_random_uuid(), 'Test');
-- 4. UPDATE status to 'ACK' — verify updated_at changes
-- 5. Verify RLS: pca can SELECT, others cannot
--
-- ROLLBACK: See block at bottom.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  check_code text NOT NULL,
  severity text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  message text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'OPEN',
  first_detected_at timestamptz NOT NULL DEFAULT now(),
  last_detected_at timestamptz NOT NULL DEFAULT now(),
  acknowledged_by uuid NULL,
  acknowledged_at timestamptz NULL,
  resolved_by uuid NULL,
  resolved_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT system_alerts_status_check CHECK (status IN ('OPEN', 'ACK', 'RESOLVED')),
  CONSTRAINT system_alerts_severity_check CHECK (severity IN ('CRITICAL', 'WARN')),
  CONSTRAINT system_alerts_unique_entity UNIQUE (check_code, entity_type, entity_id)
);

COMMENT ON TABLE public.system_alerts IS 'Persistance et workflow des alertes intégrité (OPEN/ACK/RESOLVED). Alimentée par job sync depuis v_integrity_checks.';
COMMENT ON COLUMN public.system_alerts.status IS 'Workflow: OPEN → ACK → RESOLVED';
COMMENT ON COLUMN public.system_alerts.last_detected_at IS 'Mise à jour par le job de sync quand anomalie toujours présente';
COMMENT ON COLUMN public.system_alerts.acknowledged_by IS 'auth.uid() de l''utilisateur ayant ACK';
COMMENT ON COLUMN public.system_alerts.resolved_by IS 'auth.uid() de l''utilisateur ayant RESOLVED';

-- ----------------------------------------------------------------------------
-- 2. TRIGGER updated_at
-- ----------------------------------------------------------------------------
-- Reuses public.update_updated_at_column() if present; else local function
DO $$
DECLARE
  fn text;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'update_updated_at_column') THEN
    fn := 'public.update_updated_at_column()';
  ELSE
    CREATE OR REPLACE FUNCTION public.system_alerts_set_updated_at() RETURNS trigger AS $inner$
    BEGIN
      NEW.updated_at = now();
      RETURN NEW;
    END;
    $inner$ LANGUAGE plpgsql;
    fn := 'public.system_alerts_set_updated_at()';
  END IF;
  DROP TRIGGER IF EXISTS system_alerts_updated_at ON public.system_alerts;
  EXECUTE 'CREATE TRIGGER system_alerts_updated_at BEFORE UPDATE ON public.system_alerts FOR EACH ROW EXECUTE FUNCTION ' || fn;
END $$;

-- ----------------------------------------------------------------------------
-- 3. INDEXES
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_system_alerts_status ON public.system_alerts (status);
CREATE INDEX IF NOT EXISTS idx_system_alerts_severity ON public.system_alerts (severity);
CREATE INDEX IF NOT EXISTS idx_system_alerts_last_detected_at ON public.system_alerts (last_detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_alerts_entity ON public.system_alerts (entity_type, entity_id);

-- ----------------------------------------------------------------------------
-- 4. RLS
-- ----------------------------------------------------------------------------
ALTER TABLE public.system_alerts ENABLE ROW LEVEL SECURITY;

-- Admin + directeur: full access (SELECT, INSERT, UPDATE, DELETE)
DROP POLICY IF EXISTS system_alerts_admin_directeur_all ON public.system_alerts;
CREATE POLICY system_alerts_admin_directeur_all ON public.system_alerts
  FOR ALL
  TO authenticated
  USING (LOWER(COALESCE(public.app_current_role(), '')) IN ('admin', 'directeur'))
  WITH CHECK (LOWER(COALESCE(public.app_current_role(), '')) IN ('admin', 'directeur'));

-- PCA: SELECT only
DROP POLICY IF EXISTS system_alerts_pca_select ON public.system_alerts;
CREATE POLICY system_alerts_pca_select ON public.system_alerts
  FOR SELECT
  TO authenticated
  USING (public.app_is_pca());

-- ----------------------------------------------------------------------------
-- 5. ROLLBACK (execute manually if needed)
-- ----------------------------------------------------------------------------
/*
DROP TABLE IF EXISTS public.system_alerts CASCADE;
-- Do NOT drop shared functions (update_updated_at_column, app_*)
*/

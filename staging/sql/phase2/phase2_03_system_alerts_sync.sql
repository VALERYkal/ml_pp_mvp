-- ============================================================================
-- Phase 2 — Action 2 (Patch 2.2) — sync_system_alerts_from_integrity
-- STAGING only. Additive. Reversible. Idempotent.
-- ============================================================================
-- Purpose: Populate and maintain public.system_alerts from public.v_integrity_checks.
-- - UPSERT: insert new, update existing (severity, message, payload, last_detected_at)
-- - REOPEN: RESOLVED → OPEN when check reappears (clears ack/resolved)
-- - AUTO-RESOLVE: OPEN/ACK → RESOLVED when check disappears (resolved_by = NULL)
--
-- PREREQUISITES: phase2_02_system_alerts.sql applied (table + RLS).
--
-- No scheduler yet — function must be invoked manually or by external job.
--
-- ROLLBACK: See block at bottom.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sync_system_alerts_from_integrity(p_limit int DEFAULT 200)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- A) UPSERT active checks from v_integrity_checks
  WITH snapshot AS (
    SELECT check_code, severity, entity_type, entity_id, message, payload
    FROM public.v_integrity_checks
    LIMIT p_limit
  )
  INSERT INTO public.system_alerts (
    check_code, severity, entity_type, entity_id, message, payload,
    first_detected_at, last_detected_at, status
  )
  SELECT
    s.check_code, s.severity, s.entity_type, s.entity_id, s.message, s.payload,
    now(), now(), 'OPEN'
  FROM snapshot s
  ON CONFLICT (check_code, entity_type, entity_id) DO UPDATE SET
    severity         = EXCLUDED.severity,
    message           = EXCLUDED.message,
    payload           = EXCLUDED.payload,
    last_detected_at  = now(),
    status            = CASE
      WHEN public.system_alerts.status = 'RESOLVED' THEN 'OPEN'
      ELSE public.system_alerts.status
    END,
    resolved_by       = CASE WHEN public.system_alerts.status = 'RESOLVED' THEN NULL ELSE public.system_alerts.resolved_by END,
    resolved_at       = CASE WHEN public.system_alerts.status = 'RESOLVED' THEN NULL ELSE public.system_alerts.resolved_at END,
    acknowledged_by   = CASE WHEN public.system_alerts.status = 'RESOLVED' THEN NULL ELSE public.system_alerts.acknowledged_by END,
    acknowledged_at   = CASE WHEN public.system_alerts.status = 'RESOLVED' THEN NULL ELSE public.system_alerts.acknowledged_at END;

  -- B) AUTO-RESOLVE: alerts no longer present in v_integrity_checks (full view, no LIMIT)
  UPDATE public.system_alerts sa
  SET
    status      = 'RESOLVED',
    resolved_by = NULL,
    resolved_at = now()
  WHERE sa.status IN ('OPEN', 'ACK')
    AND NOT EXISTS (
      SELECT 1 FROM public.v_integrity_checks v
      WHERE v.check_code = sa.check_code
        AND v.entity_type = sa.entity_type
        AND v.entity_id = sa.entity_id
    );
END;
$$;

COMMENT ON FUNCTION public.sync_system_alerts_from_integrity(int) IS
  'Synchronise system_alerts depuis v_integrity_checks. UPSERT + REOPEN (RESOLVED→OPEN) + AUTO-RESOLVE (disparus). p_limit=200 par défaut. Aucun scheduler.';

-- ============================================================================
-- MANUAL TEST PROTOCOL (STAGING)
-- ============================================================================
/*
1) Count active checks in view:
   SELECT count(*) FROM public.v_integrity_checks;

2) Run sync:
   SELECT public.sync_system_alerts_from_integrity();
   -- or with limit: SELECT public.sync_system_alerts_from_integrity(50);

3) Verify:
   - system_alerts rows inserted/updated
   - first_detected_at stable after second run:
     SELECT id, check_code, entity_type, entity_id, first_detected_at, last_detected_at, status
     FROM public.system_alerts ORDER BY last_detected_at DESC;
   - Run sync again; first_detected_at unchanged, last_detected_at updated

4) Check which alerts would be auto-resolved (not present in view):
   SELECT sa.*
   FROM public.system_alerts sa
   WHERE sa.status NOT IN ('RESOLVED')
     AND NOT EXISTS (
       SELECT 1 FROM public.v_integrity_checks v
       WHERE v.check_code = sa.check_code
         AND v.entity_type = sa.entity_type
         AND v.entity_id = sa.entity_id
     );

5) Expected status transitions:
   - New check in view → INSERT status=OPEN
   - Existing OPEN/ACK in view → UPDATE last_detected_at, severity, message, payload
   - Existing RESOLVED in view → REOPEN (status=OPEN, clear resolved/ack)
   - Not in view, status OPEN/ACK → AUTO-RESOLVE (status=RESOLVED, resolved_by=NULL)
*/

-- ============================================================================
-- ROLLBACK (execute manually if needed)
-- ============================================================================
/*
DROP FUNCTION IF EXISTS public.sync_system_alerts_from_integrity(int);
*/

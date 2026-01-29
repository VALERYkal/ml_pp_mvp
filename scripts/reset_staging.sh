#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   Reset standard (seed vide — STAGING miroir PROD):
#     CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
#     ALLOW_STAGING_RESET=true \
#     ./scripts/reset_staging.sh
#
#   Reset avec seed minimal (pour DB-tests):
#     CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
#     ALLOW_STAGING_RESET=true \
#     SEED_FILE=staging/sql/seed_staging_minimal_v2.sql \
#     ./scripts/reset_staging.sh
#
# Preconditions:
# - env/.env.staging exists (ignored by git)
# - contains STAGING_DB_URL and STAGING_PROJECT_REF
# - SEED_FILE defaults to staging/sql/seed_empty.sql if not specified (STAGING = miroir PROD)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$ROOT_DIR/env/.env.staging" ]]; then
  echo "❌ Missing env/.env.staging"
  echo "Create it from env/.env.staging.example (never commit secrets)."
  exit 1
fi

set -a
source "$ROOT_DIR/env/.env.staging"
set +a

if [[ "${ALLOW_STAGING_RESET:-false}" != "true" ]]; then
  echo "❌ ALLOW_STAGING_RESET must be 'true' to run reset."
  echo "Edit env/.env.staging and set ALLOW_STAGING_RESET=true temporarily."
  exit 1
fi

# Double-confirm guard: require explicit confirmation string
if [[ "${CONFIRM_STAGING_RESET:-}" != "I_UNDERSTAND_THIS_WILL_DROP_PUBLIC" ]]; then
  echo "❌ Missing CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC"
  echo "This reset will DROP all tables, views, and functions in the public schema."
  echo ""
  echo "Example (reset standard — seed vide):"
  echo "  CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \\"
  echo "  ALLOW_STAGING_RESET=true \\"
  echo "  ./scripts/reset_staging.sh"
  echo ""
  echo "Example (reset avec seed minimal pour DB-tests):"
  echo "  CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \\"
  echo "  ALLOW_STAGING_RESET=true \\"
  echo "  SEED_FILE=staging/sql/seed_staging_minimal_v2.sql \\"
  echo "  ./scripts/reset_staging.sh"
  exit 1
fi

# Anti-PROD guard: refuse if project ref is empty or does not match expected staging ref.
EXPECTED_REF="jgquhldzcisjnbotnskr"
if [[ -z "${STAGING_PROJECT_REF:-}" ]]; then
  echo "❌ STAGING_PROJECT_REF is empty (anti-prod guard)."
  echo "Set STAGING_PROJECT_REF=$EXPECTED_REF in env/.env.staging"
  exit 1
fi

if [[ "${STAGING_PROJECT_REF}" != "$EXPECTED_REF" ]]; then
  echo "❌ Ref mismatch. Refusing to run."
  echo "Got: ${STAGING_PROJECT_REF}"
  echo "Expected: $EXPECTED_REF"
  exit 1
fi

if [[ -z "${STAGING_DB_URL:-}" ]]; then
  echo "❌ STAGING_DB_URL is empty."
  exit 1
fi

echo "🧨 RESET STAGING DB: $STAGING_PROJECT_REF"

# PROD-READY: standard reset must restore schema too (STAGING stays usable)
SCHEMA_FILE="$ROOT_DIR/staging/sql/000_prod_schema_public.safe.sql"
if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "❌ Missing schema file: $SCHEMA_FILE"
  exit 1
fi

echo "1/3) Drop public objects..."

psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
-- Hard reset public schema content (staging only)
DO $$
DECLARE r RECORD;
BEGIN
  -- drop all views
  FOR r IN (SELECT table_schema, table_name FROM information_schema.views WHERE table_schema='public')
  LOOP
    EXECUTE format('DROP VIEW IF EXISTS public.%I CASCADE', r.table_name);
  END LOOP;

  -- drop all tables
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname='public')
  LOOP
    EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', r.tablename);
  END LOOP;

  -- drop all functions (public)
  FOR r IN (
    SELECT proname, oidvectortypes(proargtypes) AS args
    FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid
    WHERE n.nspname='public'
  )
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', r.proname, r.args);
  END LOOP;
END $$;
SQL

echo "2/3) Import schema: $SCHEMA_FILE"
psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE"

SEED_FILE="${SEED_FILE:-staging/sql/seed_empty.sql}"

# PROD-READY guard: refuse seeds that can pollute STAGING (must stay prod-like)
if [[ "$SEED_FILE" == *"minimal"* ]] || [[ "$SEED_FILE" == *"DISABLED"* ]]; then
  echo "❌ Refusing SEED_FILE='$SEED_FILE' (would pollute STAGING)."
  echo "   Use default (seed_empty.sql) or explicitly run DB-tests workflow if needed."
  exit 1
fi

echo "3/3) Seed: $SEED_FILE"
psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 -f "$ROOT_DIR/$SEED_FILE"

echo "✅ Staging reset + seed done."

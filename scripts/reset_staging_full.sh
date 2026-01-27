#!/usr/bin/env bash
set -euo pipefail

# Full reset STAGING:
# 1) Drop public objects
# 2) Import PROD schema (safe)
# 3) Apply seed empty (PROD-READY: aucune donnée fake)
#
# Usage:
#   ALLOW_STAGING_RESET=true ./scripts/reset_staging_full.sh
#
# Preconditions:
# - env/.env.staging exists (ignored by git)
# - contains STAGING_DB_URL and STAGING_PROJECT_REF
# - staging/sql/000_prod_schema_public.safe.sql exists
# - staging/sql/seed_empty.sql exists

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$ROOT_DIR/env/.env.staging" ]]; then
  echo "❌ Missing env/.env.staging"
  exit 1
fi

set -a
source "$ROOT_DIR/env/.env.staging"
set +a

if [[ "${ALLOW_STAGING_RESET:-false}" != "true" ]]; then
  echo "❌ ALLOW_STAGING_RESET must be 'true' to run."
  exit 1
fi

EXPECTED_REF="jgquhldzcisjnbotnskr"
if [[ -z "${STAGING_PROJECT_REF:-}" ]]; then
  echo "❌ STAGING_PROJECT_REF is empty (anti-prod guard)."
  exit 1
fi
if [[ "${STAGING_PROJECT_REF}" != "$EXPECTED_REF" ]]; then
  echo "❌ Ref mismatch. Refusing to run."
  echo "Got: ${STAGING_PROJECT_REF}"
  echo "Expected: $EXPECTED_REF"
  exit 1
fi

SCHEMA_FILE="$ROOT_DIR/staging/sql/000_prod_schema_public.safe.sql"
# PROD-READY: utiliser un seed propre (aucune donnée fake)
SEED_FILE="$ROOT_DIR/staging/sql/seed_empty.sql"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "❌ Missing schema file: $SCHEMA_FILE"
  exit 1
fi
if [[ ! -f "$SEED_FILE" ]]; then
  echo "❌ Missing seed file: $SEED_FILE"
  exit 1
fi

echo "🧨 FULL RESET STAGING DB: ${STAGING_PROJECT_REF}"

echo "1/3) Drop public objects..."
psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 <<'SQL'
DO $$
DECLARE r record;
BEGIN
  -- drop all tables (public)
  FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname='public') LOOP
    EXECUTE format('DROP TABLE IF EXISTS public.%I CASCADE', r.tablename);
  END LOOP;

  -- drop all views (public)
  FOR r IN (SELECT table_name FROM information_schema.views WHERE table_schema='public') LOOP
    EXECUTE format('DROP VIEW IF EXISTS public.%I CASCADE', r.table_name);
  END LOOP;

  -- drop all functions (public)
  FOR r IN (
    SELECT p.proname, oidvectortypes(p.proargtypes) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace=n.oid
    WHERE n.nspname='public'
  ) LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS public.%I(%s) CASCADE', r.proname, r.args);
  END LOOP;
END $$;
SQL

echo "2/3) Import schema: $SCHEMA_FILE"
psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE"

echo "3/3) Seed: $SEED_FILE"
psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 -f "$SEED_FILE"

echo "✅ Full staging reset + schema + seed done."

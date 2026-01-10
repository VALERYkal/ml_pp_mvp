#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "AXE D / D1 — ONE-SHOT VALIDATION (fallback .env OR --dart-define)"
echo "============================================================"
echo

section () { echo; echo "---- $1 ----"; }
ok () { echo "✅ $1"; }
warn () { echo "⚠️  $1"; }

# ---- CI mode detection (non-destructive)
# In CI: persist logs in .ci_logs/ for artifacts, skip cleanup trap
# Locally: use temp files, cleanup on exit as before
if [[ "${CI:-false}" == "true" ]] || [[ "${GITHUB_ACTIONS:-false}" == "true" ]]; then
  IS_CI=1
  mkdir -p .ci_logs
  ANALYZE_LOG=".ci_logs/analyze.log"
  BUILD_LOG=".ci_logs/build.log"
  echo "🤖 CI mode detected: logs will be persisted in .ci_logs/"
else
  IS_CI=0
  ANALYZE_LOG="${ANALYZE_LOG:-.tmp_d1_analyze.log}"
  BUILD_LOG="${BUILD_LOG:-.tmp_d1_build.log}"
  # Cleanup trap: remove temp logs on exit (local only)
  trap 'rm -f "$ANALYZE_LOG" "$BUILD_LOG"' EXIT
fi

# ---- Argument parsing (STRICT: only TARGET, no extra flags)
usage() {
  cat <<EOF
Usage: $0 {web|macos|apk|ios}

Runs D1 validation: anti-legacy audit, analyze, build, tests.

Arguments:
  TARGET    Build target (required): web, macos, apk, or ios

Environment variables (optional):
  RUN_E2E=1              Enable E2E UI tests
  E2E_PATH=...           Path to E2E test file
  SUPABASE_ENV=STAGING   Use --dart-define mode (CI/sandbox)
  SUPABASE_URL=...       Staging Supabase URL
  SUPABASE_ANON_KEY=...  Staging anon key

Examples:
  $0 web
  RUN_E2E=1 $0 macos

Note: This script does NOT accept flags like -q, --quiet, etc.
      flutter build does not support them.
EOF
  exit "${1:-2}"
}

# Parse TARGET (required, single positional argument)
if [[ "$#" -eq 0 ]]; then
  echo "❌ Missing required argument: TARGET"
  echo
  usage 2
fi

TARGET="${1:-}"
shift

# Refuse any extra arguments (prevents accidental -q injection)
if [[ "$#" -gt 0 ]]; then
  echo "❌ Unexpected extra arguments: $*"
  echo "   d1_one_shot.sh takes exactly ONE argument (TARGET)."
  echo
  usage 2
fi

# Validate TARGET early (will be checked again in build step)
case "$TARGET" in
  web|macos|apk|ios)
    # Valid target, continue
    ;;
  -h|--help|help)
    usage 0
    ;;
  *)
    echo "❌ Invalid TARGET: '$TARGET'"
    echo "   Must be one of: web, macos, apk, ios"
    echo
    usage 2
    ;;
esac

# ---- Sanity
section "0) Sanity checks"
command -v flutter >/dev/null 2>&1 || { echo "❌ flutter not found"; exit 1; }
test -f pubspec.yaml || { echo "❌ pubspec.yaml not found (run from project root)"; exit 1; }
ok "Flutter + pubspec.yaml OK"
ok "Target: $TARGET"

# ---- CI-only: flutter pub get (makes CI job self-contained)
# Locally: skip (user manages dependencies)
if [[ "$IS_CI" -eq 1 ]]; then
  section "CI: flutter pub get"
  flutter pub get
  ok "Dependencies fetched (CI mode)"
fi

# ---- Optional: include an E2E test (set RUN_E2E=1)
RUN_E2E="${RUN_E2E:-0}"
E2E_PATH="${E2E_PATH:-integration_test/stocks_adjustments_create_ui_e2e_test.dart}"

# ---- dart-define injection (optional)
# If SUPABASE_ENV, SUPABASE_URL, SUPABASE_ANON_KEY are present in environment,
# we will pass them as --dart-define. Otherwise we rely on env/.env.staging fallback.
SUPABASE_ENV="${SUPABASE_ENV:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"
TEST_USER_EMAIL="${TEST_USER_EMAIL:-}"
TEST_USER_PASSWORD="${TEST_USER_PASSWORD:-}"
TEST_USER_ROLE="${TEST_USER_ROLE:-}"
NON_ADMIN_EMAIL="${NON_ADMIN_EMAIL:-}"
NON_ADMIN_PASSWORD="${NON_ADMIN_PASSWORD:-}"

HAS_DEFINES=0
if [[ -n "$SUPABASE_ENV" && -n "$SUPABASE_URL" && -n "$SUPABASE_ANON_KEY" ]]; then
  HAS_DEFINES=1
fi

DART_DEFINES=()
if [[ "$HAS_DEFINES" -eq 1 ]]; then
  section "Using --dart-define (CI/macOS sandbox mode)"
  DART_DEFINES+=(--dart-define=SUPABASE_ENV="$SUPABASE_ENV")
  DART_DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
  DART_DEFINES+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")

  [[ -n "$SUPABASE_SERVICE_ROLE_KEY" ]] && DART_DEFINES+=(--dart-define=SUPABASE_SERVICE_ROLE_KEY="$SUPABASE_SERVICE_ROLE_KEY")
  [[ -n "$TEST_USER_EMAIL" ]] && DART_DEFINES+=(--dart-define=TEST_USER_EMAIL="$TEST_USER_EMAIL")
  [[ -n "$TEST_USER_PASSWORD" ]] && DART_DEFINES+=(--dart-define=TEST_USER_PASSWORD="$TEST_USER_PASSWORD")
  [[ -n "$TEST_USER_ROLE" ]] && DART_DEFINES+=(--dart-define=TEST_USER_ROLE="$TEST_USER_ROLE")
  [[ -n "$NON_ADMIN_EMAIL" ]] && DART_DEFINES+=(--dart-define=NON_ADMIN_EMAIL="$NON_ADMIN_EMAIL")
  [[ -n "$NON_ADMIN_PASSWORD" ]] && DART_DEFINES+=(--dart-define=NON_ADMIN_PASSWORD="$NON_ADMIN_PASSWORD")

  ok "dart-define enabled (secrets NOT printed)"
else
  section "Using env/.env.staging fallback (local mode)"
  if [[ -f "env/.env.staging" ]]; then
    ok "Found env/.env.staging (will be used by StagingEnv.load fallback)"
  else
    warn "env/.env.staging not found; tests requiring staging may fail unless you export SUPABASE_* env vars"
  fi
fi

# ---- 1) Anti-legacy greps (must be 0 hits)
section "1) Anti-legacy audit (must be 0 hits)"

PAT1='SortieDraftService|sortieDraftServiceProvider'
PAT2='createDraft\(|validateReception\(|rpcValidateReception\('
PAT3="from\\(['\"]stock_actuel['\"]\\)|from\\(['\"]v_stock_actuel_snapshot['\"]\\)|from\\(['\"]v_citerne_stock_actuel['\"]\\)|from\\(['\"]v_stock_actuel_owner_snapshot['\"]\\)|from\\(['\"]v_stocks_citerne_global_daily['\"]\\)|setViewData\\(['\"]stock_actuel['\"]\\)|setViewData\\(['\"]v_stock_actuel_snapshot['\"]\\)|setViewData\\(['\"]v_citerne_stock_actuel['\"]\\)|setViewData\\(['\"]v_stock_actuel_owner_snapshot['\"]\\)|setViewData\\(['\"]v_stocks_citerne_global_daily['\"]\\)"
PAT4='TODO.*CRITICAL'

echo "Checking: $PAT1"
if grep -R --line-number -E "$PAT1" lib/ test/ 2>/dev/null; then
  echo "❌ Legacy sortie draft references found. Fix before closing D1."
  exit 1
fi
ok "No SortieDraftService / sortieDraftServiceProvider"

echo "Checking: $PAT2"
if grep -R --line-number -E "$PAT2" lib/ test/ 2>/dev/null; then
  echo "❌ Legacy draft/validate/RPC references found. Fix before closing D1."
  exit 1
fi
ok "No createDraft / validateReception / rpcValidateReception"

echo "Checking: $PAT3"
if grep -R --line-number -E "$PAT3" lib/ test/ 2>/dev/null; then
  echo "❌ Legacy stock view/provider references found. Fix before closing D1."
  exit 1
fi
ok "No legacy stock view/provider references"

echo "Checking: $PAT4"
if grep -R --line-number -E "$PAT4" lib/ 2>/dev/null; then
  echo "❌ TODO CRITICAL found. Fix before closing D1."
  exit 1
fi
ok "No TODO CRITICAL"

# ---- 2) Analyze
section "2) flutter analyze"

# Neutraliser temporairement "set -e" uniquement pour flutter analyze
set +e
flutter analyze 2>&1 | tee "$ANALYZE_LOG"
ANALYZE_CODE=${PIPESTATUS[0]}
set -e

# Count issues for summary
ANALYZE_ERRORS=$(grep -c "error •" "$ANALYZE_LOG" || echo "0")
ANALYZE_WARNINGS=$(grep -c "warning •" "$ANALYZE_LOG" || echo "0")
ANALYZE_INFOS=$(grep -c "info •" "$ANALYZE_LOG" || echo "0")

echo
echo "📊 Analyze summary: errors=$ANALYZE_ERRORS warnings=$ANALYZE_WARNINGS infos=$ANALYZE_INFOS"
echo

# Bloquer seulement sur erreurs réelles
if [[ "$ANALYZE_ERRORS" -gt 0 ]]; then
  echo "❌ flutter analyze: $ANALYZE_ERRORS ERRORS detected. Fix before closing D1."
  exit 1
fi

# Option: ANALYZE_STRICT=1 fails on warnings too
if [[ "${ANALYZE_STRICT:-0}" -eq 1 ]] && [[ "$ANALYZE_WARNINGS" -gt 0 ]]; then
  echo "❌ flutter analyze: $ANALYZE_WARNINGS warnings detected (ANALYZE_STRICT=1 mode)."
  exit 1
fi

# Tolérer warnings/infos par défaut
if [[ "$ANALYZE_WARNINGS" -gt 0 ]] || [[ "$ANALYZE_INFOS" -gt 0 ]]; then
  warn "flutter analyze: warnings/infos only — tolerated (errors=$ANALYZE_ERRORS)"
  ok "flutter analyze OK (0 errors)"
else
  ok "flutter analyze OK (no issues)"
fi

# ---- 3) Build
section "3) Build"

# NOTE IMPORTANTE: flutter build ne supporte PAS le flag "-q" (quiet)
# Seul "--release" est supporté pour optimiser le build
# Ne jamais ajouter -q ici, sinon: "Could not find an option or flag '-q'"
#
# DART_DEFINES ne sont PAS passées au build (elles sont pour les tests uniquement)
# Le build doit être indépendant de l'env staging.

# Construct build command in array to prevent any word splitting / expansion
BUILD_CMD=()
case "$TARGET" in
  web)
    BUILD_CMD=(flutter build web --release)
    ;;
  macos)
    BUILD_CMD=(flutter build macos --release)
    ;;
  apk)
    BUILD_CMD=(flutter build apk --release)
    ;;
  ios)
    BUILD_CMD=(flutter build ios --release --no-codesign)
    ;;
  *)
    echo "❌ Unknown target '$TARGET'. Valid: web | macos | apk | ios"
    exit 1
    ;;
esac

# Display build command for transparency (useful for CI logs and debugging)
echo "Build command: ${BUILD_CMD[*]}"

# Defensive validation: ensure no forbidden flags (-q, --quiet) in build command
# This should NEVER happen given our strict parsing, but it's a safety net
if [[ "${BUILD_CMD[*]}" =~ (^|[[:space:]])-q([[:space:]]|$) ]] || [[ "${BUILD_CMD[*]}" =~ (^|[[:space:]])--quiet([[:space:]]|$) ]]; then
  echo "❌ Forbidden flag detected in build command: -q or --quiet"
  echo "   Build command: ${BUILD_CMD[*]}"
  echo "   This should NOT happen. Check for external wrappers or env modifications."
  exit 2
fi

# Execute build command, capturing output to log file
if ! "${BUILD_CMD[@]}" >"$BUILD_LOG" 2>&1; then
  echo "❌ flutter build $TARGET FAILED"
  echo "Build command: ${BUILD_CMD[*]}"
  echo
  echo "---- build log (last 60 lines) ----"
  tail -n 60 "$BUILD_LOG" || true
  echo "---- end ----"
  echo
  
  # Special detection: check if error is related to -q flag
  if grep -qE 'Could not find an option or flag "-q"|option or flag "-q"|flag "-q"' "$BUILD_LOG"; then
    echo "🔎 Detected '-q' error in build output."
    echo "   This usually comes from an external wrapper, env var, or shell function—NOT from script args."
    echo
    echo "Diagnostic steps:"
    echo "  1. Check flutter-related env vars:     env | grep -i flutter"
    echo "  2. Check for shell functions/aliases:   type flutter"
    echo "  3. Check CI scripts or wrappers:        which flutter"
    echo "  4. Trace script execution:              bash -x ./scripts/d1_one_shot.sh web"
    echo
  fi
  
  exit 1
fi

ok "flutter build $TARGET OK"

# ---- 4) Unit + widget tests
section "4) flutter test (unit + widget) — full suite"
flutter test -r expanded
ok "All unit/widget tests OK"

# ---- 5) Integration DB staging tests (AXE B must remain green)
section "5) Integration DB staging (AXE B)"
flutter test \
  test/integration/db_smoke_test.dart \
  test/integration/reception_stock_log_test.dart \
  test/integration/sortie_stock_log_test.dart \
  "${DART_DEFINES[@]}" \
  -r expanded
ok "Integration DB tests OK"

# ---- 6) Optional E2E UI test (only if RUN_E2E=1)
if [[ "$RUN_E2E" == "1" ]]; then
  section "6) E2E UI (optional) — $E2E_PATH"
  if [[ -f "$E2E_PATH" ]]; then
    flutter test "$E2E_PATH" "${DART_DEFINES[@]}" -r expanded
    ok "E2E UI test OK"
  else
    warn "E2E test file not found: $E2E_PATH (skipped)"
  fi
else
  section "6) E2E UI (optional) — skipped (set RUN_E2E=1 to enable)"
  ok "Skipped E2E"
fi

# ---- 7) Manual DB audit reminder
section "7) Manual DB audit reminder (DEPRECATED comments on legacy views)"
warn "Run SQL audit on STAGING to confirm legacy views are COMMENTed DEPRECATED (if not, apply migration)."

cat <<'SQL'

-- Check view comments (run in Supabase SQL editor / psql)
select n.nspname as schema, c.relname as view, d.description
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
left join pg_description d on d.objoid=c.oid and d.objsubid=0
where n.nspname='public'
  and c.relkind='v'
  and c.relname in (
    'stock_actuel',
    'v_citerne_stock_actuel',
    'v_stock_actuel_snapshot',
    'v_stock_actuel_owner_snapshot',
    'v_stocks_citerne_global_daily',
    'v_stock_actuel'
  )
order by c.relname;

SQL

echo
echo "============================================================"
echo "✅ D1 ONE-SHOT COMPLETED: anti-legacy + analyze + build + tests green"
echo "============================================================"

# ---- DEBUG HELPERS (commented, for troubleshooting) ----
# Uncomment these commands if you need to diagnose build issues:
#
# Show flutter-related environment variables:
#   env | grep -i flutter
#
# Check if flutter is a function/alias/wrapper:
#   type flutter
#   which flutter
#
# Trace script execution step-by-step:
#   bash -x ./scripts/d1_one_shot.sh web
#
# Confirm strict argument parsing (this should fail with clear error):
#   ./scripts/d1_one_shot.sh web -q
#
# Manual build test (should work):
#   flutter build web --release


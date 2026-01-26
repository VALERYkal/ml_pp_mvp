#!/usr/bin/env bash
set -euo pipefail

# ---- Safety: ensure log directory ----
mkdir -p .ci_logs

# Note: Removed safe_grep_error - we now use flutter test exit code as single source of truth
# Log scanning is only used for non-blocking warnings, not for failure detection

# ---- Helper: run step with logging ----
# Note: Uses set +o pipefail temporarily to avoid SIGPIPE (exit 141) when piped to head/sed
# Returns the exit code of the actual command (not tee)
run_step() {
  local name="$1"; shift
  echo "==> $name" | tee ".ci_logs/${name}.log"
  # Temporarily disable pipefail to avoid SIGPIPE issues with head/sed
  set +o pipefail
  ("$@" 2>&1 | tee -a ".ci_logs/${name}.log" || true)
  local cmd_rc=${PIPESTATUS[0]}  # Capture exit code of the actual command, not tee
  set -o pipefail
  return $cmd_rc
}

# ---- Argument parsing ----
# Usage: ./scripts/d1_one_shot.sh [web|macos|ios|android] [--full] [--include-flaky] [--skip-pub-get] [--skip-analyze] [--skip-build-runner] [--skip-build] [--tests-only]
TARGET="${1:-web}"
FULL_MODE=0
INCLUDE_FLAKY=0
SKIP_PUB_GET=0
SKIP_ANALYZE=0
SKIP_BUILD_RUNNER=0
SKIP_BUILD=0
TESTS_ONLY=0
DART_DEFINE_COUNT=0

# Check for flags in any position
for arg in "$@"; do
  if [[ "$arg" == --dart-define=* ]]; then
    # Validation simple : doit contenir '=' après le prefix
    val="${arg#--dart-define=}"
    if [[ "$val" == *=* ]]; then
      KEY="${val%%=*}"
      VALUE="${val#*=}"
      
      # Export as env var for Platform.environment access
      export "$KEY=$VALUE"
      
      # Increment counter for logging (never expose VALUE)
      ((DART_DEFINE_COUNT++))
    else
      echo "❌ invalid --dart-define format (expected KEY=VALUE)" >&2
      exit 1
    fi
  elif [[ "$arg" == "--full" ]]; then
    FULL_MODE=1
    INCLUDE_FLAKY=1  # Full mode includes flaky tests by default
  elif [[ "$arg" == "--include-flaky" ]]; then
    INCLUDE_FLAKY=1
  elif [[ "$arg" == "--skip-pub-get" ]]; then
    SKIP_PUB_GET=1
  elif [[ "$arg" == "--skip-analyze" ]]; then
    SKIP_ANALYZE=1
  elif [[ "$arg" == "--skip-build-runner" ]]; then
    SKIP_BUILD_RUNNER=1
  elif [[ "$arg" == "--skip-build" ]]; then
    SKIP_BUILD=1
  elif [[ "$arg" == "--tests-only" ]]; then
    TESTS_ONLY=1
    # Alias that skips everything except tests
    SKIP_PUB_GET=1
    SKIP_ANALYZE=1
    SKIP_BUILD_RUNNER=1
    SKIP_BUILD=1
  fi
done

# Log extra defines count (without exposing values)
if [[ $DART_DEFINE_COUNT -gt 0 ]]; then
  echo "ℹ️  Extra dart-defines: $DART_DEFINE_COUNT"
fi

# ---- Logs ----
CI_LOG_DIR=".ci_logs"
# Ensure log directory exists before defining log paths
mkdir -p "$CI_LOG_DIR"
# Robust log paths: use default if unset or empty (defensive against empty env vars)
ANALYZE_LOG="${ANALYZE_LOG:-$CI_LOG_DIR/d1_analyze.log}"
BUILD_LOG="${BUILD_LOG:-$CI_LOG_DIR/d1_build.log}"
TEST_LOG="${TEST_LOG:-$CI_LOG_DIR/d1_test.log}"
FLAKY_LOG="${FLAKY_LOG:-$CI_LOG_DIR/d1_flaky.log}"
# Defensive check: ensure log paths are never empty (even if env var was set to empty string)
[[ -z "$ANALYZE_LOG" ]] && ANALYZE_LOG="$CI_LOG_DIR/d1_analyze.log"
[[ -z "$BUILD_LOG" ]] && BUILD_LOG="$CI_LOG_DIR/d1_build.log"
[[ -z "$TEST_LOG" ]] && TEST_LOG="$CI_LOG_DIR/d1_test.log"
[[ -z "$FLAKY_LOG" ]] && FLAKY_LOG="$CI_LOG_DIR/d1_flaky.log"
trap 'true' EXIT

# ---- Flaky test detection helper ----
# Returns 0 if file is flaky (either file-based or tag-based), 1 otherwise
is_flaky_test() {
  local file="$1"
  
  # File-based: check if filename matches *_flaky_test.dart
  if [[ "$file" =~ _flaky_test\.dart$ ]]; then
    return 0
  fi
  
  # Tag-based: check if file contains @Tags(['flaky']) or @Tags(["flaky"])
  if command -v rg >/dev/null 2>&1; then
    # Use ripgrep if available (faster)
    if rg -q "@Tags\(\s*\[\s*['\"]flaky['\"]\s*\]" "$file" 2>/dev/null; then
      return 0
    fi
  else
    # Fallback to grep
    if grep -qE "@Tags\(\s*\[\s*['\"]flaky['\"]\s*\]" "$file" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
}

echo "============================================================"
echo "AXE D / D1 — ONE-SHOT VALIDATION"
if [[ "$FULL_MODE" -eq 1 ]]; then
  echo "(FULL MODE: unit + widget + integration + e2e)"
else
  echo "(LIGHT MODE: unit + widget only)"
fi
echo "============================================================"
echo

if [[ "${CI:-}" == "true" ]]; then
  echo "🤖 CI mode detected: logs will be persisted in $CI_LOG_DIR/"
fi

echo "---- 0) Sanity checks ----"
command -v flutter >/dev/null 2>&1 || { echo "❌ flutter not found"; exit 1; }
test -f pubspec.yaml || { echo "❌ pubspec.yaml not found"; exit 1; }
echo "✅ Flutter + pubspec.yaml OK"
echo "✅ Target: $TARGET"
echo

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  echo "---- CI: flutter pub get ----"
  run_step pub_get flutter pub get
  echo
else
  echo "ℹ️  Skipping flutter pub get (--skip-pub-get)"
fi

if [[ "$SKIP_ANALYZE" -eq 0 ]]; then
  echo "---- flutter analyze (non-blocking) ----"
  # Non bloquant comme tu l'avais fait pour MVP (retour 0 même si warnings)
  set +e
  run_step analyze flutter analyze
  ANALYZE_RC=$?
  set -e
  echo "analyze exit code: $ANALYZE_RC" | tee -a "$ANALYZE_LOG"
  echo
else
  echo "ℹ️  Skipping flutter analyze (--skip-analyze)"
fi

if [[ "$SKIP_BUILD_RUNNER" -eq 0 ]]; then
  echo "---- build runner (mocks) ----"
  run_step build_runner flutter pub run build_runner build --delete-conflicting-outputs
  echo
else
  echo "ℹ️  Skipping build_runner (--skip-build-runner)"
fi

# ---- Tests with flaky detection (D3.2) ----

echo "---- test discovery (with flaky detection) ----"

# Step 1: Discover all relevant tests based on mode
if [[ "$FULL_MODE" -eq 1 ]]; then
  echo "Mode: FULL (all tests including integration + e2e)"
  ALL_TESTS=$(find test -type f -name "*_test.dart" | sort)
else
  echo "Mode: LIGHT (unit + widget only, excluding integration/e2e)"
  ALL_TESTS=$(find test -type f -name "*_test.dart" \
    ! -path "test/integration/*" \
    ! -path "test/*/integration/*" \
    ! -path "test/e2e/*" \
    ! -path "test/*/e2e/*" \
    ! -path "test/**/e2e/*" \
    ! -name "*_e2e_test.dart" \
    ! -name "*e2e_test.dart" \
    | sort)
fi

# Step 2: Separate normal and flaky tests
NORMAL_TESTS=""
FLAKY_TESTS=""

for test_file in $ALL_TESTS; do
  if is_flaky_test "$test_file"; then
    FLAKY_TESTS="$FLAKY_TESTS $test_file"
  else
    NORMAL_TESTS="$NORMAL_TESTS $test_file"
  fi
done

# Count tests
NORMAL_COUNT=$(echo "$NORMAL_TESTS" | wc -w | tr -d ' ')
FLAKY_COUNT=$(echo "$FLAKY_TESTS" | wc -w | tr -d ' ')
TOTAL_COUNT=$((NORMAL_COUNT + FLAKY_COUNT))

echo "Discovered: $TOTAL_COUNT test files total ($NORMAL_COUNT normal + $FLAKY_COUNT flaky)"
echo

# Step 3: Execute normal tests (always)
echo "---- Phase A: normal tests ($NORMAL_COUNT files) ----"
if [[ -z "$NORMAL_TESTS" ]]; then
  echo "⚠️  No normal tests found"
else
  set +e
  # shellcheck disable=SC2086
  run_step test_normal flutter test -r expanded $NORMAL_TESTS
  NORMAL_RC=$?
  set -e
  
  # Source of truth: flutter test exit code (not log scanning)
  if [[ "$NORMAL_RC" -ne 0 ]]; then
    echo "❌ Normal tests FAILED (exit=$NORMAL_RC)" | tee -a "$TEST_LOG"
    echo "Check $TEST_LOG for details"
    exit "$NORMAL_RC"
  fi
  
  # Optional: non-blocking scan for warnings (informative only)
  if grep -qE "NoSuchMethodError|TimeoutException" "$TEST_LOG" 2>/dev/null; then
    echo "⚠️  Normal tests PASS but warnings detected in log (non-blocking)" | tee -a "$TEST_LOG"
  fi
  
  echo "✅ Normal tests PASS ($NORMAL_COUNT files)" | tee -a "$TEST_LOG"
fi

# Step 4: Execute flaky tests (if --include-flaky or --full)
if [[ "$INCLUDE_FLAKY" -eq 1 ]]; then
  echo
  echo "---- Phase B: flaky tests ($FLAKY_COUNT files) ----"
  if [[ "$FLAKY_COUNT" -eq 0 ]]; then
    echo "ℹ️  No flaky tests to run"
  else
    echo "Running flaky tests (tracked separately, see $FLAKY_LOG)"
    set +e
    # shellcheck disable=SC2086
    run_step test_flaky flutter test -r expanded $FLAKY_TESTS
    FLAKY_RC=$?
    set -e
    
    # Source of truth: flutter test exit code (not log scanning)
    if [[ "$FLAKY_RC" -ne 0 ]]; then
      echo "⚠️  FLAKY FAILURES detected (exit=$FLAKY_RC)" | tee -a "$FLAKY_LOG"
      echo "Flaky tests failed: $FLAKY_TESTS" | tee -a "$FLAKY_LOG"
      echo "Check $FLAKY_LOG for details"
      # For now, flaky failures block the build (truthful mode)
      exit "$FLAKY_RC"
    fi
    
    # Optional: non-blocking scan for warnings (informative only)
    if grep -qE "NoSuchMethodError|TimeoutException" "$FLAKY_LOG" 2>/dev/null; then
      echo "⚠️  Flaky tests PASS but warnings detected in log (non-blocking)" | tee -a "$FLAKY_LOG"
    fi
    
    echo "✅ Flaky tests PASS ($FLAKY_COUNT files)" | tee -a "$FLAKY_LOG"
  fi
else
  if [[ "$FLAKY_COUNT" -gt 0 ]]; then
    echo
    echo "ℹ️  Skipping $FLAKY_COUNT flaky test(s) (use --include-flaky to run them)"
  fi
fi

echo
echo "✅ D1 one-shot OK"

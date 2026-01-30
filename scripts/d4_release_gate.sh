#!/usr/bin/env bash
set -euo pipefail

# D4 Release Gate - Single command to validate if a commit is releasable
# Orchestrates: analyze + tests light (non-flaky) + build(s) essential
# Usage: ./scripts/d4_release_gate.sh [--android] [--ios]

ANDROID_BUILD=0
IOS_BUILD=0

# Parse flags (strict, non-interactive)
for arg in "$@"; do
  if [[ "$arg" == "--android" ]]; then
    ANDROID_BUILD=1
  elif [[ "$arg" == "--ios" ]]; then
    IOS_BUILD=1
  elif [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
    echo "Usage: ./scripts/d4_release_gate.sh [--android] [--ios]"
    echo "  --android: Build Android APK/AAB (optional)"
    echo "  --ios: Build iOS app (optional, no code signing)"
    exit 0
  else
    echo "❌ Unknown flag: $arg"
    echo "Usage: ./scripts/d4_release_gate.sh [--android] [--ios]"
    exit 2
  fi
done

# ---- Logs setup ----
CI_LOG_DIR=".ci_logs"
mkdir -p "$CI_LOG_DIR"

ANALYZE_LOG="$CI_LOG_DIR/d4_analyze.log"
TEST_LOG="$CI_LOG_DIR/d4_light_tests.log"
BUILD_WEB_LOG="$CI_LOG_DIR/d4_build_web.log"
BUILD_ANDROID_LOG="$CI_LOG_DIR/d4_build_android.log"
BUILD_IOS_LOG="$CI_LOG_DIR/d4_build_ios.log"
TIMINGS_LOG="$CI_LOG_DIR/d4_timings.txt"
FINAL_STATUS=0

# Clean up function (trap)
cleanup() {
  if [[ "$FINAL_STATUS" -ne 0 ]]; then
    echo
    echo "❌ D4 Release Gate FAILED (exit=$FINAL_STATUS)"
    echo "Check logs in $CI_LOG_DIR/ for details"
  fi
}
trap cleanup EXIT

# Time tracking helper
start_time() {
  echo "$(date +%s)" > "$CI_LOG_DIR/.d4_start_time"
}

elapsed_time() {
  if [[ -f "$CI_LOG_DIR/.d4_start_time" ]]; then
    local start=$(cat "$CI_LOG_DIR/.d4_start_time")
    local end=$(date +%s)
    echo $((end - start))
  else
    echo "0"
  fi
}

record_timing() {
  local phase="$1"
  local duration="$2"
  echo "$phase: ${duration}s" >> "$TIMINGS_LOG"
}

# ---- Header (observability) ----
echo "============================================================"
echo "AXE D / D4 — RELEASE GATE"
echo "============================================================"
echo
echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Git SHA: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
fi
if command -v flutter >/dev/null 2>&1; then
  # Fix "Broken pipe": capture version sans pipe pour éviter FileSystemException
  # (head peut fermer le pipe avant que flutter --version termine)
  FLUTTER_VERSION_FULL=$(flutter --version 2>/dev/null || echo 'N/A')
  FLUTTER_VERSION_LINE=$(echo "$FLUTTER_VERSION_FULL" | head -1 || echo 'N/A')
  echo "Flutter version: $FLUTTER_VERSION_LINE"
fi
echo "Build targets: web${ANDROID_BUILD:+" + android"}${IOS_BUILD:+" + ios"}"
echo

start_time

# ---- Step 0: Environment guard (security) ----
echo "---- Step 0: Environment Guard ----"
if ! bash scripts/d4_env_guard.sh 2>&1 | tee "$CI_LOG_DIR/d4_env_guard.log"; then
  echo "❌ Environment guard FAILED"
  exit 1
fi
ENV_GUARD_TIME=$(elapsed_time)
record_timing "env_guard" "$ENV_GUARD_TIME"
echo

# ---- Step 1: flutter pub get ----
echo "---- Step 1: flutter pub get ----"
PUB_GET_START=$(date +%s)
set +e
flutter pub get 2>&1 | tee "$CI_LOG_DIR/d4_pub_get.log"
PUB_GET_RC=${PIPESTATUS[0]}
set -e
PUB_GET_TIME=$(($(date +%s) - PUB_GET_START))
record_timing "pub_get" "$PUB_GET_TIME"

if [[ "$PUB_GET_RC" -ne 0 ]]; then
  echo "❌ flutter pub get FAILED (exit=$PUB_GET_RC)"
  echo "Check $CI_LOG_DIR/d4_pub_get.log for details"
  exit 1
fi
echo "✅ pub get OK (${PUB_GET_TIME}s)"
echo

# ---- Step 2: flutter analyze ----
echo "---- Step 2: flutter analyze ----"
ANALYZE_START=$(date +%s)
set +e
# Fix: bloquer uniquement sur erreurs (P0), pas sur infos/warnings
# --no-fatal-infos et --no-fatal-warnings permettent de continuer si seuls des warnings/infos existent
flutter analyze --no-fatal-infos --no-fatal-warnings 2>&1 | tee "$ANALYZE_LOG"
ANALYZE_RC=${PIPESTATUS[0]}
set -e
ANALYZE_TIME=$(($(date +%s) - ANALYZE_START))
record_timing "analyze" "$ANALYZE_TIME"

if [[ "$ANALYZE_RC" -ne 0 ]]; then
  echo "❌ flutter analyze FAILED (exit=$ANALYZE_RC)"
  echo "---- Last 60 lines of analyze log ----"
  tail -n 60 "$ANALYZE_LOG" || true
  echo "---- End of analyze log ----"
  echo "Full log: $ANALYZE_LOG"
  exit 1
fi

# Check for actual errors (not just warnings)
if grep -qF "error •" "$ANALYZE_LOG"; then
  echo "❌ flutter analyze: ERRORS detected"
  echo "---- Last 60 lines of analyze log ----"
  tail -n 60 "$ANALYZE_LOG" || true
  echo "---- End of analyze log ----"
  echo "Full log: $ANALYZE_LOG"
  exit 1
fi

echo "✅ analyze OK (${ANALYZE_TIME}s, 0 errors)"
echo

# ---- Step 3: Tests light (non-flaky via D1/D3.2) ----
echo "---- Step 3: Tests light (non-flaky) ----"
TEST_START=$(date +%s)
set +e
bash scripts/d1_one_shot.sh web --tests-only 2>&1 | tee "$TEST_LOG"
TEST_RC=${PIPESTATUS[0]}
set -e
TEST_TIME=$(($(date +%s) - TEST_START))
record_timing "tests_light" "$TEST_TIME"

if [[ "$TEST_RC" -ne 0 ]]; then
  echo "❌ Tests light FAILED (exit=$TEST_RC)"
  echo "---- Last 60 lines of test log ----"
  tail -n 60 "$TEST_LOG" || true
  echo "---- End of test log ----"
  echo "Full log: $TEST_LOG"
  exit 1
fi

# Extract test counts from log (if available)
NORMAL_COUNT=$(grep -oE "normal tests PASS \([0-9]+" "$TEST_LOG" | grep -oE "[0-9]+" | head -1 || echo "?")
FLAKY_COUNT=$(grep -oE "Skipping [0-9]+ flaky" "$TEST_LOG" | grep -oE "[0-9]+" | head -1 || echo "0")

echo "✅ Tests light OK (${TEST_TIME}s, normal: ${NORMAL_COUNT}, flaky skipped: ${FLAKY_COUNT})"
echo

# ---- Step 4: Builds ----
# 4a: Web (always)
echo "---- Step 4a: Build web (release) ----"
BUILD_WEB_START=$(date +%s)
set +e
flutter build web --release 2>&1 | tee "$BUILD_WEB_LOG"
BUILD_WEB_RC=${PIPESTATUS[0]}
set -e
BUILD_WEB_TIME=$(($(date +%s) - BUILD_WEB_START))
record_timing "build_web" "$BUILD_WEB_TIME"

if [[ "$BUILD_WEB_RC" -ne 0 ]]; then
  echo "❌ Build web FAILED (exit=$BUILD_WEB_RC)"
  echo "---- Last 60 lines of build log ----"
  tail -n 60 "$BUILD_WEB_LOG" || true
  echo "---- End of build log ----"
  echo "Full log: $BUILD_WEB_LOG"
  exit 1
fi
echo "✅ Build web OK (${BUILD_WEB_TIME}s)"
echo

# 4b: Android (optional)
if [[ "$ANDROID_BUILD" -eq 1 ]]; then
  echo "---- Step 4b: Build Android (release) ----"
  BUILD_ANDROID_START=$(date +%s)
  set +e
  flutter build apk --release 2>&1 | tee "$BUILD_ANDROID_LOG"
  BUILD_ANDROID_RC=${PIPESTATUS[0]}
  set -e
  BUILD_ANDROID_TIME=$(($(date +%s) - BUILD_ANDROID_START))
  record_timing "build_android" "$BUILD_ANDROID_TIME"

  if [[ "$BUILD_ANDROID_RC" -ne 0 ]]; then
    echo "❌ Build Android FAILED (exit=$BUILD_ANDROID_RC)"
    echo "---- Last 60 lines of build log ----"
    tail -n 60 "$BUILD_ANDROID_LOG" || true
    echo "---- End of build log ----"
    echo "Full log: $BUILD_ANDROID_LOG"
    exit 1
  fi
  echo "✅ Build Android OK (${BUILD_ANDROID_TIME}s)"
  echo
fi

# 4c: iOS (optional)
if [[ "$IOS_BUILD" -eq 1 ]]; then
  echo "---- Step 4c: Build iOS (release, no code signing) ----"
  BUILD_IOS_START=$(date +%s)
  set +e
  flutter build ios --release --no-codesign 2>&1 | tee "$BUILD_IOS_LOG"
  BUILD_IOS_RC=${PIPESTATUS[0]}
  set -e
  BUILD_IOS_TIME=$(($(date +%s) - BUILD_IOS_START))
  record_timing "build_ios" "$BUILD_IOS_TIME"

  if [[ "$BUILD_IOS_RC" -ne 0 ]]; then
    echo "❌ Build iOS FAILED (exit=$BUILD_IOS_RC)"
    echo "---- Last 60 lines of build log ----"
    tail -n 60 "$BUILD_IOS_LOG" || true
    echo "---- End of build log ----"
    echo "Full log: $BUILD_IOS_LOG"
    exit 1
  fi
  echo "✅ Build iOS OK (${BUILD_IOS_TIME}s)"
  echo
fi

# ---- Step 5: Final environment guard (anti-secrets in logs) ----
echo "---- Step 5: Final environment guard (anti-secrets) ----"
FINAL_GUARD_START=$(date +%s)
if ! bash scripts/d4_env_guard.sh 2>&1 | tee -a "$CI_LOG_DIR/d4_env_guard.log"; then
  echo "❌ Final environment guard FAILED (secrets detected in logs)"
  exit 1
fi
FINAL_GUARD_TIME=$(($(date +%s) - FINAL_GUARD_START))
record_timing "final_env_guard" "$FINAL_GUARD_TIME"
echo

# ---- Summary ----
TOTAL_TIME=$(elapsed_time)
record_timing "TOTAL" "$TOTAL_TIME"

echo "============================================================"
echo "✅ D4 RELEASE GATE PASS"
echo "============================================================"
echo
echo "Summary:"
echo "  Total duration: ${TOTAL_TIME}s"
echo "  Tests: normal=${NORMAL_COUNT}, flaky skipped=${FLAKY_COUNT}"
echo "  Builds: web ✅${ANDROID_BUILD:+" android ✅"}${IOS_BUILD:+" ios ✅"}"
echo
echo "Logs location: $CI_LOG_DIR/"
echo "  - analyze: $ANALYZE_LOG"
echo "  - tests: $TEST_LOG"
echo "  - build web: $BUILD_WEB_LOG"
if [[ "$ANDROID_BUILD" -eq 1 ]]; then
  echo "  - build android: $BUILD_ANDROID_LOG"
fi
if [[ "$IOS_BUILD" -eq 1 ]]; then
  echo "  - build ios: $BUILD_IOS_LOG"
fi
echo "  - timings: $TIMINGS_LOG"
echo

# Clean up temporary time tracking
rm -f "$CI_LOG_DIR/.d4_start_time"

FINAL_STATUS=0

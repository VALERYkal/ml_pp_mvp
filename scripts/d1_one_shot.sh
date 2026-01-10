#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-web}" # web|macos|ios|android (pour l'instant on gère web simplement)

# ---- Logs ----
CI_LOG_DIR=".ci_logs"
ANALYZE_LOG="${ANALYZE_LOG:-$CI_LOG_DIR/d1_analyze.log}"
BUILD_LOG="${BUILD_LOG:-$CI_LOG_DIR/d1_build.log}"

mkdir -p "$CI_LOG_DIR"
trap 'true' EXIT

echo "============================================================"
echo "AXE D / D1 — ONE-SHOT VALIDATION (fallback .env OR --dart-define)"
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

echo "---- CI: flutter pub get ----"
flutter pub get 2>&1 | tee -a "$BUILD_LOG"
echo

echo "---- flutter analyze (non-blocking) ----"
# Non bloquant comme tu l'avais fait pour MVP (retour 0 même si warnings)
set +e
flutter analyze 2>&1 | tee -a "$ANALYZE_LOG"
ANALYZE_RC=${PIPESTATUS[0]}
set -e
echo "analyze exit code: $ANALYZE_RC" | tee -a "$ANALYZE_LOG"
echo

echo "---- build runner (mocks) ----"
flutter pub run build_runner build --delete-conflicting-outputs 2>&1 | tee -a "$BUILD_LOG"
echo

echo "---- tests (unit & widget only) ----"
flutter test 2>&1 | tee -a "$BUILD_LOG"
echo

echo "✅ D1 one-shot OK"

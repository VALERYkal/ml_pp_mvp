#!/usr/bin/env bash
set -euo pipefail

# D4 Environment Guard - Anti-secrets + Env validation
# Checks SUPABASE_ENV and scans logs for sensitive patterns

CI_LOG_DIR="${CI_LOG_DIR:-.ci_logs}"

# Pattern to detect secrets (without exposing values)
SECRET_PATTERNS=(
  "SUPABASE_ANON_KEY"
  "eyJhbGciOi"
  "anon_key"
  "service_role"
  "Authorization: Bearer"
  "SUPABASE_SERVICE_ROLE_KEY"
  "JWT"
)

echo "---- D4 Environment Guard ----"

# Step 1: Check SUPABASE_ENV is defined
if [[ -z "${SUPABASE_ENV:-}" ]]; then
  echo "❌ SUPABASE_ENV is not set"
  echo "Required: SUPABASE_ENV must be set to PROD or STAGING"
  exit 1
fi

# Step 2: Validate SUPABASE_ENV value (case-insensitive)
SUPABASE_ENV_UPPER=$(echo "${SUPABASE_ENV}" | tr '[:lower:]' '[:upper:]')
if [[ "$SUPABASE_ENV_UPPER" != "PROD" && "$SUPABASE_ENV_UPPER" != "STAGING" ]]; then
  echo "❌ Invalid SUPABASE_ENV value: ${SUPABASE_ENV}"
  echo "Allowed values: PROD, STAGING"
  exit 1
fi

echo "✅ SUPABASE_ENV=${SUPABASE_ENV_UPPER}"

# Step 3: Scan log files for sensitive patterns
SECRETS_FOUND=0
LOG_FILES=()

# Collect all D4 and D1 log files
if [[ -d "$CI_LOG_DIR" ]]; then
  for log_file in "$CI_LOG_DIR"/d4_*.log "$CI_LOG_DIR"/d1_*.log; do
    if [[ -f "$log_file" ]]; then
      LOG_FILES+=("$log_file")
    fi
  done
fi

if [[ ${#LOG_FILES[@]} -eq 0 ]]; then
  echo "ℹ️  No log files found in $CI_LOG_DIR (skipping secret scan)"
else
  echo "Scanning ${#LOG_FILES[@]} log file(s) for sensitive patterns..."
  
  for log_file in "${LOG_FILES[@]}"; do
    for pattern in "${SECRET_PATTERNS[@]}"; do
      if grep -q "$pattern" "$log_file" 2>/dev/null; then
        echo "⚠️  SECRET PATTERN DETECTED: '$pattern' found in $(basename "$log_file")"
        SECRETS_FOUND=1
      fi
    done
  done
  
  if [[ $SECRETS_FOUND -eq 1 ]]; then
        echo "❌ Secrets detected in log files. DO NOT commit or expose these logs."
        echo "Action required: Remove secrets from logs or regenerate them."
        echo "Log files checked: ${LOG_FILES[*]}"
        exit 1
    fi
fi

echo "✅ No secrets detected in logs"
echo "✅ Environment guard PASS"

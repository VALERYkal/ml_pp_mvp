#!/bin/bash
set -e

echo "🔎 Vérification branche..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "❌ Vous devez être sur la branche main"
  exit 1
fi

echo "🔄 Pull latest..."
git pull origin main

# Guardrails secrets
: "${SUPABASE_URL:?Missing SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?Missing SUPABASE_ANON_KEY}"

echo "📌 Commit: $(git rev-parse --short HEAD) - $(git log -1 --pretty=%s)"

echo "🧼 Clean + deps..."
flutter clean
flutter pub get

echo "🧪 Tests Flutter..."
flutter test

echo "🏗 Build Flutter Web (PROD)..."
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "🚀 Deploy Firebase Hosting..."
firebase deploy --only hosting --project ml-pp-mvp-web

echo "✅ Déploiement terminé."


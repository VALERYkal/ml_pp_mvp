#!/bin/bash
set -euo pipefail

# Script pour lancer l'app macOS en mode STAGING
# Lit .env.local et lance flutter run avec --dart-define

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Vérifier que .env.local existe
if [[ ! -f .env.local ]]; then
  echo "❌ Fichier .env.local non trouvé."
  echo "Créez-le depuis .env.example :"
  echo "  cp .env.example .env.local"
  echo "Puis remplissez les valeurs réelles dans .env.local"
  exit 1
fi

# Charger .env.local (source bash)
set -a
source .env.local
set +a

# Vérifier que les variables sont définies
if [[ -z "${SUPABASE_URL:-}" ]] || [[ -z "${SUPABASE_ANON_KEY:-}" ]]; then
  echo "❌ SUPABASE_URL ou SUPABASE_ANON_KEY manquants dans .env.local"
  exit 1
fi

# Définir SUPABASE_ENV si absent (par défaut STAGING)
export SUPABASE_ENV="${SUPABASE_ENV:-STAGING}"

echo "🌍 Environnement: $SUPABASE_ENV"
echo "📍 Supabase: ${SUPABASE_URL%%/*}//$(echo "$SUPABASE_URL" | sed 's|.*//||' | cut -d'/' -f1)"

# Lancer Flutter avec --dart-define
flutter run -d macos \
  --dart-define=SUPABASE_ENV="$SUPABASE_ENV" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

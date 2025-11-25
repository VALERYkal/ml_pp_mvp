#!/bin/bash
# Commandes finales pour retour au vert
# Copier-coller dans PowerShell (sans le shebang)

echo "🎯 ÉTAPE 1: Génération des mocks"
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ ÉTAPE 2: Vérification"
flutter analyze

echo ""
echo "🚀 ÉTAPE 3: Lancement de l'app (si 0 erreurs ci-dessus)"
# flutter run -d chrome

# ═══════════════════════════════════════════════════════════
# SI BUILD_RUNNER POSE PROBLÈME:
# ═══════════════════════════════════════════════════════════

# Option A: Clean complet
# flutter clean
# Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue
# flutter pub get
# flutter pub run build_runner build --delete-conflicting-outputs

# Option B: Exclure tests temporairement (créer analysis_options.yaml)
# analyzer:
#   exclude:
#     - test/**
# flutter analyze

# ═══════════════════════════════════════════════════════════
# NETTOYAGE OPTIONNEL (APRÈS LE VERT):
# ═══════════════════════════════════════════════════════════

# Auto-fix warnings rapides
# dart fix --apply

# Vérifier les dépendances obsolètes
# flutter pub outdated

# Mise à jour prudente
# flutter pub upgrade


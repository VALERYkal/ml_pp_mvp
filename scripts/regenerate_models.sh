#!/bin/bash

# Script de régénération des modèles Freezed/JSON
# Usage: ./scripts/regenerate_models.sh

echo "🔄 Régénération des modèles Freezed/JSON..."

# Nettoyer les fichiers générés existants
echo "🧹 Nettoyage des fichiers générés..."
find . -name "*.freezed.dart" -delete
find . -name "*.g.dart" -delete

# Régénérer tous les fichiers
echo "🔨 Régénération avec build_runner..."
dart run build_runner build --delete-conflicting-outputs

# Vérifier que la génération s'est bien passée
if [ $? -eq 0 ]; then
    echo "✅ Régénération réussie !"
    echo "📁 Fichiers générés :"
    find . -name "*.freezed.dart" -o -name "*.g.dart" | sort
else
    echo "❌ Erreur lors de la régénération"
    exit 1
fi

echo "🎉 Régénération terminée !"

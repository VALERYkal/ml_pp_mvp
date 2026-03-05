#!/usr/bin/env bash
# Garde-fou anti-régression: vérifie que les fichiers générés (Freezed/JSON) sont à jour.
# Usage: ./scripts/d0_codegen_check.sh
# Sortie: 0 si générés alignés avec le source, 1 si des fichiers générés ont divergé.
set -euo pipefail

echo "==> d0_codegen_check: build_runner + git diff (anti-régression)"
dart run build_runner build --delete-conflicting-outputs
echo "==> d0_codegen_check: vérification qu'aucun fichier généré (*.freezed.dart, *.g.dart) n'a divergé"
git diff --exit-code -- '**/*.freezed.dart' '**/*.g.dart' || {
  echo "❌ Des fichiers générés ont changé. Commitez-les après 'dart run build_runner build --delete-conflicting-outputs'."
  exit 1
}
echo "✅ Codegen à jour"

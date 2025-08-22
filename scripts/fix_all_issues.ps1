# Script de correction complète des problèmes d'analyse (Windows PowerShell)
# Usage: .\scripts\fix_all_issues.ps1

Write-Host "🔧 Correction complète des problèmes d'analyse..." -ForegroundColor Cyan

# Étape 1: Mise à jour des dépendances
Write-Host "📦 Étape 1: Mise à jour des dépendances..." -ForegroundColor Yellow
flutter pub get

# Étape 2: Régénération des modèles Freezed
Write-Host "🔄 Étape 2: Régénération des modèles Freezed..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

# Étape 3: Vérification de l'analyse
Write-Host "🔍 Étape 3: Vérification de l'analyse..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos

# Étape 4: Tests
Write-Host "🧪 Étape 4: Exécution des tests..." -ForegroundColor Yellow
flutter test

Write-Host "✅ Correction terminée !" -ForegroundColor Green
Write-Host "📊 Résumé:" -ForegroundColor Cyan
Write-Host "  - Dépendances mises à jour" -ForegroundColor White
Write-Host "  - Modèles Freezed régénérés" -ForegroundColor White
Write-Host "  - Analyse statique vérifiée" -ForegroundColor White
Write-Host "  - Tests exécutés" -ForegroundColor White

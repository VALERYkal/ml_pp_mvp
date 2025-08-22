# Script de régénération des modèles Freezed/JSON (Windows PowerShell)
# Usage: .\scripts\regenerate_models.ps1

Write-Host "🔄 Régénération des modèles Freezed/JSON..." -ForegroundColor Cyan

# Mettre à jour les dépendances
Write-Host "📦 Mise à jour des dépendances..." -ForegroundColor Yellow
flutter pub get

# Nettoyer les fichiers générés existants
Write-Host "🧹 Nettoyage des fichiers générés..." -ForegroundColor Yellow
Get-ChildItem -Recurse -Include "*.freezed.dart", "*.g.dart" | Remove-Item -Force

# Régénérer tous les fichiers
Write-Host "🔨 Régénération avec build_runner..." -ForegroundColor Yellow
dart run build_runner build --delete-conflicting-outputs

# Vérifier que la génération s'est bien passée
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Régénération réussie !" -ForegroundColor Green
    Write-Host "📁 Fichiers générés :" -ForegroundColor Cyan
    Get-ChildItem -Recurse -Include "*.freezed.dart", "*.g.dart" | Select-Object FullName | Sort-Object FullName
} else {
    Write-Host "❌ Erreur lors de la régénération" -ForegroundColor Red
    exit 1
}

Write-Host "🎉 Régénération terminée !" -ForegroundColor Green

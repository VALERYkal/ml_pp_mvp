# 🧪 Tests du Système KPI Unifié

## 📋 Vue d'ensemble

Cette suite de tests couvre le nouveau système KPI unifié implémenté dans la refactorisation majeure du 17 septembre 2025.

## 🗂️ Structure des tests

### 1. **Tests des modèles KPI** (`test/features/kpi/models/kpi_models_test.dart`)
- ✅ `KpiNumberVolume` - Volumes avec compteurs
- ✅ `KpiStocks` - Stocks avec capacité et ratio d'utilisation
- ✅ `KpiBalanceToday` - Balance du jour (réceptions - sorties)
- ✅ `KpiCiterneAlerte` - Alertes de citernes sous seuil
- ✅ `KpiTrendPoint` - Points de tendance sur 7 jours
- ✅ `KpiSnapshot` - Snapshot complet de tous les KPIs

### 2. **Tests du provider unifié** (`test/features/kpi/providers/kpi_provider_test.dart`)
- ✅ Retour de `KpiSnapshot` avec données valides
- ✅ Gestion des données vides
- ✅ Gestion des erreurs
- ✅ Filtrage par dépôt
- ✅ Accès global (sans dépôt assigné)

### 3. **Tests Golden du RoleDashboard** (`test/features/dashboard/widgets/role_dashboard_test.dart`)
- ✅ État de chargement
- ✅ État d'erreur
- ✅ État avec données
- ✅ Gestion des citernes vides
- ✅ Balance négative

### 4. **Tests Smoke des écrans** (`test/features/dashboard/screens/dashboard_screens_smoke_test.dart`)
- ✅ `DashboardAdminScreen`
- ✅ `DashboardOperateurScreen`
- ✅ `DashboardDirecteurScreen`
- ✅ `DashboardGerantScreen`
- ✅ `DashboardPcaScreen`
- ✅ `DashboardLectureScreen`
- ✅ Vérification du contenu identique

## 🚀 Exécution des tests

### Tests individuels
```bash
# Tests des modèles
flutter test test/features/kpi/models/kpi_models_test.dart

# Tests du provider
flutter test test/features/kpi/providers/kpi_provider_test.dart

# Tests du dashboard
flutter test test/features/dashboard/widgets/role_dashboard_test.dart

# Tests smoke des écrans
flutter test test/features/dashboard/screens/dashboard_screens_smoke_test.dart
```

### Suite complète
```bash
flutter test test/kpi_unified_test_suite.dart
```

### Tous les tests
```bash
flutter test
```

## 📊 Couverture des tests

- **Modèles KPI** : 100% des propriétés et méthodes testées
- **Provider unifié** : Cas normaux, erreurs, et edge cases
- **Interface utilisateur** : États de chargement, erreur, et données
- **Écrans** : Vérification que tous les dashboards se construisent correctement

## 🎯 Critères de réussite

- ✅ Tous les tests passent sans erreur
- ✅ Couverture ≥ 80% pour les providers
- ✅ Tests Golden passent
- ✅ Tests Smoke confirment la construction des écrans
- ✅ Aucune régression détectée

## 🔧 Maintenance

Les tests doivent être mis à jour si :
- De nouveaux KPIs sont ajoutés au `KpiSnapshot`
- La structure des modèles change
- L'interface du `RoleDashboard` évolue
- De nouveaux écrans de dashboard sont créés

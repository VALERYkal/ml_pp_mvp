# Phase 3 - Cartographie de l'existant

**Date** : 06/12/2025  
**Objectif** : Lister tous les fichiers Flutter qui consomment des stocks pour les rebrancher sur les nouvelles vues SQL

---

## 📋 Tableau récapitulatif

| Fichier | Table/Vue actuelle | Champs utilisés | Agrégation | Statut | Notes |
|---------|-------------------|-----------------|------------|--------|-------|
| | | | | | |

---

## 🔍 Fichiers à analyser

### Dashboard

- [ ] `lib/features/dashboard/screens/dashboard_admin_screen.dart`
- [ ] `lib/features/dashboard/screens/dashboard_directeur_screen.dart`
- [ ] `lib/features/dashboard/screens/dashboard_gerant_screen.dart`
- [ ] `lib/features/dashboard/providers/admin_kpi_provider.dart`
- [ ] `lib/features/dashboard/providers/directeur_kpi_provider.dart`
- [ ] `lib/features/dashboard/widgets/kpi_card.dart`

### Stocks Journaliers

- [ ] `lib/features/stocks_journaliers/screens/stocks_list_screen.dart`
- [ ] `lib/features/stocks_journaliers/providers/stocks_providers.dart`
- [ ] `lib/features/stocks_journaliers/data/stocks_service.dart`

### Citernes

- [ ] `lib/features/citernes/screens/citerne_list_screen.dart`
- [ ] `lib/features/citernes/providers/citerne_providers.dart`
- [ ] `lib/features/citernes/data/citerne_service.dart`

### KPI

- [ ] `lib/features/kpi/providers/stocks_kpi_provider.dart`
- [ ] `lib/features/kpi/providers/kpi_provider.dart`

---

## 📝 Notes par fichier

### À compléter lors de l'analyse

Pour chaque fichier, noter :
- Quelle table/vue il interroge actuellement
- Quels champs il utilise
- Comment il agrège les données
- S'il fait des calculs manuels (SUM, etc.)
- Quelle vue SQL de remplacement utiliser

---

## ✅ Checklist de migration

Une fois la cartographie complète, cocher au fur et à mesure :

- [ ] Modèles Dart créés
- [ ] Service `StockKpiService` créé
- [ ] Providers Riverpod créés
- [ ] Dashboard Admin rebranché
- [ ] Écran Stocks rebranché
- [ ] Écran Citernes rebranché
- [ ] Tests créés
- [ ] Anciens services/providers supprimés
- [ ] Documentation mise à jour


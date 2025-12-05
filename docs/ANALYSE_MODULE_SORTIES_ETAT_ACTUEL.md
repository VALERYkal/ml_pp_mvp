# 📊 ANALYSE COMPLÈTE — MODULE SORTIES — ÉTAT ACTUEL

**Date d'analyse** : 30 novembre 2025  
**Référence de comparaison** : Module Réceptions (production-ready)  
**Objectif** : Identifier ce qui est fait, finalisé, et ce qui reste à faire

---

## 📋 RÉSUMÉ EXÉCUTIF

### ✅ **CE QUI EST FAIT ET FINALISÉ**

1. **Modèle de données** (`SortieProduit`) : ✅ **Complet**
   - Structure alignée avec la table `sorties_produit`
   - Champs obligatoires définis (indices, température, densité)
   - Freezed avec immutabilité

2. **Service layer de base** (`SortieService`) : ✅ **Partiellement complet**
   - CRUD de base fonctionnel
   - Méthode `createValidated()` présente
   - Calcul volume 15°C intégré

3. **UI Formulaire** (`SortieFormScreen`) : ✅ **Fonctionnel**
   - Formulaire de création opérationnel
   - Sélection produit/citerne
   - Gestion propriétaire (MONALUXE/PARTENAIRE)

4. **UI Liste** (`SortieListScreen`) : ✅ **Basique mais fonctionnel**
   - Affichage des sorties
   - Navigation vers création

5. **Providers Riverpod** : ✅ **Partiellement complet**
   - `sortiesListProvider` : Liste des sorties
   - `sortieServiceProvider` : Service injectable
   - `sortieDraftProvider` : Gestion brouillons

6. **KPI intégration partielle** : ✅ **Partiellement complet**
   - Sorties incluses dans `kpiProviderProvider` (global)
   - Pas de repository KPI dédié (contrairement à Réceptions)

7. **Tests unitaires** : ✅ **Partiellement complet**
   - Tests service (`sortie_service_test.dart`)
   - Tests UI formulaire (`sortie_form_screen_test.dart`)

---

## ⚠️ **CE QUI EST PARTIELLEMENT FAIT (À FINALISER)**

### 1. **Service Layer — Validations Métier**

**État actuel** :
- `SortieService.createValidated()` existe mais validations moins strictes que Réceptions
- Indices, température, densité sont `double?` (optionnels) alors qu'ils devraient être **OBLIGATOIRES**

**Gap identifié** :
```dart
// ❌ ACTUEL (sortie_service.dart)
Future<SortieProduit> createValidated({
  required String citerneId,
  required String produitId,
  required double? indexAvant,  // ❌ Optionnel
  required double? indexApres,  // ❌ Optionnel
  double? temperature,           // ❌ Optionnel
  double? densite,               // ❌ Optionnel
  // ...
})
```

**Référence Réceptions** :
```dart
// ✅ RÉFÉRENCE (reception_service.dart)
Future<Reception> createValidated({
  required double indexAvant,   // ✅ Obligatoire
  required double indexApres,   // ✅ Obligatoire
  required double temperature,   // ✅ Obligatoire
  required double densite,       // ✅ Obligatoire
  // ...
})
```

**Action requise** :
- ✅ Rendre `indexAvant`, `indexApres`, `temperature`, `densite` **OBLIGATOIRES** (non-nullable)
- ✅ Ajouter validation stricte : `indexAvant >= 0`, `indexApres > indexAvant`
- ✅ Ajouter validation : `temperature > 0`, `densite > 0`
- ✅ Calcul volume 15°C **OBLIGATOIRE** dès que T° + densité présents

---

### 2. **Exception Métier Dédiée**

**État actuel** :
- ❌ **AUCUNE exception métier dédiée** pour Sorties
- Les erreurs utilisent des exceptions génériques

**Référence Réceptions** :
- ✅ `ReceptionValidationException` avec messages métier clairs

**Action requise** :
- ✅ Créer `SortieValidationException` (même structure que `ReceptionValidationException`)
- ✅ Messages d'erreur métier : "Indices invalides", "Température obligatoire", "Densité obligatoire", "Citerne inactive", etc.

---

### 3. **UI Formulaire — Modernisation**

**État actuel** :
- Formulaire fonctionnel mais structure basique
- Pas de validation visuelle stricte (contrairement à Réceptions)

**Référence Réceptions** :
- ✅ Formulaire structuré avec `ListView` + `Card`
- ✅ Validation visuelle stricte (`_canSubmit` getter)
- ✅ Champs obligatoires marqués avec `*`
- ✅ Calcul volume 15°C en temps réel

**Action requise** :
- ✅ Restructurer formulaire avec `ListView` + `Card` (comme Réceptions)
- ✅ Ajouter `_canSubmit` getter avec validation stricte
- ✅ Marquer champs obligatoires avec `*`
- ✅ Afficher calcul volume 15°C en temps réel
- ✅ Ajouter commentaires PROD-LOCK sur zones critiques

---

### 4. **UI Liste — Modernisation**

**État actuel** :
- ❌ `DataTable` basique (pas de pagination, pas de tri, pas de refresh)
- ❌ Pas de `sortiesTableProvider` (contrairement à `receptionsTableProvider`)
- ❌ Pas de gestion d'état vide moderne
- ❌ Pas de gestion d'erreur moderne

**Référence Réceptions** :
- ✅ `PaginatedDataTable` avec tri et pagination
- ✅ `receptionsTableProvider` avec ViewModel (`ReceptionRowVM`)
- ✅ État vide moderne avec message et bouton
- ✅ Gestion d'erreur avec bouton "Réessayer"

**Action requise** :
- ✅ Créer `SortieRowVM` (même structure que `ReceptionRowVM`)
- ✅ Créer `sortiesTableProvider` (même pattern que `receptionsTableProvider`)
- ✅ Migrer `SortieListScreen` vers `PaginatedDataTable`
- ✅ Ajouter tri (date, volume 15°C)
- ✅ Ajouter pagination
- ✅ Ajouter gestion d'état vide moderne
- ✅ Ajouter gestion d'erreur avec refresh

---

### 5. **KPI Repository Dédié**

**État actuel** :
- ❌ **AUCUN repository KPI dédié** pour Sorties
- Sorties incluses dans `kpiProviderProvider` (global) mais pas de repository séparé

**Référence Réceptions** :
- ✅ `ReceptionsKpiRepository` avec méthode `getReceptionsKpiForDay()`
- ✅ `receptionsKpiTodayProvider` dédié
- ✅ Structure `KpiNumberVolume` (count + volume15c + volumeAmbient)

**Action requise** :
- ✅ Créer `SortiesKpiRepository` (même structure que `ReceptionsKpiRepository`)
- ✅ Méthode `getSortiesKpiForDay(DateTime day, {String? depotId})`
- ✅ Créer `sortiesKpiTodayProvider` (même pattern que `receptionsKpiTodayProvider`)
- ✅ Retourner `KpiNumberVolume` (count + volume15c + volumeAmbient)
- ✅ Filtrer par `statut = 'validee'` et `date_sortie` du jour
- ✅ Support filtrage par dépôt via `citernes.depot_id`

---

### 6. **Tests — Couverture Complète**

**État actuel** :
- ✅ Tests unitaires service (`sortie_service_test.dart`)
- ✅ Tests UI formulaire (`sortie_form_screen_test.dart`)
- ❌ **AUCUN test d'intégration** (contrairement à Réceptions)
- ❌ **AUCUN test E2E** (contrairement à Réceptions)

**Référence Réceptions** :
- ✅ Tests unitaires service + validations
- ✅ Tests intégration : Réception → Stocks journaliers
- ✅ Tests E2E UI-only : `/dashboard → /receptions → /receptions/new → save → list + KPI update`

**Action requise** :
- ✅ **Test intégration** : Sortie → Stocks journaliers (vérifier décrémentation)
- ✅ **Test E2E UI-only** : `/dashboard → /sorties → /sorties/new → save → list + KPI update`
- ✅ Tests KPI repository (`sorties_kpi_repository_test.dart`)
- ✅ Tests KPI provider (`sorties_kpi_provider_test.dart`)

---

## ❌ **CE QUI MANQUE COMPLÈTEMENT**

### 1. **Invalidation/Refresh Flow**

**État actuel** :
- ❌ Pas de mécanisme d'invalidation automatique après création
- ❌ `sortie_form_screen.dart` invalide `sortiesListProvider` mais pas `sortiesTableProvider` (qui n'existe pas)

**Référence Réceptions** :
- ✅ `reception_form_screen.dart` invalide `receptionsListProvider` + `receptionsTableProvider`
- ✅ `reception_list_screen.dart` a bouton "Réessayer" qui invalide `receptionsTableProvider`

**Action requise** :
- ✅ Après création sortie, invalider `sortiesListProvider` + `sortiesTableProvider` + `sortiesKpiTodayProvider`
- ✅ Ajouter bouton "Réessayer" dans `SortieListScreen` qui invalide `sortiesTableProvider`

---

### 2. **Navigation/Routing**

**État actuel** :
- ✅ Routes de base présentes (`/sorties`, `/sorties/new`)
- ❌ Pas de route détail (`/sorties/:id`)

**Référence Réceptions** :
- ✅ Routes complètes : `/receptions`, `/receptions/new`, `/receptions/:id`

**Action requise** :
- ✅ Ajouter route détail `/sorties/:id`
- ✅ Créer `SortieDetailScreen` (lecture seule, affichage complet)

---

### 3. **Protections PROD-LOCK**

**État actuel** :
- ❌ **AUCUN commentaire PROD-LOCK** dans le module Sorties

**Référence Réceptions** :
- ✅ Commentaires `// 🚨 PROD-LOCK: do not modify without updating tests` sur zones critiques
- ✅ Audit complet avec rapport (`AUDIT_RECEPTIONS_PROD_LOCK.md`)

**Action requise** :
- ✅ Ajouter commentaires PROD-LOCK sur :
  - `SortieService.createValidated()` (validations métier)
  - `SortieFormScreen._canSubmit` (validation UI)
  - `SortieFormScreen._buildMesuresCard` (structure champs)
  - `SortiesKpiRepository.getSortiesKpiForDay()` (calcul KPI)
- ✅ Générer audit complet (`AUDIT_SORTIES_PROD_LOCK.md`)

---

### 4. **Documentation Release Notes**

**État actuel** :
- ❌ **AUCUNE release note finale** pour Sorties

**Référence Réceptions** :
- ✅ `RECEPTIONS_FINAL_RELEASE_NOTES_2025-11-30.md` (format complet)

**Action requise** :
- ✅ Générer `SORTIES_FINAL_RELEASE_NOTES_2025-XX-XX.md` (même format que Réceptions)

---

## 📊 TABLEAU COMPARATIF SORTIES vs RÉCEPTIONS

| Composant | Réceptions | Sorties | Gap |
|-----------|------------|---------|-----|
| **Modèle** | ✅ `Reception` (Freezed) | ✅ `SortieProduit` (Freezed) | ✅ Aligné |
| **Service** | ✅ Validations strictes | ⚠️ Validations partielles | ❌ Indices/T°/Densité optionnels |
| **Exception métier** | ✅ `ReceptionValidationException` | ❌ Aucune | ❌ À créer |
| **UI Formulaire** | ✅ Moderne (ListView+Card) | ⚠️ Basique | ❌ À moderniser |
| **UI Liste** | ✅ `PaginatedDataTable` | ❌ `DataTable` basique | ❌ À moderniser |
| **Table Provider** | ✅ `receptionsTableProvider` | ❌ Aucun | ❌ À créer |
| **Row VM** | ✅ `ReceptionRowVM` | ❌ Aucun | ❌ À créer |
| **KPI Repository** | ✅ `ReceptionsKpiRepository` | ❌ Aucun | ❌ À créer |
| **KPI Provider** | ✅ `receptionsKpiTodayProvider` | ❌ Aucun | ❌ À créer |
| **Tests unitaires** | ✅ Complets | ✅ Partiels | ⚠️ À compléter |
| **Tests intégration** | ✅ Réception → Stocks | ❌ Aucun | ❌ À créer |
| **Tests E2E** | ✅ UI-only flow complet | ❌ Aucun | ❌ À créer |
| **PROD-LOCK** | ✅ Commentaires + Audit | ❌ Aucun | ❌ À ajouter |
| **Release Notes** | ✅ Finales | ❌ Aucune | ❌ À générer |

---

## 🎯 PLAN D'ACTION PRIORISÉ

### **PRIORITÉ 1 — CRITIQUE (Blocage production)**

1. **Renforcer validations métier** (`SortieService`)
   - Rendre indices, température, densité **OBLIGATOIRES**
   - Ajouter validations strictes (indexAvant >= 0, indexApres > indexAvant, etc.)
   - Calcul volume 15°C **OBLIGATOIRE**

2. **Créer exception métier** (`SortieValidationException`)
   - Messages métier clairs
   - Même structure que `ReceptionValidationException`

3. **Créer KPI Repository + Provider**
   - `SortiesKpiRepository` avec `getSortiesKpiForDay()`
   - `sortiesKpiTodayProvider` retournant `KpiNumberVolume`

---

### **PRIORITÉ 2 — IMPORTANT (Qualité production)**

4. **Moderniser UI Liste**
   - Créer `SortieRowVM`
   - Créer `sortiesTableProvider`
   - Migrer vers `PaginatedDataTable` avec tri + pagination

5. **Moderniser UI Formulaire**
   - Restructurer avec `ListView` + `Card`
   - Ajouter `_canSubmit` getter strict
   - Afficher calcul volume 15°C en temps réel

6. **Tests intégration**
   - Sortie → Stocks journaliers (décrémentation)

---

### **PRIORITÉ 3 — AMÉLIORATION (Robustesse)**

7. **Tests E2E**
   - UI-only flow : `/dashboard → /sorties → /sorties/new → save → list + KPI update`

8. **Protections PROD-LOCK**
   - Commentaires sur zones critiques
   - Audit complet (`AUDIT_SORTIES_PROD_LOCK.md`)

9. **Documentation**
   - Release notes finales (`SORTIES_FINAL_RELEASE_NOTES_2025-XX-XX.md`)

10. **Navigation**
    - Route détail `/sorties/:id`
    - `SortieDetailScreen`

---

## 📈 ESTIMATION EFFORT

| Tâche | Complexité | Temps estimé |
|-------|------------|--------------|
| Renforcer validations métier | Moyenne | 2-3h |
| Créer exception métier | Faible | 1h |
| Créer KPI Repository + Provider | Moyenne | 3-4h |
| Moderniser UI Liste | Élevée | 4-5h |
| Moderniser UI Formulaire | Moyenne | 3-4h |
| Tests intégration | Moyenne | 2-3h |
| Tests E2E | Élevée | 4-5h |
| Protections PROD-LOCK | Faible | 1-2h |
| Documentation | Faible | 2-3h |
| Navigation détail | Faible | 1-2h |
| **TOTAL** | | **23-32h** |

---

## ✅ CONCLUSION

Le module **Sorties** est **fonctionnellement opérationnel** mais nécessite des **renforcements critiques** pour atteindre le niveau de qualité production du module Réceptions :

1. **Validations métier strictes** (indices, température, densité obligatoires)
2. **KPI Repository dédié** (alignement avec Réceptions)
3. **UI modernisée** (liste + formulaire)
4. **Tests complets** (intégration + E2E)
5. **Protections PROD-LOCK** (audit + commentaires)

**Recommandation** : Traiter les **PRIORITÉ 1** en premier (validations + exception + KPI) avant de passer en production.

---

**Document généré le** : 30 novembre 2025  
**Auteur** : Analyse automatisée basée sur comparaison avec module Réceptions (référence production-ready)


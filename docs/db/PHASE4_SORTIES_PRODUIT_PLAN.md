# 🔥 Phase 4 – Sorties Produit (Vue globale)

**Date de démarrage** : 06/12/2025  
**Statut** : 🚧 **EN PLANIFICATION**  
**Modules impactés** : Sorties Produit, Service, Providers, Tests, Dashboard, KPIs

---

## 🎯 Objectif global

Rendre le module **Sorties Produit** réellement exploitable en production, aligné avec la logique métier et le backend SQL (triggers + stocks_journaliers), avec :

- ✅ Un service Flutter propre (`SortieService`) aligné sur la fonction/trigger côté DB
- ✅ Un flux de saisie/validation clair par rôle (opérateur vs gérant/directeur/admin)
- ✅ Un formulaire fiable avec validations métier
- ✅ Des tests automatisés (unitaires + intégration) verts, dont `sorties_submission_test.dart`

---

## 📋 Découpage proposé

### 4.1 – Stabiliser le backend Flutter Sorties (Service + Provider + Tests d'intégration)

**Priorité** : 🔴 **HAUTE** (bloque les tests)

**Objectifs** :
- Aligner la signature de `SortieService.createValidated(...)` avec ce qu'on veut réellement envoyer à Supabase
- Corriger `_SpySortieService` / `MockSortieService` dans `sorties_submission_test.dart` (erreur sur `proprietaireType` & `volumeCorrige15C`)
- S'assurer que le service appelle bien la bonne RPC / insertion (unique function + trigger unifié)

**Livrable** : `sorties_submission_test.dart` compile et passe

**Voir** : `docs/db/PHASE4_1_SORTIES_SERVICE_STABILISATION.md`

---

### 4.2 – Nettoyer & finaliser le formulaire Sortie Produit

**Priorité** : 🟡 **MOYENNE**

**Statut** : 🚧 **EN PLANIFICATION**

**Objectifs** :
- Dé-skipper et stabiliser le test d'intégration `sorties_submission_test.dart`
- Vérifier les champs obligatoires (chauffeur, plaque, citerne, produit, volume, temp, densité, propriétaire, etc.)
- Harmoniser les validations Flutter avec la logique SQL (volume dispo, citerne active, etc. → côté UI = pré-checks simples + messages d'erreur)
- Garantir un mapping propre Form → DTO → `SortieService.createValidated`
- Gérer les erreurs du service de manière robuste

**Livrables** :
- Test d'intégration fonctionnel et utile
- Formulaire avec validations métier complètes
- Messages d'erreur clairs et contextuels
- Mapping Form → Service testé
- Gestion d'erreurs robuste

**Voir** : `docs/db/PHASE4_2_FORMULAIRE_TEST_INTEGRATION.md` pour le plan détaillé

---

### 4.3 – Flux de validation & rôles

**Priorité** : 🟡 **MOYENNE**

**Objectifs** :
- Implémenter/terminer la logique statuts : `SORTIE_CREEE`, `SORTIE_VALIDE`, `SORTIE_REJETEE`
- UI & providers pour :
  - **opérateur** = saisie uniquement
  - **gérant/directeur/admin** = validation / rejet
- S'assurer que ça colle avec `log_actions` et les statuts en DB

**Livrables** :
- Workflow de validation par rôle fonctionnel
- Intégration avec `log_actions`
- UI adaptée selon le rôle utilisateur

---

### 4.4 – Intégration au Dashboard & KPIs

**Priorité** : 🟢 **BASSE** (dépend de Phase 3)

**Objectifs** :
- Vérifier que les nouvelles sorties impactent correctement :
  - les stocks journaliers (via trigger `stock_upsert_journalier`)
  - les KPIs (vues déjà branchées dans Phase 3)
- Ajouter éventuellement des cards / lignes KPI spécifiques aux sorties

**Livrables** :
- KPIs sorties intégrés au Dashboard
- Vérification de cohérence stocks journaliers
- Cards KPI sorties si nécessaire

---

### 4.5 – Documentation & tests finaux

**Priorité** : 🟢 **BASSE**

**Objectifs** :
- Mettre à jour la doc (`docs/db` + `docs/app`)
- S'assurer que :
  - tests unitaires `SortieService`
  - tests d'intégration (dont `sorties_submission_test.dart`)
  - e2e si existant
  sont au vert

**Livrables** :
- Documentation complète et à jour
- Suite de tests 100% verte
- Guide utilisateur si nécessaire

---

## 🗺️ Roadmap

```
Phase 4.1 (Priorité HAUTE)
    ↓
Phase 4.2 (Priorité MOYENNE)
    ↓
Phase 4.3 (Priorité MOYENNE)
    ↓
Phase 4.4 (Priorité BASSE - dépend Phase 3)
    ↓
Phase 4.5 (Priorité BASSE - finalisation)
```

---

## 📊 Critères de succès

### Phase 4.1
- ✅ `sorties_submission_test.dart` compile sans erreur
- ✅ `sorties_submission_test.dart` passe (tests verts)
- ✅ Signature `SortieService.createValidated` alignée avec la DB

### Phase 4.2
- ✅ Formulaire avec toutes les validations métier
- ✅ Messages d'erreur clairs
- ✅ Mapping Form → Service testé

### Phase 4.3
- ✅ Workflow de validation par rôle fonctionnel
- ✅ Intégration `log_actions` opérationnelle
- ✅ UI adaptée selon le rôle

### Phase 4.4
- ✅ KPIs sorties intégrés au Dashboard
- ✅ Cohérence stocks journaliers vérifiée

### Phase 4.5
- ✅ Documentation complète
- ✅ Suite de tests 100% verte

---

## 🔗 Liens vers documentation détaillée

- **Phase 4.1** : `docs/db/PHASE4_1_SORTIES_SERVICE_STABILISATION.md`
- **Phase 4.2** : (à créer)
- **Phase 4.3** : (à créer)
- **Phase 4.4** : (à créer)
- **Phase 4.5** : (à créer)

---

## 📝 Notes importantes

- **Phase 4.1 est critique** : elle bloque les tests et doit être faite en premier
- **Alignement DB/Flutter** : toutes les signatures doivent être cohérentes entre le service Flutter et les fonctions SQL
- **Tests d'abord** : chaque phase doit inclure des tests automatisés
- **Rôles utilisateurs** : bien distinguer opérateur (saisie) vs gérant/directeur/admin (validation)

---

## 🎯 Objectif final

À la fin de la Phase 4, le module **Sorties Produit** doit être :

- ✅ **Production-ready** : stable, testé, documenté
- ✅ **Aligné avec la DB** : cohérent avec les triggers et fonctions SQL
- ✅ **Utilisable par tous les rôles** : workflow clair selon le rôle
- ✅ **Intégré au Dashboard** : KPIs et stocks à jour


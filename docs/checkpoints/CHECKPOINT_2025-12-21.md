# CHECKPOINT — ML_PP MVP  
**Date : 2025-12-21**  
**Statut : CHECKPOINT VALIDÉ — À REPRENDRE À LA PROCHAINE SESSION**

---

## 1. CONTEXTE GÉNÉRAL

Projet : **ML_PP MVP (Monaluxe)**  
Stack : **Flutter + Riverpod + Supabase (DB-STRICT)**  

Objectif stratégique :

> Construire un système **transactionnel robuste** où **Réceptions** et **Sorties** sont les **seules opérations autorisées à modifier le stock**, avec :
> - validation atomique,
> - immutabilité absolue,
> - corrections uniquement par compensation,
> - stock calculé exclusivement côté base de données.

---

## 2. DÉCISION D'ARCHITECTURE (NON NÉGOCIABLE)

### Paradigme transactionnel final

- ❌ Pas de brouillon  
- ❌ Pas de `validate()` applicatif  
- ❌ Aucune modification / suppression de transaction  
- ✅ **INSERT = validation**
- ✅ Transactions **immutables**
- ✅ Corrections **par mouvements compensatoires**
- ✅ Stock calculé **uniquement côté DB** (triggers + vues)

Ce paradigme est formalisé dans :
- `docs/TRANSACTION_CONTRACT.md`

---

## 3. TRAVAUX EFFECTUÉS (FACTUELS)

### 3.1 Suppression du legacy Réceptions (VALIDÉ)

Les fichiers suivants ont été **supprimés définitivement** :

- `lib/features/receptions/screens/reception_screen.dart`
- `lib/features/receptions/data/reception_service_v2.dart`
- `lib/features/receptions/data/reception_service_v3.dart`

👉 Le **flux Réception officiel** repose désormais **uniquement** sur :

```dart
ReceptionService.createValidated()
```

### 3.2 Audit automatisé du legacy (FAIT)

Un audit complet (grep / rg) a confirmé la présence résiduelle de legacy dans :

- `lib/features/receptions/data/reception_service.dart`
  - méthodes `createDraft()` et `validate()`
- `lib/features/receptions/providers/reception_providers.dart`
- `test/integration/reception_flow_test.dart`
- documentation legacy (`docs/rapports`, `docs/releases`)

### 3.3 Stabilisation de l'analyse Flutter (FAIT)

**Problème initial :**
- `analysis_options.yaml` cassé (parse_error, mauvais excludes)

**Correction appliquée :**
- YAML simplifié
- Exclusion correcte de :
  - `_attic/**`
  - `test_legacy/**`

👉 Objectif atteint : pouvoir corriger une erreur à la fois sans bruit parasite.

### 3.4 Clarification Dashboard KPI (DÉCISION VALIDÉE)

Le KPI Trend 7 jours :
- ❌ N'a plus de valeur métier
- ❌ Crée du note et de la dette technique
- ❌ Duplique / brouille la lecture du stock

Il a été remplacé fonctionnellement par :
- **Stock par propriétaire** (MONALUXE / PARTENAIRE)

👉 Décision actée et **EXÉCUTÉE** :
- ✅ `kpiTrend7dProvider` supprimé du code
- ✅ Carte "Balance du jour" / "Tendance 7 jours" supprimée
- ✅ Remplacé par "Stock par propriétaire" (MONALUXE / PARTENAIRE)

### 3.5 État actuel du Dashboard (CONFIRMÉ)

Le dashboard affiche correctement :
- Stock total
- Stock par propriétaire
- Réceptions du jour
- Sorties du jour
- Camions à suivre
- Alertes citernes

👉 Le Trend 7 jours n'est plus affiché côté UI.

---

## 4. TRAVAUX RESTANTS (PLAN À REPRENDRE)

### ÉTAPE 1 — Finaliser le nettoyage Réceptions (PRIORITÉ 1)

**À faire :**

**Dans `lib/features/receptions/data/reception_service.dart`**
- ❌ Supprimer `createDraft()`
- ❌ Supprimer `validate()`

**Dans `lib/features/receptions/providers/reception_providers.dart`**
- Remplacer tout usage de `createDraft()` par `createValidated()`
- Supprimer toute référence à :
  - RPC `validate_reception`

**Mettre à jour les tests :**
- `test/integration/reception_flow_test.dart`
- Tester directement `createValidated()`

**Validation obligatoire :**
- `flutter analyze`
- `flutter test`

### ÉTAPE 2 — Supprimer Trend 7 jours (PRIORITÉ 2) ✅ DONE

**Statut :** ✅ **COMPLÉTÉ**

**Actions effectuées :**
- ✅ `kpiTrend7dProvider` supprimé du code (vérifié via `rg`)
- ✅ Carte "Balance du jour" / "Tendance 7 jours" supprimée du dashboard
- ✅ Code Flutter propre : aucune référence restante dans `lib/` ou `test/`

**Preuve (vérification) :**
- `rg -n "kpiTrend7dProvider|sumReceptions15c7d|sumSorties15c7d|Trend 7" lib test` → Aucun résultat (code propre)
- `rg -n "kpiTrend7dProvider|trend7d|Trend 7" docs` → Mentions restantes uniquement dans la documentation (historique + Post-MVP), pas d'action requise

**Note :** Les occurrences restantes sont attendues dans :
- `docs/db/stocks_views_tests.md` : Champs `tendance_7j_*` marqués DEPRECATED (présents en DB mais non utilisés)
- `docs/rapports/*` : Remplacement documenté (contexte historique des refactorisations)
- `docs/app/kpi-directeur.md` : Tendances hebdomadaires = Post-MVP Analytics (hors dashboard)

**Remplacement fonctionnel :**
- ✅ **Stock par propriétaire** (MONALUXE / PARTENAIRE) remplace fonctionnellement le Trend 7 jours
- ✅ Dashboard affiche maintenant : Stock global + Stock par propriétaire (plus lisible et utile métier)

### ÉTAPE 3 — Harmoniser Sorties (PLUS TARD)

Le module Sorties devra suivre strictement la même logique que Réceptions :
- Pas de brouillon
- INSERT = validation
- Immutabilité
- Compensation uniquement

---

## 5. RÈGLES DE TRAVAIL POUR LA SUITE

- ⚠️ Une seule correction à la fois
- ⚠️ Toujours relancer `flutter analyze`
- ⚠️ Pas de refactor large pendant la migration
- ⚠️ Le contrat transactionnel prime sur le code
- ⚠️ Pas de nouvelles features avant stabilisation

---

## 6. ÉTAT CIBLE FINAL

- Réceptions / Sorties = écritures comptables immuables
- Stock = calcul DB, jamais côté app
- Dashboard = lisible, sans KPI décoratifs
- Code = sans legacy, sans chemins alternatifs
- Tests = simples, atomiques, alignés DB-STRICT

---

## 7. PHRASE DE REPRISE (À DONNER À LA PROCHAINE SESSION)

« Nous avons validé un paradigme DB-STRICT avec immutabilité absolue.
Les écrans et services legacy Réceptions ont été supprimés.
Il reste à enlever createDraft/validate du service officiel et migrer les tests.
Le Trend 7 jours a été complètement supprimé du code (provider + UI) et remplacé par "Stock par propriétaire".
On avance une correction à la fois, toujours validée par flutter analyze. »

---

### Recommandation finale
👉 Ajoute ce fichier sous :
`docs/checkpoints/CHECKPOINT_2025-12-21.md`


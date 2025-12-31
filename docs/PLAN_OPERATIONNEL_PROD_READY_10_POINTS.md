# PLAN OPÉRATIONNEL — ML_PP MVP → PROD READY (10 POINTS)

**Date de création :** 31 décembre 2025  
**Nature :** Checklist de validation production (critères, pas jours)  
**Référence :** [Rapport de Synthèse Production](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md)

---

## 🎯 Présentation

Ce plan définit **10 critères de validation** (POINTS) obligatoires pour considérer ML_PP MVP comme "production industrielle auditée".

> ⚠️ **IMPORTANT :** Il s'agit de 10 POINTS DE VALIDATION (contrôles qualité), pas de 10 jours de travail.  
> L'effort estimé total est de **7 à 10 jours ouvrés** pour compléter tous les points P0 (points 1-6).

**Verdict actuel :**
- 🟢 **Fonctionnel : GO** (production interne contrôlée)
- 🔴 **Industriel : NO-GO** (points 1-6 requis)

---

## 1️⃣ Finaliser DB-STRICT — Immutabilité absolue

### Objectif
Garantir qu'aucun mouvement ne peut être modifié après insertion.

### À faire

**Bloquer UPDATE et DELETE sur :**
- `receptions`
- `sorties_produit`
- `stocks_journaliers`

**Ajouter triggers BEFORE UPDATE/DELETE → RAISE EXCEPTION**

### Critère de validation

✅ Toute tentative d'UPDATE/DELETE échoue côté DB  
✅ Test manuel SQL documenté

### Blocage production

⛔ **Sans ça → NO-GO PROD**

---

## 2️⃣ Implémenter les compensations officielles

### Objectif
Corriger sans casser l'historique.

### À faire

- Créer table `stock_adjustments`
- Fonctions SQL : `admin_adjust_stock(...)`
- Logs CRITICAL obligatoires
- RLS admin uniquement

### Critère de validation

✅ Aucune correction directe possible sur stocks  
✅ Toute correction passe par compensation traçable

### Blocage production

⛔ **Sans compensation → NO-GO PROD**

---

## 3️⃣ Verrouiller la traçabilité Sorties

### Objectif
Audit incontestable.

### À faire

- Trigger BEFORE INSERT sur `sorties_produit`
- Forcer `created_by = auth.uid()` si NULL
- Vérifier compatibilité service role

### Critère de validation

✅ Aucun enregistrement sans `created_by`  
✅ Test SQL + test Flutter

### Blocage production

⛔ **Sans traçabilité → NO-GO PROD**

---

## 4️⃣ Supabase STAGING obligatoire

### Objectif
Tester la DB réelle, pas des mocks.

### À faire

- Créer projet Supabase dédié (staging)
- Variables `.env.staging`
- Script reset DB + seed minimal

### Critère de validation

✅ DB staging recréable à l'identique  
✅ Accès contrôlé

### Blocage production

⛔ **Sans staging → NO-GO PROD**

---

## 5️⃣ Activer les tests d'intégration DB

### Objectif
Vérifier triggers + RLS + stock réel.

### À faire

**Dé-SKIP :**
- Réception → stock → log
- Sortie → stock → log

**Tester refus RLS** (mauvais rôle)

### Critère de validation

✅ Tests passent sur staging  
✅ Échec réel si trigger/RLS cassé

### Blocage production

⛔ **Sans tests DB → NO-GO PROD**

---

## 6️⃣ Décider et appliquer la politique RLS PROD

### Objectif
Sécurité maîtrisée.

### Décision formelle requise

**Option A :** Lecture globale ❓  
**Option B :** Lecture par dépôt ❓

### À faire

- Implémenter policies choisies
- Ajouter tests de permissions par rôle

### Critère de validation

✅ Un utilisateur ne voit que ce qu'il doit voir  
✅ Tests automatisés

### Blocage production

⛔ **RLS flou → NO-GO PROD**

---

## 7️⃣ Nettoyer le legacy bloquant

### Objectif
Réduire le risque futur.

### À supprimer / geler

- `SortieDraftService`
- `rpcValidateReception`
- TODO critiques dans services KPI / sorties

### Critère de validation

✅ Aucun code legacy utilisé  
✅ Annotations @Deprecated nettoyées

### Blocage production

⛔ **Legacy actif → RISQUE PROD**

---

## 8️⃣ Verrouiller la vérité stock (contrat)

### Objectif
Empêcher toute régression stock. **Une seule source canonique, plus d'ambiguïté.**

### À faire

**Document officiel :**
- **Vue canonique unique** : `v_stock_actuel_snapshot` (temps réel)
- Règles d'agrégation documentées

**Marquer TOUTES vues legacy DEPRECATED :**
- `stock_actuel` (table legacy)
- `v_citerne_stock_actuel` (vue legacy)
- `v_stock_actuel_owner_snapshot` (naming trompeur)
- Tout autre vue "stock/snapshot/daily/global/owner"

**Tests contractuels sur vue canonique**

### Critère de validation

✅ Une seule source "stock actuel" (`v_stock_actuel_snapshot`)  
✅ Toutes vues legacy marquées DEPRECATED en DB  
✅ Toute modification de contrat casse les tests  
✅ Plus d'ambiguïté vocabulaire (snapshot/daily/global/owner)

### Blocage production

⛔ **Vérité stock ambiguë → NO-GO PROD**

---

## 9️⃣ Mettre en place le runbook de release

### Objectif
Zéro déploiement sauvage.

### À faire

- Checklist SQL obligatoire (stocks)
- Procédure : avant release / après release
- Archivage des résultats

### Critère de validation

✅ Une release = un dossier de preuves  
✅ Pas de "deploy à la main"

### Blocage production

⛔ **Pas de runbook → NO-GO PROD**

---

## 🔟 Activer l'observabilité minimale

### Objectif
Détecter avant la casse.

### À faire

**Logs DB :**
- Erreurs triggers
- Compensations

**Logs Flutter :**
- Erreurs API
- Fallback KPI

**Option :** Sentry / équivalent

### Critère de validation

✅ Une erreur = visible  
✅ Plus de silence côté KPI

### Blocage production

⛔ **Pas d'observabilité → PROD AVEUGLE**

---

## 🎯 DÉCISION FINALE

| État | Condition |
|------|-----------|
| ❌ **NO-GO** | 1 point P0 manquant |
| 🟡 **PROD INTERNE** | Points 1 → 6 OK |
| 🟢 **PROD INDUSTRIEL** | Points 1 → 10 OK |

---

**Document créé le :** 31 décembre 2025  
**Version :** 1.0


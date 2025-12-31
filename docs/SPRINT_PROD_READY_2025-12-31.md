# 🎯 SPRINT PROD-READY — ML_PP MVP

**Date de démarrage :** À définir  
**Date de fin cible :** À définir (10-15 jours ouvrés après démarrage)  
**Référence :** [Rapport de Synthèse Production](./RAPPORT_SYNTHESE_PRODUCTION_2025-12-31.md) | [Plan Opérationnel 10 Points](./PLAN_OPERATIONNEL_PROD_READY_10_POINTS.md)

---

## 🎯 Objectif Unique du Sprint

**👉 À la fin du sprint, ML_PP MVP est déployable en production industrielle auditée.**

### Durée Cible

**≈ 10–15 jours ouvrés** (selon disponibilité de l'équipe)

### Definition of Done (DoD) du Sprint

✅ **Les 10 points PROD sont validés**  
✅ **Tous les tests passent** (unit + widget + intégration DB)  
✅ **Release documentée** + preuves SQL archivées

---

## 🧭 Structure du Sprint

Le sprint est découpé en **4 AXES**, eux-mêmes divisés en **tickets atomiques**.

**Chaque ticket est :**
- 🔴 **Bloquant** : Doit être terminé pour passer en prod
- 🟡 **Non-bloquant** : Recommandé mais pas critique

---

## 🔴 AXE A — DB-STRICT & INTÉGRITÉ MÉTIER (BLOQUANT)

### A1 — Immutabilité totale des mouvements

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 0.5 jour

#### Objectif
Aucun `UPDATE`/`DELETE` possible sur les mouvements validés.

#### Tâches

- [ ] **T1.1** Créer trigger `BEFORE UPDATE` sur `receptions`
- [ ] **T1.2** Créer trigger `BEFORE DELETE` sur `receptions`
- [ ] **T1.3** Répéter pour `sorties_produit`
- [ ] **T1.4** Répéter pour `stocks_journaliers`
- [ ] **T1.5** Créer migration SQL idempotente
- [ ] **T1.6** Créer tests SQL de validation

#### DoD (Definition of Done)

✅ `UPDATE`/`DELETE` échouent systématiquement avec message explicite  
✅ Test SQL archivé et validé  
✅ Documentation des tests complète

---

### A2 — Compensations officielles (stock_adjustments)

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 1.5 jours

#### Objectif
Corriger sans casser l'historique.

#### Tâches

- [ ] **T2.1** Créer table `stock_adjustments`
- [ ] **T2.2** Créer fonction `admin_adjust_stock(...)`
- [ ] **T2.3** Créer trigger `AFTER INSERT` sur `stock_adjustments`
- [ ] **T2.4** Ajouter logs CRITICAL automatiques
- [ ] **T2.5** Configurer RLS admin uniquement
- [ ] **T2.6** Créer migration SQL
- [ ] **T2.7** Tests SQL de validation

#### DoD

✅ Correction possible uniquement via compensation  
✅ Aucune écriture directe autorisée sur `receptions`/`sorties_produit`  
✅ Log CRITICAL généré automatiquement  
✅ Tests passent

---

### A3 — Traçabilité Sorties

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 0.5 jour

#### Objectif
Audit parfait (aucune sortie sans traçabilité).

#### Tâches

- [ ] **T3.1** Créer trigger `BEFORE INSERT` sur `sorties_produit`
- [ ] **T3.2** Tester avec service role (migrations/seeds)
- [ ] **T3.3** Créer migration SQL
- [ ] **T3.4** Tests SQL + Flutter

#### DoD

✅ 100% des sorties ont `created_by` défini  
✅ Test SQL validé  
✅ Test Flutter validé

---

## 🔴 AXE B — TESTS DB RÉELS (BLOQUANT)

### B1 — Supabase STAGING

**Type :** Infra / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 1 jour

#### Objectif
Tester la DB réelle, pas des mocks.

#### Tâches

- [ ] **T4.1** Créer projet Supabase staging
- [ ] **T4.2** Configurer `.env.staging`
- [ ] **T4.3** Créer script `reset_staging.sh`
- [ ] **T4.4** Créer seed minimal `seed_staging_minimal.sql`
- [ ] **T4.5** Documenter procédure d'accès

#### DoD

✅ DB staging recréable à l'identique  
✅ Accès sécurisé (pas d'exposition publique)  
✅ Script reset fonctionnel

---

### B2 — Tests d'intégration DB

**Type :** Tests / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 2 jours

#### Objectif
Vérifier triggers + RLS + stock réel.

#### Tâches

- [ ] **T5.1** Dé-SKIP test réception → stock → log
- [ ] **T5.2** Dé-SKIP test sortie → stock → log
- [ ] **T5.3** Créer test refus RLS
- [ ] **T5.4** Configurer SupabaseClient de test
- [ ] **T5.5** Mettre à jour CI pour tests d'intégration (optionnel)

#### DoD

✅ Tests passent sur staging  
✅ Échec réel si trigger/RLS cassé  
✅ Coverage : réception, sortie, RLS

---

## 🔴 AXE C — SÉCURITÉ & CONTRAT PROD (BLOQUANT)

### C1 — Décision RLS PROD

**Type :** Gouvernance / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 0.5 jour

#### Objectif
Décision écrite et validée.

#### Tâches

- [ ] **T6.1** Documenter les options
- [ ] **T6.2** Prendre décision formelle
- [ ] **T6.3** Documenter implications

#### DoD

✅ Décision écrite et signée  
✅ Implications documentées

---

### C2 — Implémentation RLS

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 1.5 jours

#### Objectif
Accès strictement conforme.

#### Tâches

- [ ] **T6.4** Implémenter policies `SELECT`
- [ ] **T6.5** Implémenter policies `INSERT`
- [ ] **T6.6** Implémenter policies `UPDATE`
- [ ] **T6.7** Répéter pour toutes tables critiques
- [ ] **T6.8** Créer migration SQL
- [ ] **T6.9** Tests de permissions par rôle

#### DoD

✅ Policies `SELECT`, `INSERT`, `UPDATE`, `DELETE` appliquées  
✅ Tests automatisés verts  
✅ Aucune fuite de données entre dépôts

---

## 🟡 AXE D — STABILISATION & RUN (OBLIGATOIRE AVANT PROD)

### D1 — Nettoyage legacy

**Type :** Code / Qualité  
**Priorité :** 🟡 Obligatoire  
**Effort estimé :** 1 jour

#### Objectif
Aucun legacy actif en runtime.

#### Tâches

- [ ] **T7.1** Supprimer `SortieDraftService`
- [ ] **T7.2** Supprimer appels `rpcValidateReception`
- [ ] **T7.3** Nettoyer TODO critiques
- [ ] **T7.4** Geler vues legacy

#### DoD

✅ Aucun code legacy utilisé  
✅ Annotations `@Deprecated` nettoyées  
✅ `grep "TODO.*CRITICAL" lib/` retourne 0 résultats

---

### D2 — Contrat "Vérité Stock"

**Type :** Architecture / Critique  
**Priorité :** 🟡 Obligatoire  
**Effort estimé :** 1 jour

#### Objectif
Une seule source "stock actuel". Éliminer toute ambiguïté snapshot/daily/global/owner.

#### Tâches

- [ ] **T8.1** Créer document officiel
  - Fichier : `docs/CONTRAT_VERITE_STOCK.md`
  - **Vue canonique unique** : `v_stock_actuel_snapshot` (temps réel)
  - Règles d'agrégation documentées

- [ ] **T8.2** Marquer toutes les vues legacy DEPRECATED
  ```sql
  COMMENT ON VIEW stock_actuel IS 'DEPRECATED: Use v_stock_actuel_snapshot';
  COMMENT ON VIEW v_citerne_stock_actuel IS 'DEPRECATED: Use v_stock_actuel_snapshot';
  COMMENT ON VIEW v_stock_actuel_owner_snapshot IS 'DEPRECATED: Naming trompeur, use v_kpi_stock_owner';
  ```

- [ ] **T8.3** Tests contractuels SQL
  - Fichier : `docs/db/STOCK_CONTRACT_TESTS.md`
  - Vérifier agrégation cohérente
  - Vérifier séparation propriétaires

- [ ] **T8.4** Tests Flutter
  - Fichier : `test/db/stock_contract_test.dart`
  - Toute référence à vue legacy = échec test

#### DoD

✅ Une seule source documentée (`v_stock_actuel_snapshot`)  
✅ Toutes vues legacy marquées DEPRECATED en DB  
✅ Toute régression (utilisation legacy) casse les tests  
✅ Plus d'ambiguïté snapshot/daily/global/owner

---

### D3 — Runbook de release

**Type :** Ops / Critique  
**Priorité :** 🟡 Obligatoire  
**Effort estimé :** 1 jour

#### Objectif
Aucune release sans dossier de validation.

#### Tâches

- [ ] **T9.1** Créer runbook
- [ ] **T9.2** Créer checklist SQL
- [ ] **T9.3** Créer template de validation
- [ ] **T9.4** Créer structure `releases/`

#### DoD

✅ Runbook complet et actionable  
✅ Checklist SQL obligatoire  
✅ Template de validation créé

---

### D4 — Observabilité minimale

**Type :** Ops / Recommandé fort  
**Priorité :** 🟡 Recommandé  
**Effort estimé :** 1.5 jours

#### Objectif
Plus aucun silence en cas d'erreur.

#### Tâches

- [ ] **T10.1** Logs DB erreurs triggers
- [ ] **T10.2** Logs Flutter erreurs API
- [ ] **T10.3** Logs KPI fallback
- [ ] **T10.4** Option Sentry (optionnel)

#### DoD

✅ Logs DB erreurs triggers fonctionnels  
✅ Logs Flutter erreurs API fonctionnels  
✅ Plus de fallback silencieux dans KPI

---

## 🎯 TABLEAU DE SUIVI (GO / NO-GO)

| Axe | Tickets | Statut | Responsable | Date cible |
|-----|---------|--------|-------------|------------|
| **A** | A1–A3 | ⬜ 0/3 | - | - |
| **B** | B1–B2 | ⬜ 0/2 | - | - |
| **C** | C1–C2 | ⬜ 0/2 | - | - |
| **D** | D1–D4 | ⬜ 0/4 | - | - |

**Légende :** ⬜ À faire | 🟡 En cours | ✅ Terminé | ❌ Bloqué

---

## 🏁 CRITÈRE FINAL DU SPRINT

### 🟢 GO PROD INDUSTRIEL si :

✅ **Tous les tickets A, B, C = DONE** (bloquants)  
✅ **Tous les tickets D = DONE** (obligatoires)  
✅ **CI verte** + intégration DB verte  
✅ **Runbook rempli** et archivé

### ❌ NO-GO si :

❌ **1 seul ticket A/B/C non terminé**  
❌ **Tests d'intégration DB non validés**  
❌ **Runbook incomplet**

---

## 📊 Détail des Tickets par Jour (Planning Indicatif)

### Semaine 1 (Jours 1-5)

**Jour 1-2 :** AXE A (DB-STRICT & Intégrité)
- A1 : Immutabilité (0.5j)
- A2 : Compensations (1.5j)

**Jour 3 :** AXE A (suite) + AXE B (début)
- A3 : Traçabilité Sorties (0.5j)
- B1 : Supabase STAGING (0.5j)

**Jour 4-5 :** AXE B + AXE C (début)
- B1 : STAGING suite (0.5j)
- B2 : Tests intégration DB (2j)
- C1 : Décision RLS (0.5j)

### Semaine 2 (Jours 6-10)

**Jour 6-7 :** AXE C (suite)
- C2 : Implémentation RLS (1.5j)
- Tests RLS (0.5j)

**Jour 8-9 :** AXE D (Stabilisation)
- D1 : Nettoyage legacy (1j)
- D2 : Contrat vérité stock (1j)

**Jour 10 :** AXE D (suite) + Finalisation
- D3 : Runbook (1j)
- D4 : Observabilité (optionnel si temps)

### Semaine 3 (Jours 11-15 si nécessaire)

**Jour 11-12 :** Buffer & Corrections
- Corrections bugs détectés
- Finalisation D4 si non fait

**Jour 13-14 :** Validation finale
- Relecture complète
- Tests exhaustifs
- Remplissage runbook

**Jour 15 :** GO / NO-GO
- Réunion décision
- Archivage documentation

---

## 📝 Suivi Quotidien

### Template Daily Standup

**Date :** [JJ/MM/AAAA]

**✅ Fait hier :**
- [Ticket X] : [Description]

**🎯 Aujourd'hui :**
- [Ticket Y] : [Objectif]

**🚧 Blocages :**
- [Description blocage]

**📊 Avancement :**
- Axe A : X/3 tickets
- Axe B : X/2 tickets
- Axe C : X/2 tickets
- Axe D : X/4 tickets

---

## 🎓 Critères de Succès par Axe

### AXE A — Succès si :
✅ Aucun mouvement modifiable après insertion  
✅ Compensations fonctionnelles et tracées  
✅ 100% des sorties traçables

### AXE B — Succès si :
✅ STAGING recréable à l'identique  
✅ Tests d'intégration DB passent  
✅ Triggers et RLS validés en conditions réelles

### AXE C — Succès si :
✅ Politique RLS décidée et documentée  
✅ Accès strictement conformes  
✅ Tests automatisés verts

### AXE D — Succès si :
✅ Aucun legacy actif  
✅ Vérité stock verrouillée  
✅ Runbook complet  
✅ Observabilité en place

---

## 📞 Contacts & Escalade

**Product Owner :** [Nom]  
**Tech Lead :** [Nom]  
**DBA :** [Nom]

**Escalade si :**
- Blocage technique > 4h
- Décision architecture requise
- Délai sprint compromis

---

**Document créé le :** 31 décembre 2025  
**Dernière mise à jour :** 31 décembre 2025  
**Version :** 1.0


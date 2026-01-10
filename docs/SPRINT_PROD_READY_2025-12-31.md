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

## 🟢 AXE A — DB-STRICT & INTÉGRITÉ MÉTIER ✅ DONE

**⚠️ IMPORTANT** : AXE A verrouillé côté DB (2025-12-31). Toute régression Flutter ou SQL est interdite sans modification explicite du contrat `docs/db/AXE_A_DB_STRICT.md`.

### A1 — Immutabilité totale des mouvements

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 0.5 jour

#### Objectif
Aucun `UPDATE`/`DELETE` possible sur les mouvements validés.

#### Tâches

- [x] **T1.1** Créer trigger `BEFORE UPDATE` sur `receptions`
- [x] **T1.2** Créer trigger `BEFORE DELETE` sur `receptions`
- [x] **T1.3** Répéter pour `sorties_produit`
- [x] **T1.4** Répéter pour `stocks_journaliers`
- [x] **T1.5** Créer migration SQL idempotente
- [x] **T1.6** Créer tests SQL de validation

#### DoD (Definition of Done)

✅ `UPDATE`/`DELETE` échouent systématiquement avec message explicite  
✅ Test SQL archivé et validé  
✅ Documentation des tests complète

**Documentation** : `docs/db/AXE_A_DB_STRICT.md` (section "Immutabilité des tables critiques")

---

### A2 — Compensations officielles (stock_adjustments)

**Type :** DB / Critique  
**Priorité :** 🔴 Bloquant  
**Effort estimé :** 1.5 jours

#### Objectif
Corriger sans casser l'historique.

#### Tâches

- [x] **T2.1** Créer table `stock_adjustments`
- [x] **T2.2** Créer fonction `admin_adjust_stock(...)`
- [x] **T2.3** Créer trigger `AFTER INSERT` sur `stock_adjustments`
- [x] **T2.4** Ajouter logs CRITICAL automatiques
- [x] **T2.5** Configurer RLS admin uniquement
- [x] **T2.6** Créer migration SQL
- [x] **T2.7** Tests SQL de validation

#### DoD

✅ Correction possible uniquement via compensation  
✅ Aucune écriture directe autorisée sur `receptions`/`sorties_produit`  
✅ Log CRITICAL généré automatiquement  
✅ Tests passent

**Documentation** : `docs/db/AXE_A_DB_STRICT.md` (section "Corrections officielles via stocks_adjustments")

---

### A2.7 — Source de vérité stock (v_stock_actuel) ✅ DONE

**Type :** DB / Architecture  
**Priorité** : 🔴 Bloquant  
**Statut** : ✅ **DONE** (2025-12-31)

#### Objectif
Définir la source de vérité unique pour le stock actuel.

#### Tâches

- [x] **T2.7.1** Créer vue `v_stock_actuel` (snapshot + adjustments)
- [x] **T2.7.2** Créer contrat officiel `docs/db/CONTRAT_STOCK_ACTUEL.md`
- [x] **T2.7.3** Documenter interdictions (sources legacy)
- [x] **T2.7.4** Mettre à jour documentation vues SQL

#### DoD

✅ Vue `v_stock_actuel` créée et documentée  
✅ Contrat officiel créé  
✅ Documentation vues SQL mise à jour  
✅ Interdictions clairement documentées

**Documentation** : 
- `docs/db/CONTRAT_STOCK_ACTUEL.md` (contrat officiel)
- `docs/db/AXE_A_DB_STRICT.md` (section "Source de vérité du stock")

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

**⚠️ IMPORTANT : AXE D est requis avant toute mise en production.**

### D1 — Nettoyage legacy & gel des sources ambiguës

**Type :** Code / Critique  
**Priorité :** 🔴 Bloquant PROD  
**Effort estimé :** 1 jour

#### Objectif
Suppression ou neutralisation de toutes les sources legacy de stock. Interdiction d'utiliser des lectures non canoniques. Marquage explicite des vues / providers legacy comme DEPRECATED.

#### Tâches

- [ ] **T7.1** Supprimer `SortieDraftService` et autres services legacy
- [ ] **T7.2** Supprimer appels `rpcValidateReception` et autres RPC legacy
- [ ] **T7.3** Nettoyer TODO critiques
- [ ] **T7.4** Geler vues legacy (marquer DEPRECATED en DB)
- [ ] **T7.5** Marquer providers Flutter legacy comme `@Deprecated`
- [ ] **T7.6** Interdire toute lecture non canonique dans le code

#### DoD

✅ Aucun code legacy utilisé en runtime  
✅ Annotations `@Deprecated` nettoyées  
✅ `grep "TODO.*CRITICAL" lib/` retourne 0 résultats  
✅ Toutes vues legacy marquées DEPRECATED en DB  
✅ Tous providers legacy marqués `@Deprecated`  
✅ Tests empêchent toute utilisation de sources legacy

---

### D2 — Contrat "Vérité Stock"

**Type :** Architecture / Critique  
**Priorité :** 🔴 Bloquant PROD  
**Effort estimé :** 1 jour

#### Objectif
Définition d'une source canonique unique pour le stock courant. Documentation formelle (contrat). Tests SQL + Flutter empêchant toute régression. Alignement strict du naming.

#### Tâches

- [ ] **T8.1** Créer document officiel
  - Fichier : `docs/db/CONTRAT_VERITE_STOCK.md`
  - **Vue canonique unique** : `v_stock_actuel` (source de vérité)
  - Règles d'agrégation documentées
  - Naming strict documenté

- [ ] **T8.2** Marquer toutes les vues legacy DEPRECATED
  ```sql
  COMMENT ON VIEW stock_actuel IS 'DEPRECATED: Use v_stock_actuel';
  COMMENT ON VIEW v_citerne_stock_actuel IS 'DEPRECATED: Use v_stock_actuel';
  COMMENT ON VIEW v_stock_actuel_owner_snapshot IS 'DEPRECATED: Use v_stock_actuel';
  ```

- [ ] **T8.3** Tests contractuels SQL
  - Fichier : `docs/db/STOCK_CONTRACT_TESTS.md`
  - Vérifier agrégation cohérente
  - Vérifier séparation propriétaires
  - Vérifier alignement naming

- [ ] **T8.4** Tests Flutter
  - Fichier : `test/db/stock_contract_test.dart`
  - Toute référence à vue legacy = échec test
  - Toute référence à provider legacy = échec test

#### DoD

✅ Une seule source documentée (`v_stock_actuel`)  
✅ Toutes vues legacy marquées DEPRECATED en DB  
✅ Toute régression (utilisation legacy) casse les tests  
✅ Plus d'ambiguïté snapshot/daily/global/owner  
✅ Naming strict aligné et documenté

---

### D3 — Runbook de release

**Type :** Ops / Critique  
**Priorité :** 🟡 Obligatoire avant release  
**Effort estimé :** 1 jour

#### Objectif
Checklist pré-release / post-release. Ordre exact d'exécution des migrations et déploiements. Procédure de rollback documentée.

#### Tâches

- [ ] **T9.1** Créer runbook complet
  - Checklist pré-release
  - Checklist post-release
  - Ordre exact d'exécution (migrations → déploiement)
  - Procédure de rollback documentée

- [ ] **T9.2** Créer checklist SQL
  - Vérification migrations appliquées
  - Vérification RLS activée
  - Vérification triggers fonctionnels

- [ ] **T9.3** Créer template de validation
  - Structure `releases/`
  - Template de validation de release

#### DoD

✅ Runbook complet et actionable  
✅ Checklist SQL obligatoire  
✅ Template de validation créé  
✅ Procédure de rollback documentée et testée

---

### D4 — Observabilité minimale

**Type :** Ops / Critique  
**Priorité :** 🟡 Obligatoire avant release  
**Effort estimé :** 1.5 jours

#### Objectif
Logs DB sur erreurs critiques (triggers, RLS). Logs applicatifs sur échecs Supabase. Suppression des fallbacks silencieux.

#### Tâches

- [ ] **T10.1** Logs DB erreurs triggers
  - Logs automatiques sur échec trigger
  - Logs automatiques sur violation RLS

- [ ] **T10.2** Logs Flutter erreurs API
  - Logs sur échec Supabase
  - Logs sur erreurs réseau
  - Suppression fallbacks silencieux

- [ ] **T10.3** Logs KPI fallback
  - Logs explicites sur fallback KPI
  - Suppression fallbacks silencieux

- [ ] **T10.4** Option Sentry (optionnel)

#### DoD

✅ Logs DB erreurs triggers fonctionnels  
✅ Logs Flutter erreurs API fonctionnels  
✅ Plus de fallback silencieux dans KPI  
✅ Toutes erreurs critiques loggées

---

### D5 — UX & lisibilité métier

**Type :** UX / Complément  
**Priorité :** 🟡 Non bloquant mais recommandé  
**Effort estimé :** 1 jour

#### Objectif
Numérotation claire des citernes. Badge "stock ajusté" cohérent. Tooltips explicites (date, auteur, type d'ajustement). KPI lisibles pour décideurs.

⚠️ **D5 est explicitement subordonné à D1/D2.** D5 ne peut être démarré qu'après validation complète de D1 et D2.

#### Tâches

- [ ] **T11.1** Numérotation claire des citernes
  - Identification visuelle (CITERNE 1, CITERNE 2, etc.)
  - Numérotation stable après tri

- [ ] **T11.2** Badge "stock ajusté" cohérent
  - Badge standardisé utilisé partout
  - Tooltip explicite indiquant la présence d'ajustements

- [ ] **T11.3** Tooltips explicites
  - Date de création d'ajustement
  - Auteur de l'ajustement
  - Type d'ajustement (Volume, Température, etc.)

- [ ] **T11.4** KPI lisibles pour décideurs
  - Formatage cohérent des volumes
  - Affichage clair des totaux
  - Indicateurs visuels d'état

#### DoD

✅ Numérotation citernes claire et stable  
✅ Badge "stock ajusté" cohérent partout  
✅ Tooltips explicites sur tous les ajustements  
✅ KPI lisibles et compréhensibles pour décideurs

---

## 🎯 TABLEAU DE SUIVI (GO / NO-GO)

| Axe | Tickets | Statut | Responsable | Date cible |
|-----|---------|--------|-------------|------------|
| **A** | A1, A2, A2.7 | ✅ 3/3 DONE | - | 2025-12-31 |
| **B** | B1–B2 | ✅ 2/2 DONE | - | 04/01/2026 |
| **C** | C1–C2 | ✅ 2/2 DONE | - | 09/01/2026 |
| **D** | D1–D5 | ⬜ 0/5 | - | - |

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

**Jour 8-9 :** AXE D (Stabilisation) — Bloquants
- D1 : Nettoyage legacy & gel sources (1j) — BLOQUANT
- D2 : Contrat vérité stock (1j) — BLOQUANT

**Jour 10-11 :** AXE D (suite) — Obligatoires
- D3 : Runbook de release (1j) — OBLIGATOIRE
- D4 : Observabilité minimale (1.5j) — OBLIGATOIRE

**Jour 12 :** AXE D (complément) — Non bloquant
- D5 : UX & lisibilité métier (1j) — COMPLÉMENT (après D1/D2 validés)

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
- Axe D : X/5 tickets

---

## 🎓 Critères de Succès par Axe

### AXE A — Succès si :
✅ Aucun mouvement modifiable après insertion  
✅ Compensations fonctionnelles et tracées  
✅ 100% des sorties traçables

**Statut** : ✅ **DONE** (2025-12-31) — Voir `docs/db/AXE_A_DB_STRICT.md`

### AXE B — Succès si :
✅ STAGING recréable à l'identique  
✅ Tests d'intégration DB passent  
✅ Triggers et RLS validés en conditions réelles

### AXE C — Succès si :
✅ Politique RLS décidée et documentée  
✅ Accès strictement conformes  
✅ Tests automatisés verts

### AXE D — Succès si :
✅ Aucun legacy actif (D1)  
✅ Vérité stock verrouillée (D2)  
✅ Runbook complet (D3)  
✅ Observabilité en place (D4)  
✅ UX & lisibilité métier améliorées (D5 — complément)

---

## 🟢 AXE D — D1 : Nettoyage Legacy & Build Production-Ready ✅ VALIDÉ

**Date de validation :** 10 janvier 2026  
**Référence :** `scripts/d1_one_shot.sh`

### Objectif de D1

Éliminer les flux legacy (draft/validate/RPC), sécuriser le pipeline de build contre les injections de flags invalides, et fournir des diagnostics automatiques en cas d'échec.

### Périmètre exact

**✅ Inclus :**
- Suppression des flows legacy : `SortieDraftService`, `sortieDraftServiceProvider`, `createDraft()`, `validateReception()`, `rpcValidateReception()`
- Parsing strict des arguments : refus de tout flag non supporté (ex: `-q`, `--quiet`)
- Build encapsulé via tableau Bash : `BUILD_CMD=()` pour empêcher word splitting / injection
- Logging automatique : capture stdout/stderr du build dans un fichier temporaire
- Diagnostic automatique : détection de l'erreur `-q` avec guide de résolution
- Trap de nettoyage : suppression garantie des logs temporaires via `trap EXIT`
- Audits anti-legacy : patterns regex pour détecter du code legacy actif

**❌ Exclu (hors périmètre D1) :**
- Migration des vues DB legacy (sera traité en D2)
- Modifications de logique métier ou DB
- Changements de contrats API / RPC
- Refactoring UI/UX

### Actions réalisées

1. **Suppression des références legacy** :
   - Retrait de `sortieDraftServiceProvider` dans `lib/features/sorties/providers/sortie_providers.dart`
   - Retrait de `rpcValidateReception` dans `lib/shared/db/db_port.dart` (interface + implémentation)
   - Retrait de `rpcValidateReception` dans `test/fixtures/fake_db_port.dart`
   - Suppression du test legacy `test/sorties/sortie_draft_service_test.dart`

2. **Parsing strict des arguments** (`scripts/d1_one_shot.sh`) :
   - Fonction `usage()` avec documentation claire
   - Validation TARGET ∈ {web, macos, apk, ios}
   - Refus de tout argument supplémentaire : `if [[ "$#" -gt 0 ]]; then ... exit 2`
   - Support de `--help` / `-h`

3. **Build sécurisé et tracé** :
   - Construction de la commande dans un tableau : `BUILD_CMD=(flutter build web --release)`
   - Affichage transparent : `echo "Build command: ${BUILD_CMD[*]}"`
   - Validation défensive : regex pour détecter `-q` / `--quiet` dans `BUILD_CMD`
   - Capture de log : `"${BUILD_CMD[@]}" >"$BUILD_LOG" 2>&1`
   - En cas d'échec : affichage des 60 dernières lignes + diagnostic ciblé si erreur `-q` détectée

4. **Nettoyage automatique** :
   - Définition de `ANALYZE_LOG` et `BUILD_LOG` avec valeurs par défaut
   - Trap global : `trap 'rm -f "$ANALYZE_LOG" "$BUILD_LOG"' EXIT`
   - Nettoyage garanti même en cas d'erreur (`set -euo pipefail`)

5. **Audits anti-legacy** (étape 1 du script) :
   - Pattern 1 : `SortieDraftService|sortieDraftServiceProvider`
   - Pattern 2 : `createDraft\(|validateReception\(|rpcValidateReception\(`
   - Pattern 3 : vues legacy spécifiques (stock_actuel, v_citerne_stock_actuel, etc.)
   - Pattern 4 : `TODO.*CRITICAL`
   - Échec du script si pattern détecté dans `lib/` ou `test/`

### Résultat

✅ **Build reproductible** : Commande build explicite et déterministe (tableau Bash)  
✅ **Diagnostics explicites** : En cas d'échec, guide automatique vers la source probable  
✅ **Aucun impact métier** : Aucune modification de logique DB, triggers, ou contrats API  
✅ **Validation CI/CD** : Script `d1_one_shot.sh` prêt pour intégration continue  
✅ **Tests verts** : 469 tests unitaires/widgets PASS

### Statut

**✅ VALIDÉ** — D1 clôturé le 10 janvier 2026

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
**Version :** 1.1

**⚠️ IMPORTANT** : AXE A verrouillé côté DB (2025-12-31). Toute régression Flutter ou SQL est interdite sans modification explicite du contrat `docs/db/AXE_A_DB_STRICT.md`.


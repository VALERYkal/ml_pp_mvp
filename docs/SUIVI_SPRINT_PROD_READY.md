# 📊 SUIVI SPRINT PROD-READY

**Référence :** [Sprint Prod-Ready Complet](./SPRINT_PROD_READY_2025-12-31.md)

---

## 🎯 Objectif du Sprint

**À la fin du sprint, ML_PP MVP est déployable en production industrielle auditée.**

**Durée cible :** 10-15 jours ouvrés  
**Date début :** [À définir]  
**Date fin :** [À définir]

---

## 📊 Vue d'Ensemble Axes

| Axe | Nom | Tickets | Complétés | % | Statut |
|-----|-----|---------|-----------|---|--------|
| 🟢 A | DB-STRICT & Intégrité | 3 | 3/3 | 100% | ✅ DONE |
| 🟢 B | Tests DB Réels | 2 | 2/2 | 100% | ✅ DONE |
| 🟢 C | Sécurité & Contrat | 2 | 2/2 | 100% | ✅ DONE |
| 🟡 D | Stabilisation & Run | 5 | 1/5 | 20% | 🔄 En cours |

**Total :** 8/12 tickets (67%)

---

## 🟢 AXE A — DB-STRICT & INTÉGRITÉ MÉTIER ✅ DONE

**⚠️ IMPORTANT** : AXE A verrouillé côté DB. Toute régression Flutter ou SQL est interdite sans modification explicite du contrat `docs/db/AXE_A_DB_STRICT.md`.

| Ticket | Titre | Effort | Statut | Assigné | Date |
|--------|-------|--------|--------|---------|------|
| A1 | Immutabilité totale | 0.5j | ✅ DONE | - | 2025-12-31 |
| A2 | Compensations officielles | 1.5j | ✅ DONE | - | 2025-12-31 |
| A2.7 | Source de vérité stock | - | ✅ DONE | - | 2025-12-31 |

**Documentation** : `docs/db/AXE_A_DB_STRICT.md`

---

## 🔴 AXE B — TESTS DB RÉELS ✅ DONE

| Ticket | Titre | Effort | Statut | Assigné | Date |
|--------|-------|--------|--------|---------|------|
| B1 | Supabase STAGING | 1j | ✅ DONE | - | 03/01/2026 |
| B2 | Tests intégration DB | 2j | ✅ DONE | - | 04/01/2026 |

**Notes :** Runner one-shot vert (db_smoke + reception + sortie). Documentation : `docs/tests/B2_2_INTEGRATION_DB_STAGING.md`

---

## 🟢 AXE C — SÉCURITÉ & CONTRAT PROD ✅ DONE

| Ticket | Titre | Effort | Statut | Assigné | Date |
|--------|-------|--------|--------|---------|------|
| C1 | Décision RLS PROD | 0.5j | ✅ DONE | - | 09/01/2026 |
| C2 | Implémentation RLS | 1.5j | ✅ DONE | - | 09/01/2026 |

**Documentation** : `docs/security/AXE_C_RLS_S2.md`

---

## 🟡 AXE D — STABILISATION & RUN

**⚠️ IMPORTANT : AXE D est requis avant toute mise en production.**

| Ticket | Titre | Effort | Priorité | Statut | Assigné | Date |
|--------|-------|--------|----------|--------|---------|------|
| D1 | Nettoyage legacy & gel des sources ambiguës | 1j | 🔴 Bloquant PROD | ✅ DONE | - | 10/01/2026 |
| D2 | Contrat "Vérité Stock" | 1j | 🔴 Bloquant PROD | ⬜ | - | - |
| D3 | Runbook de release | 1j | 🟡 Obligatoire avant release | ⬜ | - | - |
| D4 | Observabilité minimale | 1.5j | 🟡 Obligatoire avant release | ⬜ | - | - |
| D5 | UX & lisibilité métier | 1j | 🟡 Non bloquant mais recommandé | ⬜ | - | - |

**Note importante :** D5 ne peut être démarré qu'après validation complète de D1 et D2.

### D1 — Nettoyage Legacy & Build Production-Ready ✅ VALIDÉ

**Référence :** `scripts/d1_one_shot.sh`

**Actions réalisées :**
- Suppression des flows legacy : `SortieDraftService`, `createDraft()`, `validateReception()`, `rpcValidateReception()`
- Parsing strict des arguments : refus de tout flag non supporté (ex: `-q`)
- Build encapsulé via tableau Bash pour empêcher injections
- Logging automatique + diagnostic en cas d'échec
- Trap de nettoyage pour logs temporaires
- Audits anti-legacy intégrés au pipeline

**Résultat :** Build reproductible, diagnostics explicites, aucun impact métier.

**Statut :** ✅ Validé le 10/01/2026 — **D1 clôturé, prêt pour audit DB (D2)**

---

## 🏁 Critère GO / NO-GO

```
🟢 GO PROD INDUSTRIEL si :
   ✅ Tous tickets A, B, C = DONE
   ✅ Tous tickets D = DONE
   ✅ CI verte + intégration DB verte
   ✅ Runbook rempli

❌ NO-GO si :
   ❌ 1 seul ticket A/B/C non terminé
```

**Statut actuel :** ❌ NO-GO (7/7 tickets bloquants complétés — AXE A, B, C terminés — AXE D restant)

---

## 📝 Journal du Sprint

### 31/12/2025 - Finalisation AXE A

**Tickets complétés :**
- ✅ A1 — Immutabilité totale des mouvements
- ✅ A2 — Compensations officielles (stock_adjustments)
- ✅ A2.7 — Source de vérité stock (v_stock_actuel)

**Tickets en cours :**
- [Aucun]

**Blocages :**
- [Aucun]

**Notes :**
- AXE A complété intégralement côté DB
- Documentation exhaustive créée : `docs/db/AXE_A_DB_STRICT.md`
- Contrat stock actuel créé : `docs/db/CONTRAT_STOCK_ACTUEL.md`
- CHANGELOG mis à jour avec entrée AXE A
- **⚠️ IMPORTANT** : AXE A verrouillé côté DB. Toute régression Flutter ou SQL est interdite sans modification explicite du contrat.

---

### 04/01/2026 - Finalisation AXE B

**Tickets complétés :**
- ✅ B1 — Supabase STAGING
- ✅ B2 — Tests intégration DB (runner one-shot vert)

**Notes :**
- Tests d'intégration DB réels STAGING validés
- Documentation officielle créée : `docs/tests/B2_2_INTEGRATION_DB_STAGING.md`
- Runner one-shot vert : `flutter test test/integration/db_smoke_test.dart test/integration/reception_stock_log_test.dart test/integration/sortie_stock_log_test.dart -r expanded`

---

### 09/01/2026 - Finalisation AXE C

**Tickets complétés :**
- ✅ C1 — Décision RLS PROD (RLS S2)
- ✅ C2 — Implémentation RLS (migration + smoke tests)

**Notes :**
- Mise en place du **Row Level Security (RLS) S2** sur les tables critiques
- Création de helpers SQL sécurisés (`SECURITY DEFINER`) : `app_uid()`, `app_current_role()`, `app_current_depot_id()`, `app_is_admin()`, `app_is_cadre()`
- Politique critique appliquée : **INSERT sur `stocks_adjustments` autorisé uniquement pour le rôle `admin`**
- Validation en staging minimal (admin + lecture) :
  - `admin` → INSERT `stocks_adjustments` : **OK**
  - `lecture` → INSERT `stocks_adjustments` : **bloqué (ERROR 42501 RLS)**
- Script de smoke test dédié : `staging/sql/rls_smoke_test_s2.sql`
- Documentation créée : `docs/security/AXE_C_RLS_S2.md`
- CHANGELOG mis à jour avec entrée AXE C

---

**Dernière mise à jour :** 09/01/2026


# Décision GO PROD — ML_PP MVP (Janvier 2026)

**Date de décision** : 2026-01-27  
**Statut** : ✅ **GO PROD AUTORISÉ**  
**Responsable** : Release Manager / Tech Lead  
**Version** : 1.0

---

## 1. Contexte de validation

### Environnement de validation

- **STAGING** : Environnement prod-like validé avec données réelles
- **Seed aligné** : `staging/sql/seed_staging_prod_like.sql` aligné avec les IDs hardcodés Flutter
- **Validation métier** : Cycle complet exécuté (Admin → Gérant → Directeur → PCA)

### Validation technique

- **CI PR** : ✅ Verte (tests unit/widget, analyse statique)
- **CI Nightly** : ✅ Verte (Full Suite, ≥1 cycle complet validé)
- **Tests** : 482 tests passants, 8 skippés (opt-in DB, suites dépréciées)
- **Intégrité DB** : Triggers, FK, vues, RLS validés
- **Sécurité** : RLS activé, verrouillage rôle utilisateur (DB-level)

---

## 2. Checklist GO PROD complète

| Catégorie | Élément | Statut | Notes |
|-----------|---------|--------|-------|
| **Flux métier** | CDR → Réception → Stock → Sortie | ✅ | Cycle end-to-end validé en STAGING |
| **Intégrité DB** | Triggers, FK, vues, RLS | ✅ | Validation complète |
| **UI cohérente** | Affichage DB ↔ UI | ✅ | Citernes, Stocks, KPI alignés |
| **CI PR** | Tests unit/widget verts | ✅ | Feedback rapide (~2-3 min) |
| **CI Nightly** | Full Suite verte | ✅ | ≥1 cycle complet validé |
| **Sécurité** | RLS, verrouillage rôle | ✅ | P0 neutralisé (DB-level) |
| **Documentation** | CHANGELOG, post-mortem, Release Gate | ✅ | Complète et opposable |
| **STAGING** | Validation métier finale | ✅ | 2026-01-23 — Cycle réel validé |
| **Seed aligné** | IDs produits hardcodés | ✅ | AGO = `22222222-2222-2222-2222-222222222222` |

---

## 3. Décision explicite

### ✅ GO PROD AUTORISÉ

**Justification** :

1. **Flux métier opérationnel** : CDR → Réception → Stock → Sortie validé en conditions réelles
2. **Intégrité DB garantie** : Triggers, FK, vues, RLS conformes aux exigences
3. **UI cohérente** : Affichage aligné avec la source de vérité DB
4. **CI stable** : PR et Nightly vertes, tests déterministes passants
5. **Sécurité renforcée** : RLS activé, verrouillage rôle utilisateur (DB-level)
6. **Documentation complète** : Post-mortem, Release Gate, CHANGELOG à jour

### Aucun risque bloquant identifié

- ✅ Aucun test en échec (482 passants)
- ✅ Aucune régression fonctionnelle détectée
- ✅ Aucun secret exposé (audit Git effectué)
- ✅ Aucune anomalie DB critique
- ✅ Aucun écart métier bloquant

---

## 4. Limitations assumées du MVP

### Périmètre MVP (gelé)

- **Stock-only** : 6 citernes (TANK1 → TANK6)
- **Modules inclus** : CDR, Réceptions, Sorties, Stocks, KPI, Logs
- **Modules hors scope** : Clients, Fournisseurs, Transporteurs, Douane, Fiscalité, PDF, Commandes

### Tests DB opt-in

- Tests d'intégration DB nécessitent `RUN_DB_TESTS=1` + `env/.env.staging`
- Tests DB non exécutés par défaut en CI PR (opt-in explicite)
- Validation DB complète via CI Nightly (mode FULL)

### Bruit logs tests/CI

- Logs verbeux identifiés (debugPrint UI, initialisation Supabase)
- Stratégie : réduction progressive via flags, séparation signal/bruit
- Impact : aucun sur sécurité, stabilité, production

---

## 5. Signature technique

**Date** : 2026-01-27  
**Validateur** : Release Manager / Tech Lead  
**Commit de référence** : `HEAD` (après alignement seed STAGING)  
**Tag** : `prod-ready-2026-01-23-nightly-green` (checkpoint officiel)

---

## 6. Références

- `docs/POST_MORTEM_NIGHTLY_2026_01.md` : Post-mortem CI Nightly
- `docs/RELEASE_GATE_2026_01.md` : Release Gate validé
- `docs/02_RUNBOOKS/PROD_READY_STATUS_2026_01_15.md` : État de préparation production
- `docs/04_PLANS/SPRINT_PROD_READY_2026_01.md` : Journal de sprint
- `CHANGELOG.md` : Historique des changements
- `docs/SECURITY_REPORT_V2.md` : Audit sécurité (P0 neutralisé)

---

**Document créé le** : 2026-01-27  
**Dernière mise à jour** : 2026-01-27  
**Version** : 1.0  
**Responsable** : Release Manager / Tech Lead

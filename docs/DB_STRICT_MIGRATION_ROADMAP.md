# Roadmap Migration DB-STRICT — Réceptions & Sorties

**Statut** : 🟡 En cours  
**Date de création** : 2025-12-21  
**Objectif** : Rendre les modules Réceptions & Sorties "DB-STRICT industriel"

---

## 🎯 Objectif poursuivi

Rendre le module Réception (et ensuite Sortie) **"DB-STRICT industriel"** :

- ✅ **INSERT = validation** (pas de brouillon, pas de `validate()` applicatif)
- ✅ **Stock mis à jour uniquement par la DB** (triggers → `stock_upsert_journalier`)
- ✅ **Transactions immuables** (aucun UPDATE/DELETE sur `receptions` et `sorties_produit`)
- ✅ **Corrections uniquement par compensation** (`stock_adjustments`)
- ✅ **Traçabilité totale** (`log_actions` systématique, compensations en CRITICAL)
- ✅ **Sécurité solide Supabase** (RLS correct + SECURITY DEFINER maîtrisé + pas de fallback silencieux)

**Résultat attendu** : zéro incohérence stock, KPI fiables, maintenance simple, surface de bug réduite.

---

## 📋 Plan d'exécution (ordre strict)

### Phase 0 — Contrat & garde-fous (verrouillage conceptuel)

**Statut** : 🟢 Complété  
**Livrables** :
- ✅ `docs/TRANSACTION_CONTRACT.md` validé (1 page)
- ✅ Décision : "pas de draft en MVP" confirmée
- ✅ Décision : "correction = compensation only" confirmée

**Critère de sortie** :
- [x] Toute l'équipe dev accepte que `receptions`/`sorties_produit` sont immutables.

**Documentation** : [Transaction Contract](./TRANSACTION_CONTRACT.md)

---

### Phase 1 — Migration SQL "Lock + Adjustments" (le cœur)

**Statut** : 🟡 En cours  
**But** : Rendre la DB impossible à contourner.

**Livrables** :
- [ ] Triggers immutabilité (UPDATE/DELETE bloqués)
- [ ] Table `stock_adjustments` créée
- [ ] RLS propre sur `stock_adjustments`
- [ ] Fonctions admin de compensation (`admin_compensate_reception`, `admin_compensate_sortie`)
- [ ] Tests manuels SQL validés

**Critère de sortie** :
- [ ] SQL appliqué sur staging : OK
- [ ] Tests manuels SQL :
  - [ ] `UPDATE reception` → rejet
  - [ ] `DELETE sortie` → rejet
  - [ ] `INSERT adjustment admin` → stock modifié + log CRITICAL
  - [ ] Non-admin insert adjustment → rejet

**Documentation** : [Guide Migration SQL](./db/DB_STRICT_MIGRATION_SQL.md)

---

### Phase 2 — Nettoyage code Flutter (supprimer le legacy)

**Statut** : ⚪ À faire  
**But** : Empêcher l'app d'appeler des chemins interdits.

**Livrables** :
- [ ] Supprimer `createDraft()`/`validate()` (réceptions)
- [ ] Supprimer `SortieDraftService`
- [ ] Supprimer providers/écrans legacy ou les migrer vers `createValidated()`
- [ ] S'assurer que UI moderne utilise uniquement `createValidated()`

**Critère de sortie** :
- [ ] Recherche globale : plus aucune occurrence de `createDraft`, `validateReception`, `SortieDraftService`, `brouillon`.

**Documentation** : [Guide Nettoyage Code](./DB_STRICT_CLEANUP_CODE.md)

---

### Phase 3 — Migration tests (aligner la vérité)

**Statut** : ⚪ À faire  
**But** : Les tests doivent tester le paradigme DB-STRICT.

**Livrables** :
- [ ] Tests d'intégration Réception : `createValidated()` uniquement, asserts sur invariants
- [ ] Tests Sorties : idem
- [ ] Ajouter tests "immutabilité" et "compensation"

**Critère de sortie** :
- [ ] Suite tests verte sur CI/local

**Documentation** : [Guide Migration Tests](./DB_STRICT_MIGRATION_TESTS.md)

---

### Phase 4 — Hardening & observabilité

**Statut** : ⚪ À faire  
**But** : Finaliser la robustesse et la traçabilité.

**Livrables** :
- [ ] Codes d'erreur DB stables (pour mapping UI)
- [ ] Documentation mise à jour
- [ ] Changelog
- [ ] Optionnel : endpoints admin UI pour compensation (plus tard)

**Critère de sortie** :
- [ ] Tous les codes d'erreur documentés
- [ ] Documentation à jour
- [ ] Changelog publié

**Documentation** : [Guide Hardening](./DB_STRICT_HARDENING.md)

---

## 📊 Suivi d'avancement

| Phase | Statut | Date début | Date fin | Blocages |
|-------|--------|------------|----------|----------|
| Phase 0 | 🟢 Complété | 2025-12-21 | 2025-12-21 | Aucun |
| Phase 1 | 🟡 En cours | 2025-12-21 | - | - |
| Phase 2 | ⚪ À faire | - | - | - |
| Phase 3 | ⚪ À faire | - | - | - |
| Phase 4 | ⚪ À faire | - | - | - |

---

## 🔗 Liens utiles

- [Transaction Contract](./TRANSACTION_CONTRACT.md)
- [Guide Migration SQL](./db/DB_STRICT_MIGRATION_SQL.md)
- [Guide Nettoyage Code](./DB_STRICT_CLEANUP_CODE.md)
- [Guide Migration Tests](./DB_STRICT_MIGRATION_TESTS.md)
- [Guide Hardening](./DB_STRICT_HARDENING.md)

---

## 📝 Notes importantes

- **Ordre strict** : Ne pas passer à la phase suivante tant que les critères de sortie ne sont pas remplis.
- **Tests obligatoires** : Chaque phase doit être validée par des tests avant de passer à la suivante.
- **Documentation** : Toute modification doit être documentée dans le changelog.

---

**Dernière mise à jour** : 2025-12-21


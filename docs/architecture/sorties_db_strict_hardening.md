# Sorties DB-STRICT Hardening — Implémentation

**Date** : 2025-12-19  
**Migration** : `2025-12-19_sorties_db_strict_hardening.sql`  
**Statut** : ✅ Implémenté

---

## Vue d'ensemble

Cette migration implémente le verrouillage DB-STRICT pour `public.sorties_produit` :
- ✅ Validations **BEFORE INSERT** (stock suffisant, citerne active, produit/citerne, XOR bénéficiaire)
- ✅ Contrainte CHECK **XOR stricte** (client_id XOR partenaire_id)
- ✅ **Immutabilité absolue** (UPDATE/DELETE bloqués)
- ✅ Codes d'erreur stables pour mapping UI

---

## État Avant/Après

### Triggers Avant

| Nom | Type | Timing | Fonction | État |
|-----|------|--------|----------|------|
| `trg_sorties_after_insert` | Trigger | AFTER | `fn_sorties_after_insert()` | ✅ Conservé |
| `trg_sortie_before_upd_trg` | Trigger | BEFORE | `sortie_before_upd_trg()` | ❌ Remplacé |

### Triggers Après

| Nom | Type | Timing | Fonction | État |
|-----|------|--------|----------|------|
| `trg_sorties_check_before_insert` | Trigger | BEFORE | `sorties_check_before_insert()` | ✅ Nouveau |
| `trg_sorties_after_insert` | Trigger | AFTER | `fn_sorties_after_insert()` | ✅ Conservé |
| `trg_prevent_sortie_update` | Trigger | BEFORE | `prevent_sortie_update()` | ✅ Nouveau |
| `trg_prevent_sortie_delete` | Trigger | BEFORE | `prevent_sortie_delete()` | ✅ Nouveau |

---

## Patch 1 : Validation BEFORE INSERT

### Fonction : `sorties_check_before_insert()`

**Rôle** : Valide toutes les règles métier **avant** insertion dans la table.

**Validations effectuées** :

1. **Existence citerne**
   - Code erreur : `CITERNE_NOT_FOUND`
   
2. **Citerne active**
   - Code erreur : `CITERNE_INACTIVE`
   - Vérifie `citerne.statut = 'active'`
   
3. **Cohérence produit/citerne**
   - Code erreur : `PRODUIT_INCOMPATIBLE`
   - Vérifie `citerne.produit_id = sortie.produit_id`
   
4. **XOR bénéficiaire** (client_id XOR partenaire_id)
   - Code erreur : `BENEFICIAIRE_XOR`
   - MONALUXE → `client_id IS NOT NULL AND partenaire_id IS NULL`
   - PARTENAIRE → `partenaire_id IS NOT NULL AND client_id IS NULL`
   
5. **Stock suffisant** (ambiant)
   - Code erreur : `STOCK_INSUFFISANT`
   - Vérifie `stock_ambiant >= volume_ambiant_demandé`
   
6. **Stock 15°C suffisant**
   - Code erreur : `STOCK_INSUFFISANT_15C`
   - Vérifie `stock_15c >= volume_15c_demandé`
   
7. **Capacité sécurité**
   - Code erreur : `CAPACITE_SECURITE`
   - Vérifie `(stock_ambiant - volume_ambiant) >= capacite_securite`

**Note** : Cette fonction ne modifie pas `NEW`, elle valide uniquement. Le calcul des volumes suit la convention existante : `index_apres - index_avant`.

---

## Patch 2 : Contrainte CHECK XOR stricte

### Contrainte : `sorties_produit_beneficiaire_xor`

**Définition** :
```sql
CHECK (
  (client_id IS NOT NULL AND partenaire_id IS NULL) OR
  (client_id IS NULL AND partenaire_id IS NOT NULL)
)
```

**Garantit** : Exactement un des deux (client_id OU partenaire_id) doit être présent.

**Remplacé** : L'ancienne contrainte `sorties_produit_beneficiaire_check` (`client_id IS NOT NULL OR partenaire_id IS NOT NULL`) qui permettait les deux à NULL (ce qui est déjà géré par la vérification XOR dans le trigger).

---

## Patch 3 : Immutabilité absolue

### Fonction : `prevent_sortie_update()`

**Rôle** : Bloque **tous** les UPDATE sur `sorties_produit`.

**Code erreur** : `IMMUTABLE_TRANSACTION`

**Note** : Remplace l'ancien trigger `sortie_before_upd_trg()` qui permettait les UPDATE pour les admins.

### Fonction : `prevent_sortie_delete()`

**Rôle** : Bloque **tous** les DELETE sur `sorties_produit`.

**Code erreur** : `IMMUTABLE_TRANSACTION`

**Note** : Aucun trigger DELETE n'existait avant cette migration.

---

## Patch 4 : Nettoyage (optionnel)

Les fonctions suivantes sont candidates à suppression mais sont **commentées** dans la migration pour sécurité :

- `sorties_check_produit_citerne()` : remplacée par `sorties_check_before_insert()`
- `sorties_apply_effects()` : logique intégrée dans `fn_sorties_after_insert()`
- `sorties_log_created()` : logique intégrée dans `fn_sorties_after_insert()`
- `sortie_before_upd_trg()` : remplacée par `prevent_sortie_update()`

**Recommandation** : Vérifier les dépendances avant suppression avec :
```sql
SELECT * FROM pg_depend WHERE objid = 'public.sorties_check_produit_citerne()'::regproc;
```

---

## Codes d'erreur stables

Pour mapping UI/Flutter, les codes d'erreur suivants sont émis :

| Code | Message | Contexte |
|------|---------|----------|
| `CITERNE_NOT_FOUND` | Citerne introuvable | Citerne ID invalide |
| `CITERNE_INACTIVE` | Citerne inactive ou en maintenance | Citerne non active |
| `PRODUIT_INCOMPATIBLE` | Produit incompatible avec citerne | Produit ≠ produit citerne |
| `BENEFICIAIRE_XOR` | Violation XOR bénéficiaire | client_id/partenaire_id incohérent |
| `STOCK_INSUFFISANT` | Stock insuffisant (ambiant) | stock < volume demandé |
| `STOCK_INSUFFISANT_15C` | Stock insuffisant (15°C) | stock_15c < volume_15c demandé |
| `CAPACITE_SECURITE` | Dépassement capacité sécurité | Stock après < capacité sécurité |
| `IMMUTABLE_TRANSACTION` | Transaction immuable | Tentative UPDATE/DELETE |

---

## Flow d'exécution

### INSERT Sortie

```
1. BEFORE INSERT: trg_sorties_check_before_insert()
   ├─ Validation citerne active
   ├─ Validation produit/citerne
   ├─ Validation XOR bénéficiaire
   ├─ Validation stock suffisant
   └─ Validation capacité sécurité
   ✅ Si OK → continue
   ❌ Si KO → RAISE EXCEPTION (rollback automatique)

2. INSERT dans sorties_produit (commit si pas d'erreur)

3. AFTER INSERT: trg_sorties_after_insert() → fn_sorties_after_insert()
   ├─ Débit stock (via stock_upsert_journalier)
   └─ Log action (log_actions)
```

### UPDATE Sortie

```
1. BEFORE UPDATE: trg_prevent_sortie_update()
   └─ ❌ RAISE EXCEPTION (IMMUTABLE_TRANSACTION)
```

### DELETE Sortie

```
1. BEFORE DELETE: trg_prevent_sortie_delete()
   └─ ❌ RAISE EXCEPTION (IMMUTABLE_TRANSACTION)
```

---

## Tests SQL manuels

Voir `docs/db/sorties_trigger_tests.md` section "DB-STRICT Hardening Tests".

---

## Migration idempotente

Tous les patches utilisent :
- `CREATE OR REPLACE FUNCTION` (idempotent)
- `DROP TRIGGER IF EXISTS` (idempotent)
- `DROP CONSTRAINT IF EXISTS` (idempotent)
- `ALTER TABLE ... ADD CONSTRAINT ...` (échoue si existe déjà, mais idempotent avec DROP avant)

La migration peut être rejouée sans erreur.

---

## Rétrocompatibilité

- ✅ Aucune modification du schéma de table (colonnes inchangées)
- ✅ Le trigger AFTER INSERT existant (`fn_sorties_after_insert`) est **conservé**
- ✅ Les validations sont **additionnelles** (BEFORE), pas remplaçantes
- ⚠️ **Breaking change** : UPDATE/DELETE sont maintenant bloqués (même pour admin)

---

## Références

- [Audit initial](sorties_db_audit.md)
- [Transaction Contract](../TRANSACTION_CONTRACT.md)
- [DB-STRICT Migration Roadmap](../DB_STRICT_MIGRATION_ROADMAP.md)

---

**Dernière mise à jour** : 2025-12-19


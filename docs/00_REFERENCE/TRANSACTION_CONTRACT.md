# CONTRAT TRANSACTIONNEL — Réceptions & Sorties

**Statut** : ✅ VALIDÉ — OBLIGATOIRE  
**Date de création** : 2025-12-21  
**Version** : 1.0  
**NE PAS MODIFIER SANS VALIDATION DIRECTION**

---

## Principe fondamental

**Les réceptions et sorties sont des écritures comptables de stock.**

Elles ne sont **PAS** des entités CRUD modifiables.

---

## Invariants non négociables

### 1. Atomicité : INSERT = validation

Une réception ou sortie **validée** est créée en **un seul acte atomique** :

```
INSERT → Trigger DB → Stock mis à jour → Transaction committée
```

**Pas de brouillon.** Pas de validation différée.

---

### 2. Immutabilité absolue : zéro exception

Une transaction validée **ne peut JAMAIS être modifiée ou supprimée**.

- ❌ `UPDATE receptions SET ... WHERE statut='validee'` → **BLOQUÉ PAR TRIGGER**
- ❌ `DELETE FROM sorties_produit WHERE statut='validee'` → **BLOQUÉ PAR TRIGGER**

**Il n'existe aucun bypass, aucune exception, aucun flag admin.**

**Protection DB :** triggers `prevent_reception_update()` et `prevent_sortie_update()` rejettent **toute** tentative, sans exception.

---

### 3. Correction : compensation uniquement

En cas d'erreur, on **ne modifie jamais** la transaction incorrecte.

**On crée un mouvement compensatoire dans `stock_adjustments` :**

| Cas | Solution |
|-----|----------|
| Réception saisie en double | `admin_compensate_reception(id, raison)` → crée adjustment négatif |
| Sortie avec mauvais volume | `admin_compensate_sortie(id, raison)` → crée adjustment positif |
| Erreur de saisie | Créer un nouvel adjustment manuel avec raison détaillée |

**Caractéristiques du mouvement compensatoire :**
- Inséré dans `stock_adjustments` (table dédiée)
- Trigger applique automatiquement `stock_upsert_journalier()`
- Log niveau CRITICAL généré automatiquement
- Référence la transaction source (`source_type`, `source_id`)
- Raison obligatoire (minimum 10 caractères)
- Réservé au rôle `admin`

**Toute compensation est tracée et auditée.**

---

### 4. Source de vérité : la base de données

Le **stock** est calculé **uniquement** par la base de données via :

- `stock_upsert_journalier()` (fonction atomique)
- `stocks_journaliers` (table de fait, alimentée par triggers + adjustments)
- `v_citerne_stock_actuel` (vue consolidée)

**L'application ne calcule jamais le stock elle-même.**

---

### 5. Validation métier : triggers SQL

Les règles métier sont appliquées **côté base** via triggers :

- `receptions_apply_effects()` → crédit stock
- `sorties_apply_effects()` → débit stock
- `apply_stock_adjustment()` → delta stock (compensation)
- Vérifications produit/citerne, capacité, etc.

**L'application peut faire des validations UX, mais la DB est le juge final.**

---

### 6. Audit : logs obligatoires

Toute transaction et toute compensation génèrent :

- Une entrée dans `log_actions`
- Détails JSON complets
- **Les compensations sont en niveau CRITICAL**

---

## Conséquences pour les développeurs

### ✅ Ce qui est autorisé

- Créer une réception : `ReceptionService.createValidated()`
- Créer une sortie : `SortieService.createValidated()`
- Créer une compensation admin : `admin_compensate_reception(id, reason)`
- Lire le stock : `StocksRepository.totauxActuels()`

### ❌ Ce qui est interdit (bloqué par trigger)

- Modifier une transaction validée : `UPDATE receptions WHERE statut='validee'`
- Supprimer une transaction validée : `DELETE FROM sorties_produit WHERE statut='validee'`
- Créer un brouillon : `createDraft()` n'existe plus
- Valider différemment : `validate()` n'existe plus
- Calculer le stock côté app : `stocks_journaliers` est la source

---

## Gestion des erreurs humaines

**Cas : réception saisie en double**

```sql
-- Appeler la fonction de compensation
SELECT admin_compensate_reception(
  'uuid-reception-erronee',
  'Réception saisie en double, annulation du mouvement de stock'
);
```

Résultat :
- La réception originale reste en base (historique vrai)
- Un `stock_adjustment` négatif est créé
- Le stock est automatiquement corrigé
- Log CRITICAL tracé

**Pas de modification de la réception originale.**

---

## Tests de validation

- [ ] INSERT réception → stock crédité
- [ ] INSERT sortie → stock débité
- [ ] UPDATE réception validée → exception
- [ ] DELETE sortie validée → exception
- [ ] Compensation admin → adjustment créé + stock corrigé + log CRITICAL

---

## Historique

| Date | Auteur | Action |
|------|--------|--------|
| 2025-12-21 | Architecture | Création contrat v1.0 (immutabilité absolue) |

---

**Ce document est un contrat d'architecture. Toute modification nécessite validation direction + équipe technique.**


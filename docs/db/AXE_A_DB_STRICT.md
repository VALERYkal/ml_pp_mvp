# AXE A — DB-STRICT & INTÉGRITÉ MÉTIER

**Date de finalisation** : 2025-12-31  
**Statut** : ✅ **DONE** — PROD-READY DB-STRICT  
**Version** : 1.0  
**Verrouillage** : AXE A verrouillé côté DB. Toute régression Flutter ou SQL est interdite sans modification explicite de ce contrat.

---

## Objectif de l'AXE A

Rendre la base de données **impossible à contourner** pour garantir l'intégrité métier absolue des transactions de stock (réceptions, sorties) et la traçabilité complète.

**Résultat** : Zéro incohérence de stock, KPI fiables, maintenance simple, surface de bug réduite.

---

## Principe DB-STRICT

### Définition

**DB-STRICT** signifie que la base de données est le **juge final** pour toutes les règles métier critiques :

- ✅ **Immutabilité absolue** : Les transactions validées ne peuvent jamais être modifiées ou supprimées
- ✅ **Corrections officielles uniquement** : Toute correction passe par un mécanisme de compensation tracé
- ✅ **Source de vérité unique** : Le stock actuel est calculé exclusivement par la DB
- ✅ **Traçabilité totale** : Toute action critique est journalisée et auditée

### Pourquoi DB-STRICT

**Problème résolu** : Avant DB-STRICT, il était possible de :
- Modifier une réception après validation (risque d'incohérence stock)
- Supprimer une sortie (perte d'audit)
- Corriger directement dans les tables (pas de traçabilité)

**Solution** : La DB bloque toute opération non conforme et force l'utilisation de mécanismes officiels tracés.

---

## Immutabilité des tables critiques

### Tables concernées

Les tables suivantes sont **immuables** une fois qu'une transaction est validée :

1. **`receptions`** — Réceptions de produits
2. **`sorties_produit`** — Sorties de produits
3. **`stocks_journaliers`** — Historique des stocks (lecture seule sauf admin)
4. **`stocks_adjustments`** — Corrections officielles (insertion uniquement, jamais modification)

### Mécanisme technique

#### Triggers BEFORE UPDATE / DELETE

**Principe** : Des triggers `BEFORE UPDATE` et `BEFORE DELETE` sont installés sur chaque table critique.

**Comportement** :
- Toute tentative d'`UPDATE` ou `DELETE` sur une transaction validée est **rejetée**
- Exception PostgreSQL explicite levée (code `P0001`)
- Message d'erreur clair : "Cette transaction ne peut pas être modifiée. Utilisez une compensation administrative."

**Exemple de trigger** :
```sql
CREATE TRIGGER prevent_reception_update
BEFORE UPDATE ON public.receptions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_transaction_update();

CREATE TRIGGER prevent_reception_delete
BEFORE DELETE ON public.receptions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_transaction_delete();
```

**Fonctions de protection** :
- `prevent_transaction_update()` : Rejette tout UPDATE avec exception `P0001`
- `prevent_transaction_delete()` : Rejette tout DELETE avec exception `P0001`

**Aucune exception** : Il n'existe aucun bypass, aucun flag admin, aucune condition spéciale.

---

## Corrections officielles via stocks_adjustments

### Pourquoi cette table existe

**Problème métier** : En cas d'erreur humaine (réception en double, sortie avec mauvais volume), il faut corriger le stock sans :
- Modifier l'historique (les transactions originales restent en base)
- Perdre la traçabilité (toute correction est auditée)
- Créer des incohérences (le stock doit rester cohérent)

**Solution** : Table `stocks_adjustments` dédiée aux corrections officielles.

### Logique comptable (écriture de compensation)

**Principe** : Une compensation est un **mouvement de stock** qui corrige une erreur sans modifier la transaction source.

**Exemple** :
- Réception saisie en double de 1000 L
- Correction : `stock_adjustment` avec `delta_ambiant = -1000` (négatif pour annuler)
- Résultat : Le stock est corrigé, la réception originale reste en base (historique vrai)

**Caractéristiques** :
- `delta_ambiant` et `delta_15c` : Volumes de correction (positifs ou négatifs)
- `source_type` : Type de transaction source (`RECEPTION`, `SORTIE`, `MANUAL`)
- `source_id` : UUID de la transaction source (si applicable)
- `reason` : Raison obligatoire (minimum 10 caractères)
- `created_by` : UUID de l'utilisateur admin ayant créé la compensation

### Fonctions admin de compensation

**Fonctions disponibles** :
- `admin_compensate_reception(reception_id UUID, reason TEXT)` : Compense une réception erronée
- `admin_compensate_sortie(sortie_id UUID, reason TEXT)` : Compense une sortie erronée
- `admin_adjust_stock(citerne_id UUID, produit_id UUID, delta_ambiant NUMERIC, delta_15c NUMERIC, reason TEXT)` : Ajustement manuel direct

**Sécurité** :
- Toutes les fonctions sont `SECURITY DEFINER`
- Vérification du rôle : uniquement `admin` peut appeler ces fonctions
- RLS sur `stocks_adjustments` : INSERT réservé aux admins

### Trigger automatique

**Trigger** : `AFTER INSERT ON stocks_adjustments`

**Comportement** :
1. Appelle `stock_upsert_journalier()` avec les deltas de compensation
2. Génère automatiquement un log `log_actions` avec niveau `CRITICAL`
3. Référence la transaction source dans les détails JSON

**Résultat** : Toute compensation modifie le stock et est tracée automatiquement.

---

## Validation d'intégrité des mouvements

### Lien RECEPTION / SORTIE

**Principe** : Chaque mouvement (réception ou sortie) est **lié** à une transaction source pour garantir la traçabilité.

**Tables concernées** :
- `receptions` : Peut être liée à un `cours_de_route` (optionnel)
- `sorties_produit` : Doit avoir un bénéficiaire (`client_id` OU `partenaire_id`)

**Validation** :
- Triggers `BEFORE INSERT` vérifient la cohérence des liens
- Exemple : Une sortie sans bénéficiaire est rejetée

### Contraintes d'intégrité

**Contraintes CHECK** :
- `receptions` : `index_apres > index_avant`, `volume_ambiant >= 0`, etc.
- `sorties_produit` : `index_apres > index_avant`, `volume_ambiant >= 0`, `client_id IS NOT NULL OR partenaire_id IS NOT NULL`, etc.

**Contraintes UNIQUE** :
- `stocks_journaliers` : `(citerne_id, produit_id, date_jour, proprietaire_type)` — Garantit l'unicité des snapshots journaliers

---

## Source de vérité du stock

### v_stock_actuel

**Vue canonique** : `public.v_stock_actuel`

**Rôle** : Source de vérité unique et non ambiguë pour le stock actuel.

**Logique** :
```
stock_actuel = stock_snapshot + Σ(stocks_adjustments)
```

**Expose** :
- Stock actuel corrigé (ambiant et 15°C)
- Par dépôt, citerne, produit et propriétaire
- Tenant compte des mouvements validés et des corrections officielles

**Contrat** : Voir `docs/db/CONTRAT_STOCK_ACTUEL.md` pour les règles absolues.

### Interdiction d'utiliser les sources legacy

**Strictement interdit** pour le stock actuel :
- ❌ `stocks_journaliers` (historique uniquement)
- ❌ `stocks_snapshot` (table interne)
- ❌ `v_stock_actuel_snapshot` (ancienne source, dépréciée)
- ❌ `v_stocks_citerne_global_daily` (historique uniquement)
- ❌ Toute vue legacy ou calcul Flutter

**Raison** : Ces objets sont internes ou historiques. Seule `v_stock_actuel` garantit la cohérence avec les corrections officielles.

---

## Garanties d'audit

### Traçabilité

**Toute action critique génère un log** :
- Réception créée → `log_actions` avec `action = 'RECEPTION_CREEE'`
- Sortie créée → `log_actions` avec `action = 'SORTIE_CREEE'`
- Compensation créée → `log_actions` avec `action = 'STOCK_ADJUSTMENT_CREATED'`, niveau `CRITICAL`

**Champs de traçabilité** :
- `user_id` : Utilisateur ayant effectué l'action
- `module` : Module concerné (`RECEPTIONS`, `SORTIES`, `STOCKS`)
- `action` : Action effectuée
- `niveau` : Niveau de sévérité (`INFO`, `WARNING`, `CRITICAL`)
- `details` : Détails JSON complets
- `cible_id` : UUID de la transaction concernée

### Recalculabilité

**Principe** : Toute valeur de stock affichée est **recalculable** à partir des données sources.

**Sources de calcul** :
1. `receptions` : Volumes crédités
2. `sorties_produit` : Volumes débités
3. `stocks_adjustments` : Corrections officielles
4. `stocks_journaliers` : Historique (pour validation)

**Vérification** : La vue `v_stock_actuel` peut être recalculée à tout moment depuis ces sources.

---

## Statut

### AXE A = DONE

**Date de finalisation** : 2025-12-31

**Tickets complétés** :
- ✅ **A1** — Immutabilité totale des mouvements
- ✅ **A2** — Compensations officielles (`stock_adjustments`)
- ✅ **A2.7** — Source de vérité stock (`v_stock_actuel`)

**Preuves** :
- Triggers `BEFORE UPDATE`/`DELETE` installés et testés
- Table `stocks_adjustments` créée avec RLS
- Fonctions admin de compensation opérationnelles
- Vue `v_stock_actuel` créée et documentée
- Tests SQL de validation archivés

### PROD-READY DB-STRICT

**Critères validés** :
- ✅ Immutabilité garantie par triggers DB
- ✅ Corrections officielles tracées
- ✅ Source de vérité unique documentée
- ✅ Traçabilité complète
- ✅ Recalculabilité garantie

**Verrouillage** : AXE A verrouillé côté DB. Toute régression Flutter ou SQL est interdite sans modification explicite de ce contrat.

---

## Références

- **Contrat transactionnel** : `docs/TRANSACTION_CONTRACT.md`
- **Contrat stock actuel** : `docs/db/CONTRAT_STOCK_ACTUEL.md`
- **Roadmap migration** : `docs/DB_STRICT_MIGRATION_ROADMAP.md`
- **Guide hardening** : `docs/DB_STRICT_HARDENING.md`
- **Sprint Prod-Ready** : `docs/SPRINT_PROD_READY_2025-12-31.md`

---

**Ce document est un contrat d'architecture DB-STRICT. Toute modification nécessite validation direction + équipe technique.**


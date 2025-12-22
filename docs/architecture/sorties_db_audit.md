# Audit DB-STRICT — public.sorties_produit

**Date** : 2025-12-19  
**Auditeur** : DB Auditor  
**Objectif** : Audit complet des triggers, fonctions et contraintes avant implémentation des verrous DB-STRICT

---

## 1. Liste des Triggers sur public.sorties_produit

### 1.1 Triggers Actifs (selon migration 2025-12-19)

| Nom | Type | Timing | Événement | Fonction | État |
|-----|------|--------|-----------|----------|------|
| `trg_sorties_after_insert` | Trigger | AFTER | INSERT | `fn_sorties_after_insert()` | ✅ Actif |
| `trg_sortie_before_upd_trg` | Trigger | BEFORE | UPDATE | `sortie_before_upd_trg()` | ✅ Actif (conservé) |

### 1.2 Triggers Supprimés (par migration 2025-12-19)

Les triggers suivants ont été supprimés et remplacés par `trg_sorties_after_insert` :
- ❌ `trg_sorties_check_produit_citerne` (BEFORE INSERT/UPDATE) → logique intégrée dans `fn_sorties_after_insert()`
- ❌ `trg_sorties_apply_effects` (AFTER INSERT) → logique intégrée dans `fn_sorties_after_insert()`
- ❌ `trg_sorties_log_created` (AFTER INSERT) → logique intégrée dans `fn_sorties_after_insert()`

---

## 2. Définitions des Fonctions de Trigger

### 2.1 `fn_sorties_after_insert()` — Trigger Unifié AFTER INSERT

**Source** : `supabase/migrations/2025-12-19_sorties_trigger_unified.sql` (lignes 186-319)

**Type** : `RETURNS trigger`  
**Langage** : `plpgsql`  
**Sécurité** : `SECURITY DEFINER`  
**Timing** : AFTER INSERT  
**WHEN clause** : Aucune (s'applique à toutes les insertions)

**Responsabilités** :

1. **Normalisation date + propriétaire** (lignes 197-203)
   - Normalise `date_sortie` → `v_date_jour` (fallback: `CURRENT_DATE`)
   - Normalise `proprietaire_type` → UPPER (fallback: `'MONALUXE'`)

2. **Validation citerne** (lignes 206-220)
   - Vérifie que la citerne existe
   - ⚠️ **PROBLÈME** : Vérifie `citerne.statut <> 'active'` (ligne 214)
   - Vérifie `citerne.produit_id = NEW.produit_id` (ligne 218)
   - ⚠️ **PROBLÈME** : Ces validations sont dans AFTER INSERT, pas BEFORE

3. **Normalisation volumes** (lignes 224-236)
   - Calcule `v_volume_ambiant` depuis indices ou utilise `volume_ambiant`
   - Calcule `v_volume_15c` depuis `volume_corrige_15c` ou fallback `v_volume_ambiant`

4. **Cohérence propriétaire/client/partenaire** (lignes 238-253)
   - ✅ MONALUXE → `client_id IS NOT NULL` ET `partenaire_id IS NULL`
   - ✅ PARTENAIRE → `partenaire_id IS NOT NULL` ET `client_id IS NULL`
   - ❌ Sinon → exception

5. **Récupération stock journalier** (lignes 255-268)
   - Récupère le dernier stock connu avant `v_date_jour`
   - ⚠️ **PROBLÈME** : Si `NOT FOUND`, exception générique (pas de vérification stock suffisant avant débit)

6. **Contrôle capacité sécurité** (lignes 270-275)
   - ✅ Vérifie que `(stock_ambiant - volume_ambiant) >= capacite_securite`
   - ⚠️ **PROBLÈME** : Vérifie capacité sécurité mais pas stock suffisant (peut permettre stock négatif)

7. **Débit stock** (lignes 277-287)
   - Appelle `stock_upsert_journalier()` avec volumes négatifs
   - Utilise `proprietaire_type`, `depot_id`, source `'SORTIE'`

8. **Log action** (lignes 289-315)
   - Insère dans `log_actions` avec détails complets

---

### 2.2 `sortie_before_upd_trg()` — Trigger BEFORE UPDATE

**Source** : `supabase/migrations/2025-08-22_sorties_mvp.sql` (lignes 57-78)

**Type** : `RETURNS trigger`  
**Langage** : `plpgsql`  
**Sécurité** : `SECURITY DEFINER`  
**Timing** : BEFORE UPDATE  
**WHEN clause** : Aucune

**Responsabilités** :

1. **Immutabilité partielle** (lignes 63-66)
   - ❌ Non-admin → bloque UPDATE si `OLD.statut <> 'brouillon'`
   - ✅ Admin → autorise UPDATE

2. **Recalcul volume_ambiant** (lignes 68-76)
   - Si indices modifiés → recalcule `volume_ambiant`
   - Vérifie cohérence indices (`index_apres > index_avant`)

**⚠️ PROBLÈME DB-STRICT** : Ce trigger permet encore les UPDATE (même limités). Pour DB-STRICT, tous les UPDATE doivent être bloqués (sauf compensation).

---

### 2.3 Fonctions Obsolètes (non supprimées)

Les fonctions suivantes sont encore présentes mais ne sont plus utilisées par des triggers actifs :

- `sorties_check_produit_citerne()` — remplacée par logique dans `fn_sorties_after_insert()`
- `sorties_apply_effects()` — remplacée par logique dans `fn_sorties_after_insert()`
- `sorties_log_created()` — remplacée par logique dans `fn_sorties_after_insert()`

**Recommandation** : Supprimer ces fonctions après validation.

---

## 3. Identification des Duplications

### 3.1 Fonctions `apply_effects` en Double

**❌ Aucune duplication identifiée** dans l'état actuel (migration 2025-12-19).

**Historique** :
- Migration 2025-08-22 : `sorties_apply_effects()` (AFTER INSERT)
- Migration 2025-12-02 : Intégration dans `fn_sorties_after_insert()`
- Migration 2025-12-19 : Suppression de `trg_sorties_apply_effects`, logique unifiée

**⚠️ NOTE** : Il existe aussi `sorties_apply_effects_v2()` dans `2025-12-XX_stock_engine_v2.sql`, mais elle n'est **pas utilisée** par un trigger actif (trigger `trg_sorties_after_insert_v2` créé mais peut-être non appliqué selon l'ordre des migrations).

---

## 4. Invariants Déjà Appliqués

### 4.1 ✅ Bénéficiaire (client_id XOR partenaire_id)

**Contrainte CHECK** : `sorties_produit_beneficiaire_check` (schemaSQL.md ligne 180)
```sql
CHECK (client_id IS NOT NULL OR partenaire_id IS NOT NULL)
```

**Vérification trigger** : `fn_sorties_after_insert()` lignes 238-253
- ✅ MONALUXE → `client_id IS NOT NULL` ET `partenaire_id IS NULL`
- ✅ PARTENAIRE → `partenaire_id IS NOT NULL` ET `client_id IS NULL`

**✅ État** : **ENFORCED** (CHECK + trigger)

---

### 4.2 ✅ Produit ↔ Citerne

**Vérification trigger** : `fn_sorties_after_insert()` ligne 218
```sql
IF v_citerne.produit_id <> NEW.produit_id THEN
  RAISE EXCEPTION 'Produit incompatible avec la citerne %', v_citerne.id;
END IF;
```

**⚠️ PROBLÈME** : Vérification faite dans **AFTER INSERT** au lieu de **BEFORE INSERT**.

**✅ État** : **ENFORCED** (mais timing suboptimal)

---

### 4.3 ⚠️ Débit Stock

**Appel fonction** : `fn_sorties_after_insert()` lignes 277-287
```sql
PERFORM public.stock_upsert_journalier(
  NEW.citerne_id, NEW.produit_id, v_date_jour,
  -1 * v_volume_ambiant,  -- Débit (négatif)
  -1 * v_volume_15c,      -- Débit (négatif)
  v_proprietaire, v_depot_id, 'SORTIE'
);
```

**Contrôle capacité sécurité** : Lignes 270-275
```sql
IF (v_stock_jour.stock_ambiant - v_volume_ambiant) < v_citerne.capacite_securite THEN
  RAISE EXCEPTION 'Sortie dépasserait la capacité de sécurité...';
END IF;
```

**❌ PROBLÈME** : Pas de vérification que le stock est **suffisant** avant débit. Seule la capacité de sécurité est vérifiée, ce qui peut permettre des stocks négatifs.

**✅ État** : **PARTIALLY ENFORCED** (débit appliqué, mais pas de vérification stock suffisant)

---

### 4.4 ✅ Citerne Active

**Vérification trigger** : `fn_sorties_after_insert()` lignes 214-216
```sql
IF v_citerne.statut <> 'active' THEN
  RAISE EXCEPTION 'Citerne % inactive ou en maintenance', v_citerne.id;
END IF;
```

**⚠️ PROBLÈME** : Vérification faite dans **AFTER INSERT** au lieu de **BEFORE INSERT**.

**✅ État** : **ENFORCED** (mais timing suboptimal)

---

## 5. Verrous DB-STRICT Manquants

### 5.1 ❌ Stock Insuffisant — REJET INSERT

**Problème** : `fn_sorties_after_insert()` vérifie uniquement la capacité de sécurité, pas le stock disponible.

**Code actuel** (lignes 255-275) :
```sql
-- Récupère dernier stock
SELECT * INTO v_stock_jour FROM public.stocks_journaliers
WHERE citerne_id = NEW.citerne_id
  AND produit_id = NEW.produit_id
  AND proprietaire_type = v_proprietaire
  AND date_jour <= v_date_jour
ORDER BY date_jour DESC LIMIT 1;

IF NOT FOUND THEN
  RAISE EXCEPTION 'Aucun stock journalier trouvé...';
END IF;

-- Contrôle capacité sécurité seulement
IF (v_stock_jour.stock_ambiant - v_volume_ambiant) < v_citerne.capacite_securite THEN
  RAISE EXCEPTION 'Sortie dépasserait la capacité de sécurité...';
END IF;
```

**❌ MANQUE** : Vérification que `v_stock_jour.stock_ambiant >= v_volume_ambiant` (et idem pour `stock_15c >= v_volume_15c`)

**Recommandation** : Ajouter vérification **BEFORE INSERT** (ou dans `fn_sorties_after_insert()` si on garde AFTER) :

```sql
-- Vérifier stock suffisant
IF v_stock_jour.stock_ambiant < v_volume_ambiant THEN
  RAISE EXCEPTION 'SORTIE_STOCK_INSUFFISANT: stock_disponible=% volume_demande=%', 
    v_stock_jour.stock_ambiant, v_volume_ambiant;
END IF;

IF v_stock_jour.stock_15c < v_volume_15c THEN
  RAISE EXCEPTION 'SORTIE_STOCK_INSUFFISANT_15C: stock_15c_disponible=% volume_15c_demande=%',
    v_stock_jour.stock_15c, v_volume_15c;
END IF;
```

---

### 5.2 ⚠️ Citerne Inactive — REJET INSERT

**État actuel** : ✅ Vérifié dans `fn_sorties_after_insert()` ligne 214, mais **AFTER INSERT**.

**Recommandation DB-STRICT** : Déplacer en **BEFORE INSERT** pour éviter insertion ligne invalide.

**Recommandation** : Recréer trigger `trg_sorties_check_citerne_active` en BEFORE INSERT, ou intégrer dans une fonction BEFORE INSERT unifiée.

---

### 5.3 ⚠️ client_id XOR partenaire_id — ENFORCEMENT STRICT

**État actuel** : ✅ Vérifié dans `fn_sorties_after_insert()` lignes 238-253, mais **AFTER INSERT**.

**Problème** : La contrainte CHECK `sorties_produit_beneficiaire_check` autorise `client_id IS NULL AND partenaire_id IS NOT NULL` ou `client_id IS NOT NULL AND partenaire_id IS NULL`, mais **pas** `client_id IS NOT NULL AND partenaire_id IS NOT NULL`.

**Recommandation** : La contrainte CHECK actuelle ne garantit pas l'exclusivité. Ajouter une contrainte CHECK supplémentaire :

```sql
ALTER TABLE public.sorties_produit 
DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_xor;
ALTER TABLE public.sorties_produit 
ADD CONSTRAINT sorties_produit_beneficiaire_xor
CHECK (
  (client_id IS NOT NULL AND partenaire_id IS NULL) OR
  (client_id IS NULL AND partenaire_id IS NOT NULL)
);
```

Ou renforcer la vérification en BEFORE INSERT (déplacer logique du trigger).

---

### 5.4 ❌ Contraintes CDR/Linked — NON APPLICABLE

**Recherche effectuée** : Aucune colonne `cours_de_route_id` trouvée dans `public.sorties_produit`.

**État** : Les sorties ne sont **pas liées** aux cours de route (contrairement aux réceptions).

**✅ Conclusion** : Aucune contrainte CDR à appliquer pour les sorties.

---

### 5.5 ❌ Immutabilité UPDATE/DELETE — PARTIELLEMENT APPLIQUÉE

**État actuel** :
- ✅ UPDATE partiellement bloqué : `sortie_before_upd_trg()` bloque UPDATE si non-admin et `statut <> 'brouillon'`
- ❌ DELETE non bloqué : Aucun trigger DELETE

**Recommandation DB-STRICT** : Bloquer **TOUS** les UPDATE et DELETE (même pour admin, sauf compensation via `stock_adjustments`).

**Recommandation** :
```sql
-- Blocage UPDATE absolu
CREATE OR REPLACE FUNCTION prevent_sortie_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être modifiées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN NEW;
END;
$$;

-- Blocage DELETE absolu
CREATE OR REPLACE FUNCTION prevent_sortie_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être supprimées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_sortie_update ON public.sorties_produit;
CREATE TRIGGER trg_prevent_sortie_update
BEFORE UPDATE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_update();

DROP TRIGGER IF EXISTS trg_prevent_sortie_delete ON public.sorties_produit;
CREATE TRIGGER trg_prevent_sortie_delete
BEFORE DELETE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_delete();
```

---

## 6. Recommandations Finales — Patches SQL Minimaux (Idempotents)

### 6.1 Patch 1 : Vérification Stock Suffisant (BEFORE INSERT)

**Objectif** : Rejeter INSERT si stock insuffisant.

**Approche** : Créer un trigger BEFORE INSERT qui vérifie le stock **avant** insertion.

```sql
-- Fonction de vérification stock suffisant
CREATE OR REPLACE FUNCTION sorties_check_stock_sufficient()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_citerne public.citernes%ROWTYPE;
  v_stock_jour public.stocks_journaliers%ROWTYPE;
  v_date_jour date;
  v_proprietaire text;
  v_volume_ambiant double precision;
  v_volume_15c double precision;
BEGIN
  -- Normalisation
  v_date_jour := COALESCE(NEW.date_sortie::date, CURRENT_DATE);
  v_proprietaire := UPPER(COALESCE(TRIM(NEW.proprietaire_type), 'MONALUXE'));
  
  v_volume_ambiant := COALESCE(
    NEW.volume_ambiant,
    CASE 
      WHEN NEW.index_avant IS NOT NULL AND NEW.index_apres IS NOT NULL 
      THEN NEW.index_apres - NEW.index_avant 
      ELSE 0 
    END
  );
  v_volume_15c := COALESCE(NEW.volume_corrige_15c, v_volume_ambiant);
  
  -- Charger citerne
  SELECT * INTO v_citerne
  FROM public.citernes
  WHERE id = NEW.citerne_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Citerne introuvable pour sortie';
  END IF;
  
  -- Vérifier citerne active
  IF v_citerne.statut <> 'active' THEN
    RAISE EXCEPTION 'SORTIE_CITERNE_INACTIVE: Citerne % inactive ou en maintenance', v_citerne.id;
  END IF;
  
  -- Vérifier produit/citerne
  IF v_citerne.produit_id <> NEW.produit_id THEN
    RAISE EXCEPTION 'PRODUIT_CITERNE_MISMATCH: citerne % ne porte pas le produit %', NEW.citerne_id, NEW.produit_id;
  END IF;
  
  -- Récupérer dernier stock
  SELECT * INTO v_stock_jour
  FROM public.stocks_journaliers
  WHERE citerne_id = NEW.citerne_id
    AND produit_id = NEW.produit_id
    AND proprietaire_type = v_proprietaire
    AND date_jour <= v_date_jour
  ORDER BY date_jour DESC
  LIMIT 1;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SORTIE_STOCK_INSUFFISANT: Aucun stock journalier trouvé pour cette citerne/produit/propriétaire';
  END IF;
  
  -- Vérifier stock suffisant (DB-STRICT)
  IF v_stock_jour.stock_ambiant < v_volume_ambiant THEN
    RAISE EXCEPTION 'SORTIE_STOCK_INSUFFISANT: stock_disponible=% volume_demande=%',
      v_stock_jour.stock_ambiant, v_volume_ambiant;
  END IF;
  
  IF v_stock_jour.stock_15c < v_volume_15c THEN
    RAISE EXCEPTION 'SORTIE_STOCK_INSUFFISANT_15C: stock_15c_disponible=% volume_15c_demande=%',
      v_stock_jour.stock_15c, v_volume_15c;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger BEFORE INSERT
DROP TRIGGER IF EXISTS trg_sorties_check_stock_sufficient ON public.sorties_produit;
CREATE TRIGGER trg_sorties_check_stock_sufficient
BEFORE INSERT ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION sorties_check_stock_sufficient();
```

**Note** : Cette fonction duplique certaines validations de `fn_sorties_after_insert()`, mais c'est intentionnel pour garantir l'ordre BEFORE INSERT.

---

### 6.2 Patch 2 : Contrainte CHECK client_id XOR partenaire_id

**Objectif** : Garantir exclusivité stricte au niveau DB.

```sql
-- Supprimer ancienne contrainte (si nécessaire, garder aussi)
-- ALTER TABLE public.sorties_produit DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_check;

-- Ajouter contrainte XOR stricte
ALTER TABLE public.sorties_produit 
DROP CONSTRAINT IF EXISTS sorties_produit_beneficiaire_xor;
ALTER TABLE public.sorties_produit 
ADD CONSTRAINT sorties_produit_beneficiaire_xor
CHECK (
  (client_id IS NOT NULL AND partenaire_id IS NULL) OR
  (client_id IS NULL AND partenaire_id IS NOT NULL)
);
```

---

### 6.3 Patch 3 : Immutabilité UPDATE/DELETE Absolue

**Objectif** : Bloquer tous UPDATE et DELETE (DB-STRICT).

```sql
-- Fonction blocage UPDATE
CREATE OR REPLACE FUNCTION prevent_sortie_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être modifiées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN NEW;
END;
$$;

-- Fonction blocage DELETE
CREATE OR REPLACE FUNCTION prevent_sortie_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les sorties ne peuvent pas être supprimées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN OLD;
END;
$$;

-- Trigger UPDATE
DROP TRIGGER IF EXISTS trg_prevent_sortie_update ON public.sorties_produit;
DROP TRIGGER IF EXISTS trg_sortie_before_upd_trg ON public.sorties_produit;  -- Remplacer ancien
CREATE TRIGGER trg_prevent_sortie_update
BEFORE UPDATE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_update();

-- Trigger DELETE
DROP TRIGGER IF EXISTS trg_prevent_sortie_delete ON public.sorties_produit;
CREATE TRIGGER trg_prevent_sortie_delete
BEFORE DELETE ON public.sorties_produit
FOR EACH ROW
EXECUTE FUNCTION prevent_sortie_delete();
```

---

### 6.4 Patch 4 : Nettoyage Fonctions Obsolètes (Optionnel)

**Objectif** : Supprimer les fonctions non utilisées.

```sql
-- Supprimer fonctions obsolètes (après validation que fn_sorties_after_insert fonctionne)
DROP FUNCTION IF EXISTS public.sorties_check_produit_citerne();
DROP FUNCTION IF EXISTS public.sorties_apply_effects();
DROP FUNCTION IF EXISTS public.sorties_log_created();
DROP FUNCTION IF EXISTS public.sortie_before_upd_trg();
```

---

## 7. Résumé des Problèmes Identifiés

| Problème | Priorité | État Actuel | Action Requise |
|----------|----------|-------------|----------------|
| Stock insuffisant non vérifié | 🔴 CRITIQUE | Partiellement vérifié (capacité sécurité seulement) | Ajouter vérification `stock >= volume` |
| Validations en AFTER INSERT | 🟡 MOYEN | Validations citerne/produit après insertion | Déplacer en BEFORE INSERT ou accepter rollback |
| UPDATE partiellement autorisé | 🟡 MOYEN | Bloqué pour non-admin, autorisé pour admin | Bloquer absolument (sauf compensation) |
| DELETE non bloqué | 🔴 CRITIQUE | Aucun trigger DELETE | Ajouter trigger DELETE |
| Contrainte XOR non stricte | 🟢 FAIBLE | CHECK + trigger, mais CHECK non strict | Renforcer contrainte CHECK |

---

## 8. Checklist d'Implémentation

- [ ] **Patch 1** : Implémenter vérification stock suffisant (BEFORE INSERT)
- [ ] **Patch 2** : Ajouter contrainte CHECK XOR stricte
- [ ] **Patch 3** : Implémenter immutabilité UPDATE/DELETE absolue
- [ ] **Patch 4** : Nettoyer fonctions obsolètes (après validation)
- [ ] **Tests** : Valider que toutes les insertions invalides sont rejetées
- [ ] **Tests** : Valider que tous les UPDATE/DELETE sont bloqués
- [ ] **Documentation** : Mettre à jour `docs/db/sorties_mvp.md` avec nouvelles contraintes

---

---

## 8. DB-STRICT Split of Responsibilities

**Date refactoring** : 2025-12-19  
**Migration** : `2025-12-19_sorties_after_insert_refactor.sql`

### 8.1 Principe de Séparation

Dans l'architecture DB-STRICT, les responsabilités sont clairement séparées entre les triggers BEFORE et AFTER :

- **BEFORE INSERT** : Toutes les **validations et rejections** (empêcher l'insertion de données invalides)
- **AFTER INSERT** : Uniquement les **effets irréversibles** (débit stock, logs)

### 8.2 Responsabilités BEFORE INSERT

**Fonction** : `sorties_check_before_insert()`  
**Trigger** : `trg_sorties_check_before_insert`

**Rôle** : Valider et **rejeter** toute insertion invalide avant écriture dans la table.

**Validations effectuées** :
1. ✅ Existence citerne
2. ✅ Citerne active
3. ✅ Cohérence produit/citerne
4. ✅ XOR bénéficiaire (client_id XOR partenaire_id)
5. ✅ Stock suffisant (ambiant et 15°C)
6. ✅ Capacité sécurité

**Calculs effectués** :
- Calcul `v_volume_ambiant` depuis indexes si `NEW.volume_ambiant` est NULL
- Calcul `v_volume_15c` depuis `volume_corrige_15c` ou fallback `v_volume_ambiant`
- Normalisation `proprietaire_type`

**Important** : Si une validation échoue, `RAISE EXCEPTION` → rollback automatique, aucune ligne insérée.

---

### 8.3 Responsabilités AFTER INSERT

**Fonction** : `fn_sorties_after_insert()`  
**Trigger** : `trg_sorties_after_insert`

**Rôle** : Appliquer les **effets irréversibles** une fois la ligne insérée avec succès.

**Actions effectuées** :
1. ✅ Calcul `v_date_jour` (avec fallback sur `created_at` si `date_sortie` null)
2. ✅ Normalisation `proprietaire_type` (répétée pour cohérence)
3. ✅ Chargement `depot_id` depuis citerne (lecture seule, pas de validation)
4. ✅ Calcul volumes depuis `NEW` (utilise `NEW.volume_ambiant` déjà calculé en BEFORE, pas de recalcul depuis indexes)
5. ✅ Débit stock via `stock_upsert_journalier()`
6. ✅ Log action dans `log_actions`

**Important** :
- **Aucune validation** (déjà faites en BEFORE)
- **Aucun recalcul** depuis indexes (utilise valeurs déjà normalisées)
- **Utilise `NEW.created_by`** pour le log (pas `auth.uid()`)
- **Stocke valeurs calculées** dans le log (`v_volume_ambiant`, `v_volume_15c`, `v_date_jour`)

---

### 8.4 Code Supprimé du AFTER INSERT (refactoring)

Les blocs suivants ont été **retirés** de `fn_sorties_after_insert()` car dupliqués et non nécessaires :

1. ❌ **Validation citerne active** (lignes 214-216)
   - Raison : Déjà validée en BEFORE INSERT
   - Impact : Aucun (validation redondante supprimée)

2. ❌ **Validation produit/citerne** (lignes 218-220)
   - Raison : Déjà validée en BEFORE INSERT
   - Impact : Aucun (validation redondante supprimée)

3. ❌ **Validation XOR bénéficiaire** (lignes 238-253)
   - Raison : Déjà validée en BEFORE INSERT (CHECK constraint + trigger)
   - Impact : Aucun (validation redondante supprimée)

4. ❌ **Récupération et vérification stock suffisant** (lignes 255-275)
   - Raison : Déjà validé en BEFORE INSERT
   - Impact : Aucun (validation redondante supprimée, débit stock reste identique)

5. ❌ **Recalcul volumes depuis indexes** (lignes 225-232)
   - Raison : Les volumes sont déjà calculés/normalisés en BEFORE INSERT
   - Impact : Utilise directement `NEW.volume_ambiant` (cohérent avec BEFORE)

---

### 8.5 Avantages de la Séparation

1. **Clarté** : Responsabilités distinctes et documentées
2. **Maintenabilité** : Pas de duplication de logique
3. **Performance** : Validations en BEFORE évitent écriture inutile si invalide
4. **Robustesse** : Une seule source de vérité pour chaque validation
5. **Traçabilité** : Log contient valeurs calculées/normalisées utilisées

---

### 8.6 Flow d'Exécution Complet

```
1. INSERT INTO sorties_produit (...)

2. BEFORE INSERT: trg_sorties_check_before_insert()
   ├─ Validation citerne active
   ├─ Validation produit/citerne
   ├─ Validation XOR bénéficiaire
   ├─ Calcul volumes depuis indexes si nécessaire
   ├─ Validation stock suffisant
   └─ Validation capacité sécurité
   ✅ Si OK → continue
   ❌ Si KO → RAISE EXCEPTION (rollback, pas d'INSERT)

3. INSERT dans sorties_produit (commit si pas d'erreur)

4. AFTER INSERT: trg_sorties_after_insert() → fn_sorties_after_insert()
   ├─ Calcul date_jour (fallback created_at)
   ├─ Normalisation proprietaire
   ├─ Chargement depot_id
   ├─ Utilisation volumes depuis NEW (déjà calculés)
   ├─ Débit stock (irréversible)
   └─ Log action (irréversible)
   ✅ Toujours exécuté si INSERT réussi (pas de validation)
```

---

**Dernière mise à jour** : 2025-12-19 (refactoring)


# Guide Migration SQL — DB-STRICT

**Phase** : Phase 1  
**Statut** : 🟡 En cours  
**Objectif** : Rendre la DB impossible à contourner

---

## Vue d'ensemble

Cette migration implémente :
1. **Immutabilité absolue** : triggers bloquant UPDATE/DELETE sur `receptions` et `sorties_produit`
2. **Table `stock_adjustments`** : pour les compensations administratives
3. **Fonctions admin** : `admin_compensate_reception()` et `admin_compensate_sortie()`
4. **RLS sécurisée** : protection des données sensibles
5. **Robustesse** : utilisation de `current_setting('request.jwt.claim.sub')` au lieu de `auth.uid()`

---

## Fichier de migration

**Fichier** : `supabase/migrations/2025-12-21_db_strict_lock.sql`

**Important** : Exécuter d'abord sur **staging**, puis valider avant production.

---

## 1. Triggers d'immutabilité

### Réceptions

```sql
-- Protection UPDATE sur réceptions (TOUT bloquer)
CREATE OR REPLACE FUNCTION prevent_reception_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les réceptions ne peuvent pas être modifiées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN NEW;
END;
$$;

-- Protection DELETE sur réceptions
CREATE OR REPLACE FUNCTION prevent_reception_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSACTION: Les réceptions ne peuvent pas être supprimées. Utilisez un mouvement compensatoire (stock_adjustments).';
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_reception_update ON public.receptions;
CREATE TRIGGER trg_prevent_reception_update
BEFORE UPDATE ON public.receptions
FOR EACH ROW
EXECUTE FUNCTION prevent_reception_update();

DROP TRIGGER IF EXISTS trg_prevent_reception_delete ON public.receptions;
CREATE TRIGGER trg_prevent_reception_delete
BEFORE DELETE ON public.receptions
FOR EACH ROW
EXECUTE FUNCTION prevent_reception_delete();
```

### Sorties

```sql
-- Protection UPDATE/DELETE sur sorties (identique)
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

## 2. Table `stock_adjustments`

```sql
CREATE TABLE IF NOT EXISTS public.stock_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Référence à la transaction source
  source_type text CHECK (source_type IN ('reception', 'sortie', 'correction_manuelle')),
  source_id uuid,
  
  -- Mouvement
  citerne_id uuid NOT NULL REFERENCES public.citernes(id),
  produit_id uuid NOT NULL REFERENCES public.produits(id),
  date_adjustment date NOT NULL DEFAULT CURRENT_DATE,
  
  -- Propriétaire (OBLIGATOIRE pour séparation Monaluxe/Partenaire)
  proprietaire_type text NOT NULL CHECK (proprietaire_type IN ('MONALUXE', 'PARTENAIRE')),
  
  -- Dépôt (si architecture multi-dépôt)
  depot_id uuid REFERENCES public.depots(id),
  
  -- Volumes (positifs = ajout stock, négatifs = retrait stock)
  volume_ambiant_delta double precision NOT NULL,
  volume_15c_delta double precision NOT NULL,
  
  -- Justification (OBLIGATOIRE)
  reason text NOT NULL CHECK (char_length(reason) >= 10),
  adjustment_type text NOT NULL CHECK (adjustment_type IN ('COMPENSATION', 'CORRECTION_INVENTAIRE', 'ERREUR_SAISIE')),
  
  -- Audit
  created_by uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  validated_by uuid,
  validated_at timestamptz,
  
  -- Contraintes
  CONSTRAINT stock_adjustments_delta_not_zero CHECK (volume_ambiant_delta <> 0 OR volume_15c_delta <> 0)
);

-- Index
CREATE INDEX idx_stock_adjustments_citerne ON public.stock_adjustments(citerne_id);
CREATE INDEX idx_stock_adjustments_produit ON public.stock_adjustments(produit_id);
CREATE INDEX idx_stock_adjustments_date ON public.stock_adjustments(date_adjustment);
CREATE INDEX idx_stock_adjustments_source ON public.stock_adjustments(source_type, source_id);
CREATE INDEX idx_stock_adjustments_owner ON public.stock_adjustments(proprietaire_type);
```

---

## 3. Trigger `set_created_by` (robuste)

```sql
CREATE OR REPLACE FUNCTION set_created_by()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  IF NEW.created_by IS NOT NULL THEN
    RETURN NEW;
  END IF;
  
  -- Utiliser current_setting au lieu de auth.uid() (plus robuste)
  BEGIN
    v_user_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
  EXCEPTION
    WHEN OTHERS THEN
      v_user_id := NULL;
  END;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED: created_by must be set or user must be authenticated (no JWT context found)';
  END IF;
  
  NEW.created_by := v_user_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_adjustments_set_created_by ON public.stock_adjustments;
CREATE TRIGGER trg_stock_adjustments_set_created_by
BEFORE INSERT ON public.stock_adjustments
FOR EACH ROW
EXECUTE FUNCTION set_created_by();
```

---

## 4. Fonction `assert_is_admin` (triple vérification)

```sql
CREATE OR REPLACE FUNCTION assert_is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
  v_role text;
  v_auth_role text;
BEGIN
  -- 1) Récupérer user_id depuis JWT
  BEGIN
    v_user_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
  EXCEPTION
    WHEN OTHERS THEN
      v_user_id := NULL;
  END;
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Aucun utilisateur authentifié (JWT manquant).';
  END IF;
  
  -- 2) Vérifier auth.role() = 'authenticated'
  BEGIN
    v_auth_role := current_setting('request.jwt.claim.role', true);
  EXCEPTION
    WHEN OTHERS THEN
      v_auth_role := NULL;
  END;
  
  IF v_auth_role IS NULL OR v_auth_role <> 'authenticated' THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Rôle JWT invalide (doit être "authenticated").';
  END IF;
  
  -- 3) Lire le rôle depuis profils
  SELECT role INTO v_role
  FROM public.profils
  WHERE user_id = v_user_id;
  
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Aucun profil trouvé pour cet utilisateur.';
  END IF;
  
  IF v_role <> 'admin' THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Seuls les admins peuvent effectuer cette opération (rôle actuel: %).', v_role;
  END IF;
  
  RETURN true;
END;
$$;
```

---

## 5. Fonction `stock_apply_delta` (stable, sans fallback)

```sql
-- Wrapper stable pour appliquer les deltas de stock
-- IMPORTANT : Adapter selon votre signature réelle de stock_upsert_journalier

CREATE OR REPLACE FUNCTION stock_apply_delta(
  p_citerne_id uuid,
  p_produit_id uuid,
  p_date_jour date,
  p_volume_ambiant_delta double precision,
  p_volume_15c_delta double precision,
  p_proprietaire_type text,
  p_depot_id uuid,
  p_source text DEFAULT 'ADJUSTMENT'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Option A : Si stock_upsert_journalier a la signature étendue
  PERFORM stock_upsert_journalier(
    p_citerne_id,
    p_produit_id,
    p_date_jour,
    p_volume_ambiant_delta,
    p_volume_15c_delta,
    p_proprietaire_type,
    p_depot_id,
    p_source
  );
  
  -- Option B : Si stock_upsert_journalier a seulement 5 params, implémenter directement :
  -- INSERT INTO public.stocks_journaliers (...)
  -- ON CONFLICT (...) DO UPDATE SET ...
END;
$$;
```

**Note** : Vérifier la signature réelle de `stock_upsert_journalier` dans vos migrations et adapter.

---

## 6. Trigger `apply_stock_adjustment`

```sql
CREATE OR REPLACE FUNCTION apply_stock_adjustment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  -- Appliquer le delta au stock
  PERFORM stock_apply_delta(
    NEW.citerne_id,
    NEW.produit_id,
    NEW.date_adjustment,
    NEW.volume_ambiant_delta,
    NEW.volume_15c_delta,
    NEW.proprietaire_type,
    NEW.depot_id,
    'ADJUSTMENT'
  );
  
  -- Récupérer user_id pour le log
  BEGIN
    v_user_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
  EXCEPTION
    WHEN OTHERS THEN
      v_user_id := NEW.created_by;
  END;
  
  -- Logger en CRITICAL
  INSERT INTO public.log_actions (
    user_id,
    action,
    module,
    niveau,
    details,
    cible_id
  ) VALUES (
    COALESCE(v_user_id, NEW.created_by),
    'STOCK_ADJUSTMENT',
    'stock_adjustments',
    'CRITICAL',
    jsonb_build_object(
      'adjustment_id', NEW.id,
      'source_type', NEW.source_type,
      'source_id', NEW.source_id,
      'citerne_id', NEW.citerne_id,
      'produit_id', NEW.produit_id,
      'proprietaire_type', NEW.proprietaire_type,
      'depot_id', NEW.depot_id,
      'volume_ambiant_delta', NEW.volume_ambiant_delta,
      'volume_15c_delta', NEW.volume_15c_delta,
      'reason', NEW.reason,
      'adjustment_type', NEW.adjustment_type,
      'timestamp', now()
    ),
    NEW.id
  );
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_stock_adjustment ON public.stock_adjustments;
CREATE TRIGGER trg_apply_stock_adjustment
AFTER INSERT ON public.stock_adjustments
FOR EACH ROW
EXECUTE FUNCTION apply_stock_adjustment();
```

---

## 7. RLS sur `stock_adjustments`

```sql
ALTER TABLE public.stock_adjustments ENABLE ROW LEVEL SECURITY;

-- SELECT : restreindre aux rôles sensibles (admin, directeur, pca)
CREATE POLICY read_stock_adjustments_sensitive
ON public.stock_adjustments
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profils
    WHERE user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
    AND role IN ('admin', 'directeur', 'pca')
  )
);

-- INSERT : uniquement admin
CREATE POLICY insert_stock_adjustments_admin
ON public.stock_adjustments
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profils 
    WHERE user_id = NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
    AND role = 'admin'
  )
);
```

---

## 8. Fonctions admin de compensation

### `admin_compensate_reception`

```sql
CREATE OR REPLACE FUNCTION admin_compensate_reception(
  p_reception_id uuid,
  p_reason text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reception record;
  v_adjustment_id uuid;
  v_depot_id uuid;
  v_volume_15c double precision;
  v_user_id uuid;
BEGIN
  PERFORM assert_is_admin();
  
  IF p_reason IS NULL OR char_length(p_reason) < 10 THEN
    RAISE EXCEPTION 'INVALID_REASON: La raison doit contenir au moins 10 caractères.';
  END IF;
  
  SELECT * INTO v_reception
  FROM public.receptions
  WHERE id = p_reception_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'RECEPTION_NOT_FOUND: Réception introuvable (id=%)', p_reception_id;
  END IF;
  
  IF v_reception.statut <> 'validee' THEN
    RAISE EXCEPTION 'INVALID_STATUS: Seules les réceptions validées peuvent être compensées (statut=%)', v_reception.statut;
  END IF;
  
  IF v_reception.volume_ambiant IS NULL OR v_reception.volume_ambiant = 0 THEN
    RAISE EXCEPTION 'INVALID_VOLUME: La réception ne contient pas de volume ambiant valide.';
  END IF;
  
  -- Volume 15°C canonique : volume_15c → volume_corrige_15c → volume_ambiant
  v_volume_15c := COALESCE(
    v_reception.volume_15c,
    v_reception.volume_corrige_15c,
    v_reception.volume_ambiant
  );
  
  IF v_volume_15c IS NULL OR v_volume_15c = 0 THEN
    RAISE EXCEPTION 'INVALID_VOLUME_15C: Le volume à 15°C est invalide.';
  END IF;
  
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = v_reception.citerne_id;
  
  -- Récupérer user_id depuis JWT
  BEGIN
    v_user_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'AUTH_REQUIRED: JWT context required';
  END;
  
  INSERT INTO public.stock_adjustments (
    source_type,
    source_id,
    citerne_id,
    produit_id,
    date_adjustment,
    proprietaire_type,
    depot_id,
    volume_ambiant_delta,
    volume_15c_delta,
    reason,
    adjustment_type,
    created_by
  ) VALUES (
    'reception',
    p_reception_id,
    v_reception.citerne_id,
    v_reception.produit_id,
    CURRENT_DATE,
    v_reception.proprietaire_type,
    v_depot_id,
    -1 * v_reception.volume_ambiant,
    -1 * v_volume_15c,
    p_reason,
    'COMPENSATION',
    v_user_id
  ) RETURNING id INTO v_adjustment_id;
  
  RETURN v_adjustment_id;
END;
$$;
```

### `admin_compensate_sortie`

```sql
CREATE OR REPLACE FUNCTION admin_compensate_sortie(
  p_sortie_id uuid,
  p_reason text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_sortie record;
  v_adjustment_id uuid;
  v_depot_id uuid;
  v_volume_15c double precision;
  v_user_id uuid;
BEGIN
  PERFORM assert_is_admin();
  
  IF p_reason IS NULL OR char_length(p_reason) < 10 THEN
    RAISE EXCEPTION 'INVALID_REASON: La raison doit contenir au moins 10 caractères.';
  END IF;
  
  SELECT * INTO v_sortie
  FROM public.sorties_produit
  WHERE id = p_sortie_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'SORTIE_NOT_FOUND: Sortie introuvable (id=%)', p_sortie_id;
  END IF;
  
  IF v_sortie.statut <> 'validee' THEN
    RAISE EXCEPTION 'INVALID_STATUS: Seules les sorties validées peuvent être compensées (statut=%)', v_sortie.statut;
  END IF;
  
  IF v_sortie.volume_ambiant IS NULL OR v_sortie.volume_ambiant = 0 THEN
    RAISE EXCEPTION 'INVALID_VOLUME: La sortie ne contient pas de volume ambiant valide.';
  END IF;
  
  -- Volume 15°C : volume_corrige_15c → volume_ambiant
  v_volume_15c := COALESCE(
    v_sortie.volume_corrige_15c,
    v_sortie.volume_ambiant
  );
  
  IF v_volume_15c IS NULL OR v_volume_15c = 0 THEN
    RAISE EXCEPTION 'INVALID_VOLUME_15C: Le volume à 15°C est invalide.';
  END IF;
  
  SELECT depot_id INTO v_depot_id
  FROM public.citernes
  WHERE id = v_sortie.citerne_id;
  
  BEGIN
    v_user_id := NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'AUTH_REQUIRED: JWT context required';
  END;
  
  INSERT INTO public.stock_adjustments (
    source_type,
    source_id,
    citerne_id,
    produit_id,
    date_adjustment,
    proprietaire_type,
    depot_id,
    volume_ambiant_delta,
    volume_15c_delta,
    reason,
    adjustment_type,
    created_by
  ) VALUES (
    'sortie',
    p_sortie_id,
    v_sortie.citerne_id,
    v_sortie.produit_id,
    CURRENT_DATE,
    v_sortie.proprietaire_type,
    v_depot_id,
    v_sortie.volume_ambiant,
    v_volume_15c,
    p_reason,
    'COMPENSATION',
    v_user_id
  ) RETURNING id INTO v_adjustment_id;
  
  RETURN v_adjustment_id;
END;
$$;
```

---

## 9. GRANT

```sql
GRANT EXECUTE ON FUNCTION assert_is_admin TO authenticated;
GRANT EXECUTE ON FUNCTION admin_compensate_reception TO authenticated;
GRANT EXECUTE ON FUNCTION admin_compensate_sortie TO authenticated;
GRANT EXECUTE ON FUNCTION stock_apply_delta TO authenticated;
```

---

## Tests manuels SQL

### Test 1 : UPDATE réception → rejet

```sql
-- Doit échouer
UPDATE public.receptions 
SET note = 'test' 
WHERE id = 'un-uuid-existant';
-- Attendu : ERROR: IMMUTABLE_TRANSACTION
```

### Test 2 : DELETE sortie → rejet

```sql
-- Doit échouer
DELETE FROM public.sorties_produit 
WHERE id = 'un-uuid-existant';
-- Attendu : ERROR: IMMUTABLE_TRANSACTION
```

### Test 3 : INSERT adjustment admin → stock modifié + log CRITICAL

```sql
-- En tant qu'admin
SELECT admin_compensate_reception(
  'uuid-reception-validee',
  'Test de compensation - réception en double'
);

-- Vérifier que le stock a été modifié
SELECT * FROM public.stocks_journaliers 
WHERE citerne_id = 'citerne-de-la-reception';

-- Vérifier le log CRITICAL
SELECT * FROM public.log_actions 
WHERE action = 'STOCK_ADJUSTMENT' 
ORDER BY created_at DESC 
LIMIT 1;
```

### Test 4 : Non-admin insert adjustment → rejet

```sql
-- En tant que non-admin (opérateur, gérant, etc.)
-- Doit échouer
INSERT INTO public.stock_adjustments (
  citerne_id, produit_id, proprietaire_type,
  volume_ambiant_delta, volume_15c_delta,
  reason, adjustment_type
) VALUES (
  'uuid-citerne', 'uuid-produit', 'MONALUXE',
  -100, -100,
  'Test non-admin', 'COMPENSATION'
);
-- Attendu : ERROR: new row violates row-level security policy
```

---

## Checklist de validation

- [ ] Migration SQL appliquée sur staging
- [ ] Test 1 : UPDATE réception → rejet ✅
- [ ] Test 2 : DELETE sortie → rejet ✅
- [ ] Test 3 : INSERT adjustment admin → stock modifié + log CRITICAL ✅
- [ ] Test 4 : Non-admin insert adjustment → rejet ✅
- [ ] Vérifier que `stock_apply_delta` utilise la bonne signature
- [ ] Vérifier que RLS sur `profils` est durcie (pas modifiable par utilisateur)

---

**Dernière mise à jour** : 2025-12-21


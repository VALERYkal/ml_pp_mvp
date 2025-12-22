# Tests manuels – Trigger Sorties → Stocks journaliers (SEL-1 à SEL-6)

## 1. Contexte & objectif

Ces tests valident le pipeline complet :

`sorties_produit` (INSERT)  
→ trigger `fn_sorties_after_insert()`  
→ appel `stock_upsert_journalier(...)`  
→ mise à jour de `stocks_journaliers` avec séparation par propriétaire  
(MONALUXE / PARTENAIRE) et par citerne.

Objectifs :

- vérifier que chaque sortie produit débite correctement `stocks_journaliers`  
- valider les cas mono-propriétaire et multi-propriétaires (citerne mixte)  
- valider le comportement multi-citernes sur une même journée  
- garantir l’absence d’erreurs de contrainte UNIQUE et d’écritures incohérentes.

## 2. Prérequis globaux
(… contenu complet déjà généré précédemment …)

---

## 3. Tests DB-STRICT Hardening (2025-12-19)

Ces tests valident les nouveaux verrous DB-STRICT implémentés dans la migration `2025-12-19_sorties_db_strict_hardening.sql`.

### Prérequis pour les tests DB-STRICT

```sql
-- Variables de test (à adapter selon votre environnement)
\set citerne_id_active 'uuid-de-citerne-active'
\set citerne_id_inactive 'uuid-de-citerne-inactive'
\set produit_id_valid 'uuid-de-produit-valide'
\set produit_id_invalid 'uuid-de-produit-invalide'
\set client_id_valid 'uuid-de-client-valide'
\set partenaire_id_valid 'uuid-de-partenaire-valide'

-- Préparer un stock journalier existant pour la citerne active
INSERT INTO public.stocks_journaliers (
  citerne_id, produit_id, date_jour, stock_ambiant, stock_15c, proprietaire_type
) VALUES (
  :'citerne_id_active', :'produit_id_valid', CURRENT_DATE, 1000.0, 950.0, 'MONALUXE'
) ON CONFLICT DO NOTHING;
```

### Test 1 : Stock suffisant → INSERT OK

**Objectif** : Valider qu'une sortie avec stock suffisant est acceptée.

```sql
-- Préparer sortie valide
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  index_avant, index_apres, volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_valid', :'client_id_valid', NULL,
  100.0, 150.0, 50.0, 47.5,
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ✅ Pas d'erreur
-- ✅ Ligne insérée dans sorties_produit
-- ✅ Stock journalier débité (stock_ambiant - 50.0)
-- ✅ Log action créé (SORTIE_CREEE)
```

### Test 2 : Stock insuffisant → INSERT BLOQUÉ

**Objectif** : Valider que le trigger BEFORE INSERT bloque une sortie avec stock insuffisant.

```sql
-- Tentative sortie avec volume > stock disponible
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_valid', :'client_id_valid', NULL,
  1500.0, 1425.0,  -- > stock disponible (1000.0)
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur attendue: STOCK_INSUFFISANT
-- ❌ Aucune ligne insérée dans sorties_produit
-- ❌ Stock journalier non modifié
-- ❌ Aucun log action créé
```

### Test 3 : Citerne inactive → INSERT BLOQUÉ

**Objectif** : Valider que le trigger BEFORE INSERT bloque une sortie sur citerne inactive.

```sql
-- Tentative sortie sur citerne inactive
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_inactive', :'produit_id_valid', :'client_id_valid', NULL,
  50.0, 47.5,
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur attendue: CITERNE_INACTIVE
-- ❌ Aucune ligne insérée
-- ❌ Stock non modifié
-- ❌ Aucun log créé
```

### Test 4 : Produit incompatible → INSERT BLOQUÉ

**Objectif** : Valider que le trigger BEFORE INSERT bloque une sortie avec produit incompatible.

```sql
-- Tentative sortie avec produit différent de celui de la citerne
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_invalid', :'client_id_valid', NULL,
  50.0, 47.5,
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur attendue: PRODUIT_INCOMPATIBLE
-- ❌ Aucune ligne insérée
```

### Test 5 : XOR bénéficiaire → INSERT BLOQUÉ (client_id + partenaire_id)

**Objectif** : Valider que la contrainte CHECK XOR bloque les deux IDs présents.

```sql
-- Tentative sortie avec client_id ET partenaire_id
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_valid', :'client_id_valid', :'partenaire_id_valid',
  50.0, 47.5,
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur CHECK constraint: sorties_produit_beneficiaire_xor
-- ❌ Aucune ligne insérée
```

### Test 6 : XOR bénéficiaire → INSERT BLOQUÉ (aucun ID)

**Objectif** : Valider que la contrainte CHECK XOR bloque l'absence des deux IDs.

```sql
-- Tentative sortie sans client_id ni partenaire_id
INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_valid', NULL, NULL,
  50.0, 47.5,
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur CHECK constraint: sorties_produit_beneficiaire_xor
-- ❌ Aucune ligne insérée
```

### Test 7 : UPDATE → BLOQUÉ

**Objectif** : Valider que le trigger BEFORE UPDATE bloque toutes les modifications.

```sql
-- Récupérer une sortie existante
SELECT id INTO sortie_test_id FROM public.sorties_produit LIMIT 1;

-- Tentative modification
UPDATE public.sorties_produit
SET volume_ambiant = 100.0
WHERE id = sortie_test_id;

-- Vérifications
-- ❌ Erreur attendue: IMMUTABLE_TRANSACTION
-- ❌ Aucune modification effectuée
```

### Test 8 : DELETE → BLOQUÉ

**Objectif** : Valider que le trigger BEFORE DELETE bloque toutes les suppressions.

```sql
-- Récupérer une sortie existante
SELECT id INTO sortie_test_id FROM public.sorties_produit LIMIT 1;

-- Tentative suppression
DELETE FROM public.sorties_produit
WHERE id = sortie_test_id;

-- Vérifications
-- ❌ Erreur attendue: IMMUTABLE_TRANSACTION
-- ❌ Aucune suppression effectuée
```

### Test 9 : Capacité sécurité → INSERT BLOQUÉ

**Objectif** : Valider que le trigger bloque une sortie qui ferait descendre le stock sous la capacité de sécurité.

```sql
-- Préparer citerne avec capacité sécurité
-- (À adapter selon votre schéma, ex: capacite_securite = 200.0)

-- Stock actuel: 1000.0, capacité sécurité: 200.0
-- Tentative sortie de 850.0 → stock après = 150.0 < 200.0

INSERT INTO public.sorties_produit (
  citerne_id, produit_id, client_id, partenaire_id,
  volume_ambiant, volume_corrige_15c,
  proprietaire_type, date_sortie
) VALUES (
  :'citerne_id_active', :'produit_id_valid', :'client_id_valid', NULL,
  850.0, 807.5,  -- Fait descendre stock sous capacité sécurité
  'MONALUXE', CURRENT_DATE
);

-- Vérifications
-- ❌ Erreur attendue: CAPACITE_SECURITE
-- ❌ Aucune ligne insérée
```

---

## 4. Résumé des tests

| Test | Scénario | Résultat attendu |
|------|----------|------------------|
| 1 | Stock suffisant | ✅ INSERT OK + débit stock + log |
| 2 | Stock insuffisant | ❌ STOCK_INSUFFISANT, pas d'INSERT |
| 3 | Citerne inactive | ❌ CITERNE_INACTIVE, pas d'INSERT |
| 4 | Produit incompatible | ❌ PRODUIT_INCOMPATIBLE, pas d'INSERT |
| 5 | client_id + partenaire_id | ❌ CHECK constraint, pas d'INSERT |
| 6 | Aucun bénéficiaire | ❌ CHECK constraint, pas d'INSERT |
| 7 | UPDATE | ❌ IMMUTABLE_TRANSACTION, pas de modification |
| 8 | DELETE | ❌ IMMUTABLE_TRANSACTION, pas de suppression |
| 9 | Capacité sécurité | ❌ CAPACITE_SECURITE, pas d'INSERT |

---

**Dernière mise à jour** : 2025-12-19

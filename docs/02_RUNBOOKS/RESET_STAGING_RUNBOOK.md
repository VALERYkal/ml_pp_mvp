# Reset STAGING — Runbook

**Date de création** : 2026-01-27  
**Statut** : Actif  
**Version** : 1.0

---

## 1. Objectif

Ce runbook décrit la procédure de reset de l'environnement STAGING pour garantir un état propre, prod-like et aligné avec la production.

---

## 2. Pré-requis

### Variables d'environnement

- `env/.env.staging` doit exister (gitignored)
- Contient `STAGING_DB_URL` et `STAGING_PROJECT_REF`
- `ALLOW_STAGING_RESET=true` (obligatoire)
- `CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC` (double-confirm)

### Fichiers requis

- `staging/sql/000_prod_schema_public.safe.sql` (schéma PROD)
- `staging/sql/seed_empty.sql` (seed vide par défaut)
- `staging/sql/seed_staging_prod_like.sql` (seed prod-like, opt-in explicite)

---

## 3. Procédure de reset

### Reset complet (recommandé)

```bash
# Reset complet : drop public + import schéma + seed vide
ALLOW_STAGING_RESET=true \
CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
./scripts/reset_staging_full.sh
```

**Résultat** :
- Tables transactionnelles : 0 ligne
- Citernes : TANK1 → TANK6 uniquement (aligné PROD)
- Aucune donnée fake

### Reset avec seed prod-like (validation métier)

```bash
# Reset avec seed prod-like (tests métier / GO PROD)
CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
ALLOW_STAGING_RESET=true \
SEED_FILE=staging/sql/seed_staging_prod_like.sql \
./scripts/reset_staging.sh
```

**Résultat** :
- Dépôt : Dépôt Daipn (ID fixe)
- Produits : ESS (`640cf7ec-1616-4503-a484-0a61afb20005`) + G.O (`22222222-2222-2222-2222-222222222222`)
- Citernes : TANK1 → TANK6 (aligné PROD)

---

## 4. Validation post-reset (OBLIGATOIRE)

### Vérifications obligatoires

#### 1. Produits

```sql
-- Vérifier la présence des 2 produits attendus
SELECT id, nom, code FROM public.produits ORDER BY code;
```

**Attendu** :
- `640cf7ec-1616-4503-a484-0a61afb20005` → Essence (ESS)
- `22222222-2222-2222-2222-222222222222` → Gasoil/AGO (G.O)

#### 2. Citernes

```sql
-- Vérifier les 6 citernes attendues (TANK1 → TANK6)
SELECT id, nom, produit_id FROM public.citernes ORDER BY nom;
```

**Attendu** :
- 6 citernes : TANK1, TANK2, TANK3, TANK4, TANK5, TANK6
- Toutes associées au produit G.O (`22222222-2222-2222-2222-222222222222`)

#### 3. Absence de citernes fantômes

```sql
-- Vérifier l'absence de citernes fantômes
SELECT COUNT(*) FROM public.citernes
WHERE nom IN ('TANK STAGING 1', 'TANK TEST')
   OR id IN (
     '33333333-3333-3333-3333-333333333333',
     '44444444-4444-4444-4444-444444444444'
   );
```

**Attendu** : `0` (aucune citerne fantôme)

#### 4. Création CDR

**Action** : Créer un CDR via l'application (rôle Admin)

**Vérification** :
- CDR créé avec succès
- Produit sélectionnable (ESS ou G.O)
- Statut initial : `CHARGEMENT`

#### 5. Réception → Stock

**Action** : Valider une réception liée au CDR

**Vérification** :
- Réception validée avec succès
- Stock incrémenté dans `stocks_snapshot`
- Stock visible dans `v_stock_actuel`
- Stock affiché correctement dans l'UI (Citernes)

#### 6. Sortie → Décrément

**Action** : Valider une sortie produit

**Vérification** :
- Sortie validée avec succès
- Stock décrémenté dans `stocks_snapshot`
- Stock visible dans `v_stock_actuel`
- Stock affiché correctement dans l'UI (Citernes)

---

## 5. Garde-fous anti-pollution

### Seeds interdits

Le script `reset_staging.sh` refuse automatiquement :
- Tout seed contenant `"minimal"` dans le nom
- Tout seed contenant `"DISABLED"` dans le nom

**Message d'erreur** :
```
❌ Refusing SEED_FILE='...' (would pollute STAGING).
   Use default (seed_empty.sql) ou explicitly run DB-tests workflow if needed.
```

### Seed par défaut

- **Par défaut** : `staging/sql/seed_empty.sql` (aucune INSERT)
- **Opt-in explicite** : `SEED_FILE=staging/sql/seed_staging_prod_like.sql` requis

---

## 6. Pré-requis GO PROD

Ce runbook est un **pré-requis obligatoire** avant toute décision GO PROD :

1. ✅ Reset STAGING exécuté avec succès
2. ✅ Validation post-reset complète (6 vérifications)
3. ✅ Aucune citerne fantôme détectée
4. ✅ Flux métier validé (CDR → Réception → Sortie)
5. ✅ Stock cohérent (DB ↔ UI)

---

## 7. Références

- `scripts/reset_staging_full.sh` : Reset complet (drop public + schéma + seed vide)
- `scripts/reset_staging.sh` : Reset avec seed personnalisé (opt-in)
- `staging/sql/seed_empty.sql` : Seed vide (par défaut)
- `staging/sql/seed_staging_prod_like.sql` : Seed prod-like (opt-in explicite)
- `docs/04_PLANS/SPRINT_PROD_READY_2026_01.md` : Journal de sprint (hardening STAGING)

---

**Document créé le** : 2026-01-27  
**Dernière mise à jour** : 2026-01-27  
**Version** : 1.0  
**Responsable** : DevOps / Release Manager

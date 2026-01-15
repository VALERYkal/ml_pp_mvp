# Rapport de Non-Bypass UI — ML_PP MVP

**Date de création :** 2026-01-14  
**Objectif :** Documenter que l'interface utilisateur (Flutter) ne peut pas contourner les politiques RLS de la base de données

## Principe Fondamental

**L'application Flutter est une couche d'orchestration et d'affichage uniquement.**  
Toutes les règles métier critiques et les contrôles de sécurité sont appliqués au niveau de la base de données (PostgreSQL/Supabase).

## Architecture de Sécurité

### Couche 1 : Base de Données (Source de Vérité)
- ✅ **RLS activé** sur toutes les tables critiques
- ✅ **Triggers** pour validation métier (ex: `apply_stock_adjustment`)
- ✅ **Fonctions SQL sécurisées** (`SECURITY DEFINER`) pour les opérations critiques
- ✅ **Contraintes CHECK** pour validation des données
- ✅ **Policies RLS** qui s'appliquent à TOUTES les requêtes, quelle que soit leur origine

### Couche 2 : Application Flutter (Orchestration)
- ✅ **Aucune écriture directe** en base de données
- ✅ **Toutes les opérations** passent par Supabase Client (qui respecte RLS)
- ✅ **Calculs critiques** délégués à la base de données (fonctions SQL)
- ✅ **UI = affichage** des résultats calculés par la DB

## Preuves Techniques

### 1. Aucune Écriture Directe en DB

**Flutter utilise exclusivement Supabase Client :**
```dart
// Exemple : Création d'un ajustement de stock
await supabase
  .from('stocks_adjustments')
  .insert(payload)
  .select()
  .single();
```

**Conséquence :** Même si le code Flutter tente une insertion, Supabase applique automatiquement les policies RLS. Si l'utilisateur n'est pas admin, l'erreur `42501` est retournée.

### 2. Calculs Critiques Côté DB

**Exemple : Application d'un ajustement de stock**
- ❌ **Flutter ne calcule PAS** les nouveaux volumes
- ✅ **Trigger DB `trg_apply_stock_adjustment`** calcule et applique l'ajustement
- ✅ **Fonction `apply_stock_adjustment()`** garantit la cohérence

**Code SQL (source de vérité) :**
```sql
CREATE TRIGGER trg_apply_stock_adjustment
AFTER INSERT ON public.stocks_adjustments
FOR EACH ROW
EXECUTE FUNCTION apply_stock_adjustment();
```

### 3. Validation Métier en DB

**Exemple : Création d'un ajustement**
- ✅ **Contrainte CHECK** : `reason` doit avoir au moins 10 caractères
- ✅ **Contrainte CHECK** : `adjustment_type` doit être dans la liste autorisée
- ✅ **Policy RLS** : Seul `admin` peut INSERT
- ✅ **Trigger** : `set_created_by()` garantit l'audit trail

**Même si l'UI bug :** Les contraintes DB empêchent les données invalides.

### 4. Fonctions SQL Sécurisées

**Exemple : `admin_compensate_reception()`**
```sql
CREATE OR REPLACE FUNCTION admin_compensate_reception(...)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM assert_is_admin();  -- Vérification triple
  -- ... logique métier ...
END;
$$;
```

**Flutter appelle cette fonction :**
```dart
await supabase.rpc('admin_compensate_reception', params: {...});
```

**Conséquence :** Même si Flutter appelle la fonction, `assert_is_admin()` bloque les non-admins.

## Scénarios de Protection

### Scénario 1 : Bug UI — Tentative d'ajustement par operateur

**Ce qui se passe :**
1. UI Flutter : L'utilisateur `operateur` clique sur "Ajuster stock"
2. Flutter : Envoie `INSERT INTO stocks_adjustments ...`
3. Supabase : Applique la policy RLS `stocks_adjustments_insert`
4. DB : Vérifie `app_is_admin()` → **FALSE**
5. Résultat : **ERROR 42501** retourné à Flutter
6. UI : Affiche l'erreur (pas de bypass possible)

### Scénario 2 : Tentative de manipulation directe SQL

**Ce qui se passe :**
1. Attaquant : Tente `INSERT INTO stocks_adjustments ...` via SQL direct
2. DB : Applique la policy RLS (même pour requêtes directes)
3. Résultat : **ERROR 42501** si non-admin

### Scénario 3 : Bug UI — Données invalides

**Ce qui se passe :**
1. UI Flutter : Envoie un ajustement avec `reason = "test"` (trop court)
2. DB : Contrainte CHECK `char_length(reason) >= 10` bloque
3. Résultat : **ERROR** retourné à Flutter
4. UI : Affiche l'erreur de validation

## Architecture de Défense en Profondeur

```
┌─────────────────────────────────────────┐
│  UI Flutter (Orchestration)            │
│  - Aucune logique métier critique      │
│  - Affichage uniquement                │
└──────────────┬──────────────────────────┘
               │
               │ Supabase Client
               │ (applique RLS automatiquement)
               ▼
┌─────────────────────────────────────────┐
│  PostgreSQL (Source de Vérité)          │
│  - RLS Policies (blocage accès)         │
│  - Triggers (calculs critiques)         │
│  - Contraintes CHECK (validation)       │
│  - Fonctions SQL sécurisées             │
└─────────────────────────────────────────┘
```

## Conclusion

✅ **L'UI ne peut PAS contourner la sécurité DB** car :
1. Toutes les requêtes passent par Supabase Client (qui applique RLS)
2. Les calculs critiques sont dans des triggers DB (non modifiables par Flutter)
3. Les validations métier sont des contraintes DB (non contournables)
4. Les fonctions SQL vérifient les permissions (triple vérification pour admin)

**Même si l'UI bug ou est compromise :** La base de données protège les données critiques.

## Références

- **Architecture** : `docs/architecture.md`
- **RLS Policies** : `scripts/rls_policies.sql`
- **Migrations RLS** : `supabase/migrations/20260109041723_axe_c_rls_s2.sql`
- **Code Flutter** : `lib/features/stocks_adjustments/` (tous les appels passent par Supabase)

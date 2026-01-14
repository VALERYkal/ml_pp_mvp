# Matrice Officielle des Droits — ML_PP MVP

**Date de création :** 2026-01-14  
**Statut :** Document contractuel de référence  
**Source de vérité :** RLS policies en base de données (`scripts/rls_policies.sql`, `supabase/migrations/`)

## Matrice des Permissions par Rôle

| Rôle | Lire stocks | Créer réception | Valider réception | Créer sortie | Ajuster stock | Accès logs |
|------|-------------|----------------|-------------------|-------------|---------------|------------|
| **admin** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **directeur** | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **gerant** | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **operateur** | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| **pca** | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **lecture** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## Détails par Fonctionnalité

### 📊 Lire stocks (`stocks_journaliers`, `v_stock_actuel`)
- **Tous les rôles authentifiés** : ✅ Lecture autorisée
- **Source :** `stocks_select` policy : `auth.role() = 'authenticated'`

### 📥 Créer réception (`receptions`)
- **admin, gerant, operateur** : ✅ INSERT autorisé
- **directeur, pca, lecture** : ❌ Bloqué par RLS
- **Source :** `receptions_insert` policy : `role_in('admin','gerant','operateur')`

### ✅ Valider réception (`receptions` UPDATE statut)
- **admin, gerant** : ✅ UPDATE autorisé
- **directeur, operateur, pca, lecture** : ❌ Bloqué par RLS
- **Source :** `receptions_update` policy : `role_in('admin','gerant')`

### 📤 Créer sortie (`sorties_produit`)
- **admin, gerant, operateur** : ✅ INSERT autorisé
- **directeur, pca, lecture** : ❌ Bloqué par RLS
- **Source :** `sorties_insert` policy : `role_in('admin','gerant','operateur')`

### 🔧 Ajuster stock (`stocks_adjustments`)
- **admin** : ✅ INSERT autorisé (UNIQUEMENT)
- **Tous les autres rôles** : ❌ Bloqué par RLS (ERROR 42501)
- **Source :** `stocks_adjustments_insert` policy : `app_is_admin()`
- **Critique :** Seul le rôle admin peut créer des ajustements de stock

### 📋 Accès logs (`log_actions`)
- **admin, directeur, gerant, pca** : ✅ SELECT autorisé
- **operateur, lecture** : ❌ Bloqué par RLS
- **Source :** `logs_select_admin` policy : `role_in('admin','directeur','gerant','pca')`

## Notes Importantes

1. **RLS activé** : Toutes les tables critiques ont RLS activé (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`)
2. **Helpers SQL sécurisés** : Fonctions `user_role()`, `role_in()`, `app_is_admin()` en `SECURITY DEFINER`
3. **Pas de bypass UI** : L'application Flutter ne peut pas contourner les politiques RLS
4. **Validation DB-strict** : Toutes les règles métier sont appliquées au niveau base de données

## Références Techniques

- **Fichiers SQL** :
  - `scripts/rls_policies.sql` : Policies principales
  - `supabase/migrations/20260109041723_axe_c_rls_s2.sql` : Policies stocks_adjustments
- **Fonctions helpers** :
  - `public.user_role()` : Retourne le rôle de l'utilisateur connecté
  - `public.role_in(variadic roles text[])` : Vérifie si le rôle est dans la liste
  - `public.app_is_admin()` : Vérifie si l'utilisateur est admin

## Validation

Cette matrice est la **vérité contractuelle** pour les permissions dans ML_PP MVP.  
Toute modification nécessite :
1. Mise à jour des policies RLS en base
2. Mise à jour de ce document
3. Tests de validation en staging
4. Révision formelle si changement de sécurité

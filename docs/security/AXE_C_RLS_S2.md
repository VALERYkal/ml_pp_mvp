# AXE C — Sécurité & Accès (RLS S2)

## Objectif
Sécuriser l'accès aux données critiques du système ML_PP MVP en appliquant des règles
de **Row Level Security (RLS)** cohérentes avec les rôles métiers, sans impacter
la logique métier existante (AXE A).

L'objectif principal de l'AXE C est d'empêcher toute action sensible non autorisée,
en particulier les **ajustements de stock**.

---

## Principe général (S2)
- Lecture :
  - Accès global pour les rôles cadres (à valider quand présents).
  - Accès filtré par dépôt pour les rôles non-cadres.
- Écriture :
  - Strictement contrôlée par rôle.
  - Certaines tables sont **admin-only**.

---

## Règle critique : Ajustements de stock
La table `stocks_adjustments` est considérée comme **hautement sensible**.

### Règle appliquée
- **INSERT** sur `stocks_adjustments` :
  - ✅ Autorisé uniquement pour le rôle `admin`
  - ❌ Interdit pour tous les autres rôles (`lecture`, etc.)
- **UPDATE / DELETE** :
  - Interdits (historique immuable).

Cette règle est appliquée exclusivement via RLS (et non via l'application).

---

## Helpers SQL
Les helpers suivants sont utilisés dans les policies RLS :

- `app_uid()` → retourne `auth.uid()`
- `app_current_role()` → lit le rôle depuis `public.profils`
- `app_current_depot_id()` → lit le dépôt associé à l'utilisateur
- `app_is_admin()` → true si rôle = `admin`
- `app_is_cadre()` → true si rôle ∈ (admin, directeur, gerant, pca)

Tous les helpers sont :
- `SECURITY DEFINER`
- `null-safe`
- protégés par `SET search_path = public`

---

## Validation en staging (configuration minimale)
L'environnement staging actuel contient uniquement :
- 1 utilisateur `admin`
- 1 utilisateur `lecture`

### Scénarios validés
- Admin :
  - INSERT `stocks_adjustments` → **autorisé**
- Lecture :
  - INSERT `stocks_adjustments` → **bloqué par RLS (ERROR 42501)**

Ces tests confirment que la règle critique **"admin only adjustments"** est effectivement
enforced au niveau base de données.

---

## Smoke tests
Un script de smoke test est fourni dans :
staging/sql/rls_smoke_test_s2.sql

Caractéristiques :
- Exécutable directement dans Supabase SQL Editor
- Utilise `request.jwt.claim.sub` + `SET LOCAL ROLE authenticated`
- Aligné avec la configuration staging minimale
- Ne dépend pas de rôles inexistants

---

## Évolutions prévues
Lorsque les utilisateurs suivants seront créés en staging ou en production :
- `operateur`
- `directeur`
- `gerant`
- `pca`

Les scénarios RLS correspondants (déjà implémentés) seront activés et validés
sans modification de la migration.

---

## Conclusion
AXE C garantit que :
- Les ajustements de stock ne peuvent pas être falsifiés.
- La sécurité est assurée **au niveau base de données**, indépendamment de l'UI.
- Le système est prêt pour un passage en production contrôlé.

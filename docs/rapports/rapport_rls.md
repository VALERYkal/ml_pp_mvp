# Rapport RLS — Politiques de sécurité (MVP)

- Tables concernées: `receptions`, `sorties_produit`, `stocks_journaliers`, `citernes`, `log_actions`
- Principe MVP: lecture globale pour utilisateurs authentifiés, écriture limitée selon rôle
- Fonctions helpers: `public.user_role()`, `public.role_in(variadic roles text[])`

## Résumé des politiques
- `receptions`
  - SELECT: tout utilisateur authentifié
  - INSERT: `admin`, `gerant`, `operateur`
  - UPDATE: `admin`, `gerant`
  - DELETE: `admin`
- `sorties_produit`
  - SELECT: tout utilisateur authentifié
  - INSERT: `admin`, `gerant`, `operateur`
  - UPDATE: `admin`, `gerant`
  - DELETE: `admin`
- `stocks_journaliers`
  - SELECT: tout utilisateur authentifié
  - ALL (upsert): `admin`, `gerant`, `operateur`
- `citernes`
  - SELECT: tout utilisateur authentifié
  - UPDATE: `admin`
- `log_actions`
  - SELECT: `admin`, `directeur`, `gerant`, `pca`
  - INSERT: tout utilisateur authentifié (journalisation côté app)

## Fichier de politique
Voir `scripts/rls_policies.sql` (exécuter dans Supabase SQL Editor).

## Tests ciblés (manuels)
- Créer/valider une réception avec un compte `operateur`: OK INSERT, pas UPDATE statut si restreint
- Créer une sortie avec un compte `operateur`: OK INSERT
- Lire `stocks_journaliers` avec `lecture`: OK SELECT, pas d’UPDATE
- Lire `log_actions` avec `directeur`: OK SELECT
- Tenter UPDATE `citernes` avec `gerant`: rejeté

## Extensions ultérieures
- Restreindre SELECT par dépôt (`profils.depot_id`) si nécessaire
- Journaux: filtrer visibilité par module selon rôle
- Politique stricte INSERT sur `log_actions` (réservée au backend) selon besoin
# Décision — Environnement Flutter Web en PROD

**Date** : 2026-02  
**Statut** : VALIDÉ PROD  
**Contexte** : Session critique Web PROD (RLS + endpoint + dart-define)

---

## Contexte

Incident critique PROD : authentification OK mais **redirection bloquée** après login.

## Cause racine

`.env` vide en build Web — les variables Supabase n'étaient pas disponibles côté client, empêchant l'initialisation correcte et la navigation post-login.

## Décision

En **PROD Web** :

- **dotenv interdit** : aucun chargement de fichier `.env` pour l'environnement d'exécution Web.
- **Secrets injectés via `--dart-define` uniquement** : `SUPABASE_URL` et `SUPABASE_ANON_KEY` passés au build par le script officiel (`tools/release_web_prod.sh`).
- **Vérification obligatoire** : les logs console doivent afficher `[ENV]` avec statut ok pour confirmer l'injection.

## Impact

- Plus aucun fichier `.env` servi au navigateur.
- Déploiement sécurisé et reproductible.
- Runbook et README mis à jour (politique ENV Web, section Environnement Web PROD).

**Référence** : [DEPLOY_WEB_PROD_RUNBOOK.md](../02_RUNBOOKS/DEPLOY_WEB_PROD_RUNBOOK.md) — section Politique ENV Web.

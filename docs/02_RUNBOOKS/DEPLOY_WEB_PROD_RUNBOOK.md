# Runbook — Déploiement PROD Web (ML_PP MVP)

**Statut** : Document officiel  
**Dernière mise à jour** : 2026-02-12  
**Responsable** : Équipe technique

---

## 1. Contexte

- **Projet** : ML_PP MVP (Monaluxe Petrol Platform)
- **Statut** : PROD EN EXPLOITATION (GO LIVE acté)
- **Front** : Flutter Web (SPA)
- **Hosting** : Firebase Hosting — project **ml-pp-mvp-web**
- **Domaine** : https://monaluxe.app
- **Backend** : Supabase PROD
- **Déploiement** : Manuel contrôlé (pas de CI/CD)

**Principe** : Tout déploiement PROD Web doit passer par le **script officiel existant** (`tools/release_web_prod.sh`). Ce script build en release avec `--dart-define` et déploie sur Firebase. Il a été testé et ne doit pas être regénéré.

---

## 2. Pré-requis

### Branche
- Être sur la branche **main**.

### Outils
- **Firebase CLI** installé et authentifié (`firebase login`).
- **Flutter** opérationnel (`flutter doctor`).

### Variables d'environnement (shell)
Les variables suivantes doivent être **exportées** avant de lancer le script (jamais committées) :
- `SUPABASE_URL` — URL du projet Supabase PROD
- `SUPABASE_ANON_KEY` — Clé anonyme Supabase PROD

### Vérification (sans afficher la clé)
```bash
echo "$SUPABASE_URL"
echo "$SUPABASE_ANON_KEY" | wc -c
```
- `SUPABASE_URL` doit afficher une URL valide (https://…).
- `wc -c` doit afficher un nombre de caractères > 0 (confirme que la clé est définie).

---

## 3. Procédure standard de déploiement

1. Vérifier les pré-requis (section 2).
2. Depuis la racine du repo :
   ```bash
   ./tools/release_web_prod.sh
   ```
3. Attendre la fin du script (tests, build, deploy).
4. En cas de succès : **appliquer le tagging Git** (section 4).

---

## 4. Tagging Git obligatoire après déploiement réussi

Chaque déploiement PROD réussi doit être tagué pour traçabilité.

**Format du tag** : `prod-web-YYYYMMDD-HHMM` (UTC)

**Commandes** :
```bash
TAG="prod-web-$(date -u +%Y%m%d-%H%M)"
git tag -a "$TAG" -m "PROD web deploy"
git push origin "$TAG"
```

Exemple : `prod-web-20260211-1430`

---

## 5. Vérifications post-déploiement (smoke tests)

1. **Ouvrir** : `https://monaluxe.app/?v=<TAG>`  
   (ex. `?v=prod-web-20260211-1430` pour forcer le cache à considérer une nouvelle version.)

2. **Login** : Se connecter → redirection vers le dashboard OK.

3. **Navigation** : Tester au minimum :
   - Dashboard
   - Réceptions
   - Stocks

4. **Cache** : En cas de doute (ancienne version affichée), effectuer un **hard refresh** :  
   - Mac : **Cmd+Shift+R**  
   - Windows/Linux : **Ctrl+Shift+R**

---

## 6. Rollback (procédure)

En cas de problème critique après déploiement :

1. **Identifier** un tag précédent `prod-web-*` :
   ```bash
   git tag -l 'prod-web-*' | tail -5
   ```

2. **Checkout** ce tag et redéployer :
   ```bash
   git checkout <TAG>
   ./tools/release_web_prod.sh
   ```

3. **Revenir** sur `main` :
   ```bash
   git checkout main
   ```

4. Documenter l’incident (cause, tag rollback, correctif prévu) dans `docs/02_RUNBOOKS/incidents/` si pertinent.

---

## 7. Notes sécurité

- **Aucun secret dans Git** : Ne jamais commiter `SUPABASE_ANON_KEY`, `.env` contenant des clés, ou tout fichier contenant des secrets.
- **Pas de `.env` servi au navigateur** : En PROD Flutter Web, les variables sont injectées via `--dart-define` au build ; le fichier `.env` n’est pas utilisé en production (cf. `lib/main.dart`).
- **Toujours passer par le script officiel** : Ne pas lancer manuellement `flutter build web` + `firebase deploy` sans utiliser `tools/release_web_prod.sh` pour rester aligné avec les garde-fous (branche main, variables, tests).

---

## 8. Politique ENV Web

En PROD :

- **dotenv désactivé** : aucun chargement de `.env` en production Web.
- **Secrets via `--dart-define`** : injection au build par le script officiel uniquement.
- **Vérifier les logs console** après chargement de l'app :
  - `[ENV] SUPABASE_URL ok=true`
  - `[ENV] SUPABASE_ANON_KEY ok=true`  
  Si l'un des deux est `ok=false`, le déploiement n'est pas valide (vérifier variables shell et rebuild).

---

**Références** :
- `tools/release_web_prod.sh` — Script officiel de release
- `docs/00_REFERENCE/PROD_STATUS.md` — État production
- `docs/01_DECISIONS/DECISION_GO_PROD_2026_01.md` — Décision GO PROD
- `docs/01_DECISIONS/DECISION_WEB_ENV_DART_DEFINE_2026_02.md` — Décision ENV Web (dart-define)

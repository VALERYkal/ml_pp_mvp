# Plan d'Exécution Post-Release Gate — Janvier 2026

**Date de création** : 2026-01-23  
**Statut** : Procédure active  
**Version** : 1.0  
**Release Gate référencé** : `docs/RELEASE_GATE_2026_01.md`  
**Tag validé** : `prod-ready-2026-01-23-nightly-green` (commit `0c5c2b7`)

---

## Préambule

Ce document définit les procédures d'exécution **après validation du Release Gate** pour les 3 scénarios exclusifs :

- **Scénario A** : Déploiement STAGING contrôlé
- **Scénario B** : Déploiement PRODUCTION contrôlé  
- **Scénario C** : Freeze Release + backlog post-release

**Règle absolue** : Aucun scénario ne peut être exécuté sans Release Gate validé et checklist complète (section 4 de `RELEASE_GATE_2026_01.md`).

---

## Scénario A : Déploiement STAGING contrôlé

### Objectif

Déployer le code validé par le Release Gate dans l'environnement STAGING pour validation métier finale avant production.

### Pré-requis exacts

#### Obligatoires (BLOQUANTS)

1. ✅ **Release Gate validé** : Checklist complète (section 4) avec ✅ uniquement
2. ✅ **Tag Git présent** : `prod-ready-2026-01-23-nightly-green` sur commit `0c5c2b7`
3. ✅ **CI Nightly verte** : ≥1 cycle complet (24h) sur `main`
4. ✅ **Fichier de configuration** : `env/.env.staging` présent et configuré
5. ✅ **Variables d'environnement** : `STAGING_DB_URL`, `STAGING_PROJECT_REF` définies
6. ✅ **Autorisation explicite** : Release Manager / PCA a validé le déploiement STAGING

#### Vérifications pré-déploiement

```bash
# 1. Vérifier le tag
git describe --tags --exact-match HEAD
# Doit retourner : prod-ready-2026-01-23-nightly-green

# 2. Vérifier l'état du dépôt
git status
# Doit être : "working tree clean"

# 3. Vérifier la configuration STAGING
test -f env/.env.staging && echo "✅ Configuration STAGING présente"

# 4. Vérifier les variables (sans exposer les valeurs)
grep -q "STAGING_DB_URL" env/.env.staging && echo "✅ STAGING_DB_URL configuré"
grep -q "STAGING_PROJECT_REF" env/.env.staging && echo "✅ STAGING_PROJECT_REF configuré"
```

### Commandes autorisées

#### Phase 1 : Préparation (READ-ONLY)

```bash
# Vérification du checkpoint
git checkout prod-ready-2026-01-23-nightly-green
git log --oneline -1

# Vérification de la CI Nightly (via GitHub Actions UI ou API)
# URL : https://github.com/<org>/<repo>/actions/workflows/nightly.yml

# Backup de l'état STAGING actuel (si applicable)
# Note : STAGING est resetable, mais backup recommandé pour audit
```

#### Phase 2 : Reset STAGING (EXÉCUTIF — avec garde-fous)

```bash
# Reset STAGING avec seed vide (miroir PROD)
CONFIRM_STAGING_RESET=I_UNDERSTAND_THIS_WILL_DROP_PUBLIC \
ALLOW_STAGING_RESET=true \
./scripts/reset_staging.sh

# Vérification post-reset
# Se connecter à STAGING et vérifier :
# - Tables transactionnelles vides
# - Vues présentes
# - Référentiels intacts
```

#### Phase 3 : Build & Déploiement (EXÉCUTIF)

```bash
# Build Flutter pour web (STAGING)
flutter build web --release \
  --dart-define=SUPABASE_URL=<STAGING_URL> \
  --dart-define=SUPABASE_ANON_KEY=<STAGING_KEY>

# Vérification du build
test -d build/web && echo "✅ Build web réussi"

# Déploiement (méthode dépend de l'infrastructure)
# Exemple : Firebase Hosting, Netlify, Vercel, etc.
# firebase deploy --only hosting:staging
# ou
# netlify deploy --prod --dir=build/web
```

#### Phase 4 : Validation post-déploiement (READ-ONLY)

```bash
# Tests de smoke sur STAGING
# 1. Connexion utilisateur test
# 2. Navigation principale
# 3. Vérification des modules critiques
# 4. Vérification des logs d'audit

# Vérification DB STAGING
# Se connecter à STAGING DB et vérifier :
# - Aucune donnée transactionnelle (seed vide)
# - Schéma conforme
# - RLS activé
```

### Risques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Reset STAGING échoue | Faible | Blocant | Script avec garde-fous (`ALLOW_STAGING_RESET`, `CONFIRM_STAGING_RESET`) |
| Build Flutter échoue | Faible | Blocant | Vérification locale avant déploiement |
| Déploiement partiel | Moyenne | Critique | Rollback immédiat si échec |
| Données STAGING corrompues | Faible | Moyen | Reset STAGING réversible (seed vide) |
| Variables d'environnement incorrectes | Moyenne | Critique | Vérification pré-déploiement obligatoire |

### Critères de succès

✅ **Build réussi** : `flutter build web` sans erreur  
✅ **Déploiement réussi** : Application accessible sur URL STAGING  
✅ **Smoke tests passent** : Connexion, navigation, modules critiques fonctionnels  
✅ **DB STAGING propre** : Seed vide appliqué, schéma conforme  
✅ **Logs d'audit présents** : `log_actions` fonctionnel  
✅ **Validation métier** : Utilisateurs tests peuvent exécuter les workflows critiques

### Critères d'abandon / rollback

❌ **Abandon immédiat si** :
- Build échoue après 2 tentatives
- Déploiement échoue après 2 tentatives
- Smoke tests critiques échouent
- Erreur de configuration détectée (variables, DB)

**Procédure de rollback** :
```bash
# 1. Identifier le commit précédent STAGING (si taggé)
git tag -l "staging-*" | tail -1

# 2. Rebuild avec commit précédent
git checkout <commit-precedent>
flutter build web --release ...

# 3. Redéploiement
# (méthode dépend de l'infrastructure)

# 4. Documentation du rollback
echo "Rollback STAGING le $(date)" >> docs/STAGING_DEPLOYMENTS.md
```

---

## Scénario B : Déploiement PRODUCTION contrôlé

### Objectif

Déployer le code validé par le Release Gate dans l'environnement PRODUCTION après validation STAGING réussie.

### Pré-requis exacts

#### Obligatoires (BLOQUANTS)

1. ✅ **Release Gate validé** : Checklist complète (section 4) avec ✅ uniquement
2. ✅ **Scénario A réussi** : STAGING déployé et validé ≥48h sans incident
3. ✅ **Tag Git présent** : `prod-ready-2026-01-23-nightly-green` sur commit `0c5c2b7`
4. ✅ **CI Nightly verte** : ≥2 cycles complets (48h) sur `main` sans régression
5. ✅ **Fichier de configuration** : `env/.env.prod` présent et configuré (jamais commité)
6. ✅ **Autorisation explicite** : PCA / Directeur a validé le déploiement PRODUCTION
7. ✅ **Fenêtre de maintenance** : Horaire défini, utilisateurs notifiés (si applicable)
8. ✅ **Plan de rollback** : Procédure documentée et testée

#### Vérifications pré-déploiement

```bash
# 1. Vérifier le tag
git describe --tags --exact-match HEAD
# Doit retourner : prod-ready-2026-01-23-nightly-green

# 2. Vérifier l'état du dépôt
git status
# Doit être : "working tree clean"

# 3. Vérifier la configuration PROD (sans exposer les valeurs)
test -f env/.env.prod && echo "✅ Configuration PROD présente"
# ⚠️ NE JAMAIS COMMITER env/.env.prod

# 4. Vérifier les variables PROD (sans exposer)
grep -q "PROD_DB_URL\|SUPABASE_URL" env/.env.prod && echo "✅ URL PROD configurée"
grep -q "PROD_PROJECT_REF\|SUPABASE_PROJECT_REF" env/.env.prod && echo "✅ Project ref PROD configuré"

# 5. Vérifier que STAGING est stable
# (validation manuelle requise : ≥48h sans incident)
```

### Commandes autorisées

#### Phase 1 : Préparation (READ-ONLY)

```bash
# Vérification du checkpoint
git checkout prod-ready-2026-01-23-nightly-green
git log --oneline -1

# Vérification de la CI Nightly (≥2 cycles)
# URL : https://github.com/<org>/<repo>/actions/workflows/nightly.yml

# Backup PROD (si applicable)
# Note : PROD doit avoir un backup automatique, mais vérification recommandée
```

#### Phase 2 : Build PRODUCTION (EXÉCUTIF — avec validation)

```bash
# Build Flutter pour web (PRODUCTION)
flutter build web --release \
  --dart-define=SUPABASE_URL=<PROD_URL> \
  --dart-define=SUPABASE_ANON_KEY=<PROD_KEY>

# Vérification du build
test -d build/web && echo "✅ Build web réussi"

# Vérification de la taille du build (détection d'anomalie)
du -sh build/web
# Comparer avec build précédent (si disponible)
```

#### Phase 3 : Déploiement PRODUCTION (EXÉCUTIF — avec monitoring)

```bash
# Déploiement (méthode dépend de l'infrastructure)
# Exemple : Firebase Hosting, Netlify, Vercel, etc.
# firebase deploy --only hosting:production
# ou
# netlify deploy --prod --dir=build/web

# ⚠️ DÉPLOIEMENT EN PRODUCTION : Action irréversible
# ⚠️ Monitoring actif requis pendant et après déploiement
```

#### Phase 4 : Validation post-déploiement (READ-ONLY)

```bash
# Tests de smoke sur PRODUCTION (immédiat)
# 1. Connexion utilisateur test
# 2. Navigation principale
# 3. Vérification des modules critiques
# 4. Vérification des logs d'audit

# Monitoring (premières 2h critiques)
# - Taux d'erreur
# - Temps de réponse
# - Logs d'erreur
# - Alertes utilisateurs
```

### Risques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Déploiement PROD échoue | Faible | Critique | Plan de rollback immédiat |
| Régression non détectée | Moyenne | Critique | Validation STAGING ≥48h, tests exhaustifs |
| Données PROD corrompues | Très faible | Critique | Backup automatique, rollback DB si nécessaire |
| Variables d'environnement incorrectes | Faible | Critique | Vérification pré-déploiement, double validation |
| Incident utilisateur | Moyenne | Critique | Monitoring actif, rollback si nécessaire |
| Perte de disponibilité | Faible | Critique | Déploiement en fenêtre de maintenance |

### Critères de succès

✅ **Build réussi** : `flutter build web` sans erreur  
✅ **Déploiement réussi** : Application accessible sur URL PRODUCTION  
✅ **Smoke tests passent** : Connexion, navigation, modules critiques fonctionnels  
✅ **Monitoring stable** : Aucune alerte critique dans les 2 premières heures  
✅ **Validation métier** : Utilisateurs réels peuvent exécuter les workflows critiques  
✅ **Logs d'audit présents** : `log_actions` fonctionnel en PROD

### Critères d'abandon / rollback

❌ **Rollback immédiat si** :
- Smoke tests critiques échouent
- Taux d'erreur > 5% dans les 30 premières minutes
- Incident utilisateur critique signalé
- Erreur de configuration détectée (variables, DB)
- Perte de disponibilité > 5 minutes

**Procédure de rollback PRODUCTION** :
```bash
# 1. Identifier le commit PROD précédent (taggé)
git tag -l "prod-*" | tail -1

# 2. Rebuild avec commit précédent
git checkout <commit-prod-precedent>
flutter build web --release ...

# 3. Redéploiement immédiat
# (méthode dépend de l'infrastructure)

# 4. Documentation du rollback
echo "Rollback PROD le $(date) - Raison: <raison>" >> docs/PROD_DEPLOYMENTS.md

# 5. Post-mortem obligatoire
# Créer docs/POST_MORTEM_ROLLBACK_YYYY_MM_DD.md
```

---

## Scénario C : Freeze Release + backlog post-release

### Objectif

Geler la release validée et planifier le backlog post-release sans déploiement immédiat.

### Pré-requis exacts

#### Obligatoires (BLOQUANTS)

1. ✅ **Release Gate validé** : Checklist complète (section 4) avec ✅ uniquement
2. ✅ **Tag Git présent** : `prod-ready-2026-01-23-nightly-green` sur commit `0c5c2b7`
3. ✅ **Décision de freeze** : Release Manager / PCA a décidé de ne pas déployer immédiatement
4. ✅ **Raison documentée** : Justification du freeze dans ce document

### Commandes autorisées

#### Phase 1 : Freeze Release (READ-ONLY)

```bash
# Vérification du checkpoint
git checkout prod-ready-2026-01-23-nightly-green
git log --oneline -1

# Création d'un tag de freeze (optionnel, pour traçabilité)
git tag -a "freeze-2026-01-23" -m "Freeze release après validation Release Gate"
git push origin freeze-2026-01-23

# Documentation du freeze
echo "Freeze release le $(date)" >> docs/RELEASE_FREEZES.md
```

#### Phase 2 : Création du backlog post-release (READ-ONLY)

```bash
# Création d'un document de backlog
# Fichier : docs/BACKLOG_POST_RELEASE_2026_01.md

# Structure recommandée :
# - Améliorations identifiées
# - Bugs mineurs non bloquants
# - Optimisations
# - Features futures
```

### Risques identifiés

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Dérive du code | Moyenne | Moyen | Freeze strict, aucune modification sans nouveau Gate |
| Perte de contexte | Faible | Faible | Documentation exhaustive du freeze |
| Délai de déploiement | Moyenne | Faible | Planification claire du déploiement futur |

### Critères de succès

✅ **Freeze documenté** : Raison, date, responsable documentés  
✅ **Backlog créé** : Liste des items post-release identifiés  
✅ **Tag de freeze** : Tag Git créé pour traçabilité (optionnel)  
✅ **Communication** : Équipe notifiée du freeze

### Critères d'abandon / rollback

❌ **Abandon du freeze si** :
- Décision de déploiement immédiat (passage au Scénario A ou B)
- Nouveau Release Gate requis (modifications de code)

**Procédure de sortie de freeze** :
```bash
# 1. Vérifier que le Release Gate est toujours valide
# (aucune modification de code depuis le freeze)

# 2. Si valide : Exécuter Scénario A ou B
# 3. Si non valide : Nouveau Release Gate requis
```

---

## Règles communes aux 3 scénarios

### Traçabilité obligatoire

Chaque scénario doit documenter :

1. **Date et heure** : Timestamp exact de l'exécution
2. **Validateur** : Rôle et nom de la personne ayant autorisé
3. **Checkpoint Git** : Tag et commit exacts
4. **Résultat** : Succès / Échec / Rollback
5. **Incidents** : Tout incident même mineur doit être documenté

### Commandes interdites (TOUS LES SCÉNARIOS)

❌ `git push --force` sur `main`  
❌ `git tag -d` sur les tags validés  
❌ Modification de code sans nouveau Release Gate  
❌ Bypass des garde-fous (scripts, vérifications)  
❌ Déploiement sans validation préalable

### Documentation post-exécution

Après exécution de n'importe quel scénario :

1. **Mise à jour du CHANGELOG.md** : Entrée datée avec référence au tag
2. **Mise à jour de RELEASE_GATE_2026_01.md** : Section "Historique des validations"
3. **Création d'un rapport** : `docs/DEPLOYMENT_REPORT_YYYY_MM_DD.md` (si déploiement)

---

## Décision de scénario

### Matrice de décision

| Condition | Scénario recommandé |
|-----------|---------------------|
| Validation métier requise | **Scénario A** (STAGING) |
| STAGING validé ≥48h, confiance élevée | **Scénario B** (PRODUCTION) |
| Décision différée, freeze souhaité | **Scénario C** (Freeze) |
| Nouveau code après Release Gate | **Nouveau Release Gate requis** |

### Autorité de décision

- **Scénario A** : Release Manager / QA Lead
- **Scénario B** : PCA / Directeur (après validation STAGING)
- **Scénario C** : Release Manager / PCA

---

## Références

### Documents liés

- `docs/RELEASE_GATE_2026_01.md` : Release Gate officiel
- `docs/POST_MORTEM_NIGHTLY_2026_01.md` : Post-mortem CI Nightly
- `CHANGELOG.md` : Historique des changements
- `scripts/reset_staging.sh` : Script de reset STAGING
- `scripts/d1_one_shot.sh` : Script de validation CI

### Tags Git

- `prod-ready-2026-01-23-nightly-green` : Checkpoint Release Gate validé

---

**Document créé le** : 2026-01-23  
**Dernière mise à jour** : 2026-01-23  
**Version** : 1.0  
**Responsable** : Release Manager / QA Lead

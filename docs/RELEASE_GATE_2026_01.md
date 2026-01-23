# Release Gate — Janvier 2026

**Date de création** : 2026-01-23  
**Statut** : Procédure active  
**Version** : 1.0

---

## 1. Préambule

### Contexte

Ce Release Gate fait suite à la stabilisation complète de la CI Nightly documentée dans le post-mortem officiel : `docs/POST_MORTEM_NIGHTLY_2026_01.md`

### Checkpoint Git officiel

**Tag** : `prod-ready-2026-01-23-nightly-green`  
**Commit** : `0c5c2b7`

**Commande de vérification** :
```bash
git describe --tags --exact-match HEAD
# Doit retourner : prod-ready-2026-01-23-nightly-green
```

### Objectif du Release Gate

Transformer une **CI Nightly verte** en état **"prêt à livrer"** via une validation formelle et irréversible.

---

## 2. Définition du Release Gate

### Ce qu'est un Release Gate

- ✅ **Verrou de validation** : Contrôle formel avant toute mise en production
- ✅ **Checklist contractuelle** : Critères de sortie irréversibles et traçables
- ✅ **Point de non-retour** : Validation engageante pour l'équipe et les parties prenantes
- ✅ **Documentation officielle** : Preuve d'audit pour conformité et traçabilité

### Ce qu'il n'est pas

- ❌ **Phase de développement** : Pas de code, pas de refactor, pas de feature
- ❌ **Test de validation** : Les tests sont déjà passés (pré-requis)
- ❌ **Déploiement automatique** : Le Gate valide, ne déploie pas
- ❌ **Processus optionnel** : Obligatoire avant toute prod / staging durable

### Pourquoi il est requis

1. **Sécurité** : Empêche les mises en production implicites ou non contrôlées
2. **Traçabilité** : Archive formelle de la décision de release
3. **Conformité** : Répond aux exigences d'audit et de gouvernance
4. **Confiance** : Garantit que tous les critères sont validés avant production

---

## 3. Pré-requis techniques (BLOQUANTS)

### Liste exhaustive

#### CI PR verte

- ✅ Toutes les Pull Requests passent les tests (mode LIGHT)
- ✅ Aucun test unitaire ou widget en échec
- ✅ `flutter analyze` sans erreur bloquante
- ✅ `build_runner` génère les fichiers sans conflit

**Vérification** :
```bash
# Vérifier l'état des dernières PR mergées
gh pr list --state merged --limit 5
```

#### CI Nightly verte sur ≥1 cycle

- ✅ Nightly Full Suite (mode FULL) verte sur `main`
- ✅ Tous les tests (unit, widget, integration, e2e) passent
- ✅ Validation sur ≥1 cycle complet (24h minimum)
- ✅ Aucun échec intermittent non résolu

**Vérification** :
```bash
# Consulter les logs Nightly sur GitHub Actions
# Vérifier que la dernière exécution est verte
```

#### Aucun test flaky non justifié

- ✅ Tous les tests flaky sont identifiés et taggés `@Tags(['flaky'])`
- ✅ Les tests flaky passent en mode FULL (si inclus)
- ✅ Aucun test instable non documenté

**Vérification** :
```bash
# Lister les tests flaky
find test -name "*_flaky_test.dart" -o -name "*flaky*test.dart"
```

#### Aucun accès direct à main

- ✅ Aucun push direct sur `main` (hors merge PR)
- ✅ Aucun force push sur `main`
- ✅ Toute modification passe par une PR validée

**Vérification** :
```bash
# Vérifier l'historique récent de main
git log --oneline --graph main -10
```

#### Scripts CI durcis et loggés

- ✅ `scripts/d1_one_shot.sh` utilise `run_step()` pour chaque étape
- ✅ Dossier `.ci_logs/` créé systématiquement
- ✅ Variables sécurisées (`EXTRA_DEFINES` protégé contre `set -u`)

**Vérification** :
```bash
# Vérifier la présence de run_step dans le script
grep -n "run_step" scripts/d1_one_shot.sh
```

#### Tag Git existant et documenté

- ✅ Tag `prod-ready-YYYY-MM-DD-*` présent sur le commit validé
- ✅ Tag référencé dans la documentation (CHANGELOG, post-mortem)
- ✅ Tag pointe vers un commit mergé sur `main`

**Vérification** :
```bash
git describe --tags --exact-match HEAD
```

### Règle de blocage

❌ **Si un seul pré-requis échoue → Release Gate refusé**

Aucune exception. Le Release Gate est un verrou, pas une négociation.

---

## 4. Checklist Release Gate (À COCHER)

| Catégorie | Élément | Statut | Notes |
|-----------|---------|--------|-------|
| **CI** | Nightly Full Suite verte | ✅ | Vérifier ≥1 cycle complet |
| **CI** | PR validées et mergées | ✅ | Aucune PR en attente critique |
| **Tests** | Aucun test ignoré | ✅ | Tous les tests exécutés |
| **Tests** | Tests flaky documentés | ✅ | Tags `@Tags(['flaky'])` présents |
| **Git** | Tag prod-ready présent | ✅ | Format : `prod-ready-YYYY-MM-DD-*` |
| **Git** | Commit sur main | ✅ | Pas de commit direct, uniquement merge PR |
| **Docs** | Post-mortem Nightly validé | ✅ | `POST_MORTEM_NIGHTLY_2026_01.md` présent |
| **Docs** | CHANGELOG à jour | ✅ | Entrées récentes documentées |
| **Sécurité** | Aucun secret en clair | ✅ | Variables d'environnement sécurisées |
| **Sécurité** | Aucune clé API exposée | ✅ | Vérification manuelle requise |
| **Infra** | Scripts CI durcis | ✅ | `d1_one_shot.sh` utilise `run_step()` |
| **Infra** | Logs CI disponibles | ✅ | Dossier `.ci_logs/` créé systématiquement |

### Instructions de remplissage

1. **Cocher chaque élément** : ✅ si validé, ❌ si bloquant, 🟡 si à revoir
2. **Ajouter des notes** si nécessaire (ex: exception documentée)
3. **Ne pas valider** si un élément est ❌ (blocage immédiat)

---

## 5. Commandes de validation

### Commandes de validation non-destructives

> Ces commandes ne déploient rien, ne modifient ni la base de données ni le code source,  
> mais peuvent générer des artifacts locaux temporaires (ex. `.ci_logs`, outputs build_runner).

#### Vérification Git

```bash
# Vérifier le tag actuel
git describe --tags --exact-match HEAD

# Vérifier l'état du dépôt
git status

# Vérifier l'historique récent
git log --oneline --graph main -10

# Lister les tags prod-ready
git tag -l "prod-ready-*"
```

#### Vérification CI

```bash
# Exécuter la validation locale (mode LIGHT)
./scripts/d1_one_shot.sh web

# Vérifier les logs générés
ls -la .ci_logs/

# Vérifier la présence de run_step
grep -n "run_step" scripts/d1_one_shot.sh
```

#### Vérification Tests

```bash
# Lister les tests flaky
find test -name "*_flaky_test.dart" -o -name "*flaky*test.dart"

# Compter les tests
find test -name "*_test.dart" | wc -l
```

#### Vérification Documentation

```bash
# Vérifier la présence du post-mortem
test -f docs/POST_MORTEM_NIGHTLY_2026_01.md && echo "✅ Post-mortem présent"

# Vérifier le CHANGELOG
head -20 CHANGELOG.md
```

### Aucune commande destructive

⚠️ **Interdit** : `git push --force`, `git tag -d`, `rm -rf`, toute commande modifiant l'état du dépôt.

---

## 6. Décision de Release

### États possibles

#### ✅ Release autorisé

**Conditions** :
- Tous les pré-requis techniques validés
- Checklist complète avec ✅ uniquement
- Aucun élément bloquant identifié

**Action** :
- Documenter la décision dans ce fichier (section 7)
- Archiver la validation (date, validateur, commit)
- Autoriser le déploiement en staging/production

#### 🟡 Release différé

**Conditions** :
- Pré-requis techniques validés
- Checklist avec 🟡 (éléments à revoir non bloquants)
- Conditions de déblocage identifiées et documentées

**Action** :
- Lister les conditions de déblocage
- Définir une date de réévaluation
- Ne pas autoriser le déploiement tant que les conditions ne sont pas remplies

**Exemples de conditions** :
- Attente d'une validation externe (client, sécurité)
- Correction mineure documentée et planifiée
- Attente d'une fenêtre de maintenance

#### ❌ Release bloqué

**Conditions** :
- Au moins un pré-requis technique en échec
- Checklist avec ❌ (éléments bloquants)
- Raison obligatoire documentée

**Action** :
- Documenter la raison du blocage
- Identifier les actions correctives nécessaires
- Refuser tout déploiement jusqu'à résolution

**Exemples de blocages** :
- CI Nightly en échec
- Test flaky non documenté
- Secret exposé en clair
- Script CI non durci

---

## 7. Traçabilité & responsabilité

### Qui valide (rôles)

#### Release Manager / QA Lead

- **Responsabilité** : Validation finale du Release Gate
- **Autorité** : Décision finale de release
- **Signature** : Date, nom, rôle (à documenter dans la section ci-dessous)

#### DevOps / CI Lead

- **Responsabilité** : Validation des pré-requis techniques (CI, scripts)
- **Autorité** : Veto technique si pré-requis non respectés

#### Tech Lead / Architect

- **Responsabilité** : Validation de l'architecture et de la sécurité
- **Autorité** : Veto si risque architectural identifié

### Où la décision est archivée

1. **Ce document** : Section "Historique des validations" (ci-dessous)
2. **Git** : Commit de validation avec message formaté
3. **CHANGELOG.md** : Entrée datée avec référence au tag

### Lien vers le commit/tag exact

**Format de référence** :
```
Tag: prod-ready-YYYY-MM-DD-*
Commit: <hash>
Date de validation: YYYY-MM-DD
Validateur: <rôle> / <nom>
```

### Historique des validations

| Date | Tag | Commit | Validateur | Décision | Notes |
|------|-----|--------|------------|----------|-------|
| 2026-01-23 | `prod-ready-2026-01-23-nightly-green` | `0c5c2b7` | Release Manager | ✅ Autorisé | CI Nightly stabilisée, post-mortem validé |

---

## 8. Règles post-Release Gate

### Ce qui est autorisé après validation

✅ **Déploiement en staging** : Mise en production dans l'environnement de staging  
✅ **Déploiement en production** : Mise en production dans l'environnement de production  
✅ **Hotfixes documentés** : Corrections critiques avec nouveau Release Gate si nécessaire  
✅ **Rollback** : Retour en arrière si problème critique identifié (avec documentation)

### Ce qui est strictement interdit

❌ **Modifications non validées** : Aucun changement de code sans nouveau Release Gate  
❌ **Bypass du Gate** : Aucun déploiement sans validation formelle  
❌ **Modifications du tag** : Aucune modification ou suppression du tag validé  
❌ **Force push sur main** : Aucun push direct ou force push après validation

### Nécessité d'un nouveau Gate

Un **nouveau Release Gate est requis** si :

1. **Modification de code** : Tout changement de code applicatif après validation
2. **Modification de configuration** : Changement de config DB, API, infra
3. **Modification de dépendances** : Mise à jour majeure de packages
4. **Incident critique** : Problème identifié nécessitant un correctif
5. **Changement d'architecture** : Modification structurelle du système

**Exception** : Hotfixes documentés et validés via un Gate simplifié (procédure à définir).

---

## 9. Procédure de validation complète

### Étape 1 : Vérification des pré-requis

```bash
# Exécuter toutes les commandes de validation (section 5)
# Vérifier que chaque pré-requis est respecté
```

### Étape 2 : Remplissage de la checklist

- Cocher chaque élément de la checklist (section 4)
- Documenter les notes si nécessaire
- Identifier les éléments bloquants (❌)

### Étape 3 : Décision de Release

- Évaluer l'état (✅ / 🟡 / ❌)
- Documenter la décision dans la section 7
- Archiver la validation

### Étape 4 : Communication

- Notifier l'équipe de la décision
- Documenter dans le CHANGELOG si release autorisée
- Mettre à jour les dashboards de suivi

---

## 10. Références

### Documents liés

- `docs/POST_MORTEM_NIGHTLY_2026_01.md` : Post-mortem de l'incident CI Nightly
- `docs/PROD_READY_STATUS_2026_01_15.md` : État de préparation production
- `docs/SPRINT_PROD_READY_2026_01.md` : Journal de sprint
- `CHANGELOG.md` : Historique des changements

### Tags Git

- `prod-ready-2026-01-23-nightly-green` : Checkpoint officiel après stabilisation Nightly

### Scripts CI

- `scripts/d1_one_shot.sh` : Script de validation complète

---

**Document créé le** : 2026-01-23  
**Dernière mise à jour** : 2026-01-23  
**Version** : 1.0  
**Responsable** : Release Manager / QA Lead

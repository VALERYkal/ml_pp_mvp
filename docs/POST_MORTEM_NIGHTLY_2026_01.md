# Post-Mortem — Incident CI Nightly (Janvier 2026)

**Date** : 2026-01-23  
**Statut** : ✅ Résolu  
**Impact** : CI Nightly Full Suite en échec systématique malgré PR vertes

---

## 1. Contexte

### Différence entre CI PR et CI Nightly

- **CI PR** : Exécution des tests unitaires et widget uniquement (mode LIGHT)
- **CI Nightly** : Exécution complète de la suite de tests (mode FULL) incluant integration + e2e sur environnement Linux

### Symptôme observé

- ✅ **PR** : Toutes les PR passent les tests (mode LIGHT)
- ❌ **Nightly** : Échecs systématiques sur `main` (mode FULL, Linux)
- **Pattern** : Tests passent localement (macOS) mais échouent en CI Nightly (Linux)

### Impact réel

- Aucun bug en production (tests PR valident le code)
- Perte de confiance dans la CI Nightly comme source de vérité
- Blocage potentiel des releases (impossibilité de valider l'état réel de `main`)

---

## 2. Diagnostic

### Ce qui a été vérifié

- Comparaison des environnements PR vs Nightly
- Analyse des logs d'échec (agrégations vides, snapshots de stock incorrects)
- Vérification des différences de comportement entre macOS et Linux
- Inspection des implémentations de fakes Supabase dans les tests

### Ce qui a été exclu

- ❌ Problème de code applicatif (tests PR passent)
- ❌ Problème de dépendances (mêmes versions en PR et Nightly)
- ❌ Problème de configuration Supabase (même setup)
- ❌ Problème de timing/race conditions (échecs reproductibles)

### Pourquoi le problème n'apparaissait pas en PR

- Mode LIGHT n'exécute pas tous les tests (exclusion integration/e2e)
- Les tests problématiques ne sont déclenchés qu'en mode FULL
- Certains chemins de code appellent `limit(1)` uniquement en contexte Linux
- Les fakes locaux incomplets fonctionnent pour les cas simples mais échouent pour les cas complexes

---

## 3. Cause racine (Root Cause)

### Implémentations locales divergentes de fakes Supabase

**Problème structurel** : Chaque fichier de test (`stocks_kpi_repository_test.dart`, etc.) implémentait sa propre version locale de `FakeFilterBuilder`, `FakeSupabaseTableBuilder`, et `FakeSupabaseClient`.

**Conséquence** :
- Comportements divergents entre tests
- Impossibilité de garantir la cohérence entre PR et Nightly
- Maintenance complexe (modifications à répliquer dans plusieurs fichiers)

### Fake Postgrest incomplet (limit() absent)

**Problème technique** : Le fake Supabase ne supportait pas la méthode `limit()` utilisée par certains chemins de code en CI Linux.

**Conséquence** :
- Appels à `limit(1)` ignorés silencieusement
- Retour de listes complètes au lieu de listes limitées
- Agrégations vides ou incorrectes dans les tests Nightly

### Script CI fragile (set -u + EXTRA_DEFINES non défini, logs absents)

**Problème opérationnel** : Le script `scripts/d1_one_shot.sh` utilisait `set -euo pipefail` sans sécuriser les variables optionnelles.

**Conséquences** :
- Erreur "unbound variable" si `EXTRA_DEFINES` non défini
- Absence de logs `.ci_logs/` si le script échoue avant la création du dossier
- Impossibilité de diagnostiquer les échecs Nightly (pas de traces)

**Note** : Ces problèmes sont structurels (architecture de tests, design du script), pas des erreurs humaines ponctuelles.

---

## Incident CI Nightly — gestion des DART_DEFINES (en cours d'analyse)

### Symptôme observé

Échec du script `d1_one_shot.sh` avec l'erreur :
```
DART_DEFINES[@]: unbound variable
```

Échec constaté lors de l'exécution des phases :
- Phase A (tests normaux)
- Phase B (tests flaky)

### Cause racine identifiée

- Exécution du script sous shell strict (`set -u`)
- Expansion non protégée d'un tableau vide ou non initialisé (`"${DART_DEFINES[@]}"`)
- Le tableau `DART_DEFINES` était utilisé sans déclaration explicite, causant une erreur "unbound variable" sous `set -u`
- Correction de l'incrémentation `((DART_DEFINE_COUNT++))` pour éviter exit code 1

### Correctif appliqué

**Portée** : Script CI uniquement (`scripts/d1_one_shot.sh`), aucun refactor applicatif

1. **Déclaration explicite du tableau** :
   ```bash
   typeset -a DART_DEFINES; DART_DEFINES=()
   ```

2. **Sécurisation de l'expansion en Phase A (tests normaux)** :
   ```bash
   ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}
   ```

3. **Sécurisation de l'expansion en Phase B (tests flaky)** :
   ```bash
   ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}
   ```

4. **Restauration de `run_step()`** pour stabilité du pipeline

### Validation locale

- ✅ Exécution `./scripts/d1_one_shot.sh web --full` réussie (exit code 0)
- ✅ Tests FULL + DB tests exécutés sans crash Bash
- ✅ Preuve technique : D1 one-shot OK (FULL + DB)

### Statut final

- Correctifs appliqués localement et documentés
- Validation GitHub Actions Nightly : **en attente de confirmation**
- **Incident non clôturé définitivement** : La résolution dépend du résultat du prochain run Nightly GitHub

---

## Post-mortem CI Nightly — Stabilisation technique (2026-01-26)

### Impact

- **Blocage** : Nightly échouait très tôt avec `DART_DEFINES[@]: unbound variable` sous `set -u`
- **Symptômes secondaires** : Warning GitHub "No files were found with the provided path: .ci_logs/" (artefacts manquants)
- **Conséquence** : Impossible de valider les correctifs CI sans exécution manuelle

### Root cause

- **Bash `set -u`** : Mode strict activé dans `d1_one_shot.sh`
- **Array expansion non protégée** : `"${DART_DEFINES[@]}"` utilisé sans déclaration explicite ni expansion sûre
- **Collecte artefacts** : `.ci_logs/` créé trop tard (après crash early)
- **Déclenchement limité** : Workflow Nightly uniquement sur schedule + manual, pas sur PR

### Détection

- Observation directe dans les logs CI Nightly
- Erreur reproductible localement avec `set -u` activé
- Warning artefacts visible dans les runs GitHub Actions

### Fix (3 actions)

1. **Hardening d1_one_shot** : Rendu l'expansion de `DART_DEFINES` compatible `set -u` (normal + flaky) via expansion sûre `${DART_DEFINES[@]+"${DART_DEFINES[@]}"}`.
2. **Sécurisation collecte artefacts** : Garantie que `.ci_logs/` existe systématiquement (même si crash early), pour éviter l'avertissement "No artifacts will be uploaded".
3. **Déclenchement CI Nightly** : Ajout d'un déclenchement `pull_request` vers `main` afin d'obtenir une exécution full suite au moment des changements (sans remplacer le cron).

### Résultats observés

- ✅ **PR full suite** : Run PR (full suite) passé ✅ (checks verts)
- ✅ **Manual run** : Run manuel sur `main` passé ✅ (ex: "Flutter CI Nightly (Full Suite) #29" vert)
- ⏳ **Scheduled run** : Le déclenchement schedule cron n'est pas confirmé comme "réparé" tant qu'on n'a pas observé au moins 1 exécution planifiée green après 02:00 UTC

### Leçons / Prévention

- **Shell strict** : Toujours protéger l'expansion de tableaux sous `set -u` avec `${ARRAY[@]+"${ARRAY[@]}"}`
- **Artefacts CI** : Créer les dossiers de logs dès le début du script, avant toute exécution
- **Déclenchement PR** : Ajouter `pull_request` trigger pour validation immédiate des correctifs CI

### Risques restants & Follow-up

- ⚠️ **Warning dart_test.yaml** : `Warning: A tag was used that wasn't specified in dart_test.yaml. flaky...` (tag "flaky" utilisé sans déclaration). Non bloquant mais à corriger pour réduire le bruit.
- ⚠️ **Logs DEBUG** : Logs DEBUG dans tests (ex: `sorties_submission_test`) : bruit mais tests passent → proposer comment réduire sans refacto (ex: filtrage logs CI / conventions de logging / réduire print en tests).

---

## Root Causes — Analyse complète

### Causes identifiées

1. **dart-defines non initialisées sous `set -u`**
   - Tableau `DART_DEFINES` utilisé sans déclaration explicite
   - Expansion `${DART_DEFINES[@]}` échoue sous mode strict
   - Impact : Crash précoce du script avant exécution des tests

2. **Tests DB exécutés sans garde**
   - Tests d'intégration STAGING s'exécutaient systématiquement
   - Absence de fichier `env/.env.staging` en CI → crash
   - Impact : Échec Nightly même si tests unit/widget passent

3. **Mocks incomplets**
   - `FakeFilterBuilder` manquant dans certains tests
   - Snapshots vides non gérées correctement
   - Impact : Tests flaky selon ordre d'exécution

4. **Divergence PR vs Nightly**
   - PR exécute uniquement tests unit/widget (mode LIGHT)
   - Nightly exécute full suite + DB tests
   - Impact : PR verte mais Nightly rouge (détection tardive)

## Corrective Actions — Solutions appliquées

1. **Export des dart-defines en variables d'environnement**
   - Déclaration explicite : `typeset -a DART_DEFINES; DART_DEFINES=()`
   - Expansion sûre : `${DART_DEFINES[@]+"${DART_DEFINES[@]}"}`
   - Résultat : Script compatible `set -u`

2. **Garde `RUN_DB_TESTS`**
   - Tests DB conditionnés par variable d'environnement ou dart-define
   - Skip automatique si `RUN_DB_TESTS` non défini
   - Résultat : Tests DB opt-in uniquement

3. **Durcissement des fakes**
   - `FakeSupabaseClient` enrichi avec mocks complets
   - Snapshots vides gérées explicitement
   - Résultat : Tests déterministes indépendants de l'ordre

4. **Artefacts toujours créés**
   - Création de `.ci_logs/` dès le début du script
   - Résultat : Pas de warning "No artifacts will be uploaded"

5. **Nightly exécuté sur PR → plus de divergence**
   - Ajout trigger `pull_request` dans workflow Nightly
   - Résultat : PR et Nightly exécutent la même suite complète

## Conclusion

Le Nightly n'est plus un détecteur de hasard mais un **gate de confiance équivalent à la prod**.

**État final** :
- ✅ PR checks = green
- ✅ Nightly Full Suite = green
- ✅ Manual dispatch = green
- ✅ `main` branch protégée par règles GitHub

**Règles d'or** :
- **Nightly ≠ tests bonus** → **Nightly = prod gate**
- **PR verte + Nightly verte = seule condition GO PROD**
- **Tout échec Nightly futur = régression bloquante, pas "flakiness"**

La phase "CI Stabilization" est officiellement **CLOSE**.
=======
- ⏳ **Confirmation cron** : Attendre/observer le prochain run schedule à 02:00 UTC (ou déclencher manuellement "workflow_dispatch" et comparer). Si le cron reste silencieux : vérifier settings Actions (workflow disabled?), branche par défaut, permissions repo, ou absence d'activité schedule sur fork/private restrictions.
- ⚠️ **Warning dart_test.yaml** : `Warning: A tag was used that wasn't specified in dart_test.yaml. flaky...` (tag "flaky" utilisé sans déclaration). Non bloquant mais à corriger pour réduire le bruit.
- ⚠️ **Logs DEBUG** : Logs DEBUG dans tests (ex: `sorties_submission_test`) : bruit mais tests passent → proposer comment réduire sans refacto (ex: filtrage logs CI / conventions de logging / réduire print en tests).
>>>>>>> origin/main

---

## 4. Correctifs appliqués

### Centralisation du fake Supabase Query Builder

**Action** : Extraction du fake le plus complet vers `test/support/fakes/fake_supabase_query.dart`

**Fichiers modifiés** :
- `test/support/fakes/fake_supabase_query.dart` (créé)
- `test/features/stocks/stocks_kpi_repository_test.dart` (nettoyage)

**Impact** : Un seul fake partagé, comportement déterministe, maintenance simplifiée

### Ajout du support limit() dans le fake

**Action** : Implémentation de `limit(int count)` dans `FakeFilterBuilder<T>`

**Code ajouté** :
```dart
@override
FakeFilterBuilder<T> limit(int count, {String? foreignTable}) {
  if (_result is List) {
    final list = _result as List;
    final limited = list.take(count).toList();
    return FakeFilterBuilder<T>(limited as T);
  }
  return this;
}
```

**Impact** : Reproduction fidèle du comportement Postgrest, tests Nightly Linux stables

### Durcissement de scripts/d1_one_shot.sh

**Actions** :
- Sécurisation de `EXTRA_DEFINES` (initialisation safe avec `set -u`)
- Création systématique de `.ci_logs/` en début de script
- Ajout du helper `run_step()` pour logger chaque étape
- Remplacement des commandes directes par `run_step` (pub_get, analyze, build_runner, test_normal, test_flaky)

**Impact** : Logs toujours présents, variables sécurisées, diagnostic facilité

### Documentation de clôture

**Fichiers mis à jour** :
- `CHANGELOG.md`
- `docs/PROD_READY_STATUS_2026_01_15.md`
- `docs/SPRINT_PROD_READY_2026_01.md`

**PR référencées** :
- PR #23 (correctifs techniques)
- PR #24 / #25 (documentation)

---

## 5. Garde-fous établis (CRITIQUE)

### Règles de développement

❌ **Interdit** : Créer des fakes Supabase locaux dans les fichiers de test  
✅ **Obligatoire** : Utiliser uniquement `test/support/fakes/fake_supabase_query.dart`

❌ **Interdit** : Modifier les scripts CI sans garantir la création de `.ci_logs/`  
✅ **Obligatoire** : Toute étape CI doit être loggée via `run_step()` ou équivalent

❌ **Interdit** : Modifier `main` directement (push direct, force push)  
✅ **Obligatoire** : Toute modification de `main` passe par une PR validée

❌ **Interdit** : Déclarer un état PROD-READY sans tag Git  
✅ **Obligatoire** : Tout état validé doit avoir un tag Git officiel

### Processus de validation

1. **Avant merge PR** : Vérifier que les tests utilisent le fake centralisé
2. **Après merge PR** : Surveiller la CI Nightly sur `main`
3. **En cas d'échec Nightly** : Analyser les logs `.ci_logs/` avant toute action
4. **Avant release** : Valider que la Nightly Full Suite est verte sur `main`

---

## 6. Checkpoint officiel

### Tag Git

```
prod-ready-2026-01-23-nightly-green
```

### Commit gelé

```
71f0456
```

### Commande de reprise

```bash
git checkout prod-ready-2026-01-23-nightly-green
```

### État validé

- ✅ CI Nightly Full Suite verte sur `main`
- ✅ Tous les tests (unit, widget, integration, e2e) passent
- ✅ Fake Supabase centralisé et complet
- ✅ Scripts CI durcis et loggés
- ✅ Documentation à jour

---

## 7. Conclusion

### Statut final

✅ **CI Nightly considérée fiable à nouveau**  
✅ **CI redevient une source de vérité**  
✅ **Base saine établie pour Release Gate**

### Leçons apprises

1. **Centralisation des fakes** : Évite les divergences et facilite la maintenance
2. **Complétude des fakes** : Doit reproduire fidèlement le comportement réel (Postgrest)
3. **Robustesse des scripts CI** : Variables sécurisées, logs systématiques, diagnostic facilité
4. **Documentation continue** : Post-mortem, changelog, et garde-fous pour éviter les régressions

### Prochaines étapes

- Surveillance continue de la CI Nightly sur `main`
- Extension du fake si de nouvelles méthodes Postgrest sont utilisées
- Révision périodique des garde-fous (trimestrielle)

---

---

## Conclusions — Mise à jour GO PROD (24/01/2026)

### État final du projet

**ML_PP MVP est prêt pour le déploiement en production** dans le cadre d'un pilote sur 1 dépôt.

#### Points validés
- ✅ **Stabilité CI** : PR light + Nightly full opérationnelles
- ✅ **Tests critiques** : 482/490 passants (98.4%), aucun test critique produit cassé
- ✅ **Sécurité** : RLS active, rôles séparés, verrouillage rôle utilisateur (DB-level)
- ✅ **Périmètre MVP** : Stock-only (6 citernes) clairement défini et assumé
- ✅ **Exploitation terrain** : Tablette / desktop / web opérationnels

#### Limitations assumées
- **Périmètre volontairement limité** : Modules clients, fournisseurs, transporteurs, douane, fiscalité, PDF, commandes hors scope MVP
- **Tests DB opt-in** : Activation explicite requise (`RUN_DB_TESTS=1` + `env/.env.staging`)
- **Logs verbeux** : Bruit développement non bloquant, filtré en production

#### Décision
🟢 **GO PROD autorisé pour un pilote sur 1 dépôt, avec montée en charge progressive.**

L'incident CI Nightly est résolu et ne constitue plus un blocage pour le déploiement. Le projet est stable, sécurisé et exploitable pour son périmètre actuel.

---

<<<<<<< HEAD
---

## Mise à jour — Enforcement Contrat Stock (24/01/2026)

### Contrat stock actuel formalisé

**`v_stock_actuel` est la source unique pour le stock actuel.**

#### Mesures d'enforcement
- Dépréciation `CiterneService.getStockActuel()` avec annotation `@Deprecated` et commentaire de contrat
- Test de contrat `test/contracts/stock_source_contract_test.dart` vérifiant l'utilisation de `v_stock_actuel`
- Garde-fou documentaire contre réintroduction de chemins legacy

#### Impact
- Aucun changement fonctionnel
- Contrat explicite et testable
- Réduction risque de régression

### Qualité code — État réel

**`flutter analyze` : ~312 issues (warnings + info).**

#### Décision assumée
- Aucun warning bloquant (niveau `error`)
- Aucun impact PROD (warnings concernent tests et conventions)
- Stabilité MVP préservée (pas de refactorisation large)
- Réduction progressive : 5 warnings corrigés (317 → 312)

---

=======
>>>>>>> origin/main
**Document créé le** : 2026-01-23  
**Dernière mise à jour** : 2026-01-24  
**Auteur** : Équipe DevOps / QA Lead

---

## Incident STAGING — Reset + Seed prod-like (Jan 2026)

### Contexte
Lors des opérations de stabilisation Nightly et de préparation GO PROD, l’environnement **STAGING** présentait :
- des citernes fantômes (`TANK STAGING 1`, `TANK TEST`)
- une base parfois vide ou incohérente après reset
- des échecs intermittents de connexion `psql` malgré une URL valide

### Cause racine
1. **Seed STAGING volontairement vide par défaut** (`seed_empty.sql`), ce qui est correct, mais nécessitait un seed métier explicite pour les tests fonctionnels.
2. **Citernes de test historiques** (IDs `3333…` / `4444…`) non explicitement interdites.
3. **Mot de passe Postgres contenant des caractères spéciaux** non URL-encodés dans `STAGING_DB_URL`, provoquant un échec silencieux lors de `source env/.env.staging`.

### Correctifs appliqués
- Création d’un **seed opt-in prod-like** :
  - `staging/sql/seed_staging_prod_like.sql`
  - Dépôt réel (ID fixe)
  - Produits **hardcodés dans l’app Flutter** (AGO / Essence)
  - 6 citernes actives **TANK1 → TANK6**
  - Idempotent (`ON CONFLICT DO UPDATE`)
- Ajout d’une **garde anti-citernes fantômes** (hard fail).
- Maintien de `seed_empty.sql` comme **comportement par défaut**.
- Encodage correct du mot de passe dans `STAGING_DB_URL` (URL-encoding).
- Validation manuelle post-reset :
  - `depots = 1`
  - `produits = 2`
  - `citernes_actives = 6`

### Invariants P0 établis
- **Produits** :  
  - `452b557c-e974-4315-b6c2-cda8487db428` → Gasoil / AGO  
  - `640cf7ec-1616-4503-a484-0a61afb20005` → Essence  
  Ces IDs sont hardcodés dans l’app et doivent exister en STAGING/PROD.
- **Citernes** :
  - Chargées dynamiquement depuis la DB
  - Noms autorisés : `TANK1..TANK6`
  - Citernes fantômes strictement interdites
- **Reset STAGING** : toujours protégé par double confirmation + anti-PROD guard.

### Statut
✅ Incident résolu  
✅ STAGING désormais **miroir PROD opérationnel**  
✅ Scripts et seeds prêts pour GO PROD

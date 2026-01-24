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

**Document créé le** : 2026-01-23  
**Dernière mise à jour** : 2026-01-24  
**Auteur** : Équipe DevOps / QA Lead

# 🗺️ Roadmap D3-D6 — Stabilisation Production-Ready

## 📋 Vue d'ensemble

Cette roadmap complète l'AXE D (Build & Tooling) après D1 (build one-shot) et D2 PRO (CI hardening).

**Objectif** : rendre les tests stables, rapides, et diagnosticables en production.

---

## ✅ D3.1 — Test Discovery Centralisée [TERMINÉ — 10/01/2026]

### Objectif
Éliminer la duplication des patterns `find ... ! -path ...` entre le script et les workflows CI.

### Solution
- **Source unique de vérité** : `scripts/d1_one_shot.sh`
- Mode LIGHT : `find test -name "*_test.dart"` avec exclusions centralisées
- Mode FULL : `flutter test` (tous les tests)
- Affichage du nombre de tests découverts pour validation immédiate

### Approche abandonnée
- Manifest avec imports explicites (`test/run_ci_light.dart`) : trop fragile pour ~100 fichiers de tests

### Impact
- ✅ Zéro duplication
- ✅ Robuste aux ajouts de tests
- ✅ Compteur de tests pour détection de régressions

---

## 🔜 D3.2 — Quarantine des Tests Flaky [TERMINÉ — 10/01/2026]

### Objectif
Éliminer les surprises : les tests instables ne doivent pas bloquer les PRs.

### Actions
1. **Ajouter un tag** : `@Tags(['flaky'])`
2. **Convention de nommage** : `*_flaky_test.dart`
3. **Light CI** : exclut les tests flaky
4. **Nightly CI** : inclut les tests flaky, mais rapport séparé

### Avantages
- Les PRs ne sont pas bloquées par des tests instables
- Les tests flaky sont toujours exécutés (nightly) et trackés
- Pression pour les fixer (visibles dans le rapport nightly)

---

## ✅ D4 — Release Gate + Observabilité Minimale [TERMINÉ — 10/01/2026]

### Objectif
Une seule commande locale pour valider si un commit est livrable (analyze + tests light non-flaky + builds essentiels), avec logs propres, diagnostic rapide, et garde-fous anti-secrets.

### Livré
1. **Script `scripts/d4_release_gate.sh`** :
   - Orchestrateur : pub get → analyze → tests light → build(s)
   - Flags optionnels : `--android`, `--ios` (web par défaut)
   - Logs structurés : `.ci_logs/d4_*.log` (analyze, tests, builds)
   - Timings : `.ci_logs/d4_timings.txt` (durée par phase)
   - Header observabilité : timestamp, git SHA, flutter version

2. **Script `scripts/d4_env_guard.sh`** :
   - Vérification `SUPABASE_ENV` obligatoire (PROD/STAGING)
   - Scan anti-secrets des logs (patterns sensibles détectés sans exposer valeurs)
   - Échec propre si secrets détectés

3. **Flags non cassants dans D1** :
   - `--skip-pub-get`, `--skip-analyze`, `--skip-build-runner`, `--skip-build`, `--tests-only`
   - Backward-compatible (comportement par défaut inchangé)

4. **Documentation `docs/RELEASE_RUNBOOK.md`** :
   - Commandes locales, où trouver les logs, troubleshooting, checklist RC

### Avantages
- ✅ Une seule commande pour valider un commit livrable
- ✅ Logs propres (pas de secrets exposés, vérifié automatiquement)
- ✅ Observabilité (timings, git SHA, flutter version)
- ✅ Diagnostic rapide (tail 60 lignes en cas d'échec)
- ✅ Sécurité stricte (SUPABASE_ENV obligatoire, scan anti-secrets)

---

## 🔜 D5 — Performance & Fiabilité CI [TODO]

### Objectif
Garder PR < 3 min, nightly rapide et stable.

### Actions
1. **Cache agressif** :
   - `~/.pub-cache`
   - `.dart_tool`
   - `build/` (outputs de build_runner)
2. **Concurrency** :
   - Annuler les runs PR précédents quand on pushe (éviter la file d'attente)
3. **Timeouts propres** :
   - Test timeout : 10 min
   - Build timeout : 5 min
   - Garder les logs même si timeout

### Résultats attendus
- PR feedback < 3 min
- Nightly < 10 min
- Réduction des "stuck jobs"

---

## 🔜 D6 — Branch Protection Propre [TODO]

### Objectif
Règles GitHub cohérentes et sans surprises.

### Actions
1. **Required check** : `Run Flutter tests` ✅ (déjà actif)
2. **Optionnel** : "Require branches up to date before merging" (si stricte)
3. **Interdire push direct main** ✅ (déjà actif)
4. **Interdire force push** sur `main`

### Validation
- Vérifier que les règles sont visibles dans Settings > Branches
- Tester un merge sans passer le check (doit être bloqué)

---


## 📊 Statut Global AXE D (Vue Claire)

| Axe | Statut | Commentaire |
|-----|--------|-------------|
| D1 | ✅ Verrouillé | Script source de vérité |
| D2 | ✅ Verrouillé | CI PR light + nightly full |
| D3.1 | ✅ Verrouillé | Test discovery centralisée |
| D3.2 | ✅ Verrouillé | Quarantine flaky |
| **D3 (global)** | **🟢 STABLE** | **CI fiable** |
| D4 | ✅ TERMINÉ | Release gate + observabilité minimale |
| D5 | ⏭️ Optionnel | Nettoyage legacy |
| D6 | ⏭️ Optionnel | Durcissement final |

### ✅ Statut Détaillé par Phase

| Phase | Statut | Date | Impact |
|-------|--------|------|--------|
| D1 — Build one-shot | ✅ VERROUILLÉ | 10/01/2026 | Build anti-injection, nettoyage legacy, diagnostics |
| D2 PRO — CI hardening | ✅ VERROUILLÉ | 10/01/2026 | PR light + nightly full, artefacts, quality gates |
| D3.1 — Test discovery centralisée | ✅ TERMINÉ | 10/01/2026 | Zéro duplication patterns find |
| D3.2 — Quarantine flaky tests | ✅ TERMINÉ & VERROUILLÉ | 10/01/2026 | Éliminer les surprises PR |
| D4 — Release gate + observabilité | ✅ TERMINÉ | 10/01/2026 | Une commande pour valider livrable, logs propres, anti-secrets |

### 🎯 Point de Bascule

👉 **Tu es officiellement sorti de la zone "CI fragile".**

**Infrastructure CI stable** :
- ✅ Script central (`d1_one_shot.sh`) source de vérité
- ✅ PR light rapide et fiable (~2-3 min, feedback immédiat)
- ✅ Nightly full exhaustif (tous les tests, validation complète)
- ✅ Tests flaky quarantainés (PR stable, nightly truthful)
- ✅ Logs persistés et consultables (artefacts CI)
- ✅ Quality gates explicites (errors = KO, warnings tolérés)

**Les phases D4-D6 sont optionnelles** et peuvent être faites progressivement selon les besoins :
- D4 : Observabilité (métriques, timings, rapport de performance)
- D5 : Performance (cache agressif, optimisations)
- D6 : Branch protection (règles GitHub strictes)
---

## 🎯 Prochaine Action Recommandée

**GO D3.2 — Quarantine des tests flaky**

C'est le meilleur ROI après D3.1 : ça évite 80% des frustrations "le CI est rouge mais je n'ai rien changé".

Si tu veux lancer D3.2, dis-le et je te donne le prompt Cursor ultra-ciblé (fichiers exacts + critères d'acceptation + commande CI).

---

## 📝 Notes Importantes

- **Ne pas se disperser** : terminer D3 avant de passer à D4/D5/D6.
- **Chaque phase est indépendante** : on peut s'arrêter à tout moment.
- **Principe du MVP** : livrer petit, valider, itérer.

---

## 🔗 Références

- [CHANGELOG.md](../CHANGELOG.md) : historique détaillé des changements
- [scripts/d1_one_shot.sh](../scripts/d1_one_shot.sh) : script central de validation
- [.github/workflows/flutter_ci.yml](../.github/workflows/flutter_ci.yml) : workflow PR light
- [.github/workflows/flutter_ci_nightly.yml](../.github/workflows/flutter_ci_nightly.yml) : workflow nightly full
